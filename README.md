PowerShell module focused around interaction with the Configuration Manager client. The general theme is to provide functions that 'work as expected' in that they accept pipeline where possible, such as with Get-CCMUpdate | Invoke-CCMUpdate. Largely this is leveraging WMI to gather info, and act upon it. This is why there are custom functions to make registry edits, and gather registry info via WMI.

Current list of functions:

* ConvertFrom-CCMSchedule
* Get-CCMBaseline
* Get-CCMCache
* Get-CCMClientDirectory
* Get-CCMLoggingConfiguration
* Get-CCMLastHardwareInventory
* Get-CCMLastHeartbeat
* Get-CCMLastSoftwareInventory
* Get-CCMLastScheduleTrigger
* Get-CCMLogFile
* Get-CCMMaintenanceWindow
* Get-CCMPrimaryUser
* Get-CCMProvisioningMode
* Get-CCMServiceWindow
* Get-CCMUpdate
* Invoke-CCMBaseline
* Invoke-CCMClientAction
* Invoke-CCMResetPolicy
* Invoke-CCMUpdate
* Invoke-CIMPowerShell
* Repair-CCMCacheLocation
* Set-CCMCacheLocation
* Set-CCMCacheSize
* Set-CCMProvisioningMode
* Write-CCMLogEntry