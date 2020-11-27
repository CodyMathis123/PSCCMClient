function Get-CCMBaseline {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCB')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$BaselineName = 'NotSpecified',
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
        #region Setup our *-CIM* parameters that will apply to the CIM cmdlets in use based on input parameters
        $getBaselineSplat = @{
            Namespace   = 'root\ccm\dcm'
            ErrorAction = 'Stop'
        }
        #endregion Setup our common *-CIM* parameters that will apply to the CIM cmdlets in use based on input parameters

        #region hash table for translating compliance status
        $LastComplianceStatus = @{
            0 = 'Non-Compliant'
            1 = 'Compliant'
            2 = 'Compliance State Unknown'
            4 = 'Error'
        }
        #endregion hash table for translating compliance status
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
            $Return['ComputerName'] = $Computer

            $BLQuery = switch ($PSBoundParameters.ContainsKey('BaselineName') -and $BaselineName -ne 'NotSpecified') {
                $true {
                    [string]::Format('SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName = "{0}"', [string]::Join('" OR DisplayName = "', $BaselineName))
                }
                $false {
                    "SELECT * FROM SMS_DesiredConfiguration"
                }
            }

            #region Query WMI for Configuration Baselines based off DisplayName
            Write-Verbose "Checking for Configuration Baselines on [ComputerName='$Computer'] with [Query=`"$BLQuery`"]"
            $getBaselineSplat['Query'] = $BLQuery
            try {
                $Baselines = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getBaselineSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getBaselineSplat @connectionSplat
                    }
                }
            }
            catch {
                # need to improve this - should catch access denied vs RPC, and need to do this on ALL CIM related queries across the module.
                # Maybe write a function???
                Write-Error "Failed to query for baselines on $Connection - $($_)"
                continue
            }
            #endregion Query WMI for Configuration Baselines based off DisplayName

            #region Based on results of CIM Query, return additional information around compliance and eval time
            switch ($null -eq $Baselines) {
                $false {
                    foreach ($BL in $Baselines) {
                        $Return['BaselineName'] = $BL.DisplayName
                        $Return['Version'] = $BL.Version
                        $Return['LastComplianceStatus'] = $LastComplianceStatus[[int]$BL.LastComplianceStatus]
                        $Return['LastEvalTime'] = $BL.LastEvalTime
                        [pscustomobject]$Return
                    }
                }
                $true {
                    Write-Warning "Failed to identify any Configuration Baselines on [ConnectionName='$Connection'] with [Query=`"$BLQuery`"]"
                }
            }
            #endregion Based on results of CIM Query, return additional information around compliance and eval time
        }
    }
}