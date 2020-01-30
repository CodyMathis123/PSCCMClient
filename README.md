# CCMClient PowerShell Module

PowerShell module focused around interaction with the Configuration Manager client. The general theme is to provide functions that 'work as expected' in that they accept pipeline where possible, such as with the below example. 

```Powershell
Get-CCMUpdate | Invoke-CCMUpdate
Get-CCMPackage -PackageName 'Install Company Software' -ComputerName Workstation1 | Invoke-CCMPackage
Get-CCMServiceWindow | ConvertFrom-CCMSchedule
Get-CCMBaseline -BaselineName 'Cache Management' -CimSession $CimSession1 | Invoke-CCMBaseline
Get-CCMApplication -ApplicationName '7-Zip' -ComputerName Workstation1 | Invoke-CCMApplication -Method Uninstall
```

Largely this is leveraging CIM to gather info, and act upon it. This is why there are custom functions to make registry edits, and gather registry info via CIM.

Some parts of the MEMCM Client do not 'play nice' with CIM remotely. This can be seen with the methods on SMS_CLIENT in the root\CCM Namespace, and by trying to invoke updates, remotely
with CIM. As a workaround for this, Invoke-CIMPowerShell is used. This functions allows us to remotely execute scriptblocks via CIM with the Create method on Win32_Process.

I encourage anyone that wants to contribute to start picking away! I'm currently using VSCode to develop this module, and as part of that I'm using the 'TODO Tree' extension to make brief notes regarding future work that needs done. 

Current list of functions:

* ConvertFrom-CCMSchedule
* Get-CCMApplication
* Get-CCMBaseline
* Get-CCMCacheInfo
* Get-CCMCacheContent
* Get-CCMClientDirectory
* Get-CCMClientInfo
* Get-CCMClientVersion
* Get-CCMCurrentManagementPoint
* Get-CCMCurrentSoftwareUpdatePoint
* Get-CCMExecStartupTime
* Get-CCMDNSSuffix
* Get-CCMGUID
* Get-CCMLastHardwareInventory
* Get-CCMLastHeartbeat
* Get-CCMLastSoftwareInventory
* Get-CCMLastScheduleTrigger
* Get-CCMLogFile
* Get-CCMLoggingConfiguration
* Get-CCMMaintenanceWindow
* Get-CCMPackage
* Get-CCMPrimaryUser
* Get-CCMProvisioningMode
* Get-CCMServiceWindow
* Get-CCMSite
* Get-CCMSoftwareUpdateGroup
* Get-CCMSoftwareUpdateSettings
* Get-CCMTaskSequence
* Get-CCMUpdate
* Get-CIMRegistryProperty
* Invoke-CCMApplication
* Invoke-CCMBaseline
* Invoke-CCMClientAction
* Invoke-CCMPackage
* Invoke-CCMResetPolicy
* Invoke-CCMTriggerSchedule
* Invoke-CCMUpdate
* Invoke-CIMPowerShell
* Invoke-CCMTaskSequence
* New-LoopAction
* Remove-CCMCacheContent
* Repair-CCMCacheLocation
* Reset-CCMLoggingConfiguration
* Set-CCMCacheLocation
* Set-CCMCacheSize
* Set-CCMDNSSuffix
* Set-CCMLoggingConfiguration
* Set-CCMManagementPoint
* Set-CCMProvisioningMode
* Set-CCMSite
* Set-CIMRegistryProperty
* Test-CCMIsClientOnInternet
* Test-CCMIsClientAlwaysOnInternet
* Test-CCMIsWindowAvailableNow
* Test-CCMStaleLog
* Write-CCMLogEntry