function Set-CIMRegistryProperty {
    <#
    .SYNOPSIS
        Set registry properties values using the CIM StdRegProv
    .DESCRIPTION
        Relies on remote CIM and StdRegProv to allow for setting a Registry Property value.
        You can provide an array of computers, or cimsessions. 
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
        Create the Property if it does not exist, otherwise only existing properties will have their value modified
    .PARAMETER CimSession
        Provides CimSessions to set registry properties for
    .PARAMETER ComputerName
        Provides computer names to set registry properties for
    .EXAMPLE
        PS> Set-CIMRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer" -Value 1 -PropertyType DWORD
        Name                           Value
        ----                           -----
        Computer123                    $true
    .OUTPUTS
        [System.Collections.Hashtable]
    .NOTES
        Returns a hashtable with the computername as the key, and the value is a boolean based on successs
#>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
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
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
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
        $Method = $RegPropertyMethod[$PropertyType]
        #endregion create hash tables for translating values

        # convert RootKey friendly name to the [uint32] equivalent so it can be used later
        $Root = $RootKey[$RegRoot]

        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $setCIMRegPropSplat = @{
            Namespace   = 'root\default'
            ClassName   = 'StdRegProv'
            ErrorAction = 'Stop'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table

        $PropertyTypeMap = @{
            SetDWORDValue          = [UInt32]
            SetQWORDValue          = [UInt64]
            SetStringValue         = [String]
            SetMultiStringValue    = [String[]]
            SetExpandedStringValue = [String]
            SetBinaryValue         = [byte[]]
        }

        $ReturnValName = @{
            SetDWORDValue          = 'uValue'
            SetQWORDValue          = 'uValue'
            SetStringValue         = 'sValue'
            SetMultiStringValue    = 'sValue'
            SetExpandedStringValue = 'sValue'
            SetBinaryValue         = 'uValue'
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
                                $setCIMRegPropSplat.Remove('ComputerName')
                                $setCIMRegPropSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $setCIMRegPropSplat.Remove('CimSession')
                                $setCIMRegPropSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $setCIMRegPropSplat.Remove('CimSession')
                            $setCIMRegPropSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $setCIMRegPropSplat.Remove('ComputerName')
                    $setCIMRegPropSplat['CimSession'] = $Connection
                }
            }
            $Return = [System.Collections.Specialized.OrderedDictionary]::new()
            $Return[$Computer] = $false

            $setCIMRegPropSplat['MethodName'] = 'EnumValues'
            $setCIMRegPropSplat['Arguments'] = @{
                hDefKey     = [uint32]$Root
                sSubKeyName = $Key
            }  

            $EnumValues = Invoke-CimMethod @setCIMRegPropSplat

            $setCIMRegPropSplat['MethodName'] = $Method
            $setCIMRegPropSplat['Arguments']['sValueName'] = $Property
            $setCIMRegPropSplat['Arguments'][$ReturnValName[$Method]] = $Value -as $PropertyTypeMap[$Method]

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [sValueName = '$Property'] [Value = '$Value']", "Set-CIMRegistryProperty")) {
                switch ($EnumValues.sNames -contains $Property) {
                    $true {
                        $SetProperty = Invoke-CimMethod @setCIMRegPropSplat
                    }
                    $false {
                        switch ($Force.IsPresent) {
                            $true {
                                $SetProperty = Invoke-CimMethod @setCIMRegPropSplat
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
}
