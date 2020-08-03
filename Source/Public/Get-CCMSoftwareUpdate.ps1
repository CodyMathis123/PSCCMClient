function Get-CCMSoftwareUpdate {
    <#
        .SYNOPSIS
            Get pending MEMCM patches for a machine
        .DESCRIPTION
            Uses CIM to find MEMCM patches that are currently available on a machine.
        .PARAMETER IncludeDefs
            A switch that will determine if you want to include AV Definitions in your query
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get pending MEMCM patches for
        .PARAMETER ComputerName
            Computer name(s) which you want to get pending MEMCM patches for
        .PARAMETER PSSesison
            PSSesisons which you want to get pending MEMCM patches for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS C:\> Get-CCMSoftwareUpdate -Computer Testing123
            will return all non-AV Dev patches for computer Testing123
        .NOTES
            FileName:    Get-CCMSoftwareUpdate.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-15
            Updated:     2020-03-09
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMUpdate')]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDefs,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        $EvaluationStateMap = @{
            23 = 'WaitForOrchestration'
            22 = 'WaitPresModeOff'
            21 = 'WaitingRetry'
            20 = 'PendingUpdate'
            19 = 'PendingUserLogoff'
            18 = 'WaitUserReconnect'
            17 = 'WaitJobUserLogon'
            16 = 'WaitUserLogoff'
            15 = 'WaitUserLogon'
            14 = 'WaitServiceWindow'
            13 = 'Error'
            12 = 'InstallComplete'
            11 = 'Verifying'
            10 = 'WaitReboot'
            9  = 'PendingHardReboot'
            8  = 'PendingSoftReboot'
            7  = 'Installing'
            6  = 'WaitInstall'
            5  = 'Downloading'
            4  = 'PreDownload'
            3  = 'Detecting'
            2  = 'Submitted'
            1  = 'Available'
            0  = 'None'
        }

        $ComplianceStateMap = @{
            0 = 'NotPresent'
            1 = 'Present'
            2 = 'PresenceUnknown/NotApplicable'
            3 = 'EvaluationError'
            4 = 'NotEvaluated'
            5 = 'NotUpdated'
            6 = 'NotConfigured'
        }
        #$UpdateStatus.Get_Item("$EvaluationState")
        #endregion status type hashtable

        $Filter = switch ($IncludeDefs) {
            $true {
                "ComplianceState=0"
            }
            Default {
                "NOT (Name LIKE '%Definition%' OR Name Like 'Security Intelligence Update%') and ComplianceState=0"
            }
        }

        $getUpdateSplat = @{
            Filter    = $Filter
            Namespace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_SoftwareUpdate'
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
                [ciminstance[]]$MissingUpdates = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getUpdateSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getUpdateSplat @connectionSplat
                    }
                }
                if ($MissingUpdates -is [Object] -and $MissingUpdates.Count -gt 0) {
                    foreach ($Update in $MissingUpdates) {
                        $Result['ArticleID'] = $Update.ArticleID
                        $Result['BulletinID'] = $Update.BulletinID
                        $Result['ComplianceState'] = $ComplianceStateMap[[int]$($Update.ComplianceState)]
                        $Result['ContentSize'] = $Update.ContentSize
                        $Result['Deadline'] = $Update.Deadline
                        $Result['Description'] = $Update.Description
                        $Result['ErrorCode'] = $Update.ErrorCode
                        $Result['EvaluationState'] = $EvaluationStateMap[[int]$($Update.EvaluationState)]
                        $Result['ExclusiveUpdate'] = $Update.ExclusiveUpdate
                        $Result['FullName'] = $Update.FullName
                        $Result['IsUpgrade'] = $Update.IsUpgrade
                        $Result['MaxExecutionTime'] = $Update.MaxExecutionTime
                        $Result['Name'] = $Update.Name
                        $Result['NextUserScheduledTime'] = $Update.NextUserScheduledTime
                        $Result['NotifyUser'] = $Update.NotifyUser
                        $Result['OverrideServiceWindows'] = $Update.OverrideServiceWindows
                        $Result['PercentComplete'] = $Update.PercentComplete
                        $Result['Publisher'] = $Update.Publisher
                        $Result['RebootOutsideServiceWindows'] = $Update.RebootOutsideServiceWindows
                        $Result['RestartDeadline'] = $Update.RestartDeadline
                        $Result['StartTime'] = $Update.StartTime
                        $Result['UpdateID'] = $Update.UpdateID
                        $Result['URL'] = $Update.URL
                        $Result['UserUIExperience'] = $Update.UserUIExperience
                        [pscustomobject]$Result
                    }
                }
                else {
                    Write-Verbose "No updates found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
