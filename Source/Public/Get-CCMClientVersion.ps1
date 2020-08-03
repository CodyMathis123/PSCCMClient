function Get-CCMClientVersion {
    <#
        .SYNOPSIS
            Returns the current MEMCM client version
        .DESCRIPTION
            This function will return the current version for the MEMCM client using CIM.
        .PARAMETER CimSession
            Provides CimSessions to gather the version from
        .PARAMETER ComputerName
            Provides computer names to gather the version from
        .PARAMETER PSSession
            Provides PSSessions to gather the version from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMClientVersion
                Returns the MEMCM client version from local computer
        .EXAMPLE
            C:\PS> Get-CCMClientVersion -ComputerName 'Workstation1234','Workstation4321'
                Returns the MEMCM client version from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMClientVersion.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-24
            Updated:     2020-02-27
    #>
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
        $getClientVersionSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientVersion FROM SMS_Client'
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
                [ciminstance[]]$Currentversion = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getClientVersionSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getClientVersionSplat @connectionSplat
                    }
                }
                if ($Currentversion -is [Object] -and $Currentversion.Count -gt 0) {
                    foreach ($SMSClient in $Currentversion) {
                        $Result['ClientVersion'] = $SMSClient.ClientVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No client version found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}