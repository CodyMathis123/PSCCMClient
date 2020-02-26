function Get-CCMPrimaryUser {
    <#
        .SYNOPSIS
            Return primary users for a computer
        .DESCRIPTION
            Pulls a list of primary users from WMI on the specified computer(s) or CIMSession(s)
        .PARAMETER CimSession
            Provides CimSession to gather primary users info from
        .PARAMETER ComputerName
            Provides computer names to gather primary users info from
        .PARAMETER PSSession
            Provides PSSessions to gather primary users info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Get-CCMPrimaryUser
                Returns all primary users listed in WMI on the local computer
        .NOTES
            FileName:    Get-CCMPrimaryUser.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-05
            Updated:     2020-02-23
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
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
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPrimaryUserSplat = @{
            NameSpace = 'root\CCM\CIModels'
            Query     = 'SELECT User from CCM_PrimaryUser'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
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
                [ciminstance[]]$PrimaryUsers = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getPrimaryUserSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getPrimaryUserSplat @connectionSplat
                    }
                }
                if ($PrimaryUsers -is [Object] -and $PrimaryUsers.Count -gt 0) {
                    $Result['PrimaryUser'] = $PrimaryUsers.User
                    [PSCustomObject]$Result
                }
                else {
                    Write-Warning "No Primary Users found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}