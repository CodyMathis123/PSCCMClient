using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager site and connectivity settings
    /// </summary>
    public class CCMSiteService : CCMServiceBase
    {
        public CCMSiteService(string computerName) : base(computerName)
        {
        }

        /// <summary>
        /// Gets the current site code
        /// </summary>
        /// <returns>Site information</returns>
        public async Task<CCMSite?> GetSiteAsync()
        {
            return await Task.Run(() => GetSite());
        }

        /// <summary>
        /// Gets the current site code (synchronous)
        /// </summary>
        /// <returns>Site information</returns>
        public CCMSite? GetSite()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMSite
                    {
                        ComputerName = _computerName,
                        SiteCode = obj["ClientSite"]?.ToString() ?? ""
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve site from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Sets the site code
        /// </summary>
        /// <param name="siteCode">New site code</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetSiteAsync(string siteCode)
        {
            return await Task.Run(() => SetSite(siteCode));
        }

        /// <summary>
        /// Sets the site code (synchronous)
        /// </summary>
        /// <param name="siteCode">New site code</param>
        /// <returns>True if successful</returns>
        public bool SetSite(string siteCode)
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("SetClientSite");
                    inParams["sSiteCode"] = siteCode;
                    
                    var outParams = obj.InvokeMethod("SetClientSite", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to set site code '{siteCode}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        /// <summary>
        /// Gets the current management point
        /// </summary>
        /// <returns>Management point information</returns>
        public async Task<CCMManagementPoint?> GetCurrentManagementPointAsync()
        {
            return await Task.Run(() => GetCurrentManagementPoint());
        }

        /// <summary>
        /// Gets the current management point (synchronous)
        /// </summary>
        /// <returns>Management point information</returns>
        public CCMManagementPoint? GetCurrentManagementPoint()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Authority WHERE CurrentManagementPoint = TRUE");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMManagementPoint
                    {
                        ComputerName = _computerName,
                        CurrentManagementPoint = obj["Name"]?.ToString() ?? "",
                        Version = obj["Version"]?.ToString() ?? "",
                        Type = Convert.ToInt32(obj["Type"] ?? 0)
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve current management point from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Sets the management point
        /// </summary>
        /// <param name="managementPoint">Management point server name</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetManagementPointAsync(string managementPoint)
        {
            return await Task.Run(() => SetManagementPoint(managementPoint));
        }

        /// <summary>
        /// Sets the management point (synchronous)
        /// </summary>
        /// <param name="managementPoint">Management point server name</param>
        /// <returns>True if successful</returns>
        public bool SetManagementPoint(string managementPoint)
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("SetCurrentManagementPoint");
                    inParams["sMP"] = managementPoint;
                    
                    var outParams = obj.InvokeMethod("SetCurrentManagementPoint", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to set management point '{managementPoint}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        /// <summary>
        /// Gets the current software update point
        /// </summary>
        /// <returns>Software update point information</returns>
        public async Task<CCMSoftwareUpdatePoint?> GetCurrentSoftwareUpdatePointAsync()
        {
            return await Task.Run(() => GetCurrentSoftwareUpdatePoint());
        }

        /// <summary>
        /// Gets the current software update point (synchronous)
        /// </summary>
        /// <returns>Software update point information</returns>
        public CCMSoftwareUpdatePoint? GetCurrentSoftwareUpdatePoint()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM\\Policy\\Machine\\ActualConfig"), "SELECT * FROM CCM_SoftwareUpdatesClientConfig");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMSoftwareUpdatePoint
                    {
                        ComputerName = _computerName,
                        CurrentSoftwareUpdatePoint = obj["WSUSLocationServer"]?.ToString() ?? "",
                        Port = Convert.ToInt32(obj["WSUSLocationServerPort"] ?? 0),
                        UseSSL = Convert.ToBoolean(obj["UseSSL"] ?? false)
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve current software update point from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Gets DNS suffix
        /// </summary>
        /// <returns>DNS suffix information</returns>
        public async Task<CCMDNSSuffix?> GetDNSSuffixAsync()
        {
            return await Task.Run(() => GetDNSSuffix());
        }

        /// <summary>
        /// Gets DNS suffix (synchronous)
        /// </summary>
        /// <returns>DNS suffix information</returns>
        public CCMDNSSuffix? GetDNSSuffix()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMDNSSuffix
                    {
                        ComputerName = _computerName,
                        DNSSuffix = obj["DNSSuffix"]?.ToString() ?? ""
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve DNS suffix from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Sets DNS suffix
        /// </summary>
        /// <param name="dnsSuffix">New DNS suffix</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetDNSSuffixAsync(string dnsSuffix)
        {
            return await Task.Run(() => SetDNSSuffix(dnsSuffix));
        }

        /// <summary>
        /// Sets DNS suffix (synchronous)
        /// </summary>
        /// <param name="dnsSuffix">New DNS suffix</param>
        /// <returns>True if successful</returns>
        public bool SetDNSSuffix(string dnsSuffix)
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    obj["DNSSuffix"] = dnsSuffix;
                    obj.Put();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to set DNS suffix '{dnsSuffix}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        /// <summary>
        /// Tests if client is on internet
        /// </summary>
        /// <returns>True if client is on internet</returns>
        public async Task<bool> TestIsClientOnInternetAsync()
        {
            return await Task.Run(() => TestIsClientOnInternet());
        }

        /// <summary>
        /// Tests if client is on internet (synchronous)
        /// </summary>
        /// <returns>True if client is on internet</returns>
        public bool TestIsClientOnInternet()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_ClientUtilities");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("DetermineIfClientIsOnInternet");
                    var outParams = obj.InvokeMethod("DetermineIfClientIsOnInternet", inParams, null);
                    return Convert.ToBoolean(outParams["ClientIsOnInternet"] ?? false);
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to test if client is on internet on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        /// <summary>
        /// Tests if client is always on internet
        /// </summary>
        /// <returns>True if client is always on internet</returns>
        public async Task<bool> TestIsClientAlwaysOnInternetAsync()
        {
            return await Task.Run(() => TestIsClientAlwaysOnInternet());
        }

        /// <summary>
        /// Tests if client is always on internet (synchronous)
        /// </summary>
        /// <returns>True if client is always on internet</returns>
        public bool TestIsClientAlwaysOnInternet()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return Convert.ToBoolean(obj["AlwaysInternet"] ?? false);
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to test if client is always on internet on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        /// <summary>
        /// Sets client always on internet
        /// </summary>
        /// <param name="alwaysOnInternet">Whether client should always be on internet</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetClientAlwaysOnInternetAsync(bool alwaysOnInternet)
        {
            return await Task.Run(() => SetClientAlwaysOnInternet(alwaysOnInternet));
        }

        /// <summary>
        /// Sets client always on internet (synchronous)
        /// </summary>
        /// <param name="alwaysOnInternet">Whether client should always be on internet</param>
        /// <returns>True if successful</returns>
        public bool SetClientAlwaysOnInternet(bool alwaysOnInternet)
        {
            try
            {
                // PowerShell module uses registry approach to set this value
                // Set DWORD value "ClientAlwaysOnInternet" in "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM\Security"
                uint enablement = alwaysOnInternet ? 1u : 0u;
                
                return RegistryHelper.SetDWORDValue(
                    _computerName,
                    "HKEY_LOCAL_MACHINE",
                    "SOFTWARE\\Microsoft\\CCM\\Security",
                    "ClientAlwaysOnInternet",
                    enablement
                );
            }
            catch (Exception ex)
            {
                throw CreateException($"set client always on internet to '{alwaysOnInternet}'", ex);
            }
        }
    }
}