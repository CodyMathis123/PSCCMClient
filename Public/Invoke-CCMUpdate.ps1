function Invoke-CCMUpdate {
    <#
        .SYNOPSIS
            Invokes updates deployed via Configuration Manager on a client
        .DESCRIPTION
            This script will allow you to invoke updates a machine (with optional credentials). It uses remote CIM to find updates
            based on your input, or you can optionally provide updates via the $Updates parameter, which support pipeline from
            Get-CCMUpdate.

            Unfortunately, invoke SCCM updates remotely via CIM does NOT seem to work. As an alternative, Invoke-CIMPowerShell is used to
            execute the command 'locally' on the remote machine.
        .PARAMETER Updates
            [ciminstance[]] object that contains SCCM Updates from CCM_SoftwareUpdate class. Supports pipeline input for CIM object collected from Get-CCMUpdate
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get invoke SCCM patches for
        .PARAMETER ComputerName
            Computer name(s) which you want to get invoke SCCM patches for
        .PARAMETER PSSession
            PSSession(s) which you want to get invoke SCCM patches for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Invoke-CCMUpdate
                Invokes all updates on the local machine
        .EXAMPLE
            C:\PS> Invoke-CCMUpdate -ComputerName TestingPC1
                Invokes all updates on the the remote computer TestingPC1
        .NOTES
            FileName:    Invoke-CCMUpdate.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2018-12-22
            Updated:     2020-02-27
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
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
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Invoke-CCMUpdate', 'Get-CCMConnection'
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Invoke-CCMUpdate")) {
                try {
                    $getUpdateSplat['Query'] = switch ($PSBoundParameters.ContainsKey('ArticleID')) {
                        $true {
                            [string]::Format('SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0 AND (ArticleID = "{0}")', [string]::Join('" OR ArticleID = "', $ArticleID))
                        }
                        $false {
                            [string]::Format('SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0')
                        }
                    }

                    [ciminstance[]]$MissingUpdates = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @getUpdateSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @getUpdateSplat @connectionSplat
                        }
                    }

                    if ($MissingUpdates -is [ciminstance[]]) {
                        switch ($PSBoundParameters.ContainsKey('ArticleID')) {
                            $false {
                                $ArticleID = $MissingUpdates.ArticleID
                            }
                        }
                        $invokeCIMMethodSplat['Arguments'] = @{
                            CCMUpdates = [ciminstance[]]$MissingUpdates
                        }
                    }
                    else {
                        Write-Warning "$Computer has no updates available to invoke"
                    }
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @invokeCIMMethodSplat
                        }
                        $false {
                            $ScriptBlock = [string]::Format('Invoke-CCMUpdate -ArticleID {0}', [string]::Join(', ', $ArticleID))
                            $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    if ($Invocation) {
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