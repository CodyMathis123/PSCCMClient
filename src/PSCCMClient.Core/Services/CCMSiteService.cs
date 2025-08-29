using System;
using System.Threading.Tasks;
using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;
using PSCCMClient.Core.Interfaces;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager site and connectivity settings
    /// </summary>
    public class CCMSiteService : CCMServiceBase, ICCMSiteService
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
                {
                    return new CCMSite
                    {
                        ComputerName = ActualComputerName,
                        SiteCode = obj["ClientSite"]?.ToString() ?? ""
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve site", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
                {
                    var inParams = WMIHelper.GetInstanceMethodParameters(obj, "SetClientSite");
                    inParams["sSiteCode"] = siteCode;
                    
                    var outParams = InvokeWMIInstanceMethod(obj, "SetClientSite", inParams);
                    return WMIHelper.IsMethodCallSuccessful(outParams);
                }
            }
            catch (Exception ex)
            {
                throw CreateException($"set site code '{siteCode}'", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Authority WHERE CurrentManagementPoint = TRUE");
                
                if (obj != null)
                {
                    return new CCMManagementPoint
                    {
                        ComputerName = ActualComputerName,
                        CurrentManagementPoint = obj["Name"]?.ToString() ?? "",
                        Version = obj["Version"]?.ToString() ?? "",
                        Type = Convert.ToInt32(obj["Type"] ?? 0)
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve current management point", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
                {
                    var inParams = WMIHelper.GetInstanceMethodParameters(obj, "SetCurrentManagementPoint");
                    inParams["sMP"] = managementPoint;
                    
                    var outParams = InvokeWMIInstanceMethod(obj, "SetCurrentManagementPoint", inParams);
                    return WMIHelper.IsMethodCallSuccessful(outParams);
                }
            }
            catch (Exception ex)
            {
                throw CreateException($"set management point '{managementPoint}'", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM\\Policy\\Machine\\ActualConfig");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_SoftwareUpdatesClientConfig");
                
                if (obj != null)
                {
                    return new CCMSoftwareUpdatePoint
                    {
                        ComputerName = ActualComputerName,
                        CurrentSoftwareUpdatePoint = obj["WSUSLocationServer"]?.ToString() ?? "",
                        Port = Convert.ToInt32(obj["WSUSLocationServerPort"] ?? 0),
                        UseSSL = Convert.ToBoolean(obj["UseSSL"] ?? false)
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve current software update point", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
                {
                    return new CCMDNSSuffix
                    {
                        ComputerName = ActualComputerName,
                        DNSSuffix = obj["DNSSuffix"]?.ToString() ?? ""
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve DNS suffix", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
                {
                    obj["DNSSuffix"] = dnsSuffix;
                    obj.Put();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw CreateException($"set DNS suffix '{dnsSuffix}'", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_ClientUtilities");
                
                if (obj != null)
                {
                    var inParams = WMIHelper.GetInstanceMethodParameters(obj, "DetermineIfClientIsOnInternet");
                    var outParams = InvokeWMIInstanceMethod(obj, "DetermineIfClientIsOnInternet", inParams);
                    return Convert.ToBoolean(outParams?["ClientIsOnInternet"] ?? false);
                }
            }
            catch (Exception ex)
            {
                throw CreateException("test if client is on internet", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
                {
                    return Convert.ToBoolean(obj["AlwaysInternet"] ?? false);
                }
            }
            catch (Exception ex)
            {
                throw CreateException("test if client is always on internet", ex);
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