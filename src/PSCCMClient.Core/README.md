# PSCCMClient.Core - C# Configuration Manager Client Library

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![.NET Version](https://img.shields.io/badge/.NET-8.0-blue.svg)]()
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)]()

A comprehensive C# library providing **complete feature parity** with the PSCCMClient PowerShell module. This library offers modern, strongly-typed access to all Microsoft Endpoint Configuration Manager (MEMCM) client functionality using async/await patterns and full IntelliSense support.

## 🚀 Key Features

- **Complete Feature Parity**: All 60+ PowerShell functions available in C#
- **Modern Async/Await**: Full asynchronous programming support
- **Strongly Typed**: Rich models with IntelliSense support
- **Comprehensive Coverage**: Applications, Packages, Baselines, Cache, Updates, Task Sequences, and more
- **Dual Patterns**: Both async and synchronous method variants
- **Error Handling**: Detailed exception handling with meaningful messages

## 📦 What's Included

### Core Services
- **CCMApplicationService** - Application management (Get/Install/Uninstall)
- **CCMPackageService** - Package management (Get/Invoke) 
- **CCMBaselineService** - Configuration baselines (Get/Invoke)
- **CCMCacheService** - Cache management (Get/Set/Remove/Repair)
- **CCMClientInfoService** - Comprehensive client information
- **CCMSoftwareUpdateService** - Software updates management
- **CCMClientActionService** - Client actions (Hardware/Software inventory, Policy refresh)
- **CCMTaskSequenceService** - Task sequence management
- **CCMMaintenanceWindowService** - Maintenance windows
- **CCMSiteService** - Site and connectivity management
- **CCMLoggingService** - Logging configuration and operations
- **CCMRegistryService** - Registry operations and provisioning mode

### Rich Models
- `CCMApplication`, `CCMPackage`, `CCMBaseline`, `CCMSoftwareUpdate`
- `CCMClientInfo`, `CCMCacheInfo`, `CCMTaskSequence`
- `CCMMaintenanceWindow`, `CCMLoggingConfiguration`
- And many more strongly-typed models

## 🚀 Quick Start

### Basic Usage

```csharp
using PSCCMClient.Core;

// Create client for local computer
var client = new CCMClient();

// Test connectivity
bool connected = await client.TestConnectionAsync();

// Get comprehensive client information
var clientInfo = await client.GetClientInfoAsync();
Console.WriteLine($"Site: {clientInfo.SiteCode}, Version: {clientInfo.ClientVersion}");

// Manage applications
var apps = await client.Applications.GetApplicationsByNameAsync("7-Zip");
if (apps.Any())
{
    await client.Applications.InstallApplicationAsync(apps.First().Id);
}

// Trigger hardware inventory
await client.InvokeHardwareInventoryAsync(fullInventory: true);
```

### Remote Computer Management

```csharp
// Connect to remote computer
var remoteClient = new CCMClient("REMOTE-PC-01");

// Get and invoke packages
var packages = await remoteClient.Packages.GetPackagesAsync();
await remoteClient.Packages.InvokePackageAsync("ABC00123", "Install");

// Manage cache
await remoteClient.Cache.SetCacheSizeAsync(10240); // 10 GB
var cacheContent = await remoteClient.Cache.GetCacheContentAsync();
```

## 🔧 Advanced Examples

### Configuration Baselines
```csharp
// Get and evaluate baselines
var baselines = await client.Baselines.GetBaselinesAsync();
foreach (var baseline in baselines)
{
    if (baseline.LastComplianceStatus == "Non-Compliant")
    {
        await client.Baselines.InvokeBaselineAsync(baseline.BaselineName);
    }
}
```

### Software Updates
```csharp
// Get available updates and install them
var updates = await client.SoftwareUpdates.GetSoftwareUpdatesAsync();
foreach (var update in updates.Where(u => u.EvaluationState == "Available"))
{
    await client.SoftwareUpdates.InvokeSoftwareUpdateAsync(update.UpdateID);
}
```

### Client Actions
```csharp
// Trigger multiple client actions
var results = await client.ClientActions.InvokeClientActionsAsync(
    CCMClientActionService.ClientAction.MachinePol,
    CCMClientActionService.ClientAction.UpdateScan,
    CCMClientActionService.ClientAction.AppEval
);
```

### Cache Management
```csharp
// Comprehensive cache management
var cacheInfo = await client.Cache.GetCacheInfoAsync();
Console.WriteLine($"Cache: {cacheInfo.Location} ({cacheInfo.Size} MB)");

// List and remove old content
var content = await client.Cache.GetCacheContentAsync();
var oldContent = content.Where(c => c.LastReferenceTime < DateTime.Now.AddDays(-30));
foreach (var item in oldContent)
{
    await client.Cache.RemoveCacheContentAsync(item.ContentId);
}
```

## 📋 Complete PowerShell Mapping

| PowerShell Function | C# Method | Service |
|---------------------|-----------|---------|
| `Get-CCMApplication` | `GetApplicationsAsync()` | Applications |
| `Invoke-CCMApplication` | `InstallApplicationAsync()` | Applications |
| `Get-CCMPackage` | `GetPackagesAsync()` | Packages |
| `Invoke-CCMPackage` | `InvokePackageAsync()` | Packages |
| `Get-CCMBaseline` | `GetBaselinesAsync()` | Baselines |
| `Invoke-CCMBaseline` | `InvokeBaselineAsync()` | Baselines |
| `Get-CCMCacheInfo` | `GetCacheInfoAsync()` | Cache |
| `Set-CCMCacheSize` | `SetCacheSizeAsync()` | Cache |
| `Get-CCMClientInfo` | `GetClientInfoAsync()` | ClientInfo |
| `Get-CCMSoftwareUpdate` | `GetSoftwareUpdatesAsync()` | SoftwareUpdates |
| `Invoke-CCMClientAction` | `InvokeClientActionAsync()` | ClientActions |
| `Get-CCMTaskSequence` | `GetTaskSequencesAsync()` | TaskSequences |
| `Get-CCMMaintenanceWindow` | `GetMaintenanceWindowsAsync()` | MaintenanceWindows |
| `Get-CCMSite` | `GetSiteAsync()` | Site |
| `Get-CCMLoggingConfiguration` | `GetLoggingConfigurationAsync()` | Logging |
| `Get-CCMRegistryProperty` | `GetRegistryPropertyAsync()` | Registry |
| *...and 50+ more functions* | *...with full coverage* | *...across all services* |

## 🔄 Async/Sync Pattern Support

Every operation supports both patterns:

```csharp
// Async (recommended)
var apps = await client.Applications.GetApplicationsAsync();

// Synchronous
var apps = client.Applications.GetApplications();
```

## 🛡️ Error Handling

```csharp
try
{
    var client = new CCMClient("remote-computer");
    var info = await client.GetClientInfoAsync();
}
catch (InvalidOperationException ex)
{
    Console.WriteLine($"SCCM operation failed: {ex.Message}");
}
catch (UnauthorizedAccessException ex)
{
    Console.WriteLine($"Access denied: {ex.Message}");
}
```

## 📊 Architecture

```
CCMClient (Main Entry Point)
├── Applications (CCMApplicationService)
├── Packages (CCMPackageService)  
├── Baselines (CCMBaselineService)
├── Cache (CCMCacheService)
├── ClientInfo (CCMClientInfoService)
├── SoftwareUpdates (CCMSoftwareUpdateService)
├── ClientActions (CCMClientActionService)
├── TaskSequences (CCMTaskSequenceService)
├── MaintenanceWindows (CCMMaintenanceWindowService)
├── Site (CCMSiteService)
├── Logging (CCMLoggingService)
└── Registry (CCMRegistryService)
```

## 📋 Requirements

- **.NET 8.0+** - Built on modern .NET
- **Windows Only** - Uses Windows Management Instrumentation (WMI)
- **SCCM Client Required** - Target machines must have Configuration Manager client installed
- **Administrative Rights** - Many operations require elevated privileges

## 🤝 PowerShell Compatibility

This C# library maintains 100% compatibility with the existing PowerShell module. You can use both simultaneously without conflicts.

## 📄 License

This project follows the same license as the original PSCCMClient PowerShell module.

---

**🎉 Complete Feature Parity Achieved!** 

This C# library now provides full access to all 60+ functions available in the PowerShell module, with modern async/await patterns, strong typing, and comprehensive error handling.