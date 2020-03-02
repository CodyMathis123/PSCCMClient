function Get-CCMDNSSuffix {
    <#
        .SYNOPSIS
            Returns the current DNS suffix set for the MEMCM Client
        .DESCRIPTION
            This function will return the current DNS suffix in use for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER CimSession
            Provides CimSessions to return the current DNS suffix in use for
        .PARAMETER ComputerName
            Provides computer names to return the current DNS suffix in use for
        .PARAMETER PSSession
            Provides a PSSession to return the current DNS suffix in use for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMDNSSuffix
                Return the local computers DNS Suffix setting
        .EXAMPLE
            C:\PS> Get-CCMDNSSuffix -ComputerName 'Workstation1234','Workstation4321'
                Return the DNS Suffix setting for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMDNSSuffix.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-03-01
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
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
        $GetDNSSuffixScriptBlock = {
            $Client = New-Object -ComObject Microsoft.SMS.Client
            $Client.GetDNSSuffix()
        }
        $invokeCommandSplat = @{
            ScriptBlock = $GetDNSSuffixScriptBlock
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

            $Result['DNSSuffix'] = switch ($Computer -eq $env:ComputerName) {
                $true {
                    $GetDNSSuffixScriptBlock.Invoke()
                }
                $false {
                    Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                }
            }
            [pscustomobject]$Result
        }
    }
}