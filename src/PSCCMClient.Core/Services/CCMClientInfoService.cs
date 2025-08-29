using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for retrieving Configuration Manager client information
    /// </summary>
    public class CCMClientInfoService : CCMServiceBase
    {
        public CCMClientInfoService(string computerName) : base(computerName)
        {
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
                ComputerName = ActualComputerName
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var result = QueryFirstWMIObject(namespacePath, "SELECT ClientVersion FROM SMS_Client");
                
                return result?["ClientVersion"]?.ToString() ?? "";
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve client version", ex);
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

                if (registryProperty?.Value != null && !string.IsNullOrWhiteSpace(registryProperty.Value))
                {
                    return registryProperty.Value.TrimEnd('\\');
                }
            }
            catch (Exception ex)
            {
                // For debugging: let's see what the actual error is
                System.Diagnostics.Debug.WriteLine($"Registry access error: {ex.Message}");
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
                var namespacePath = GetNamespacePath("root\\CCM\\CIModels");
                var result = QueryFirstWMIObject(namespacePath, "SELECT User FROM CCM_PrimaryUser");
                
                return result?["User"]?.ToString() ?? "";
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve primary user", ex);
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
                var namespacePath = GetNamespacePath("root\\cimv2");
                var serviceResult = QueryFirstWMIObject(namespacePath, "SELECT ProcessID FROM Win32_Service WHERE Name = 'CCMExec'");
                
                if (serviceResult?["ProcessID"] != null)
                {
                    var processId = serviceResult["ProcessID"].ToString();
                    if (!string.IsNullOrEmpty(processId))
                    {
                        // Now get the process creation date
                        var processResult = QueryFirstWMIObject(namespacePath, $"SELECT CreationDate FROM Win32_Process WHERE ProcessID = '{processId}'");
                        
                        if (processResult?["CreationDate"] != null)
                        {
                            return ConvertWmiDateTime(processResult["CreationDate"]);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve CCMExec startup time", ex);
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
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                if (obj != null)
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
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM"), "SELECT CurrentManagementPoint FROM SMS_Authority");
                if (obj != null)
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
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\ccm\\SoftwareUpdates\\WUAHandler"), "SELECT ContentLocation FROM CCM_UpdateSource");
                if (obj != null)
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
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM\\SoftMgmtAgent"), "SELECT * FROM CacheConfig");
                if (obj != null)
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
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                if (obj != null)
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
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM"), "SELECT ClientID, ClientIDChangeDate, PreviousClientID FROM CCM_Client");
                if (obj != null)
                {
                    return new CCMGuidInfo
                    {
                        GUID = obj["ClientID"]?.ToString() ?? "",
                        ClientGUIDChangeDate = ConvertWmiDateTime(obj["ClientIDChangeDate"]),
                        PreviousGUID = obj["PreviousClientID"]?.ToString() ?? ""
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
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\ccm\\policy\\machine\\actualconfig"), "SELECT * FROM CCM_Logging_GlobalConfiguration");
                if (obj != null)
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
                throw CreateException($"set client always on internet setting to '{alwaysOnInternet}'", ex);
            }
        }

        /// <summary>
        /// Gets the last heartbeat (DDR) information
        /// </summary>
        /// <returns>Last heartbeat information</returns>
        public async Task<CCMInventoryInfo?> GetLastHeartbeatAsync()
        {
            return await Task.Run(() => GetLastHeartbeat());
        }

        /// <summary>
        /// Gets the last heartbeat (DDR) information (synchronous)
        /// </summary>
        /// <returns>Last heartbeat information</returns>
        public CCMInventoryInfo? GetLastHeartbeat()
        {
            try
            {
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM\\InvAgt"), "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000003}'");
                if (obj != null)
                {
                    return new CCMInventoryInfo
                    {
                        LastCycleStartedDate = ConvertWmiDateTime(obj["LastCycleStartedDate"]),
                        LastReportDate = ConvertWmiDateTime(obj["LastReportDate"])
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve last heartbeat", ex);
            }
            return null;
        }

        /// <summary>
        /// Gets the last hardware inventory information
        /// </summary>
        /// <returns>Last hardware inventory information</returns>
        public async Task<CCMInventoryInfo?> GetLastHardwareInventoryAsync()
        {
            return await Task.Run(() => GetLastHardwareInventory());
        }

        /// <summary>
        /// Gets the last hardware inventory information (synchronous)
        /// </summary>
        /// <returns>Last hardware inventory information</returns>
        public CCMInventoryInfo? GetLastHardwareInventory()
        {
            try
            {
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM\\InvAgt"), "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000001}'");
                if (obj != null)
                {
                    return new CCMInventoryInfo
                    {
                        LastCycleStartedDate = ConvertWmiDateTime(obj["LastCycleStartedDate"]),
                        LastReportDate = ConvertWmiDateTime(obj["LastReportDate"])
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve last hardware inventory", ex);
            }
            return null;
        }

        /// <summary>
        /// Gets the last software inventory information
        /// </summary>
        /// <returns>Last software inventory information</returns>
        public async Task<CCMInventoryInfo?> GetLastSoftwareInventoryAsync()
        {
            return await Task.Run(() => GetLastSoftwareInventory());
        }

        /// <summary>
        /// Gets the last software inventory information (synchronous)
        /// </summary>
        /// <returns>Last software inventory information</returns>
        public CCMInventoryInfo? GetLastSoftwareInventory()
        {
            try
            {
                var obj = QueryFirstWMIObject(GetNamespacePath("root\\CCM\\InvAgt"), "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000002}'");
                if (obj != null)
                {
                    return new CCMInventoryInfo
                    {
                        LastCycleStartedDate = ConvertWmiDateTime(obj["LastCycleStartedDate"]),
                        LastReportDate = ConvertWmiDateTime(obj["LastReportDate"])
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve last software inventory", ex);
            }
            return null;
        }

        private bool TestIsClientOnInternet()
        {
            try
            {
                // For local operations, use COM object like PowerShell does
                if (IsLocalComputer)
                {
                    try
                    {
                        var result = InvokeCOMMethod(COMHelper.ProgIds.SMSClient, "IsClientOnInternet");
                        return Convert.ToBoolean(result ?? false);
                    }
                    catch
                    {
                        // Fall through to WMI if COM failed
                    }
                }

                // WMI fallback for remote or when COM fails
                var wmiObject = QueryFirstWMIObject(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_ClientUtilities");
                if (wmiObject != null)
                {
                    var methodParams = WMIHelper.GetInstanceMethodParameters(wmiObject, "DetermineIfClientIsOnInternet");
                    var result = InvokeWMIInstanceMethod(wmiObject, "DetermineIfClientIsOnInternet", methodParams);
                    return Convert.ToBoolean(result?["ClientIsOnInternet"] ?? false);
                }
            }
            catch { }
            return false;
        }

        private bool TestIsClientAlwaysOnInternet()
        {
            try
            {
                // For local operations, use COM object like PowerShell does
                if (IsLocalComputer)
                {
                    try
                    {
                        var result = InvokeCOMMethod(COMHelper.ProgIds.SMSClient, "IsClientAlwaysOnInternet");
                        return Convert.ToBoolean(result ?? false);
                    }
                    catch
                    {
                        // Fall through to WMI if COM failed
                    }
                }

                // WMI fallback for remote operations
                var wmiObject = QueryFirstWMIObject(GetNamespacePath("root\\CCM"), "SELECT AlwaysInternet FROM CCM_Client");
                if (wmiObject != null)
                {
                    return Convert.ToBoolean(wmiObject["AlwaysInternet"] ?? false);
                }
            }
            catch { }
            return false;
        }
    }
}