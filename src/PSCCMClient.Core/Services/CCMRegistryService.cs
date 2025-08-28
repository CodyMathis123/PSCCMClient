using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager registry operations and provisioning mode
    /// </summary>
    public class CCMRegistryService : CCMServiceBase
    {
        public CCMRegistryService(string computerName) : base(computerName)
        {
        }

        /// <summary>
        /// Gets a registry property value
        /// </summary>
        /// <param name="hive">Registry hive (e.g., "HKEY_LOCAL_MACHINE")</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry property value</returns>
        public async Task<CCMRegistryProperty?> GetRegistryPropertyAsync(string hive, string subKey, string valueName)
        {
            return await Task.Run(() => GetRegistryProperty(hive, subKey, valueName));
        }

        /// <summary>
        /// Gets a registry property value (synchronous)
        /// </summary>
        /// <param name="hive">Registry hive (e.g., "HKEY_LOCAL_MACHINE")</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry property value</returns>
        public CCMRegistryProperty? GetRegistryProperty(string hive, string subKey, string valueName)
        {
            try
            {
                var value = RegistryHelper.GetStringValue(_computerName, hive, subKey, valueName);
                if (value != null)
                {
                    return new CCMRegistryProperty
                    {
                        ComputerName = _computerName,
                        Hive = hive,
                        SubKey = subKey,
                        ValueName = valueName,
                        Value = value,
                        ValueType = "String"
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("get registry property", ex);
            }

            return null;
        }

        /// <summary>
        /// Sets a registry property value
        /// </summary>
        /// <param name="hive">Registry hive (e.g., "HKEY_LOCAL_MACHINE")</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <param name="value">Value to set</param>
        /// <param name="valueType">Value type (String, DWORD, etc.)</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetRegistryPropertyAsync(string hive, string subKey, string valueName, object value, string valueType = "String")
        {
            return await Task.Run(() => SetRegistryProperty(hive, subKey, valueName, value, valueType));
        }

        /// <summary>
        /// Sets a registry property value (synchronous)
        /// </summary>
        /// <param name="hive">Registry hive (e.g., "HKEY_LOCAL_MACHINE")</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <param name="value">Value to set</param>
        /// <param name="valueType">Value type (String, DWORD, etc.)</param>
        /// <returns>True if successful</returns>
        public bool SetRegistryProperty(string hive, string subKey, string valueName, object value, string valueType = "String")
        {
            try
            {
                return valueType.ToUpper() switch
                {
                    "STRING" => RegistryHelper.SetStringValue(_computerName, hive, subKey, valueName, value.ToString() ?? ""),
                    "DWORD" => RegistryHelper.SetDWORDValue(_computerName, hive, subKey, valueName, Convert.ToUInt32(value)),
                    _ => RegistryHelper.SetStringValue(_computerName, hive, subKey, valueName, value.ToString() ?? "")
                };
            }
            catch (Exception ex)
            {
                throw CreateException("set registry property", ex);
            }
        }

        /// <summary>
        /// Gets provisioning mode status
        /// </summary>
        /// <returns>Provisioning mode information</returns>
        public async Task<CCMProvisioningMode?> GetProvisioningModeAsync()
        {
            return await Task.Run(() => GetProvisioningMode());
        }

        /// <summary>
        /// Gets provisioning mode status (synchronous)
        /// </summary>
        /// <returns>Provisioning mode information</returns>
        public CCMProvisioningMode? GetProvisioningMode()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMProvisioningMode
                    {
                        ComputerName = _computerName,
                        ProvisioningMode = Convert.ToBoolean(obj["IsInProvisioningMode"] ?? false),
                        ProvisioningModeStartTime = obj["ProvisioningModeStartTime"] as DateTime?
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to get provisioning mode from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Sets provisioning mode
        /// </summary>
        /// <param name="enabled">Whether to enable provisioning mode</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetProvisioningModeAsync(bool enabled)
        {
            return await Task.Run(() => SetProvisioningMode(enabled));
        }

        /// <summary>
        /// Sets provisioning mode (synchronous)
        /// </summary>
        /// <param name="enabled">Whether to enable provisioning mode</param>
        /// <returns>True if successful</returns>
        public bool SetProvisioningMode(bool enabled)
        {
            try
            {
                string namespacePath = GetNamespacePath("root\\CCM");
                
                // Use ManagementClass to call method on the class, not on instances (like PowerShell)
                using var mgmtClass = new ManagementClass(namespacePath, "SMS_Client", null);
                var inParams = mgmtClass.GetMethodParameters("SetClientProvisioningMode");
                inParams["bEnable"] = enabled;

                var outParams = mgmtClass.InvokeMethod("SetClientProvisioningMode", inParams, null);
                return Convert.ToInt32(outParams["ReturnValue"]) == 0;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to set provisioning mode to '{enabled}' on {_computerName}: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Gets the client GUID
        /// </summary>
        /// <returns>GUID information</returns>
        public async Task<CCMGuidInfo?> GetGuidAsync()
        {
            return await Task.Run(() => GetGuid());
        }

        /// <summary>
        /// Gets the client GUID (synchronous)
        /// </summary>
        /// <returns>GUID information</returns>
        public CCMGuidInfo? GetGuid()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Client");
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
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to get client GUID from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Gets the primary user
        /// </summary>
        /// <returns>Primary user information</returns>
        public async Task<CCMPrimaryUser?> GetPrimaryUserAsync()
        {
            return await Task.Run(() => GetPrimaryUser());
        }

        /// <summary>
        /// Gets the primary user (synchronous)
        /// </summary>
        /// <returns>Primary user information</returns>
        public CCMPrimaryUser? GetPrimaryUser()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM\\CIModels"), "SELECT * FROM CCM_UserAffinity");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMPrimaryUser
                    {
                        ComputerName = _computerName,
                        PrimaryUser = obj["ConsoleUser"]?.ToString() ?? "",
                        Sources = obj["Sources"]?.ToString() ?? ""
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to get primary user from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Gets the CCM execution startup time
        /// </summary>
        /// <returns>Startup time information</returns>
        public async Task<CCMExecStartupTime?> GetExecStartupTimeAsync()
        {
            return await Task.Run(() => GetExecStartupTime());
        }

        /// <summary>
        /// Gets the CCM execution startup time (synchronous)
        /// </summary>
        /// <returns>Startup time information</returns>
        public CCMExecStartupTime? GetExecStartupTime()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(GetNamespacePath("root\\CCM"), "SELECT * FROM CCM_Service WHERE Name = 'CcmExec'");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMExecStartupTime
                    {
                        ComputerName = _computerName,
                        StartupTime = obj["ProcessStartTime"] as DateTime? ?? DateTime.MinValue,
                        ServiceStatus = obj["Status"]?.ToString() ?? ""
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to get CCM exec startup time from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

    }
}