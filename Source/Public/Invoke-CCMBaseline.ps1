function Invoke-CCMBaseline {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
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
        $invokeBaselineEvalSplat = @{
            Namespace   = 'root\ccm\dcm'
            ClassName   = 'SMS_DesiredConfiguration'
            ErrorAction = 'Stop'
            Name        = 'TriggerEvaluation'
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

        <#
            Not all Properties are on all Configuration Baseline instances, this is the list of possible options
            We will identify which properties exist, and pass the respective arguments to Invoke-CimMethod with typecasting
        #>
        $PropertyOptions = 'IsEnforced', 'IsMachineTarget', 'Name', 'PolicyType', 'Version'
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

            foreach ($BLName in $BaselineName) {
                #region Query CIM for Configuration Baselines based off DisplayName
                $BLQuery = switch ($PSBoundParameters.ContainsKey('BaselineName')) {
                    $true {
                        [string]::Format("SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName = '{0}'", $BLName)
                    }
                    $false {
                        "SELECT * FROM SMS_DesiredConfiguration"
                    }
                }
                Write-Verbose "Checking for Configuration Baselines on [ComputerName='$Computer'] with [Query=`"$BLQuery`"]"
                $getBaselineSplat['Query'] = $BLQuery
                try {
                    $Baselines = switch -regex ($ConnectionInfo.ConnectionType) {
                        '^ComputerName$|^CimSession$' {
                            Get-CimInstance @getBaselineSplat @connectionSplat
                        }
                        'PSSession' {
                            Get-CCMCimInstance @getBaselineSplat @connectionSplat
                        }
                    }
                }
                catch {
                    # need to improve this - should catch access denied vs RPC, and need to do this on ALL CIM related queries across the module.
                    # Maybe write a function???
                    Write-Error "Failed to query for baselines on $Computer - $_"
                }
                #endregion Query CIM for Configuration Baselines based off DisplayName

                #region Based on results of CIM Query, identify arguments and invoke TriggerEvaluation
                switch ($null -eq $Baselines) {
                    $false {
                        foreach ($BL in $Baselines) {
                            if ($PSCmdlet.ShouldProcess($BL.DisplayName, "Invoke Evaluation")) {
                                $Return = [ordered]@{ }
                                $Return['ComputerName'] = $Computer
                                $Return['BaselineName'] = $BL.DisplayName
                                $Return['Version'] = $BL.Version
                                $Return['LastComplianceStatus'] = $LastComplianceStatus[[int]$BL.LastComplianceStatus]
                                $Return['LastEvalTime'] = $BL.LastEvalTime

                                #region generate a property list of existing arguments to pass to the TriggerEvaluation method. Type is important!
                                $ArgumentList = @{ }
                                foreach ($Property in $PropertyOptions) {
                                    $PropExist = Get-Member -InputObject $BL -MemberType Properties -Name $Property
                                    switch ($PropExist) {
                                        $null {
                                            continue
                                        }
                                        default {
                                            $TypeString = ($PropExist.Definition.Split(' '))[0]
                                            $Type = [scriptblock]::Create("[$TypeString]")
                                            $ArgumentList[$Property] = $BL.$Property -as (. $Type)
                                        }
                                    }
                                }
                                $invokeBaselineEvalSplat['Arguments'] = $ArgumentList
                                #endregion generate a property list of existing arguments to pass to the TriggerEvaluation method. Type is important!

                                #region Trigger the Configuration Baseline to run
                                Write-Verbose "Identified the Configuration Baseline [BaselineName='$($BL.DisplayName)'] on [ComputerName='$Computer'] will trigger via the 'TriggerEvaluation' CIM method"
                                $Return['Invoked'] = try {
                                    $Invocation = switch -regex ($ConnectionInfo.ConnectionType) {
                                        '^ComputerName$|^CimSession$' {
                                            Invoke-CimMethod @invokeBaselineEvalSplat @connectionSplat
                                        }
                                        'PSSession' {
                                            $InvokeCCMCommandSplat = @{
                                                Arguments   = $invokeBaselineEvalSplat
                                                ScriptBlock = {
                                                    param(
                                                        $invokeBaselineEvalSplat
                                                    )
                                                    Invoke-CimMethod @invokeBaselineEvalSplat
                                                }
                                            }
                                            Invoke-CCMCommand @InvokeCCMCommandSplat @connectionSplat

                                        }
                                    }
                                    switch ($Invocation.ReturnValue) {
                                        0 {
                                            $true
                                        }
                                        default {
                                            $false
                                        }
                                    }
                                }
                                catch {
                                    $false
                                }

                                [pscustomobject]$Return
                                #endregion Trigger the Configuration Baseline to run
                            }
                        }
                    }
                    $true {
                        Write-Warning "Failed to identify any Configuration Baselines on [ComputerName='$Computer'] with [Query=`"$BLQuery`"]"
                    }
                }
                #endregion Based on results of CIM Query, identify arguments and invoke TriggerEvaluation
            }
        }
    }
}