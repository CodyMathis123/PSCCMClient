using System;
using System.Security;
using PSCCMClient.Core.Services;

namespace PSCCMClient.Examples
{
    /// <summary>
    /// Example demonstrating credential support and remote COM execution
    /// </summary>
    public class CredentialExample
    {
        public static void Example()
        {
            // Example 1: Connect without credentials (local or current user context)
            var localSiteService = new CCMSiteService(".");
            
            // Example 2: Connect with credentials for remote machine
            var securePassword = new SecureString();
            foreach (char c in "password123")
            {
                securePassword.AppendChar(c);
            }
            securePassword.MakeReadOnly();
            
            var remoteSiteService = new CCMSiteService("remote-server.domain.com", "domain\\username", securePassword, "domain");
            
            // Example 3: COM methods now work both locally and remotely
            try
            {
                // This will use COM locally or PowerShell script execution remotely
                var site = remoteSiteService.GetSite();
                Console.WriteLine($"Site: {site?.SiteCode}");
                
                // This will use COM locally or PowerShell script execution remotely  
                var dnsSuffix = remoteSiteService.GetDNSSuffix();
                Console.WriteLine($"DNS Suffix: {dnsSuffix?.DNSSuffix}");
                
                // This will use COM locally or PowerShell script execution remotely
                bool isOnInternet = remoteSiteService.TestIsClientOnInternet();
                Console.WriteLine($"Is On Internet: {isOnInternet}");
                
                // Setting management point - uses COM locally or PowerShell remotely
                bool success = remoteSiteService.SetManagementPoint("newmp.domain.com");
                Console.WriteLine($"Set Management Point Success: {success}");
                
                // Setting site code - uses COM locally or PowerShell remotely
                bool siteSuccess = remoteSiteService.SetSite("XYZ");
                Console.WriteLine($"Set Site Success: {siteSuccess}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }
        }
    }
}