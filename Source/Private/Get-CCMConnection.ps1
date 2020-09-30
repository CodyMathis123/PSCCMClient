function Get-CCMConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$Prefer = 'CimSession',
        [Parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory = $false)]
        [Alias('Session')]
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
                                $return['connectionSplat'] = @{ CimSession = $ExistingCimSession[0] }
                                $return['ConnectionType'] = 'CimSession'
                            }
                            elseif ($ExistingSession = (Get-PSSession -ErrorAction Ignore).Where({$_.ComputerName -eq $ComputerName -and $_.State -eq 'Opened'})) {
                                Write-Verbose "Fallback active PSSession found for $ComputerName - Passing Session out"
                                $return['connectionSplat'] = @{ Session = $ExistingSession[0] }
                                $return['ConnectionType'] = 'PSSession'
                            }
                            else {
                                Write-Verbose "No active CimSession (preferred), or PSSession found for $ComputerName - falling back to -ComputerName"
                                $return['connectionSplat'] = @{ ComputerName = $Connection }
                                $return['ConnectionType'] = 'CimSession'
                            }
                        }
                        'PSSession' {
                            if ($ExistingSession = (Get-PSSession -ErrorAction Ignore).Where({$_.ComputerName -eq $ComputerName -and $_.State -eq 'Opened'})) {
                                Write-Verbose "Active PSSession found for $ComputerName - Passing Session out"
                                $return['connectionSplat'] = @{ Session = $ExistingSession[0] }
                                $return['ConnectionType'] = 'PSSession'
                            }
                            elseif ($ExistingCimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Ignore) {
                                Write-Verbose "Fallback active CimSession found for $ComputerName - Passing CimSession out"
                                $return['connectionSplat'] = @{ CimSession = $ExistingCimSession[0] }
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