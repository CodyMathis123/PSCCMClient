function Get-CCMGUID {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
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
        $getGUIDSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientID, ClientIDChangeDate, PreviousClientID FROM CCM_Client'
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
                [ciminstance[]]$CurrentGUID = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getGUIDSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getGUIDSplat @connectionSplat
                    }
                }
                if ($CurrentGUID -is [Object] -and $CurrentGUID.Count -gt 0) {
                    foreach ($GUID in $CurrentGUID) {
                        $Result['GUID'] = $GUID.ClientID
                        $Result['ClientGUIDChangeDate'] = $GUID.ClientIDChangeDate
                        $Result['PreviousGUID'] = $GUID.PreviousClientID
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No ClientID information found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}