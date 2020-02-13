# ENHANCE - Rework the 'prefer' option?
function Get-CCMConnection {
    <#
    .SYNOPSIS
        Determine, and return the preferred connection type
    .DESCRIPTION
        The purpose of this function is to determine the best possible connection type to be used for the functions
        in the PSCCMClient PowerShell Module. Optinally, a 'preference' can be specified with the Prefer parameter.
        By default the preference is a CimSession, falling back to ComputerName if one is not found. In some cases
        it can be beneficial to return a PSSession for the connection type. This can be helpful as an alternative to
        using the Invoke-CIMPowerShell function. The Invoke-CIMPowerShell function executes code remotely by converting
        scriptblocks to base64 and execting them throuth the 'Create' method of the Win32_Process CIM Class.
    .PARAMETER Prefer
        The preferred remoting type, either CimSession, or PSSession which is used in fallback scenarios where ComputerName
        is passed to the function.
    .PARAMETER CimSession
        CimSession that will be passed back out after formatting
    .PARAMETER PSSession
        PSSession that will be passed back out after formatting
    .PARAMETER ComputerName
        The computer name that will be used to determine, and return the connection type
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123 -Prefer Session
            Return a Session if found, otherwise return Computer Name
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123
            Check for a CimSession, falling back to PSSession, and return if one is found, otherwise return ComputerName
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123 -Prefer PSSession
            Check for a PSSession, falling back to CimSession, and return if one is found, otherwise return ComputerName
    .EXAMPLE
        C:\PS> Get-CCMConnection -PSSession $PSS
            Process the PSSession passed in, and return in appropriate format for consumption in module functions
    .NOTES
        FileName:    Get-CCMConnection.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-02-06
        Updated:     2020-02-13
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$Prefer = 'CimSession',
        [Parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string]$ComputerName = $env:ComputerName
    )

    $return = @{
        connectionSplat = @{ }
    }

    switch ($PSBoundParameters.Keys) {
        'CimSession' {
            Write-Verbose "CimSession passed to Get-CCMConnection - Passing CimSession out"
            $return['connectionSplat'] = @{ CimSession = $CimSession }
            $return['ComputerName'] = $CimSession.ComputerName
            $return['ConnectionType'] = 'CimSession'
        }
        'PSSession' {
            Write-Verbose "Session passed to Get-CCMConnection - Passing Session out"
            $return['connectionSplat'] = @{ Session = $PSSession }
            $return['ComputerName'] = $PSSession.ComputerName
            $return['ConnectionType'] = 'PSSession'
        }
        'ComputerName' {
            $return['ComputerName'] = $ComputerName
            switch ($ComputerName -eq $env:ComputerName) {
                $true {
                    Write-Verbose "Local computer provided - will return empty connection"
                    $return['connectionSplat'] = @{ }
                    $return['ConnectionType'] = 'ComputerName'
                }
                $false {
                    switch ($Prefer) {
                        'CimSession' {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $ComputerName - Passing CimSession out"
                                $return['connectionSplat'] = @{ CimSession = $ExistingCimSession }
                                $return['ConnectionType'] = 'CimSession'
                            }
                            elseif ($ExistingSession = Get-PSSession -ComputerName $ComputerName -ErrorAction Ignore -State Opened) {
                                Write-Verbose "Fallback active PSSession found for $ComputerName - Passing Session out"
                                $return['connectionSplat'] = @{ Session = $ExistingSession }
                                $return['ConnectionType'] = 'PSSession'
                            }
                            else {
                                Write-Verbose "No active CimSession (preferred), or PSSession found for $Connection - falling back to -ComputerName"
                                $return['connectionSplat'] = @{ ComputerName = $Connection }
                                $return['ConnectionType'] = 'CimSession'
                            }
                        }
                        'PSSession' {
                            if ($ExistingSession = Get-PSSession -ComputerName $ComputerName -ErrorAction Ignore -State Opened) {
                                Write-Verbose "Active PSSession found for $ComputerName - Passing Session out"
                                $return['connectionSplat'] = @{ Session = $ExistingSession }
                                $return['ConnectionType'] = 'PSSession'
                            }
                            elseif ($ExistingCimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Ignore) {
                                Write-Verbose "Fallback active CimSession found for $ComputerName - Passing CimSession out"
                                $return['connectionSplat'] = @{ CimSession = $ExistingCimSession }
                                $return['ConnectionType'] = 'CimSession'
                            }
                            else {
                                Write-Verbose "No active PSSession (preferred), or CimSession found for $ComputerName - falling back to -ComputerName"
                                $return['connectionSplat'] = @{ ComputerName = $ComputerName }
                                $return['ConnectionType'] = 'PSSession'
                            }
                        }
                    }
                }
            }
        }
    }

    Write-Output $return
}