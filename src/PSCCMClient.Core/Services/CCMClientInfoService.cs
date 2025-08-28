using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for retrieving Configuration Manager client information
    /// </summary>
    public class CCMClientInfoService
    {
        private readonly string _computerName;

        public CCMClientInfoService(string computerName)
        {
            _computerName = computerName ?? ".";
        }

        /// <summary>
        /// Gets comprehensive client information
        /// </summary>
        /// <returns>Client information</returns>
        public async Task<CCMClientInfo> GetClientInfoAsync()
        {
            return await Task.Run(() => GetClientInfo());
        }

        /// <summary>
        /// Gets comprehensive client information (synchronous)
        /// </summary>
        /// <returns>Client information</returns>
        public CCMClientInfo GetClientInfo()
        {
            var clientInfo = new CCMClientInfo
            {
                ComputerName = _computerName
            };

            try
            {
                // Get site code
                clientInfo.SiteCode = GetSiteCode();

                // Get management point info
                clientInfo.CurrentManagementPoint = GetCurrentManagementPoint();
                clientInfo.CurrentSoftwareUpdatePoint = GetCurrentSoftwareUpdatePoint();

                // Get cache info
                var cacheInfo = GetCacheInfo();
                if (cacheInfo != null)
                {
                    clientInfo.CacheLocation = cacheInfo.Location;
                    clientInfo.CacheSize = cacheInfo.Size;
                }

                // Get client directory
                clientInfo.ClientDirectory = GetClientDirectory();

                // Get DNS suffix
                clientInfo.DNSSuffix = GetDNSSuffix();

                // Get GUID info
                var guidInfo = GetGuidInfo();
                if (guidInfo != null)
                {
                    clientInfo.GUID = guidInfo.GUID;
                    clientInfo.ClientGUIDChangeDate = guidInfo.ClientGUIDChangeDate;
                    clientInfo.PreviousGUID = guidInfo.PreviousGUID;
                }

                // Get client version
                clientInfo.ClientVersion = GetClientVersion();

                // Get inventory dates
                var heartbeat = GetLastHeartbeat();
                if (heartbeat != null)
                {
                    clientInfo.DDRLastCycleStartedDate = heartbeat.LastCycleStartedDate;
                    clientInfo.DDRLastReportDate = heartbeat.LastReportDate;
                }

                var hwInventory = GetLastHardwareInventory();
                if (hwInventory != null)
                {
                    clientInfo.HINVLastCycleStartedDate = hwInventory.LastCycleStartedDate;
                    clientInfo.HINVLastReportDate = hwInventory.LastReportDate;
                }

                var swInventory = GetLastSoftwareInventory();
                if (swInventory != null)
                {
                    clientInfo.SINVLastCycleStartedDate = swInventory.LastCycleStartedDate;
                    clientInfo.SINVLastReportDate = swInventory.LastReportDate;
                }

                // Get logging configuration
                var logConfig = GetLoggingConfiguration();
                if (logConfig != null)
                {
                    clientInfo.LogDirectory = logConfig.LogDirectory;
                    clientInfo.LogMaxSize = logConfig.LogMaxSize;
                    clientInfo.LogMaxHistory = logConfig.LogMaxHistory;
                    clientInfo.LogLevel = logConfig.LogLevel;
                    clientInfo.LogEnabled = logConfig.LogEnabled;
                }

                // Get internet configuration
                clientInfo.IsClientOnInternet = TestIsClientOnInternet();
                clientInfo.IsClientAlwaysOnInternet = TestIsClientAlwaysOnInternet();
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve client info from {_computerName}: {ex.Message}", ex);
            }

            return clientInfo;
        }

        /// <summary>
        /// Gets the client version
        /// </summary>
        /// <returns>Client version</returns>
        public async Task<string> GetClientVersionAsync()
        {
            return await Task.Run(() => GetClientVersion());
        }

        /// <summary>
        /// Gets the client version (synchronous)
        /// </summary>
        /// <returns>Client version</returns>
        public string GetClientVersion()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_InstalledComponent WHERE DisplayName = 'Configuration Manager Client'");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["Version"]?.ToString() ?? "";
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve client version from {_computerName}: {ex.Message}", ex);
            }

            return "";
        }

        /// <summary>
        /// Gets the client directory
        /// </summary>
        /// <returns>Client directory path</returns>
        public async Task<string> GetClientDirectoryAsync()
        {
            return await Task.Run(() => GetClientDirectory());
        }

        /// <summary>
        /// Gets the client directory (synchronous)
        /// </summary>
        /// <returns>Client directory path</returns>
        public string GetClientDirectory()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["ClientDirectory"]?.ToString() ?? "";
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve client directory from {_computerName}: {ex.Message}", ex);
            }

            return "";
        }

        private string GetSiteCode()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["ClientSite"]?.ToString() ?? "";
                }
            }
            catch { }
            return "";
        }

        private string GetCurrentManagementPoint()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Authority WHERE CurrentManagementPoint = TRUE");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["Name"]?.ToString() ?? "";
                }
            }
            catch { }
            return "";
        }

        private string GetCurrentSoftwareUpdatePoint()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\Policy\Machine\ActualConfig", "SELECT * FROM CCM_SoftwareUpdatesClientConfig");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["WSUSLocationServer"]?.ToString() ?? "";
                }
            }
            catch { }
            return "";
        }

        private CCMCacheInfo? GetCacheInfo()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\SoftMgmtAgent", "SELECT * FROM CacheConfig");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMCacheInfo
                    {
                        Location = obj["Location"]?.ToString() ?? "",
                        Size = Convert.ToInt32(obj["Size"] ?? 0)
                    };
                }
            }
            catch { }
            return null;
        }

        private string GetDNSSuffix()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["DNSSuffix"]?.ToString() ?? "";
                }
            }
            catch { }
            return "";
        }

        private CCMGuidInfo? GetGuidInfo()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMGuidInfo
                    {
                        GUID = obj["ClientId"]?.ToString() ?? "",
                        ClientGUIDChangeDate = obj["ClientIdChangeDate"] as DateTime?,
                        PreviousGUID = obj["PreviousClientId"]?.ToString() ?? ""
                    };
                }
            }
            catch { }
            return null;
        }

        private CCMInventoryInfo? GetLastHeartbeat()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\InvAgt", "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000003}'");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMInventoryInfo
                    {
                        LastCycleStartedDate = obj["LastCycleStartedDate"] as DateTime?,
                        LastReportDate = obj["LastReportDate"] as DateTime?
                    };
                }
            }
            catch { }
            return null;
        }

        private CCMInventoryInfo? GetLastHardwareInventory()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\InvAgt", "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000001}'");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMInventoryInfo
                    {
                        LastCycleStartedDate = obj["LastCycleStartedDate"] as DateTime?,
                        LastReportDate = obj["LastReportDate"] as DateTime?
                    };
                }
            }
            catch { }
            return null;
        }

        private CCMInventoryInfo? GetLastSoftwareInventory()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\InvAgt", "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000002}'");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMInventoryInfo
                    {
                        LastCycleStartedDate = obj["LastCycleStartedDate"] as DateTime?,
                        LastReportDate = obj["LastReportDate"] as DateTime?
                    };
                }
            }
            catch { }
            return null;
        }

        private CCMLoggingConfiguration? GetLoggingConfiguration()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Logging_GlobalConfiguration");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMLoggingConfiguration
                    {
                        LogDirectory = obj["LogDirectory"]?.ToString() ?? "",
                        LogMaxSize = Convert.ToInt32(obj["LogMaxSize"] ?? 0),
                        LogMaxHistory = Convert.ToInt32(obj["LogMaxHistory"] ?? 0),
                        LogLevel = Convert.ToInt32(obj["LogLevel"] ?? 0),
                        LogEnabled = Convert.ToBoolean(obj["LogEnabled"] ?? false)
                    };
                }
            }
            catch { }
            return null;
        }

        private bool TestIsClientOnInternet()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_ClientUtilities");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var method = obj.GetMethodParameters("DetermineIfClientIsOnInternet");
                    var result = obj.InvokeMethod("DetermineIfClientIsOnInternet", method, null);
                    return Convert.ToBoolean(result["ClientIsOnInternet"] ?? false);
                }
            }
            catch { }
            return false;
        }

        private bool TestIsClientAlwaysOnInternet()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return Convert.ToBoolean(obj["AlwaysInternet"] ?? false);
                }
            }
            catch { }
            return false;
        }
    }
}