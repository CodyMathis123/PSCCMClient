function Invoke-CCMBaseline {
    <#
        .SYNOPSIS
            Invoke SCCM Configuration Baselines on the specified computers
        .DESCRIPTION
            This function will allow you to provide an array of computer names, or cimsessions, and configuration baseline names which will be invoked.
            If you do not specify a baseline name, then ALL baselines on the machine will be invoked. A [PSCustomObject] is returned that
            outlines the results, including the last time the baseline was ran, and if the previous run returned compliant or non-compliant.
        .PARAMETER BaselineName
            Provides the configuration baseline names that you wish to invoke.
        .PARAMETER ComputerName
            Provides computer names to invoke the configuration baselines on.
        .PARAMETER CimSession
            Provides cimsessions to invoke the configuration baselines on.
        .EXAMPLE
            C:\PS> Invoke-CCMBaseline
                Invoke all baselines identified in WMI on the local computer.
        .EXAMPLE
            C:\PS> Invoke-CCMBaseline -ComputerName 'Workstation1234','Workstation4321' -BaselineName 'Check Computer Compliance','Double Check Computer Compliance'
                Invoke the two baselines on the computers specified. This demonstrates that both ComputerName and BaselineName accept string arrays.
        .EXAMPLE
            C:\PS> Invoke-CCMBaseline -ComputerName 'Workstation1234','Workstation4321'
                Invoke all baselines identified in WMI for the computers specified.
        .NOTES
            FileName:    Invoke-CCMBaseline.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-07-24
            Updated:     2020-01-31

            It is important to note that if a configuration baseline has user settings, the only way to invoke it is if the user is logged in, and you run this script
            with those credentials provided to a CimSession. An example would be if Workstation1234 has user Jim1234 logged in, with a configuration baseline 'FixJimsStuff'
            that has user settings,

            This command would successfully invoke FixJimsStuff
            Invoke-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff' -CimSession $CimSessionWithJimsCreds

            This command would not find the baseline FixJimsStuff, and be unable to invoke it
            Invoke-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff'

            You could remotely invoke that baseline AS Jim1234, with either a runas on PowerShell, or providing Jim's credentials to a cimsesion passed to -cimsession param.
            If you try to invoke this same baseline without Jim's credentials being used in some way you will see that the baseline is not found.

            Outside of that, it will dynamically generate the arguments to pass to the TriggerEvaluation method. I found a handful of examples on the internet for
            invoking SCCM Configuration Baselines, and there were always comments about certain scenarios not working. This implementation has been consistent in
            invoking Configuration Baselines, including those with user settings, as long as the context is correct.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$BaselineName = 'NotSpecified',
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
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
            $Computer = switch ($PSCmdlet.ParameterSetName) {
                'ComputerName' {
                    Write-Output -InputObject $Connection
                    switch ($Connection -eq $env:ComputerName) {
                        $false {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $Connection -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                                $ConnectionSplat.Remove('ComputerName')
                                $ConnectionSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $ConnectionSplat.Remove('CimSession')
                                $ConnectionSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $ConnectionSplat.Remove('CimSession')
                            $ConnectionSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $ConnectionSplat.Remove('ComputerName')
                    $ConnectionSplat['CimSession'] = $Connection
                }
            }
            foreach ($BLName in $BaselineName) {
                #region Query WMI for Configuration Baselines based off DisplayName
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
                    $Baselines = Get-CimInstance @getBaselineSplat @connectionSplat
                }
                catch {
                    # need to improve this - should catch access denied vs RPC, and need to do this on ALL CIM related queries across the module.
                    # Maybe write a function???
                    Write-Error "Failed to query for baselines on $Computer - $_"
                }
                #endregion Query WMI for Configuration Baselines based off DisplayName

                #region Based on results of CIM Query, identify arguments and invoke TriggerEvaluation
                switch ($null -eq $Baselines) {
                    $false {
                        foreach ($BL in $Baselines) {
                            if ($PSCmdlet.ShouldProcess($BL.DisplayName, "Invoke Evaluation")) {
                                $Return = [System.Collections.Specialized.OrderedDictionary]::new()
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
                                            $TypeString = ($PropExist.Definition -split ' ')[0]
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
                                    $Invocation = Invoke-CimMethod @invokeBaselineEvalSplat @connectionSplat
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