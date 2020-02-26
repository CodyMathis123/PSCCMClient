function Invoke-CCMResetPolicy {
    <#
        .SYNOPSIS
            Invokes a ResetPolicy for the MEMCM client
        .DESCRIPTION
            This function will force a complete policy reset on a client for multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
        .PARAMETER ResetType
            Determins the policy reset type.

            'Purge' will wipe all policy from the machine, forcing a complete redownload, and rebuilt.

            'ForceFull' will simply force the next policy refresh to be a full instead of a delta.

            https://docs.microsoft.com/en-us/previous-versions/system-center/developer/cc143785%28v%3dmsdn.10%29
        .PARAMETER CimSession
            Provides CimSession to perform a policy reset on
        .PARAMETER ComputerName
            Provides computer names to perform a policy reset on
        .PARAMETER PSSession
            Provides PSSession to perform a policy reset on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Invoke-CCMResetPolicy
                Reset the policy on the local machine and restarts CCMExec
        .NOTES
            FileName:    Invoke-CCMResetPolicy.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-10-30
            Updated:     2020-02-23
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Purge', 'ForceFull')]
        [string]$ResetType = 'Purge',
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
        $uFlags = switch ($ResetType) {
            'Purge' {
                1
            }
            'ForceFull' {
                0
            }
        }
        $policyResetSplat = @{
            MethodName = 'ResetPolicy'
            Namespace  = 'root\ccm'
            ClassName  = 'sms_client'
            Arguments  = @{
                uFlags = [uint32]$uFlags
            }
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Invoke-CCMResetPolicy', 'Get-CCMConnection'
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
            $Result['PolicyReset'] = $false
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ResetType = '$ResetType']", "Reset CCM Policy")) {
                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @policyResetSplat
                        }
                        $false {
                            $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create([string]::Format('Invoke-CCMResetPolicy -ResetType {0}', $ResetType))
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked policy reset on $Computer via the 'ResetPolicy' CIM method"
                        $Result['PolicyReset'] = $true
                    }
                    [pscustomobject]$Result
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
            }
        }
    }
}