function Get-CCMClientDirectory {
    <#
    .SYNOPSIS
        Return the ConfigMgr Client Directory
    .DESCRIPTION
        Checks the registry of the local machine and will return the 'Local SMS Path' property of the 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties' registry key
        This function uses the Get-WmiRegistryProperty function which uses WMI to query the registry
    .PARAMETER ComputerName
        Optional ComputerName to pull the info from. Uses the WMI method of pulling registry info
    .PARAMETER Credential
        Optional PSCredential that will be used for the WMI cmdlets
    .EXAMPLE
        PS C:\> Get-CCMClientDirectory
            Name                           Value
            ----                           -----
            LOUXDWTSSA1362                 C:\WINDOWS\CCM
    #>
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [PSCredential]$Credential
    )
    begin {
        $getWmiRegistryPropertySplat = @{
            Key      = "SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties"
            Property = "Local SMS Path"
            RegRoot  = 'HKEY_LOCAL_MACHINE'
        }
        switch ($true) {
            $PSBoundParameters.ContainsKey('Credential') {
                $GetWmiRegistryProperty['Credential'] = $Credential
            }
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $getWmiRegistryPropertySplat['ComputerName'] = $ComputerName
            $ReturnHashTable = Get-WmiRegistryProperty @getWmiRegistryPropertySplat
            foreach ($PC in $ReturnHashTable.GetEnumerator()) {
                @{$PC.Key = $ReturnHashTable[$PC.Key].'Local SMS Path'.TrimEnd('\') }
            }
        }
    }
}
