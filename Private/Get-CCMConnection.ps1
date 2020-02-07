function Get-CCMConnection {
    <#
    .SYNOPSIS
        Determine and return the preferred connection type
    .DESCRIPTION
        The purpose of this function is to determine the best possible connection type to be used for the functions
        in the PSCCMClient PowerShell Module. Optinally, a 'preference' can be specified with the Prefer parameter. 
        By default the preference is a CimSession, falling back to ComputerName if one is not found. In some cases
        it can be beneficial to return a PSSession for the connection type. This can be helpful as an alternative to 
        using the Invoke-CIMPowerShell function. The Invoke-CIMPowerShell function executes code remotely by converting
        scriptblocks to base64 and execting them throuth the 'Create' method of the Win32_Process CIM Class.
    .PARAMETER Prefer
        The preferred remoting type, either CimSession, or PSSession
    .PARAMETER ComputerName
        The computer name that we will determine, and return the connection type for
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123 -Prefer PSSession
            Return a PSSession if found, otherwise return Computer Name
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123
            Check for a CimSession, and return if one is found, otherwise return ComputerName
    .NOTES
        FileName:    Get-CCMConnection.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-02-06
        Updated:     2020-02-06
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$Prefer = 'CimSession',
        [Parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.Runspaces.PSSession]$PSSession,
        [Parameter(Mandatory = $false)]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string]$ComputerName = $env:ComputerName
    )
    
    $return = @{
        connectionSplat = @{ }
    }

    switch ($PSBoundParameters.Keys) {
        'CimSession' {
            Write-Verbose "CimSession passed to Get-CCMConnection - Passing CimSession out"
            $return['connectionSplat'].Remove('ComputerName')
            $return['connectionSplat'].Remove('PSSession')
            $return['connectionSplat']['CimSession'] = $CimSession
            $return['ComputerName'] = $CimSession.ComputerName
        }
        'PSSession' {
            Write-Verbose "PSSession passed to Get-CCMConnection - Passing PSSession out"
            $return['connectionSplat'].Remove('ComputerName')
            $return['connectionSplat'].Remove('CimSession')
            $return['connectionSplat']['PSSession'] = $PSSession
            $return['ComputerName'] = $PSSession.ComputerName
        }
        'ComputerName' {
            $return['ComputerName'] = $ComputerName
            switch ($ComputerName -eq $env:ComputerName) {
                $true {
                    Write-Verbose "Local computer provided - will return empty connection"
                    $return['connectionSplat'].Remove('CimSession')
                    $return['connectionSplat'].Remove('PSSession')
                    $return['connectionSplat'].Remove('ComputerName')
                }
                $false {
                    switch ($Prefer) {
                        'CimSession' {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $ComputerName - Passing CimSession out"
                                $return['connectionSplat'].Remove('ComputerName')
                                $return['connectionSplat'].Remove('PSSession')
                                $return['connectionSplat']['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName"
                                $return['connectionSplat'].Remove('CimSession')
                                $return['connectionSplat'].Remove('PSSession')
                                $return['connectionSplat']['ComputerName'] = $Connection
                            }
                        }
                        'PSSession' {
                            if ($ExistingPSSession = Get-PSSession -ComputerName $ComputerName -ErrorAction Ignore -State Opened) {
                                Write-Verbose "Active PSSession found for $ComputerName - Passing PSSession out"
                                $return['connectionSplat'].Remove('ComputerName')
                                $return['connectionSplat'].Remove('CimSession')
                                $return['connectionSplat']['PSSession'] = $ExistingPSSession
                            }
                            else {
                                Write-Verbose "No active PSSession found for $ComputerName - falling back to -ComputerName"
                                $return['connectionSplat'].Remove('CimSession')
                                $return['connectionSplat'].Remove('PSSession')
                                $return['connectionSplat']['ComputerName'] = $ComputerName
                            }
                        }
                    }
                }
            }

            Write-Output $return
        }
    }
}