function Get-CCMLoggingConfiguration {
    <#
        .SYNOPSIS
            Get ConfigMgr client log info from computers via CIM
        .DESCRIPTION
            This function will allow you to gather the ConfigMgr client log info info from multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
        .PARAMETER CimSession
            Provides CimSession to gather log info from.
        .PARAMETER ComputerName
            Provides computer names to gather log info from.
        .PARAMETER PSSessions
            Provides PSSessionss to gather log info from.
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName paramter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMLoggingConfiguration
                Return ConfigMgr client log info info for the local computer
        .EXAMPLE
            C:\PS> Get-CCMLoggingConfiguration -ComputerName 'Workstation1234','Workstation4321'
                Return ConfigMgr client log info info for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMLoggingConfiguration.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-10
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
        $getLogInfoSplat = @{
            Namespace   = 'root\ccm\policy\machine\actualconfig'
            ClassName   = 'CCM_Logging_GlobalConfiguration'
            ErrorAction = 'Stop'
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
                [ciminstance[]]$CimResult = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getLogInfoSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getLogInfoSplat @connectionSplat
                    }
                }
                if ($CimResult -is [Object] -and $CimResult.Count -gt 0) {
                    foreach ($Object in $CimResult) {
                        $Result['LogDirectory'] = $Object.LogDirectory
                        $Result['LogMaxSize'] = $Object.LogMaxSize
                        $Result['LogMaxHistory'] = $Object.LogMaxHistory
                        $Result['LogLevel'] = $Object.LogLevel
                        $Result['LogEnabled'] = $Object.LogEnabled
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['LogDirectory'] = $null
                    $Result['LogMaxSize'] = $null
                    $Result['LogMaxHistory'] = $null
                    $Result['LogLevel'] = $null
                    $Result['LogEnabled'] = $null
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}