function Get-CCMPrimaryUser {
    <#
    .SYNOPSIS
        Return primary users for a computer

    .DESCRIPTION
        Pulls a list of primary users from WMI on the specified computer(s)

    .EXAMPLE
        PS> Get-CCMPrimaryUser
        Name                           Value
        ----                           -----
        Computer123                    humad\ccm5521

    .OUTPUTS
        [System.Collections.Hashtable]

    .NOTES
        Returns a hashtable with the computername as the key, and the value is an array of usernames
#>
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [PSCredential]$Credential
    )
    begin {
        #region define our hash tables for parameters to pass to Get-WMIObject and our return hash table
        $GetWMI_Params = @{ }
        switch ($true) {
            $PSBoundParameters.ContainsKey('Credential') {
                $GetWMI_Params['Credential'] = $Credential
            }
        }
        $GetWMI_Params['Namespace'] = 'root\CCM\CIModels'
        $GetWMI_Params['Query'] = "SELECT User from CCM_PrimaryUser"
        #endregion define our hash tables for parameters to pass to Get-WMIObject and our return hash table
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Return = @{ }

            try {
                #region Query WMI for Primary User
                $GetWMI_Params['ComputerName'] = $Computer
                $WMI_Return = Get-WmiObject @GetWMI_Params
                switch ($WMI_Return) {
                    $null {
                        Write-Warning "No primary users identified for $Computer"
                    }
                    default {
                        $Return[$Computer] = $WMI_Return.User 
                    }
                }
                #endregion Query WMI for Primary User
            }
            catch {
                Write-Error "Failed to establed WMI Connection to $Computer"
            }

            Write-Output $Return
        }
    }
}
