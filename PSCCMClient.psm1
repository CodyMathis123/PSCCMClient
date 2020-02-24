$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

#region Load Public Functions
Try {
    Get-ChildItem "$ScriptPath\Public" -Filter *.ps1 | Select-Object -ExpandProperty FullName | ForEach-Object {
        $Function = Split-Path $_ -Leaf
        . $_
    }
}
Catch {
    Write-Warning ("{0}: {1}" -f $Function, $_.Exception.Message)
    Continue
}
#endregion Load Public Functions

#region Load Private Functions
Try {
    Get-ChildItem "$ScriptPath\Private" -Filter *.ps1 | Select-Object -ExpandProperty FullName | ForEach-Object {
        $Function = Split-Path $_ -Leaf
        . $_
    }
}
Catch {
    Write-Warning ("{0}: {1}" -f $Function, $_.Exception.Message)
    Continue
}
#endregion Load Private Functions

# #region Format and Type Data
# Try {
#     Update-FormatData "$ScriptPath\TypeData\CCMClient.Format.ps1xml" -ErrorAction Stop
# }
# Catch {
# }
# Try {
#     Update-TypeData "$ScriptPath\TypeData\CCMClient.Types.ps1xml" -ErrorAction Stop
# }
# Catch {
# }
# #endregion Format and Type Data

#region Export Module Members
$ExportModule = @{
    Alias    = @('Get-CCMCB',
        'Get-CIMRegistryProperty',
        'Get-CCMCurrentMP',
        'Get-CCMCurrentSUP',
        'Get-CCMLastDDR',
        'Get-CCMLastHINV',
        'Get-CCMLastSINV'
        'Get-CCMMP',
        'Get-CCMMW',
        'Get-CCMSUP',
        'Get-CCMSUG',
        'Set-CCMMP',
        'Set-CIMRegistryProperty'
    )

    Function = @('ConvertFrom-CCMSchedule',
        'Get-CCMApplication',
        'Get-CCMBaseline',
        'Get-CCMCacheInfo',
        'Get-CCMCacheContent',
        'Get-CCMCimInstance',
        'Get-CCMClientDirectory',
        'Get-CCMClientInfo',
        'Get-CCMClientVersion',
        'Get-CCMCurrentManagementPoint',
        'Get-CCMCurrentSoftwareUpdatePoint',
        'Get-CCMCurrentWindowAvailableTime',
        'Get-CCMDNSSuffix',
        'Get-CCMExecStartupTime',
        'Get-CCMGUID',
        'Get-CCMLastHardwareInventory',
        'Get-CCMLastHeartbeat',
        'Get-CCMLastScheduleTrigger',
        'Get-CCMLastSoftwareInventory',
        'Get-CCMLogFile',
        'Get-CCMLoggingConfiguration',
        'Get-CCMMaintenanceWindow',
        'Get-CCMPackage',
        'Get-CCMPrimaryUser',
        'Get-CCMProvisioningMode',
        'Get-CCMRegistryProperty',
        'Get-CCMServiceWindow',
        'Get-CCMSite',
        'Get-CCMSoftwareUpdateGroup',
        'Get-CCMSoftwareUpdateSettings',
        'Get-CCMTaskSequence',
        'Get-CCMUpdate',
        'Invoke-CCMApplication',
        'Invoke-CCMBaseline',
        'Invoke-CCMClientAction',
        'Invoke-CCMCommand',
        'Invoke-CCMPackage',
        'Invoke-CCMResetPolicy',
        'Invoke-CCMTriggerSchedule',
        'Invoke-CCMUpdate',
        'Invoke-CIMPowerShell',
        'Invoke-CCMTaskSequence',
        'New-LoopAction',
        'Remove-CCMCacheContent',
        'Repair-CCMCacheLocation',
        'Reset-CCMLoggingConfiguration',
        'Set-CCMCacheLocation',
        'Set-CCMCacheSize',
        'Set-CCMClientAlwaysOnInternet',
        'Set-CCMDNSSuffix',
        'Set-CCMLoggingConfiguration',
        'Set-CCMManagementPoint',
        'Set-CCMProvisioningMode',
        'Set-CCMRegistryProperty',
        'Set-CCMSite',
        'Test-CCMIsClientOnInternet',
        'Test-CCMIsClientAlwaysOnInternet',
        'Test-CCMIsWindowAvailableNow',
        'Test-CCMStaleLog',
        'Write-CCMLogEntry'
    )
    Variable = @()
}
Export-ModuleMember @ExportModule
#endregion Export Module Members

$env:PSModulePath = $PSModulePath
