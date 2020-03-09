function Get-CCMRegistryProperty {
    <#
        .SYNOPSIS
            Return registry properties using the CIM StdRegProv, or Invoke-CCMCommand
        .DESCRIPTION
            Relies on remote CIM and StdRegProv to allow for returning Registry Properties under a key. If a PSSession, or ConnectionPreference
            is used, then Invoke-CCMCommand is used instead.
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
        .PARAMETER PSSession
            Provides PSSessions to get registry properties from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            PS> Get-CCMRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer"
            Name                           Value
            ----                           -----
            Computer123                 @{Allow Remote Control of an unattended computer=1}
        .OUTPUTS
            [System.Collections.Hashtable]
        .NOTES
            FileName:    Get-CCMRegistryProperty.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-11-07
            Updated:     2020-02-24
#>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CIMRegistryProperty')]
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
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
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

            $Return = [ordered]@{ }
            $PerPC_Reg = [ordered]@{ }

            switch -regex ($ConnectionInfo.ConnectionType) {
                '^CimSession$|^ComputerName$' {
                    $EnumValuesSplat['MethodName'] = 'EnumValues'
                    $EnumValuesSplat['Arguments'] = @{
                        hDefKey     = [uint32]$Root
                        sSubKeyName = $Key
                    }
        
                    $EnumValues = Invoke-CimMethod @EnumValuesSplat @connectionSplat
        
                    switch ($PSBoundParameters.ContainsKey('Property')) {
                        $true {
                            $PropertiesToReturn = $Property
                        }
                        $false {
                            $PropertiesToReturn = $EnumValues.sNames
                        }
                    }
        
                    foreach ($PropertyName In $PropertiesToReturn) {
                        $PropIndex = $EnumValues.sNames.IndexOf($PropertyName)
                        switch ($PropIndex) {
                            -1 {
                                Write-Error ([string]::Format('Failed to find [Property = {0}] under [Key = {1}\{2}]', $PropertyName, $RegRoot, $Key))
                            }
                            default {
                                $PropType = $EnumValues.Types[$PropIndex]
                                $Prop = $ReturnValName[$PropType]
                                $Method = $RegPropertyMethod[$PropType]
                                $EnumValuesSplat['MethodName'] = $Method
                                $EnumValuesSplat['Arguments']['sValueName'] = $PropertyName
                                $PropertyValueQuery = Invoke-CimMethod @EnumValuesSplat @connectionSplat
        
                                switch ($PropertyValueQuery.ReturnValue) {
                                    0 {
                                        $PerPC_Reg.$PropertyName = $PropertyValueQuery.$Prop
                                        $Return[$Computer] = $([pscustomobject]$PerPC_Reg)
                                    }
                                    default {
                                        $Return[$Computer] = $null
                                        Write-Error ([string]::Format('Failed to resolve value [Property = {0}] [Key = {1}\{2}]', $PropertyName, $RegRoot, $Key))
                                    }
                                }
                            }
                        }
                    }
        
                }
                '^PSSession$' {
                    $RegPath = [string]::Format('registry::{0}\{1}', $RegRoot, $Key)
                    $PropertyFilter = switch ($PSBoundParameters.ContainsKey('Property')) {
                        $true {
                            [string]::Format("-Name '{0}'", [string]::Join("', '", $Property))
                        }
                        $false {
                            ' '
                        }
                    }
                    $ScriptBlockString = [string]::Format('Get-ItemProperty -Path "{0}" {1}', $RegPath, $PropertyFilter)
                    $ScriptBlock = [scriptblock]::Create($ScriptBlockString)
                    $InvokeCommandSplat = @{
                        ScriptBlock = $ScriptBlock
                    }

                    $RegData = Invoke-CCMCommand @InvokeCommandSplat @connectionSplat
                    switch ($PSBoundParameters.ContainsKey('Property')) {
                        $true {
                            switch ($Property) {
                                default {
                                    $PerPC_Reg.$PSItem = $RegData.$PSItem
                                }
                            }
                            $Return[$Computer] = $([pscustomobject]$PerPC_Reg)
                        }
                        $false {
                            $AllProperties = Get-Member -InputObject $RegData -MemberType NoteProperty

                            switch -regex ($AllProperties.Name) {
                                '^PSChildName$|^PSComputerName$|^PSParentPath$|^PSPath$|^PSProvider$|^PSShowComputerName$|^RunspaceId$' {
                                    continue
                                }
                                default {
                                    $PerPC_Reg.$PSItem = $RegData.$PSItem
                                }
                            }
                            $Return[$Computer] = $([pscustomobject]$PerPC_Reg)
                        }
                    }
                }
            }

            Write-Output $Return
        }
    }
}