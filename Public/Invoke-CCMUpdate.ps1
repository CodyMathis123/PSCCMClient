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
            Updated:     2020-01-16
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ArticleID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $UpdateStatus = @{
            "23" = "WaitForOrchestration";
            "22" = "WaitPresModeOff";
            "21" = "WaitingRetry";
            "20" = "PendingUpdate";
            "19" = "PendingUserLogoff";
            "18" = "WaitUserReconnect";
            "17" = "WaitJobUserLogon";
            "16" = "WaitUserLogoff";
            "15" = "WaitUserLogon";
            "14" = "WaitServiceWindow";
            "13" = "Error";
            "12" = "InstallComplete";
            "11" = "Verifying";
            "10" = "WaitReboot";
            "9"  = "PendingHardReboot";
            "8"  = "PendingSoftReboot";
            "7"  = "Installing";
            "6"  = "WaitInstall";
            "5"  = "Downloading";
            "4"  = "PreDownload";
            "3"  = "Detecting";
            "2"  = "Submitted";
            "1"  = "Available";
            "0"  = "None";
        }
        #$UpdateStatus.Get_Item("$EvaluationState")
        #endregion status type hashtable

        $connectionSplat = @{ }
        $invokeCIMMethodSplat = @{
            Namespace  = 'root\ccm\clientsdk'
            MethodName = 'InstallUpdates'
            ClassName  = 'CCM_SoftwareUpdatesManager'
        }
        $getUpdateSplat = @{
            Namespace = 'root\CCM\ClientSDK'
        }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Invoke-CCMUpdate'
        }
    }
    process {
        # temp fix for when PSComputerName from pipeline is empty - we assume it is $env:ComputerName
        switch ($PSCmdlet.ParameterSetName) {
            'ComputerName' {
                switch ([string]::IsNullOrWhiteSpace($ComputerName)) {
                    $true {
                        $ComputerName = $env:ComputerName
                    }
                }
            }
        }        
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
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
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
                    [ciminstance[]]$MissingUpdates = Get-CimInstance @getUpdateSplat @connectionSplat
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
                        Write-Output "$Computer has no updates available to invoke"
                    }
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @invokeCIMMethodSplat
                        }
                        $false {
                            $ScriptBlock = [string]::Format('Invoke-CCMUpdate -ArticleID {0}', [string]::Join(', ', $ArticleID))
                            $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                            Invoke-CIMPowerShell @invokeCIMPowerShellSplat @connectionSplat
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