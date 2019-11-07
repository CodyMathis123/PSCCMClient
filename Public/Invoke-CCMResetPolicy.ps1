function Invoke-CCMResetPolicy {
    [CmdletBinding(SupportsShouldProcess)]
    <#
        .SYNOPSIS
            Invokes a ResetPolicy on the sms_client
        .DESCRIPTION
            This function will force a complete policy reset on a client and attempt to restart the CCMEXec service
        .PARAMETER ComputerName
            Specifies the computers to run this against
        .PARAMETER Credential
            Optional PSCredential
        .EXAMPLE
            C:\PS> Invoke-CCMResetPolicy
                Reset the policy on the local machine and restarts CCMExec
        .NOTES
            FileName:    Invoke-CCMResetPolicy.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     10-30-2019
            Updated:     10-30-2019
    #>
    param
    (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        $invokeWmiMethodSplatPolicyReset = @{
            Name        = 'ResetPolicy'
            Namespace   = 'root\ccm'
            Class       = 'sms_client'
            ArgumentList = @(1)
        }
        $invokeWmiMethodService = @{
            Path = "Win32_Service.Name='ccmexec'"
        }
        $invokeWmiMethodSplat = @{
            ErrorAction = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $invokeWmiMethodSplat['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "ResetPolicy")) {
                try {
                    $invokeWmiMethodSplat['ComputerName'] = $Computer

                    Write-Verbose "Performing ResetPolicy on $Computer"
                    $Invocation = Invoke-WmiMethod @invokeWmiMethodSplatPolicyReset @invokeWmiMethodSplat

                    Invoke-WmiMethod @invokeWmiMethodService @invokeWmiMethodSplat -Name 'StopService'
                    Start-Sleep -Seconds 30
                    Invoke-WmiMethod @invokeWmiMethodService @invokeWmiMethodSplat -Name 'StartService'
                }
                catch [System.UnauthorizedAccessException] {
                    Write-Error -Message "Access denied to $Computer" -Category AuthenticationError -Exception $_.Exception
                }
                catch {
                    Write-Warning "Failed to invoke ResetPolicy for $Computer"
                }
            }
        }
    }
}
