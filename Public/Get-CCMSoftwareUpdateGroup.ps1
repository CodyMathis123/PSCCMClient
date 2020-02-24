function Get-CCMSoftwareUpdateGroup {
    <#
        .SYNOPSIS
            Get information for the Software Update Groups deployed to a computer, including compliance
        .DESCRIPTION
            Uses CIM to find information for the Software Update Groups deployed to a computer. This includes checking the currently
            reported 'compliance' for a software update group using the CCM_AssignmentCompliance CIM class
        .PARAMETER AssignmentName
            Provide an array of Software Update Group names to query for
        .PARAMETER AssignmentID
            Provide an array of Software Update Group assignemnt ID to query for
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get information for the Software Update Groups
        .PARAMETER ComputerName
            Computer name(s) which you want to get information for the Software Update Groups
        .PARAMETER PSSession
            PSSessions which you want to get information for the Software Update Groups
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determins what type of connection / command
            the ComputerName paramter is passed to.
        .EXAMPLE
            PS C:\> Get-CCMSoftwareUpdateGroup -Computer Testing123
                Will return all info available for the Software Update Groups deployed to Testing123
        .NOTES
            FileName:    Get-CCMSoftwareUpdateGroup.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-21
            Updated:     2020-02-23
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMSUG')]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$AssignmentName,
        [Parameter(Mandatory = $false)]
        [string[]]$AssignmentID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        $getSUGSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        $getSUGComplianceSplat = @{
            Namespace = 'ROOT\ccm\SoftwareUpdates\DeploymentAgent'
        }

        $suppressRebootMap = @{
            0 = 'Not Suppressed'
            1 = 'Workstations Suppressed'
            2 = 'Servers Suppressed'
            3 = 'Workstations and Servers Suppressed'
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
            }
            switch ($PSBoundParameters.ContainsKey('ConnectionPreference')) {
                $true {
                    $getConnectionInfoSplat['Prefer'] = $ConnectionPreference
                }
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'AssignmentName' {
                        [string]::Format('AssignmentName = "{0}"', [string]::Join('" OR AssignmentName = "', $AssignmentName))
                    }
                    'AssignmentID' {
                        [string]::Format('AssignmentID = "{0}"', [string]::Join('" OR AssignmentID = "', $AssignmentID))
                    }
                }
                $Filter = switch ($null -ne $FilterParts) {
                    $true {
                        [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                    }
                    $false {
                        ' '
                    }
                }
                $getSUGSplat['Query'] = [string]::Format('SELECT * FROM CCM_UpdateCIAssignment{0}', $Filter)

                [ciminstance[]]$DeployedSUG = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getSUGSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getSUGSplat @connectionSplat
                    }
                }
                if ($DeployedSUG -is [Object] -and $DeployedSUG.Count -gt 0) {
                    foreach ($SUG in $DeployedSUG) {
                        $Result['AssignmentName'] = $SUG.AssignmentName

                        #region Query CCM_AssignmentCompliance to return SUG compliance
                        $getSUGComplianceSplat['Query'] = [string]::Format('SELECT IsCompliant FROM CCM_AssignmentCompliance WHERE AssignmentID = "{0}"', $SUG.AssignmentID)
                        $AssignmentCompliance = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                Get-CimInstance @getSUGComplianceSplat @connectionSplat
                            }
                            $false {
                                Get-CCMCimInstance @getSUGComplianceSplat @connectionSplat
                            }
                        }
                        $Result['AssignmentCompliance'] = $AssignmentCompliance.IsCompliant
                        #endregion Query CCM_AssignmentCompliance to return SUG compliance

                        $Result['StartTime'] = $SUG.StartTime
                        $Result['EnforcementDeadline'] = $SUG.EnforcementDeadline
                        $Result['UseGMTTimes'] = $SUG.UseGMTTimes
                        $Result['NotifyUser'] = $SUG.NotifyUser
                        $Result['OverrideServiceWindows'] = $SUG.OverrideServiceWindows
                        $Result['RebootOutsideOfServiceWindows'] = $SUG.RebootOutsideOfServiceWindows
                        $Result['SuppressReboot'] = $suppressRebootMap[[int]$SUG.SuppressReboot]
                        $Result['UserUIExperience'] = $xml_Reserved1.SUMReserved.UserUIExperience
                        $Result['WoLEnabled'] = $SUG.WoLEnabled
                        # TODO - Determine if AssignmentAction needs figured out
                        $Result['AssignmentAction'] = $SUG.AssignmentAction
                        $Result['AssignmentFlags'] = $SUG.AssignmentFlags
                        $Result['AssignmentID'] = $SUG.AssignmentID
                        $Result['ConfigurationFlags'] = $SUG.ConfigurationFlags
                        $Result['DesiredConfigType'] = $SUG.DesiredConfigType
                        $Result['DisableMomAlerts'] = $SUG.DisableMomAlerts
                        $Result['DPLocality'] = $SUG.DPLocality
                        $Result['ExpirationTime'] = $SUG.ExpirationTime
                        $Result['LogComplianceToWinEvent'] = $SUG.LogComplianceToWinEvent
                        # ENHANCE - Parse NonComplianceCriticality
                        $Result['NonComplianceCriticality'] = $SUG.NonComplianceCriticality
                        $Result['PersistOnWriteFilterDevices'] = $SUG.PersistOnWriteFilterDevices
                        $Result['RaiseMomAlertsOnFailure'] = $SUG.RaiseMomAlertsOnFailure

                        #region store the 'Reserved1' property of the SUG as XML so we can parse the properties
                        [xml]$xml_Reserved1 = $SUG.Reserved1
                        $Result['StateMessageVerbosity'] = $xml_Reserved1.SUMReserved.StateMessageVerbosity
                        $Result['LimitStateMessageVerbosity'] = $xml_Reserved1.SUMReserved.LimitStateMessageVerbosity
                        $Result['UseBranchCache'] = $xml_Reserved1.SUMReserved.UseBranchCache
                        $Result['RequirePostRebootFullScan'] = $xml_Reserved1.SUMReserved.RequirePostRebootFullScan
                        #endregion store the 'Reserved1' property of the SUG as XML so we can parse the properties

                        $Result['SendDetailedNonComplianceStatus'] = $SUG.SendDetailedNonComplianceStatus
                        $Result['SettingTypes'] = $SUG.SettingTypes
                        $Result['SoftDeadlineEnabled'] = $SUG.SoftDeadlineEnabled
                        $Result['StateMessagePriority'] = $SUG.StateMessagePriority
                        $Result['UpdateDeadline'] = $SUG.UpdateDeadline
                        $Result['UseSiteEvaluation'] = $SUG.UseSiteEvaluation
                        $Result['Reserved2'] = $SUG.Reserved2
                        $Result['Reserved3'] = $SUG.Reserved3
                        $Result['Reserved4'] = $SUG.Reserved4
                        #region loop through the AssignedCIs and cast them as XML so they can be easily work with
                        $Result['AssignedCIs'] = foreach ($AssignCI in $SUG.AssignedCIs) {
                            ([xml]$AssignCI).CI
                        }
                        #endregion loop through the AssignedCIs and cast them as XML so they can be easily work with

                        [pscustomobject]$Result
                    }
                }
                else {
                    Write-Verbose "No deployed SUGs found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
