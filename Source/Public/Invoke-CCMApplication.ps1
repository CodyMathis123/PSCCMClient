Function Invoke-CCMApplication {
    <#
        .SYNOPSIS
            Invoke the provided method for an application deployed to a computer
        .DESCRIPTION
            Uses the Install, or Uninstall method of the CCM_Application CIMClass to perform actions on applications.

            Not that you cannot inherently invoke these methods on every single application. It will have to adhere
            to the same logic that any application must follow for installation. This includes meeting application 
            requirements, being 'Applicable' in the sense of trying to 'Install' an application that is not currently
            detected as installed, or trying to 'Uninstall' an application that is currently detected as installed, 
            and it has an Uninstall command. 

            The most surefire way to invoke an application method is to do so as system. Otherwise, you can also do
            the invoking as the current interactive user of the targeted machine. 
        .PARAMETER ID
            An array of ID to invoke
        .PARAMETER IsMachineTarget
            Boolean value that specifies if the application is machine targeted, or user targeted
        .PARAMETER Revision
            The revision of the application that will have an action invoked. This is needed so that MEMCM knows
                what policy it should be working with.
        .PARAMETER Method
            Install, or Uninstall. Keep in mind that you can only perform whatever action is available for an application.
                If it is a required application that does not allow uninstall, then the invoke will not work.
        .PARAMETER EnforcePreference
            When the install should take place. Options are 'Immediate', 'NonBusinessHours', or 'AdminSchedule'

            Defaults to 'Immediate'
        .PARAMETER Priority
            The priority that is passed to the method. Options are 'Foreground', 'High', 'Normal', and 'Low'

            Defaults to 'High'
        .PARAMETER IsRebootIfNeeded
            Boolean that tells MEMCM if it can reboot the computer IF a reboot is required after the method completes based on exit code.
        .PARAMETER CimSession
            Provides CimSession to invoke the application method on
        .PARAMETER ComputerName
            Provides computer names to invoke the application method on
        .PARAMETER PSSession
            Provides PSSessions to invoke the application method on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Get-CCMApplication -ApplicationName '7-Zip' | Invoke-CCMApplication -Method Install
                Invokes the install of 7-Zip on the local computer
        .EXAMPLE
            PS> Invoke-CCMApplication -ID ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e -Method Uninstall
                Invokes the uninstall of the application with the specified ID
        .NOTES
            FileName:    Invoke-CCMApplication.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-21
            Updated:     2020-03-02
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ID,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [bool[]]$IsMachineTarget,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Revision,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Install', 'Uninstall')]
        [Alias('Action')]
        [string]$Method,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Immediate', 'NonBusinessHours', 'AdminSchedule')]
        [string]$EnforcePreference = 'Immediate',
        [Parameter(Mandatory = $false)]
        [ValidateSet('Foreground', 'High', 'Normal', 'Low')]
        [string]$Priority = 'High',
        [Parameter(Mandatory = $false)]
        [bool]$IsRebootIfNeeded = $false,
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
        $EnforcePreferenceMap = @{
            'Immediate'        = [uint32]0
            'NonBusinessHours' = [uint32]1
            'AdminSchedule'    = [uint32]2
        }
        $invokeAppMethodSplat = @{
            NameSpace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_Application'
            MethodName = $Method
            Arguments  = @{
                Priority          = $Priority
                EnforcePreference = $EnforcePreferenceMap[$EnforcePreference]
                IsRebootIfNeeded  = $IsRebootIfNeeded
            }
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
            $Result['AppMethodInvoked'] = $false

            foreach ($AppID in $ID) {
                if ($PSCmdlet.ShouldProcess("[Method = '$Method'] [ID = '$AppID'] [ComputerName = '$Computer']", "Invoke-CCMApplication")) {
                    $invokeAppMethodSplat.Arguments['ID'] = [string]$AppID
                    $invokeAppMethodSplat.Arguments['Revision'] = [string]$Revision
                    $invokeAppMethodSplat.Arguments['IsMachineTarget'] = [bool]$IsMachineTarget
                    try {
                        $Invocation = switch -regex ($ConnectionInfo.ConnectionType) {
                            '^CimSession$|^ComputerName$' {
                                Invoke-CimMethod @invokeAppMethodSplat @connectionSplat
                            }
                            '^PSSession$' {
                                $InvokeCommandSplat = @{
                                    ArgumentList = $invokeAppMethodSplat
                                    ScriptBlock  = {
                                        param($invokeAppMethodSplat)
                                        Invoke-CimMethod @invokeAppMethodSplat
                                    }
                                }
                                Invoke-CCMCommand @InvokeCommandSplat @connectionSplat
                            }
                        }

                        switch ($Invocation.ReturnValue) {
                            0 {
                                $Result['AppMethodInvoked'] = $true
                            }
                        }
                    }
                    catch {
                        Write-Error "Failed to invoke [Method = '$Method'] [ID = '$AppID'] [ComputerName = '$Computer'] - $($_.Exception.Message)"
                    }
                    [pscustomobject]$Result
                }
            }
        }
    }
}