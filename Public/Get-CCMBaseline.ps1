function Get-CCMBaseline {
    <#
        .SYNOPSIS
            Get SCCM Configuration Baselines on the specified computer(s) or cimsession(s)
        .DESCRIPTION
            This function is used to identify baselines on computers. You can provide an array of computer names, or cimsessions, and
            configuration baseline names which will be queried for. If you do not specify a baseline name, then there will be no filter applied.
            A [PSCustomObject] is returned that outlines the findings.
        .PARAMETER BaselineName
            Provides the configuration baseline names that you wish to search for.
        .PARAMETER ComputerName
            Provides computer names to find the configuration baselines on.
        .PARAMETER CimSession
            Provides cimsessions to return baselines from.
        .PARAMETER PSSession
           Provides PSSessions to return baselines from.
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName paramter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMBaseline
                Gets all baselines identified in WMI on the local computer.
        .EXAMPLE
            C:\PS> Get-CCMBaseline -ComputerName 'Workstation1234','Workstation4321' -BaselineName 'Check Connection Compliance','Double Check Connection Compliance'
                Gets the two baselines on the Computers specified. This demonstrates that both ComputerName and BaselineName accept string arrays.
        .EXAMPLE
            C:\PS> Get-CCMBaseline -ComputerName 'Workstation1234','Workstation4321'
                Gets all baselines identified in WMI for the Computers specified.
        .NOTES
            FileName:    Get-CCMBaseline.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-07-24
            Updated:     2020-02-22

            It is important to note that if a configuration baseline has user settings, the only way to search for it is if the user is logged in, and you run this script
            with those credentials provided to a CimSession. An example would be if Workstation1234 has user Jim1234 logged in, with a configuration baseline 'FixJimsStuff'
            that has user settings,

            This command would successfully find FixJimsStuff
            Get-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff' -CimSession $CimSessionWithJimsCreds

            This command would not find the baseline FixJimsStuff
            Get-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff'

            You could remotely query for that baseline AS Jim1234, with either a runas on PowerShell, or providing Jim's credentials to a cimsesion passed to -cimsession param.
            If you try to query for this same baseline without Jim's credentials being used in some way you will see that the baseline is not found.
    #>
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