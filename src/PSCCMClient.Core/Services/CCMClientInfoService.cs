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
                // Use query like PowerShell: 'SELECT ClientVersion FROM SMS_Client'
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT ClientVersion FROM SMS_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["ClientVersion"]?.ToString() ?? "";
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
                var registryService = new CCMRegistryService(_computerName);
                var registryProperty = registryService.GetRegistryProperty(
                    "HKEY_LOCAL_MACHINE",
                    "SOFTWARE\\Microsoft\\SMS\\Client\\Configuration\\Client Properties",
                    "Local SMS Path");

                if (registryProperty?.Value != null)
                {
                    return registryProperty.Value.TrimEnd('\\');
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve client directory from {_computerName}: {ex.Message}", ex);
            }

            return "";
        }

        /// <summary>
        /// Gets the primary user for the client
        /// </summary>
        /// <returns>Primary user information</returns>
        public async Task<string> GetPrimaryUserAsync()
        {
            return await Task.Run(() => GetPrimaryUser());
        }

        /// <summary>
        /// Gets the primary user for the client (synchronous)
        /// </summary>
        /// <returns>Primary user information</returns>
        public string GetPrimaryUser()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\CIModels", "SELECT User FROM CCM_PrimaryUser");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["User"]?.ToString() ?? "";
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve primary user from {_computerName}: {ex.Message}", ex);
            }

            return "";
        }

        /// <summary>
        /// Gets the CCMExec service startup time
        /// </summary>
        /// <returns>CCMExec startup time information</returns>
        public async Task<DateTime?> GetExecStartupTimeAsync()
        {
            return await Task.Run(() => GetExecStartupTime());
        }

        /// <summary>
        /// Gets the CCMExec service startup time (synchronous)
        /// </summary>
        /// <returns>CCMExec startup time information</returns>
        public DateTime? GetExecStartupTime()
        {
            try
            {
                // First get the CCMExec service process ID
                using var serviceSearcher = new ManagementObjectSearcher($@"\\{_computerName}\root\cimv2", "SELECT ProcessID FROM Win32_Service WHERE Name = 'CCMExec'");
                using var serviceResults = serviceSearcher.Get();

                foreach (ManagementObject serviceObj in serviceResults)
                {
                    var processId = serviceObj["ProcessID"]?.ToString();
                    if (!string.IsNullOrEmpty(processId))
                    {
                        // Now get the process creation date
                        using var processSearcher = new ManagementObjectSearcher($@"\\{_computerName}\root\cimv2", $"SELECT CreationDate FROM Win32_Process WHERE ProcessID = '{processId}'");
                        using var processResults = processSearcher.Get();

                        foreach (ManagementObject processObj in processResults)
                        {
                            var creationDate = processObj["CreationDate"]?.ToString();
                            if (!string.IsNullOrEmpty(creationDate))
                            {
                                return ManagementDateTimeConverter.ToDateTime(creationDate);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve CCMExec startup time from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        private string GetSiteCode()
        {
            try
            {
                // First try COM object approach (like PowerShell for local calls)
                if (_computerName == "." || _computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        var comType = Type.GetTypeFromProgID("Microsoft.SMS.Client");
                        if (comType != null)
                        {
                            var smsClient = Activator.CreateInstance(comType);
                            var result = smsClient?.GetType().InvokeMember("GetAssignedSite", 
                                System.Reflection.BindingFlags.InvokeMethod, null, smsClient, null);
                            return result?.ToString() ?? "";
                        }
                    }
                    catch
                    {
                        // Fall back to WMI
                    }
                }

                // Fallback to WMI approach
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
                // Use query like PowerShell: 'SELECT CurrentManagementPoint FROM SMS_Authority'
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT CurrentManagementPoint FROM SMS_Authority");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["CurrentManagementPoint"]?.ToString() ?? "";
                }
            }
            catch { }
            return "";
        }

        private string GetCurrentSoftwareUpdatePoint()
        {
            try
            {
                // Use query like PowerShell: 'SELECT ContentLocation FROM CCM_UpdateSource'
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\ccm\SoftwareUpdates\WUAHandler", "SELECT ContentLocation FROM CCM_UpdateSource");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj["ContentLocation"]?.ToString() ?? "";
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
                // First try COM object approach (like PowerShell for local calls)
                if (_computerName == "." || _computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        var comType = Type.GetTypeFromProgID("Microsoft.SMS.Client");
                        if (comType != null)
                        {
                            var smsClient = Activator.CreateInstance(comType);
                            var result = smsClient?.GetType().InvokeMember("GetDNSSuffix", 
                                System.Reflection.BindingFlags.InvokeMethod, null, smsClient, null);
                            return result?.ToString() ?? "";
                        }
                    }
                    catch
                    {
                        // Fall back to WMI
                    }
                }

                // Fallback to WMI approach
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
                // Use query like PowerShell: 'SELECT ClientID, ClientIDChangeDate, PreviousClientID FROM CCM_Client'
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT ClientID, ClientIDChangeDate, PreviousClientID FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMGuidInfo
                    {
                        GUID = obj["ClientID"]?.ToString() ?? "",
                        ClientGUIDChangeDate = obj["ClientIDChangeDate"] as DateTime?,
                        PreviousGUID = obj["PreviousClientID"]?.ToString() ?? ""
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
                // Use correct namespace like PowerShell: 'root\ccm\policy\machine\actualconfig'
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\ccm\policy\machine\actualconfig", "SELECT * FROM CCM_Logging_GlobalConfiguration");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var config = new CCMLoggingConfiguration
                    {
                        LogMaxSize = Convert.ToInt32(obj["LogMaxSize"] ?? 0),
                        LogMaxHistory = Convert.ToInt32(obj["LogMaxHistory"] ?? 0),
                        LogLevel = Convert.ToInt32(obj["LogLevel"] ?? 0),
                        LogEnabled = Convert.ToBoolean(obj["LogEnabled"] ?? false)
                    };

                    // Get log directory from registry like PowerShell does
                    try
                    {
                        var registryService = new CCMRegistryService(_computerName);
                        var logDirProperty = registryService.GetRegistryProperty(
                            "HKEY_LOCAL_MACHINE",
                            "SOFTWARE\\Microsoft\\CCM\\Logging\\@Global",
                            "LogDirectory");
                        config.LogDirectory = logDirProperty?.Value ?? "";
                    }
                    catch
                    {
                        config.LogDirectory = "";
                    }

                    return config;
                }
            }
            catch { }
            return null;
        }

        /// <summary>
        /// Tests if the client is currently on the internet
        /// </summary>
        /// <returns>True if client is on internet</returns>
        public async Task<bool> IsClientOnInternetAsync()
        {
            return await Task.Run(() => IsClientOnInternet());
        }

        /// <summary>
        /// Tests if the client is currently on the internet (synchronous)
        /// </summary>
        /// <returns>True if client is on internet</returns>
        public bool IsClientOnInternet()
        {
            return TestIsClientOnInternet();
        }

        /// <summary>
        /// Tests if the client is always on the internet
        /// </summary>
        /// <returns>True if client is always on internet</returns>
        public async Task<bool> IsClientAlwaysOnInternetAsync()
        {
            return await Task.Run(() => IsClientAlwaysOnInternet());
        }

        /// <summary>
        /// Tests if the client is always on the internet (synchronous)
        /// </summary>
        /// <returns>True if client is always on internet</returns>
        public bool IsClientAlwaysOnInternet()
        {
            return TestIsClientAlwaysOnInternet();
        }

        /// <summary>
        /// Sets the client always on internet setting
        /// </summary>
        /// <param name="alwaysOnInternet">True to set always on internet</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetClientAlwaysOnInternetAsync(bool alwaysOnInternet)
        {
            return await Task.Run(() => SetClientAlwaysOnInternet(alwaysOnInternet));
        }

        /// <summary>
        /// Sets the client always on internet setting (synchronous)
        /// </summary>
        /// <param name="alwaysOnInternet">True to set always on internet</param>
        /// <returns>True if successful</returns>
        public bool SetClientAlwaysOnInternet(bool alwaysOnInternet)
        {
            try
            {
                // First try COM object approach (like PowerShell for local calls)
                if (_computerName == "." || _computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        var comType = Type.GetTypeFromProgID("Microsoft.SMS.Client");
                        if (comType != null)
                        {
                            var smsClient = Activator.CreateInstance(comType);
                            smsClient?.GetType().InvokeMember("SetClientAlwaysOnInternet", 
                                System.Reflection.BindingFlags.InvokeMethod, null, smsClient, new object[] { alwaysOnInternet });
                            return true;
                        }
                    }
                    catch
                    {
                        // Fall back to WMI
                    }
                }

                // Fallback to WMI approach
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM", "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("SetClientAlwaysOnInternet");
                    inParams["bAlwaysOnInternet"] = alwaysOnInternet;
                    
                    var outParams = obj.InvokeMethod("SetClientAlwaysOnInternet", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to set client always on internet setting to '{alwaysOnInternet}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        private bool TestIsClientOnInternet()
        {
            try
            {
                // First try COM object approach (like PowerShell for local calls)
                if (_computerName == "." || _computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        var comType = Type.GetTypeFromProgID("Microsoft.SMS.Client");
                        if (comType != null)
                        {
                            var smsClient = Activator.CreateInstance(comType);
                            var result = smsClient?.GetType().InvokeMember("IsClientOnInternet", 
                                System.Reflection.BindingFlags.InvokeMethod, null, smsClient, null);
                            return Convert.ToBoolean(result ?? false);
                        }
                    }
                    catch
                    {
                        // Fall back to WMI
                    }
                }

                // Fallback to WMI approach
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
                // First try COM object approach (like PowerShell for local calls)
                if (_computerName == "." || _computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        var comType = Type.GetTypeFromProgID("Microsoft.SMS.Client");
                        if (comType != null)
                        {
                            var smsClient = Activator.CreateInstance(comType);
                            var result = smsClient?.GetType().InvokeMember("IsClientAlwaysOnInternet", 
                                System.Reflection.BindingFlags.InvokeMethod, null, smsClient, null);
                            return Convert.ToBoolean(result ?? false);
                        }
                    }
                    catch
                    {
                        // Fall back to WMI
                    }
                }

                // Fallback to WMI approach
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