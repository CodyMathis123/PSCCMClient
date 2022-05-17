function Get-CCMCurrentManagementPoint {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCurrentMP', 'Get-CCMMP')]
    param (
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
        $getCurrentMPSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT CurrentManagementPoint FROM SMS_Authority'
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
                [array]$CurrentMP = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCurrentMPSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCurrentMPSplat @connectionSplat
                    }
                }
                if ($CurrentMP -is [Object] -and $CurrentMP.Count -gt 0) {
                    foreach ($MP in $CurrentMP) {
                        $Result['CurrentManagementPoint'] = $MP.CurrentManagementPoint
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Management Point infomration found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}