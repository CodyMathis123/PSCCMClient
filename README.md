PowerShell module focused around interaction with the Configuration Manager client. The general theme is to provide functions that 'work as expected' in that they accept pipeline where possible, such as with Get-CCMUpdate | Invoke-CCMUpdate. Largely this is leveraging WMI to gather info, and act upon it. This is why there are custom functions to make registry edits, and gather registry info via WMI. 

Current list of functions:
* Get-CCMClientDirectory
* Get-CCMClientLogDirectory
* Get-CCMLogFile
* Get-CCMUpdate
* Get-CCMMaintenanceWindow
* Get-CCMBaseline
* Get-CCMPrimaryUser
* Get-CCMCache
* Set-CCMCacheLocation
* Set-CCMCacheSize
* Repair-CCMCacheLocation
* Invoke-CCMBaseline
* Invoke-CCMClientAction
* Invoke-CCMUpdate
* Write-CCMLogEntry
