# PSCCMClient PowerShell Module

PowerShell module focused around interaction with the Microsoft Endpoint Manager Configuration Manager (MEMCM) client. The general theme is to provide functions that 'work as expected' in that they accept pipeline where possible, such as with the below example, as well as an array of Computer Names, CimSessions or PSSessions depending on the command.

```Powershell
Get-CCMUpdate | Invoke-CCMUpdate
Get-CCMPackage -PackageName 'Install Company Software' -ComputerName Workstation1 | Invoke-CCMPackage
Get-CCMServiceWindow | ConvertFrom-CCMSchedule
Get-CCMBaseline -BaselineName 'Cache Management' -CimSession $CimSession1 | Invoke-CCMBaseline
Get-CCMApplication -ApplicationName '7-Zip' -ComputerName Workstation1 | Invoke-CCMApplication -Method Uninstall
```

Largely this is leveraging CIM to gather info, and act upon it. This is why there are custom functions to make registry edits, and gather registry info via CIM. By consistently using CIM, we can ensure that a CimSession can be used for efficiency. A PSSession parameter is also available on all functions for an alternative remote connection. In some cases, a CIMSession parameter is not available because some CIM methods for the MEMCM client do not work well remotely over CIM. This can be seen with the methods on SMS_CLIENT in the root\CCM Namespace and by trying to invoke updates remotely with CIM. In previous iterations of this module, I was executing arbitrary code via the Win32_Process:CreateProcess method. In order to do this, code was being converted to, and from Base64. This was commonly a red flag for enterprise AV. I have since removed the code that does Base64 conversion, but I am open to creative ideas!

I encourage anyone that wants to contribute to start picking away! I'm currently using VSCode to develop this module, and as part of that I'm using the 'TODO Tree' extension to make brief notes regarding future work that needs done.

Current list of functions:

* ConvertFrom-CCMSchedule
* Get-CCMApplication
* Get-CCMBaseline
* Get-CCMCacheContent
* Get-CCMCacheInfo
* Get-CCMCimInstance
* Get-CCMClientDirectory
* Get-CCMClientInfo
* Get-CCMClientVersion
* Get-CCMCurrentManagementPoint
* Get-CCMCurrentSoftwareUpdatePoint
* Get-CCMCurrentWindowAvailableTime
* Get-CCMDNSSuffix
* Get-CCMExecStartupTime
* Get-CCMGUID
* Get-CCMLastHardwareInventory
* Get-CCMLastHeartbeat
* Get-CCMLastScheduleTrigger
* Get-CCMLastSoftwareInventory
* Get-CCMLogFile
* Get-CCMLoggingConfiguration
* Get-CCMMaintenanceWindow
* Get-CCMPackage
* Get-CCMPrimaryUser
* Get-CCMProvisioningMode
* Get-CCMRegistryProperty
* Get-CCMServiceWindow
* Get-CCMSite
* Get-CCMSoftwareUpdateGroup
* Get-CCMSoftwareUpdateSettings
* Get-CCMTaskSequence
* Get-CCMUpdate
* Invoke-CCMApplication
* Invoke-CCMBaseline
* Invoke-CCMClientAction
* Invoke-CCMPackage
* Invoke-CCMResetPolicy
* Invoke-CCMTaskSequence
* Invoke-CCMTriggerSchedule
* Invoke-CCMUpdate
* Invoke-CIMPowerShell
* New-LoopAction
* Remove-CCMCacheContent
* Repair-CCMCacheLocation
* Set-CCMCacheLocation
* Set-CCMCacheSize
* Set-CCMClientAlwaysOnInternet
* Set-CCMDNSSuffix
* Set-CCMLoggingConfiguration
* Set-CCMManagementPoint
* Set-CCMProvisioningMode
* Set-CCMRegistryProperty
* Set-CCMSite
* Test-CCMIsClientAlwaysOnInternet
* Test-CCMIsClientOnInternet
* Test-CCMIsWindowAvailableNow
* Test-CCMStaleLog
* Write-CCMLogEntry