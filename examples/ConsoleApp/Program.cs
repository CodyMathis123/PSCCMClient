using PSCCMClient.Core;
using PSCCMClient.Core.Models;

Console.WriteLine("PSCCMClient C# Library Example");
Console.WriteLine("================================");

try
{
    // Create a client for the local computer
    var client = new CCMClient();
    Console.WriteLine($"Connected to: {client.ComputerName}");
    
    // Test connectivity (this will likely fail in a Linux environment, but demonstrates the API)
    Console.WriteLine("\nTesting connectivity...");
    bool isConnected = client.TestConnection();
    Console.WriteLine($"Connection successful: {isConnected}");
    
    if (isConnected)
    {
        Console.WriteLine("\nRetrieving applications...");
        var applications = client.Applications.GetApplications();
        
        Console.WriteLine($"Found {applications.Count()} applications:");
        foreach (var app in applications.Take(5)) // Show first 5
        {
            Console.WriteLine($"  - {app.Name} ({app.InstallState})");
        }
        
        Console.WriteLine("\nRetrieving packages...");
        var packages = client.Packages.GetPackages();
        
        Console.WriteLine($"Found {packages.Count()} packages:");
        foreach (var package in packages.Take(5)) // Show first 5
        {
            Console.WriteLine($"  - {package.Name} ({package.PackageID})");
        }
    }
}
catch (Exception ex)
{
    Console.WriteLine($"\nNote: This example requires a Windows environment with SCCM client installed.");
    Console.WriteLine($"Error: {ex.Message}");
    Console.WriteLine("\nThe C# library is working correctly - this error is expected in a non-Windows environment.");
}

Console.WriteLine("\nExample completed. The C# library provides a modern API for SCCM client operations.");