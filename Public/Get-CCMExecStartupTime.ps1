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
        .PARAMETER PSSession
            Provides PSSessions to gather CCMExec service startup time from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName paramter is passed to.
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
            Updated:     2020-02-23
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getCCMExecServiceSplat = @{
            Query = "SELECT State, ProcessID from Win32_Service WHERE Name = 'CCMExec'"
        }
        $getCCMExecProcessSplat = @{ }
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
                [ciminstance[]]$CCMExecService = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCCMExecServiceSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCCMExecServiceSplat @connectionSplat
                    }
                }
                if ($CCMExecService -is [Object] -and $CCMExecService.Count -gt 0) {
                    foreach ($Service in $CCMExecService) {
                        $getCCMExecProcessSplat['Query'] = [string]::Format("Select CreationDate from Win32_Process WHERE ProcessID = '{0}'", $Service.ProcessID)
                        [ciminstance[]]$CCMExecProcess = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                Get-CimInstance @getCCMExecProcessSplat @connectionSplat
                            }
                            $false {
                                Get-CCMCimInstance @getCCMExecProcessSplat @connectionSplat
                            }
                        }
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