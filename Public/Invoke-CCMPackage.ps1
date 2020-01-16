function Invoke-CCMPackage {
    <#
    .SYNOPSIS
        Invoke deployed packages on a computer
    .DESCRIPTION
        This function can invoke a package that is deployed to a computer. It has an optional 'Force' parameter which will
        temporarily change the RepeatRunBehavioar, and MandatoryAssignments parameters to force a pacakge to run regardless
        of the schedule and settings assigned to it.

        Note that the parameters for filter are all joined together with OR.
    .PARAMETER PackageID
        An array of PackageID to filter on
    .PARAMETER PackageName
        An array of package names to filter on
    .PARAMETER ProgramName
        An array of program names to filter on
    .PARAMETER Force
        Force the package to run by temporarily changing the RepeatRunBehavioar, and MandatoryAssignments parameters as shown below

            Property = @{
                ADV_RepeatRunBehavior    = 'RerunAlways'
                ADV_MandatoryAssignments = $true
            }
    .PARAMETER CimSession
        Provides CimSession to gather deployed package info from
    .PARAMETER ComputerName
        Provides computer names to gather deployed package info from
    .EXAMPLE
        PS> Invoke-CCMPackage
            Invoke all packages listed in WMI on the local computer
    .EXAMPLE
        PS> Invoke-CCMPackage -PackageName 'Software Install' -ProgramName 'Software Install - Silent'
            Invoke the deployed packages listed in WMI on the local computer which has either a package name of 'Software Install' or
            a Program Name of 'Software Install - Silent'
    .NOTES
        FileName:    Invoke-CCMPackage.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-12
        Updated:     2020-01-14
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_PackageID')]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_Name')]
        [string[]]$PackageName,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PRG_ProgramName')]
        [string[]]$ProgramName,
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Invoke-CCMPackage")) {
                try {
                    $FilterParts = switch ($PSBoundParameters.Keys) {
                        'PackageID' {
                            [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $PackageID))
                        }
                        'PackageName' {
                            [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $PackageName))
                        }
                        'ProgramName' {
                            [string]::Format('PRG_ProgramName = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $ProgramName))
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
                    $getPackageSplat['Query'] = [string]::Format('SELECT * FROM CCM_SoftwareDistribution{0}', $Filter)

                    [ciminstance[]]$Packages = Get-CimInstance @getPackageSplat @connectionSplat
                    if ($Packages -is [Object] -and $Packages.Count -gt 0) {
                        foreach ($Advertisement in $Packages) {
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
                        Write-Warning "No deployed package found for $Computer based on input filters"
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