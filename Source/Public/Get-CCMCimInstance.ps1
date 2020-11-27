function Get-CCMCimInstance {
    [CmdletBinding(DefaultParameterSetName = 'CimQuery-ComputerName')]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Namespace = 'root\cimv2',
        [Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-CimSession')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-PSSession')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-ComputerName')]
        [string]$ClassName,
        [Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-CimSession')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-PSSession')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-ComputerName')]
        [string]$Filter,
        [Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-CimSession')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-PSSession')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-ComputerName')]
        [string]$Query,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimQuery-CimSession')]
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimFilter-CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'PassThrough-ComputerName')]
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimQuery-ComputerName')]
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimFilter-ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'CimQuery-PSSession')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-PSSession')]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'CimQuery-ComputerName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference = 'CimSession'
    )
    begin {
        $ConnectionChecker = ($PSCmdlet.ParameterSetName).Split('-')[1]

        $GetCimInstanceSplat = @{ }
        switch ($PSBoundParameters.Keys) {
            'Namespace' {
                $GetCimInstanceSplat['NameSpace'] = $Namespace
            }
            'ClassName' {
                $GetCimInstanceSplat['ClassName'] = $ClassName
            }
            'Filter' {
                $GetCimInstanceSplat['Filter'] = $Filter
            }
            'Query' {
                $GetCimInstanceSplat['Query'] = $Query
            }
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $ConnectionChecker -ValueOnly -Scope Local)) {
            $getConnectionInfoSplat = @{
                $ConnectionChecker = $Connection
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat -Prefer $ConnectionPreference
            $ConnectionPreference = $ConnectionInfo.ConnectionType
            $connectionSplat = $ConnectionInfo.connectionSplat

            switch ($ConnectionPreference) {
                'CimSession' {
                    Get-CimInstance @GetCimInstanceSplat @connectionSplat
                }
                'PSSession' {
                    $GetCimInstanceOverPSSessionSplat = @{
                        ArgumentList = $GetCimInstanceSplat
                        ScriptBlock  = {
                            param($GetCimInstanceSplat)
                            Get-CimInstance @GetCimInstanceSplat
                        }
                    }

                    Invoke-Command @GetCimInstanceOverPSSessionSplat @connectionSplat
                }
            }
        }
    }
}