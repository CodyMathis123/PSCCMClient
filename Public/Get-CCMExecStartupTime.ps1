function Get-CCMExecStartupTime {
    <#
    .SYNOPSIS
        Return the CCMExec service startup time based on process creation date
    .DESCRIPTION
        This function will return the startup time of the CCMExec service if it is currently running. The method used is querying
        for the Win32_Service CIM object, and passing the ProcessID to Win32_Process CIM class. This lets us determine the 
        creation date of the CCMExec process, which would coorelate to service startup time. 
    .PARAMETER CimSession
        Provides CimSessions to gather CCMExec service startup time from
    .PARAMETER ComputerName
        Provides computer names to gather CCMExec service startup time from
    .EXAMPLE
        C:\PS> Get-CCMExecStartupTime
            Returns CCMExec service startup time for the local computer
    .EXAMPLE
        C:\PS> Get-CCMExecStartupTime -ComputerName 'Workstation1234','Workstation4321'
            Returns CCMExec service startup time for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMExecStartupTime.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-29
        Updated:     2020-01-29
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        $getCCMExecServiceSplat = @{
            Query = "SELECT State, ProcessID from Win32_Service WHERE Name = 'CCMExec'" 
        }
        $getCCMExecProcessSplat = @{ }
    }
    process {
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

            try {
                [ciminstance[]]$CCMExecService = Get-CimInstance @getCCMExecServiceSplat @connectionSplat
                if ($CCMExecService -is [Object] -and $CCMExecService.Count -gt 0) {
                    foreach ($Service in $CCMExecService) {
                        $getCCMExecProcessSplat['Query'] = [string]::Format("Select CreationDate from Win32_Process WHERE ProcessID = '{0}'", $Service.ProcessID)
                        [ciminstance[]]$CCMExecProcess = Get-CimInstance @getCCMExecProcessSplat @connectionSplat
                        if ($CCMExecProcess -is [Object] -and $CCMExecProcess.Count -gt 0) {
                            foreach ($Process in $CCMExecProcess) {        
                                $Result['ServiceState'] = $Service.State
                                $Result['StartupTime'] = $Process.CreationDate
                                [pscustomobject]$Result
                            }
                        }
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}