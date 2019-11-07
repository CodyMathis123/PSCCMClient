function Set-WmiRegistryProperty {
    <#
    .SYNOPSIS
        Set registry properties values using the WMI StdRegProv

    .DESCRIPTION
        Relies on remote WMI and StdRegProv to allow for setting a Registry Property value.
        You can provide an array of computers, and you are able to provide pscredential

    .PARAMETER RegRoot
        The root key you want to search under
        ('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')

    .PARAMETER Key
        The key you want to set properties of. (ie. SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties)

    .PARAMETER Property
        The property name you want to set the value for

    .PARAMETER Value
        The desired value for the property

    .PARAMETER PropertyType
        The type of property you are setting. This is needed because the method for setting a registry value changes based on property type.
        'String', 'ExpandedString', 'Binary', 'DWORD', 'MultiString', 'QWORD'

    .PARAMETER Force
        Create the Property if it does not exist, otherwise only exist properties will have their value modified

    .EXAMPLE
        PS> Set-WmiRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer" -Value 1 -PropertyType DWORD
        Name                           Value
        ----                           -----
        Computer123                    $true

    .OUTPUTS
        [System.Collections.Hashtable]

    .NOTES
        Returns a hashtable with the computername as the key, and the value is a boolean based on successs
#>
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')]
        [string]$RegRoot,
        [parameter(Mandatory = $true)]
        [string]$Key,
        [parameter(Mandatory = $true)]
        [string]$Property,
        [parameter(Mandatory = $true)]
        $Value,
        [parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandedString', 'Binary', 'DWORD', 'MultiString', 'QWORD')]
        [string]$PropertyType,
        [parameter(Mandatory = $false)]
        [switch]$Force,
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [PSCredential]$Credential
    )
    begin {
        #region create hash tables for translating values
        $RootKey = @{
            HKEY_CLASSES_ROOT   = 2147483648
            HKEY_CURRENT_USER   = 2147483649
            HKEY_LOCAL_MACHINE  = 2147483650
            HKEY_USERS          = 2147483651
            HKEY_CURRENT_CONFIG = 2147483653
            HKEY_DYN_DATA       = 2147483654
        }
        <#
            Maps the 'PropertyType' per property to the method we will invoke to set the value.
            For example, if the 'type' is string we have invoke the SetStringValue method
        #>
        $RegPropertyMethod = @{
            'String'         = 'SetStringValue'
            'ExpandedString' = 'SetExpandedStringValue'
            'Binary'         = 'SetBinaryValue'
            'DWORD'          = 'SetDWORDValue'
            'MultiString'    = 'SetMultiStringValue'
            'QWORD'          = 'SetQWORDValue'
        }
        #endregion create hash tables for translating values

        # convert RootKey friendly name to the [uint32] equivalent so it can be used later
        $Root = $RootKey[$RegRoot]

        #region define our hash tables for parameters to pass to Get-WMIObject and our return hash table
        $GetWMI_Params = @{
            List        = $true
            Namespace   = 'root\default'
            Class       = 'StdRegProv'
            ErrorAction = 'Stop'
        }
        switch ($true) {
            $PSBoundParameters.ContainsKey('Credential') {
                $GetWMI_Params['Credential'] = $Credential
            }
        }
        #endregion define our hash tables for parameters to pass to Get-WMIObject and our return hash table
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Return = @{ }
            $Return[$Computer] = $false
            try {
                #region establish WMI Connection
                $GetWMI_Params['ComputerName'] = $Computer
                $WMI_Connection = Get-WmiObject @GetWMI_Params
                #endregion establish WMI Connection
            }
            catch {
                Write-Error "Failed to establed WMI Connection to $Computer"
            }
            $Method = $RegPropertyMethod[$PropertyType]
            $EnumValues = $WMI_Connection.EnumValues($Root, $Key)
            switch ($EnumValues.sNames -contains $Property) {
                $true {
                    $SetProperty = $WMI_Connection.$Method($Root, $Key, $Property, $Value)
                }
                $false {
                    switch ($Force.IsPresent) {
                        $true {
                            $SetProperty = $WMI_Connection.$Method($Root, $Key, $Property, $Value)
                        }
                        $false {
                            Write-Warning ([string]::Format('[Property = {0}] does not exist under [Key = {1}\{2}] and the force parameter was not specified. No changes will be made', $Property, $RootKey, $Key))
                        }
                    }
                }
            }
            if ($null -ne $SetProperty) {
                switch ($SetProperty.ReturnValue) {
                    0 {
                        $Return[$Computer] = $true
                    }
                    default {
                        Write-Error ([string]::Format('Failed to set value [Property = {0}] [Key = {1}\{2}] [Value = {3}] [PropertyType = {4}] [Method = {5}}', $Property, $RootKey, $Key, $Value, $PropertyType, $Method))
                    }
                }
            }

            Write-Output $Return
        }
    }
}
