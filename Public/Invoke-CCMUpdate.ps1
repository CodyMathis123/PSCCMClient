function Invoke-CCMUpdate {
    [CmdletBinding(SupportsShouldProcess)]
    <#
        .SYNOPSIS
            Invokes updates deployed via Configuration Manager on a client
        .DESCRIPTION
            This script will allow you to invoke updates a machine (with optional credentials). It uses remote WMI to find updates
            based on your input, or you can optionally provide updates via the $Updates parameter, which support pipeline from
            Get-CCMUpdate
        .PARAMETER ComputerName
            Specifies the computers to run this against. Supports pipeline inpuit for common aliases
        .PARAMETER Updates
            Specifies the computers to run this against. Supports pipeline input for WMI object collectied from Get-CCMUpdate
        .PARAMETER Credential
            Optional PSCredential
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
            Created:     12-22-2018
            Updated:     10-15-2019
    #>
    param(
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false, ParameterSetName = 'PassUpdates', ValueFromPipeline)]
        [System.Management.ManagementObject[]]$Updates,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
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

        $invokeWmiMethodSplat = @{
            Namespace = 'root\ccm\clientsdk'
            Name      = 'InstallUpdates'
            Class     = 'CCM_SoftwareUpdatesManager'
        }
        $getWmiObjectSplat = @{
            Filter    = "ComplianceState=0"
            Namespace = 'root\CCM\ClientSDK'
            Class     = 'CCM_SoftwareUpdate'
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $invokeWmiMethodSplat['Credential'] = $Credential
            $getWmiObjectSplat['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Invoke-CCMUpdate")) {
                try {
                    $invokeWmiMethodSplat['ComputerName'] = $Computer
                    switch ($PSCmdlet.ParameterSetName) {
                        'PassUpdates' {
                            $invokeWmiMethodSplat['ArgumentList'] = ( , $Updates)
                            Invoke-WmiMethod @invokeWmiMethodSplat
                        }
                        default {
                            $getWmiObjectSplat['ComputerName'] = $Computer
                            [System.Management.ManagementObject[]]$MissingUpdates = Get-WmiObject @getWmiObjectSplat
                            if ($MissingUpdates -is [Object]) {
                                $invokeWmiMethodSplat['ArgumentList'] = ( , $MissingUpdates)
                                Invoke-WmiMethod @invokeWmiMethodSplat
                            }
                            else {
                                Write-Output "$Computer has no updates available to invoke"
                            }
                        }
                    }
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
            }
        }
    }
}