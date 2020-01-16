function Get-CCMUpdate {
    <#
    .SYNOPSIS
        Get pending SCCM patches for a machine
    .DESCRIPTION
        Uses CIM to find SCCM patches that are currently available on a machine.
    .PARAMETER IncludeDefs
        A switch that will determine if you want to include AV Definitions in your query
    .PARAMETER CimSession
        Computer CimSession(s) which you want to get pending SCCM patches for
    .PARAMETER ComputerName
        Computer name(s) which you want to get pending SCCM patches for
    .EXAMPLE
        PS C:\> Get-CCMUpdate -Computer Testing123
        will return all non-AV Dev patches for computer Testing123
    .NOTES
        FileName:    Get-CCMUpdate.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-15
        Updated:     2020-01-15
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDefs,
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

        $Filter = switch ($IncludeDefs) {
            $true {
                "ComplianceState=0"
            }
            Default {
                "NOT Name LIKE '%Definition%' and ComplianceState=0"
            }
        }

        $ConnectionSplat = @{ }
        $getUpdateSplat = @{
            Filter    = $Filter
            Namespace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_SoftwareUpdate'
        }
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
            try {
                [ciminstance[]]$MissingUpdates = Get-CimInstance @getUpdateSplat @ConnectionSplat
                if ($MissingUpdates -is [Object] -and $MissingUpdates.Count -gt 0) {
                    Write-Output -InputObject $MissingUpdates
                }
                else {
                    Write-Verbose "No updates found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
