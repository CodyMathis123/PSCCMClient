function Get-CCMCurrentManagementPoint {
    <#
        .SYNOPSIS
            Returns the current assigned MP from a client
        .DESCRIPTION
            This function will return the current assigned MP for the client using CIM. 
        .PARAMETER CimSession
            Provides CimSessions to gather the current assigned MP from
        .PARAMETER ComputerName
            Provides computer names to gather the current assigned MP from
        .PARAMETER PSSession
            Provides PSSessions to gather the current assigned MP from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMCurrentManagementPoint
                Returns the current assigned MP from local computer
        .EXAMPLE
            C:\PS> Get-CCMCurrentManagementPoint -ComputerName 'Workstation1234','Workstation4321'
                Returns the current assigned MP from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMCurrentManagementPoint.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-16
            Updated:     2020-02-22
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCurrentMP', 'Get-CCMMP')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
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
                [ciminstance[]]$CurrentMP = switch ($Computer -eq $env:ComputerName) {
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