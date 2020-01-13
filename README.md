# CCMClient PowerShell Module

PowerShell module focused around interaction with the Configuration Manager client. The general theme is to provide functions that 'work as expected' in that they accept pipeline where possible, such as with Get-CCMUpdate | Invoke-CCMUpdate. Largely this is leveraging CIM to gather info, and act upon it. This is why there are custom functions to make registry edits, and gather registry info via CIM.

Some parts of the MEMCM Client do not 'play nice' with CIM remotely. This can be seen with the methods on SMS_CLIENT in the root\CCM Namespace, and by trying to invoke updates, remotely
with CIM. As a workaround for this, Invoke-CIMPowerShell is used. This functions allows us to remotely execute scriptblocks via CIM with the Create method on Win32_Process. 

I encourage anyone that wants to contribute to start picking away!

Current list of functions:

* ConvertFrom-CCMSchedule
* Get-CCMBaseline
* Get-CCMCache
* Get-CCMCacheContent
* Get-CCMClientDirectory
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
* Get-CCMUpdate
* Invoke-CCMBaseline
* Invoke-CCMClientAction
* Invoke-CCMResetPolicy
* Invoke-CCMTriggerSchedule
* Invoke-CCMUpdate
* Invoke-CIMPowerShell
* Remove-CCMCacheContent
* Repair-CCMCacheLocation
* Reset-CCMLoggingConfiguration
* Set-CCMCacheLocation
* Set-CCMCacheSize
* Set-CCMLoggingConfiguration
* Set-CCMProvisioningMode
* Write-CCMLogEntry