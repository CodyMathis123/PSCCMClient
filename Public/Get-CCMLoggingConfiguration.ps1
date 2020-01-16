
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
        Updated:     2020-01-10
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
        $getLogInfoSplat = @{
            Namespace   = 'root\ccm\policy\machine\actualconfig'
            ClassName   = 'CCM_Logging_GlobalConfiguration'
            ErrorAction = 'Stop'
        }
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
                                $getLogInfoSplat.Remove('ComputerName')
                                $getLogInfoSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $getLogInfoSplat.Remove('CimSession')
                                $getLogInfoSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $getLogInfoSplat.Remove('CimSession')
                            $getLogInfoSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $getLogInfoSplat.Remove('ComputerName')
                    $getLogInfoSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$CimResult = Get-CimInstance @getLogInfoSplat
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