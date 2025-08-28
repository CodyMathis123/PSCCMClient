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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
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
                throw CreateException("get provisioning mode", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "SMS_Client", "SetClientProvisioningMode");
                inParams["bEnable"] = enabled;

                var outParams = InvokeWMIClassMethod(namespacePath, "SMS_Client", "SetClientProvisioningMode", inParams);
                return WMIHelper.IsMethodInvocationSuccessful(outParams);
            }
            catch (Exception ex)
            {
                throw CreateException($"set provisioning mode to '{enabled}'", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Client");
                
                if (obj != null)
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
                throw CreateException("get client GUID", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM\\CIModels");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_UserAffinity");
                
                if (obj != null)
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
                throw CreateException("get primary user", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM");
                var obj = QueryFirstWMIObject(namespacePath, "SELECT * FROM CCM_Service WHERE Name = 'CcmExec'");
                
                if (obj != null)
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
                throw CreateException("get CCM exec startup time", ex);
            }

            return null;
        }

    }
}