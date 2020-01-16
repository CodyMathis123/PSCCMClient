function Get-CIMRegistryProperty {
    <#
    .SYNOPSIS
        Return registry properties using the CIM StdRegProv
    .DESCRIPTION
        Relies on remote CIM and StdRegProv to allow for returning Registry Properties under a key,
        and you are able to provide pscredential
    .PARAMETER RegRoot
        The root key you want to search under
        ('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')
    .PARAMETER Key
        The key you want to return properties of. (ie. SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties)
    .PARAMETER Property
        The property name(s) you want to return the value of. This is an optional string array [string[]] and if it is not provided, all properties
        under the key will be returned
    .PARAMETER CimSession
        Provides CimSessions to get registry properties from
    .PARAMETER ComputerName
        Provides computer names to get registry properties from
    .EXAMPLE
        PS> Get-CIMRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer"
        Name                           Value
        ----                           -----
        Computer123                 @{Allow Remote Control of an unattended computer=1}
    .OUTPUTS
        [System.Collections.Hashtable]
    .NOTES
        Returns a hashtable with the computername as the key, and the value is a pscustomobject of the properties
#>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')]
        [string]$RegRoot,
        [parameter(Mandatory = $true)]
        [string]$Key,
        [parameter(Mandatory = $false)]
        [string[]]$Property,
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
            Maps the 'PropType' per property to the method we will invoke to get our return value.
            For example, if the 'type' is 1 (string) we have invoke the GetStringValue method to get our return data
        #>
        $RegPropertyMethod = @{
            1  = 'GetStringValue'
            2  = 'GetExpandedStringValue'
            3  = 'GetBinaryValue'
            4  = 'GetDWORDValue'
            7  = 'GetMultiStringValue'
            11 = 'GetQWORDValue'
        }

        <#
            Maps the 'PropType' per property to the property we will have to expand in our return value.
            For example, if the 'type' is 1 (string) we have to ExpandProperty sValue to get our return data
        #>
        $ReturnValName = @{
            1  = 'sValue'
            2  = 'sValue'
            3  = 'uValue'
            4  = 'uValue'
            7  = 'sValue'
            11 = 'uValue'
        }
        #endregion create hash tables for translating values

        # convert RootKey friendly name to the [uint32] equivalent so it can be used later
        $Root = $RootKey[$RegRoot]

        #region define our hash tables for parameters to pass to Invoke-CimMethod and our return hash table
        $EnumValuesSplat = @{ 
            Namespace = 'root\default'
            ClassName = 'StdRegProv'
        }
        #endregion define our hash tables for parameters to pass to Invoke-CimMethod and our return hash table
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
                                $EnumValuesSplat.Remove('ComputerName')
                                $EnumValuesSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $EnumValuesSplat.Remove('CimSession')
                                $EnumValuesSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $EnumValuesSplat.Remove('CimSession')
                            $EnumValuesSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $EnumValuesSplat.Remove('ComputerName')
                    $EnumValuesSplat['CimSession'] = $Connection
                }
            }
            $Return = [System.Collections.Specialized.OrderedDictionary]::new()
            $EnumValuesSplat['MethodName'] = 'EnumValues'
            $EnumValuesSplat['Arguments'] = @{
                hDefKey     = [uint32]$Root
                sSubKeyName = $Key
            }  

            $EnumValues = Invoke-CimMethod @EnumValuesSplat

            switch ($PSBoundParameters.ContainsKey('Property')) {
                $true {
                    $PropertiesToReturn = $Property
                }
                $false {
                    $PropertiesToReturn = $EnumValues.sNames
                }
            }
            $PerPC_Reg = [System.Collections.Specialized.OrderedDictionary]::new()
            
            foreach ($PropertyName In $PropertiesToReturn) {
                $PropIndex = $EnumValues.sNames.IndexOf($PropertyName)
                switch ($PropIndex) {
                    -1 {
                        Write-Error ([string]::Format('Failed to find [Property = {0}] under [Key = {1}\{2}]', $PropertyName, $RootKey, $Key))
                    }
                    default {
                        $PropType = $EnumValues.Types[$PropIndex]
                        $Prop = $ReturnValName[$PropType]
                        $Method = $RegPropertyMethod[$PropType]
                        $EnumValuesSplat['MethodName'] = $Method
                        $EnumValuesSplat['Arguments']['sValueName'] = $PropertyName
                        $PropertyValueQuery = Invoke-CimMethod @EnumValuesSplat

                        switch ($PropertyValueQuery.ReturnValue) {
                            0 {
                                $PerPC_Reg.$PropertyName = $PropertyValueQuery.$Prop
                            }
                            default {
                                $Return[$Computer] = $null
                                Write-Error ([string]::Format('Failed to resolve value [Property = {0}] [Key = {1}\{2}]', $PropertyName, $RootKey, $Key))
                            }
                        }
                        $Return[$Computer] = $([pscustomobject]$PerPC_Reg)
                    }
                }
            }

            Write-Output $Return
        }
    }
}
