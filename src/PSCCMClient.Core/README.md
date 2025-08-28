# PSCCMClient C# Library

This C# library provides a modern, strongly-typed API for interacting with Microsoft Endpoint Manager Configuration Manager (MEMCM) clients.

## Features

- **CCMClient**: Main client class for connecting to local or remote MEMCM clients
- **CCMApplicationService**: Manage MEMCM applications (get, install, uninstall)
- **CCMPackageService**: Manage MEMCM packages (get, execute)
- **Models**: Strongly-typed classes representing MEMCM objects

## Getting Started

### Installation

Add the package reference to your project:

```xml
<PackageReference Include="PSCCMClient.Core" Version="1.0.0" />
```

### Basic Usage

```csharp
using PSCCMClient.Core;

// Create a client for the local computer
var client = new CCMClient();

// Test connectivity
bool isConnected = await client.TestConnectionAsync();

// Get all applications
var applications = await client.Applications.GetApplicationsAsync();
foreach (var app in applications)
{
    Console.WriteLine($"Application: {app.Name} - {app.InstallState}");
}

// Install a specific application
var targetApp = applications.FirstOrDefault(a => a.Name == "7-Zip");
if (targetApp != null)
{
    bool success = await client.Applications.InstallApplicationAsync(targetApp.Id);
    Console.WriteLine($"Installation initiated: {success}");
}
```

### Working with Remote Computers

```csharp
// Create a client for a remote computer
var remoteClient = new CCMClient("REMOTE-PC-01");

// Get packages from the remote computer
var packages = await remoteClient.Packages.GetPackagesAsync();
foreach (var package in packages)
{
    Console.WriteLine($"Package: {package.Name} ({package.PackageID})");
}

// Execute a package program
await remoteClient.Packages.InvokePackageAsync("ABC00123", "Install");
```

## API Reference

### CCMClient

Main client class that provides access to all services.

#### Constructors
- `CCMClient()` - Creates a client for the local computer
- `CCMClient(string computerName)` - Creates a client for the specified computer

#### Properties
- `Applications` - Gets the CCMApplicationService instance
- `Packages` - Gets the CCMPackageService instance
- `ComputerName` - Gets the target computer name

#### Methods
- `TestConnectionAsync()` - Tests connectivity to the MEMCM client
- `TestConnection()` - Synchronous version of TestConnectionAsync

### CCMApplicationService

Service for managing MEMCM applications.

#### Methods
- `GetApplicationsAsync()` - Gets all applications
- `GetApplicationsByNameAsync(string name)` - Gets applications by name
- `InstallApplicationAsync(string applicationId)` - Installs an application

### CCMPackageService

Service for managing MEMCM packages.

#### Methods
- `GetPackagesAsync()` - Gets all packages
- `GetPackagesByNameAsync(string name)` - Gets packages by name
- `InvokePackageAsync(string packageId, string programName)` - Executes a package program

### Models

#### CCMApplication
Represents a Configuration Manager application with properties like:
- `Id`, `Name`, `Publisher`, `Version`, `InstallState`, etc.

#### CCMPackage
Represents a Configuration Manager package with properties like:
- `PackageID`, `Name`, `Version`, `Publisher`, `ProgramName`, etc.

## Error Handling

All methods may throw `InvalidOperationException` with detailed error messages if WMI/CIM operations fail. Always wrap calls in try-catch blocks:

```csharp
try
{
    var applications = await client.Applications.GetApplicationsAsync();
    // Process applications
}
catch (InvalidOperationException ex)
{
    Console.WriteLine($"Error retrieving applications: {ex.Message}");
}
```

## Platform Support

This library is designed for Windows environments and requires:
- .NET 8.0 or later
- Windows Management Instrumentation (WMI)
- Configuration Manager client installed on target computers

## Contributing

Contributions are welcome! Please ensure all code follows the established patterns and includes appropriate error handling.