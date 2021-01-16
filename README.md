# PSCCMClient PowerShell Module

## What is it

PSCCMClient is a PowerShell module focused around interaction with the Microsoft Endpoint Manager Configuration Manager (MEMCM/MECM/ConfigMgr/SCCM/SMS) client. The general theme is to provide functions that 'work as expected' in that they accept pipeline where possible, such as with the below examples. Additionally you can pass an array of Computer Names, CimSessions, or PSSessions to the functions to work with remote devices.

```Powershell
Get-CCMUpdate | Invoke-CCMUpdate
Get-CCMPackage -PackageName 'Install Company Software' -ComputerName Workstation1 | Invoke-CCMPackage
Get-CCMServiceWindow | ConvertFrom-CCMSchedule
Get-CCMBaseline -BaselineName 'Cache Management' -CimSession $CimSession1 | Invoke-CCMBaseline
Get-CCMApplication -ApplicationName '7-Zip' -ComputerName Workstation1 | Invoke-CCMApplication -Method Uninstall
```

Largely this is leveraging CIM to gather info, and act upon it. This is why there are custom functions to make registry edits, and gather registry info via CIM. By consistently using CIM, we can ensure that a CimSession can be used for efficiency. A PSSession parameter is also available on all functions for an alternative remote connection. In some cases, invoking certain CIMMethods over a CIMSession is not available because some CIM methods for the MEMCM client do not work well remotely over CIM. This can be seen with the methods on SMS_CLIENT in the root\CCM Namespace and by trying to invoke updates remotely with CIM. There are functions that allow executing arbitrary code via the Win32_Process:CreateProcess method. In order to do this, code is converted to, and from Base64. This might be a red flag for enterprise AV.

## [Usage](docs)

## [Contributing](CONTRIBUTING.md)

## List of functions

* [ConvertFrom-CCMLogFile](docs/ConvertFrom-CCMLogFile.md)
  * Alias: Get-CCMLogFile
* [ConvertFrom-CCMSchedule](docs/ConvertFrom-CCMSchedule.md)
* [ConvertTo-CCMLogFile](docs/ConvertTo-CCMLogFile.md)
* [Get-CCMApplication](docs/Get-CCMApplication.md)
* [Get-CCMBaseline](docs/Get-CCMBaseline.md)
  * Alias: Get-CCMCB
* [Get-CCMCacheContent](docs/Get-CCMCacheContent.md)
* [Get-CCMCacheInfo](docs/Get-CCMCacheInfo.md)
* [Get-CCMCimInstance](docs/Get-CCMCimInstance.md)
* [Get-CCMClientDirectory](docs/Get-CCMClientDirectory.md)
* [Get-CCMClientInfo](docs/Get-CCMClientInfo.md)
* [Get-CCMClientVersion](docs/Get-CCMClientVersion.md)
* [Get-CCMCurrentManagementPoint](docs/Get-CCMCurrentManagementPoint.md)
  * Alias: Get-CCMCurrentMP
  * Alias: Get-CCMMP
* [Get-CCMCurrentSoftwareUpdatePoint](docs/Get-CCMCurrentSoftwareUpdatePoint.md)
  * Alias: Get-CCMCurrentSUP
  * Alias: Get-CCMSUP
* [Get-CCMCurrentWindowAvailableTime](docs/Get-CCMCurrentWindowAvailableTime.md)
* [Get-CCMDNSSuffix](docs/Get-CCMDNSSuffix.md)
* [Get-CCMExecStartupTime](docs/Get-CCMExecStartupTime.md)
* [Get-CCMGUID](docs/Get-CCMGUID.md)
* [Get-CCMLastHardwareInventory](docs/Get-CCMLastHardwareInventory.md)
  * Alias: Get-CCMLastHINV
* [Get-CCMLastHeartbeat](docs/Get-CCMLastHeartbeat.md)
  * Alias: Get-CCMLastDDR
* [Get-CCMLastScheduleTrigger](docs/Get-CCMLastScheduleTrigger.md)
* [Get-CCMLastSoftwareInventory](docs/Get-CCMLastSoftwareInventory.md)
  * Alias: Get-CCMLastSINV
* [Get-CCMLoggingConfiguration](docs/Get-CCMLoggingConfiguration.md)
* [Get-CCMMaintenanceWindow](docs/Get-CCMMaintenanceWindow.md)
  * Alias: Get-CCMMW
* [Get-CCMPackage](docs/Get-CCMPackage.md)
* [Get-CCMPrimaryUser](docs/Get-CCMPrimaryUser.md)
* [Get-CCMProvisioningMode](docs/Get-CCMProvisioningMode.md)
* [Get-CCMRegistryProperty](docs/Get-CCMRegistryProperty.md)
  * Alias: Get-CIMRegistryProperty
* [Get-CCMServiceWindow](docs/Get-CCMServiceWindow.md)
* [Get-CCMSite](docs/Get-CCMSite.md)
* [Get-CCMSoftwareUpdate](docs/Get-CCMSoftwareUpdate.md)
  * Alias: Get-CCMUpdate
* [Get-CCMSoftwareUpdateGroup](docs/Get-CCMSoftwareUpdateGroup.md)
  * Alias: Get-CCMSUG
* [Get-CCMSoftwareUpdateSettings](docs/Get-CCMSoftwareUpdateSettings.md)
* [Get-CCMTaskSequence](docs/Get-CCMTaskSequence.md)
* [Invoke-CCMApplication](docs/Invoke-CCMApplication.md)
* [Invoke-CCMBaseline](docs/Invoke-CCMBaseline.md)
* [Invoke-CCMClientAction](docs/Invoke-CCMClientAction.md)
* [Invoke-CCMCommand](docs/Invoke-CCMCommand.md)
* [Invoke-CCMPackage](docs/Invoke-CCMPackage.md)
* [Invoke-CCMResetPolicy](docs/Invoke-CCMResetPolicy.md)
* [Invoke-CCMSoftwareUpdate](docs/Invoke-CCMSoftwareUpdate.md)
  * Alias: Invoke-CCMUpdate
* [Invoke-CCMTaskSequence](docs/Invoke-CCMTaskSequence.md)
* [Invoke-CCMTriggerSchedule](docs/Invoke-CCMTriggerSchedule.md)
* [Invoke-CIMPowerShell](docs/Invoke-CIMPowerShell.md)
* [New-LoopAction](docs/New-LoopAction.md)
* [Remove-CCMCacheContent](docs/Remove-CCMCacheContent.md)
* [Repair-CCMCacheLocation](docs/Repair-CCMCacheLocation.md)
* [Set-CCMCacheLocation](docs/Set-CCMCacheLocation.md)
* [Set-CCMCacheSize](docs/Set-CCMCacheSize.md)
* [Set-CCMClientAlwaysOnInternet](docs/Set-CCMClientAlwaysOnInternet.md)
* [Set-CCMDNSSuffix](docs/Set-CCMDNSSuffix.md)
* [Set-CCMLoggingConfiguration](docs/Set-CCMLoggingConfiguration.md)
* [Set-CCMManagementPoint](docs/Set-CCMManagementPoint.md)
  * Alias: Set-CCMMP
* [Set-CCMProvisioningMode](docs/Set-CCMProvisioningMode.md)
* [Set-CCMRegistryProperty](docs/Set-CCMRegistryProperty.md)
  * Alias: Set-CIMRegistryProperty
* [Set-CCMSite](docs/Set-CCMSite.md)
* [Test-CCMIsClientAlwaysOnInternet](docs/Test-CCMIsClientAlwaysOnInternet.md)
* [Test-CCMIsClientOnInternet](docs/Test-CCMIsClientOnInternet.md)
* [Test-CCMIsWindowAvailableNow](docs/Test-CCMIsWindowAvailableNow.md)
* [Test-CCMStaleLog](docs/Test-CCMStaleLog.md)
* [Write-CCMLogEntry](docs/Write-CCMLogEntry.md)
