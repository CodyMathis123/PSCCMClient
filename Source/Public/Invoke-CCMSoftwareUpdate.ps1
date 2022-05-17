function Invoke-CCMSoftwareUpdate {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
    [Alias('Invoke-CCMUpdate')]
    param(
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ArticleID,
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
        $invokeCIMMethodSplat = @{
            Namespace  = 'root\ccm\clientsdk'
            MethodName = 'InstallUpdates'
            ClassName  = 'CCM_SoftwareUpdatesManager'
        }
        $getUpdateSplat = @{
            Namespace = 'root\CCM\ClientSDK'
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
            $Result['Invoked'] = $false

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", 'Invoke-CCMSoftwareUpdate')) {
                try {
                    $getUpdateSplat['Query'] = switch ($PSBoundParameters.ContainsKey('ArticleID')) {
                        $true {
                            [string]::Format('SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0 AND (ArticleID = "{0}")', [string]::Join('" OR ArticleID = "', $ArticleID))
                        }
                        $false {
                            [string]::Format('SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0')
                        }
                    }

                    [array]$MissingUpdates = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @getUpdateSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @getUpdateSplat @connectionSplat
                        }
                    }

                    if ($MissingUpdates -is [array]) {
                        switch ($PSBoundParameters.ContainsKey('ArticleID')) {
                            $false {
                                $ArticleID = $MissingUpdates.ArticleID
                            }
                        }
                        $Invocation = switch -regex ($ConnectionInfo.ConnectionType) {
                            '^ComputerName$|^CimSession$' {
                                $invokeCIMMethodSplat['Arguments'] = @{
                                    CCMUpdates = [ciminstance[]]$MissingUpdates
                                }
                                Invoke-CimMethod @invokeCIMMethodSplat @connectionSplat -ErrorAction Stop
                            }
                            'PSSession' {
                            # Pass list of missing updates to the target machine as a parameter,
                            # then do any casting etc required and build icim's arguments there
                            # The Out-Null in the script block is required to avoid 'Could not infer CimType from the provided .NET object' errors, though not sure why it prevents them.
                                $invokeUpdatesSplat = @{
                                    ScriptBlock  = {
                                        param (
                                            $invokeCIMMethodSplat,
                                            $toInstall
                                        )
                                        $toInstall|Out-Null
                                        Invoke-CimMethod @invokeCIMMethodSplat -Arguments @{
                                            CCMUpdates = [ciminstance[]]$toInstall
                                        }
                                    }
                                    ArgumentList = $invokeCIMMethodSplat, $MissingUpdates
                                }
                                Invoke-Command @invokeUpdatesSplat @connectionSplat
                            }
                        }
                    }
                    else {
                        Write-Warning "$Computer has no updates available to invoke"
                    }

                    if ($Invocation) {
                        Write-Verbose "Successfully invoked updates on $Computer via the 'InstallUpdates' CIM method"
                        $Result['Invoked'] = $true
                    }

                }
                catch [Microsoft.Management.Infrastructure.CimException] {
                    if (Test-CimKnownError -FullyQualifiedErrorId $_.FullyQualifiedErrorId) {
                        Write-Verbose "Suppressing known error - [$($_.FullyQualifiedErrorId)]"
                        Write-Verbose "Successfully invoked updates on $Computer via the 'InstallUpdates' CIM method"
                        $Result['Invoked'] = $true
                    }
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }

                [pscustomobject]$Result
            }
        }
    }
}
