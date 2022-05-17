function Invoke-CCMTaskSequence {
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
        [Alias('Session')]      
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

                    [array]$TaskSequences = switch ($Computer -eq $env:ComputerName) {
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