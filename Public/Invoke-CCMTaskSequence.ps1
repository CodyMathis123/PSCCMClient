function Invoke-CCMTaskSequence {
    <#
        .SYNOPSIS
            Invoke deployed task sequence on a computer
        .DESCRIPTION
            This function can invoke a task sequence that is deployed to a computer. It has an optional 'Force' parameter which will
            temporarily change the RepeatRunBehavioar, and MandatoryAssignments parameters to force a task sequence to run regardless
            of the schedule and settings assigned to it.

            Note that the parameters for filter are all joined together with OR.
        .PARAMETER PackageID
            An array of PackageID to filter on
        .PARAMETER TaskSequenceName
            An array of task sequence names to filter on
        .PARAMETER Force
            Force the task sequence to run by temporarily changing the RepeatRunBehavioar, and MandatoryAssignments parameters as shown below

                Property = @{
                    ADV_RepeatRunBehavior    = 'RerunAlways'
                    ADV_MandatoryAssignments = $true
                }
        .PARAMETER CimSession
            Provides CimSession to invoke the task sequence on
        .PARAMETER ComputerName
            Provides computer names to invoke the task sequence on
        .PARAMETER PSSession
            Provides PSSessions to invoke the task sequence on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Invoke-CCMTaskSequence
                Invoke all task sequence listed in WMI on the local computer
        .EXAMPLE
            PS> Invoke-CCMTaskSequence -TaskSequenceName 'Windows 10' -PackageID 'TST00443'
                Invoke the deployed task sequence listed in WMI on the local computer which have either a task sequence name of 'Windows 10' or
                a PackageID of 'TST00443'
        .NOTES
            FileName:    Invoke-CCMTaskSequence.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-15
            Updated:     2020-02-27
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_PackageID')]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_Name')]
        [string[]]$TaskSequenceName,
        [Parameter(Mandatory = $false)]
        [switch]$Force,
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
    Begin {
        $setAlwaysRerunSplat = @{
            Property = @{
                ADV_RepeatRunBehavior    = 'RerunAlways'
                ADV_MandatoryAssignments = $true
            }
        }

        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getTaskSequenceSplat = @{
            NameSpace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
    }
    process {
        # temp fix for when PSComputerName from pipeline is empty - we assume it is $env:ComputerName
        switch ($PSCmdlet.ParameterSetName) {
            'ComputerName' {
                switch ([string]::IsNullOrWhiteSpace($ComputerName)) {
                    $true {
                        $ComputerName = $env:ComputerName
                    }
                }
            }
        }
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Invoke-CCMTaskSequence")) {
                try {
                    $FilterParts = switch ($PSBoundParameters.Keys) {
                        'PackageID' {
                            [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $PackageID))
                        }
                        'TaskSequenceName' {
                            [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $TaskSequenceName))
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
                    $getTaskSequenceSplat['Query'] = [string]::Format('SELECT * FROM CCM_TaskSequence{0}', $Filter)

                    [ciminstance[]]$TaskSequences = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @getTaskSequenceSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @getTaskSequenceSplat @connectionSplat
                        }
                    }
                    if ($TaskSequences -is [Object] -and $TaskSequences.Count -gt 0) {
                        foreach ($Advertisement in $TaskSequences) {
                            switch ($Force.IsPresent) {
                                $true {
                                    Write-Verbose "Force parameter present - Setting package to always rerun"
                                    $setAlwaysRerunSplat['InputObject'] = $Advertisement
                                    switch -regex ($ConnectionInfo.ConnectionType) {
                                        '^ComputerName$|^CimSession$' {
                                            Set-CimInstance @setAlwaysRerunSplat @connectionSplat
                                        }
                                        'PSSession' {
                                            $invokeCommandSplat = @{
                                                ScriptBlock  = {
                                                    param (
                                                        $setAlwaysRerunSplat
                                                    )
                                                    Set-CimInstance @setAlwaysRerunSplat
                                                }
                                                ArgumentList = $setAlwaysRerunSplat
                                            }
                                            Invoke-Command @invokeCommandSplat @connectionSplat
                                        }
                                    }
                                }
                            }
                            $getTaskSequenceSplat['Query'] = [string]::Format("SELECT ScheduledMessageID FROM CCM_Scheduler_ScheduledMessage WHERE ScheduledMessageID LIKE '{0}%'", $Advertisement.ADV_AdvertisementID)
                            $ScheduledMessageID = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Get-CimInstance @getTaskSequenceSplat @connectionSplat
                                }
                                $false {
                                    Get-CCMCimInstance @getTaskSequenceSplat @connectionSplat
                                }
                            }
                            if ($null -ne $ScheduledMessageID) {
                                Invoke-CCMTriggerSchedule -ScheduleID $ScheduledMessageID.ScheduledMessageID @connectionSplat
                            }
                            else {
                                Write-Warning "No ScheduledMessageID found for $Computer based on input filters"
                            }
                        }
                    }
                    else {
                        Write-Warning "No deployed task sequences found for $Computer based on input filters"
                    }
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
            }
        }
    }
}