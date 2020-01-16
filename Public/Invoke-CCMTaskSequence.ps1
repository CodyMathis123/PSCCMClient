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
        Updated:     2020-01-15
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
        [string[]]$ComputerName = $env:ComputerName
    )
    Begin {
        $setAlwaysRerunSplat = @{
            Property = @{
                ADV_RepeatRunBehavior    = 'RerunAlways'
                ADV_MandatoryAssignments = $true
            }
        }

        $connectionSplat = @{ }

        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPackageSplat = @{
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
            $Computer = switch ($PSCmdlet.ParameterSetName) {
                'ComputerName' {
                    Write-Output -InputObject $Connection
                    switch ($Connection -eq $env:ComputerName) {
                        $false {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $Connection -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                                $connectionSplat.Remove('ComputerName')
                                $connectionSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $connectionSplat.Remove('CimSession')
                                $connectionSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $connectionSplat.Remove('CimSession')
                            $connectionSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $connectionSplat.Remove('ComputerName')
                    $connectionSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
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
                    $getPackageSplat['Query'] = [string]::Format('SELECT * FROM CCM_TaskSequence{0}', $Filter)

                    [ciminstance[]]$TaskSequences = Get-CimInstance @getPackageSplat @connectionSplat
                    if ($TaskSequences -is [Object] -and $TaskSequences.Count -gt 0) {
                        foreach ($Advertisement in $TaskSequences) {
                            switch ($Force.IsPresent) {
                                $true {
                                    Write-Verbose "Force parameter present - Setting package to always rerun"
                                    $setAlwaysRerunSplat['InputObject'] = $Advertisement
                                    Set-CimInstance @setAlwaysRerunSplat @connectionSplat
                                }
                            }
                            $getPackageSplat['Query'] = [string]::Format("SELECT ScheduledMessageID FROM CCM_Scheduler_ScheduledMessage WHERE ScheduledMessageID LIKE '{0}%'", $Advertisement.ADV_AdvertisementID)
                            $ScheduledMessageID = Get-CimInstance @getPackageSplat @connectionSplat
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