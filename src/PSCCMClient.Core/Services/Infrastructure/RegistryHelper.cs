using System;
using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services.Infrastructure
{
    /// <summary>
    /// Helper class for registry operations via WMI StdRegProv
    /// </summary>
    public static class RegistryHelper
    {
        /// <summary>
        /// Registry hive constants
        /// </summary>
        public static class Hives
        {
            public const uint HKEY_CLASSES_ROOT = 0x80000000;
            public const uint HKEY_CURRENT_USER = 0x80000001;
            public const uint HKEY_LOCAL_MACHINE = 0x80000002;
            public const uint HKEY_USERS = 0x80000003;
            public const uint HKEY_CURRENT_CONFIG = 0x80000005;
        }

        /// <summary>
        /// Gets a registry hive value from string
        /// </summary>
        /// <param name="hive">Registry hive name</param>
        /// <returns>Hive value</returns>
        public static uint GetHiveValue(string hive)
        {
            return hive.ToUpper() switch
            {
                "HKEY_CLASSES_ROOT" => Hives.HKEY_CLASSES_ROOT,
                "HKCR" => Hives.HKEY_CLASSES_ROOT,
                "HKEY_CURRENT_USER" => Hives.HKEY_CURRENT_USER,
                "HKCU" => Hives.HKEY_CURRENT_USER,
                "HKEY_LOCAL_MACHINE" => Hives.HKEY_LOCAL_MACHINE,
                "HKLM" => Hives.HKEY_LOCAL_MACHINE,
                "HKEY_USERS" => Hives.HKEY_USERS,
                "HKU" => Hives.HKEY_USERS,
                "HKEY_CURRENT_CONFIG" => Hives.HKEY_CURRENT_CONFIG,
                "HKCC" => Hives.HKEY_CURRENT_CONFIG,
                _ => Hives.HKEY_LOCAL_MACHINE // Default to HKLM
            };
        }

        /// <summary>
        /// Gets a registry value (auto-detecting type like PowerShell module)
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry value or null if not found</returns>
        public static object? GetValue(string computerName, string hive, string subKey, string valueName)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                // First enumerate values to get the type (like PowerShell module)
                var enumParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "EnumValues");
                enumParams["hDefKey"] = hiveValue;
                enumParams["sSubKeyName"] = subKey;

                var enumResult = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "EnumValues", enumParams);
                
                if (!WMIHelper.IsMethodCallSuccessful(enumResult))
                {
                    return null;
                }

                // Find the property and its type
                var names = enumResult?["sNames"] as string[];
                var types = enumResult?["Types"] as uint[];

                if (names == null || types == null)
                {
                    return null;
                }

                var propertyIndex = Array.IndexOf(names, valueName);
                if (propertyIndex == -1)
                {
                    return null; // Property not found
                }

                var propertyType = types[propertyIndex];

                // Call the appropriate method based on type (like PowerShell module)
                return propertyType switch
                {
                    1 => GetStringValue(computerName, hive, subKey, valueName), // REG_SZ
                    2 => GetStringValue(computerName, hive, subKey, valueName), // REG_EXPAND_SZ  
                    4 => GetDWORDValue(computerName, hive, subKey, valueName), // REG_DWORD
                    7 => GetMultiStringValue(computerName, hive, subKey, valueName), // REG_MULTI_SZ
                    11 => GetQWORDValue(computerName, hive, subKey, valueName), // REG_QWORD
                    3 => GetBinaryValue(computerName, hive, subKey, valueName), // REG_BINARY
                    _ => GetStringValue(computerName, hive, subKey, valueName) // Default to string
                };
            }
            catch
            {
                // Return null on error
            }

            return null;
        }

        /// <summary>
        /// Gets a registry string value
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry value or null if not found</returns>
        public static string? GetStringValue(string computerName, string hive, string subKey, string valueName)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "GetStringValue");
                inParams["hDefKey"] = hiveValue;
                inParams["sSubKeyName"] = subKey;
                inParams["sValueName"] = valueName;

                var outParams = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "GetStringValue", inParams);
                
                if (WMIHelper.IsMethodCallSuccessful(outParams))
                {
                    return outParams?["sValue"]?.ToString();
                }
            }
            catch
            {
                // Return null on error
            }

            return null;
        }

        /// <summary>
        /// Gets a registry DWORD value
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry value or null if not found</returns>
        public static uint? GetDWORDValue(string computerName, string hive, string subKey, string valueName)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "GetDWORDValue");
                inParams["hDefKey"] = hiveValue;
                inParams["sSubKeyName"] = subKey;
                inParams["sValueName"] = valueName;

                var outParams = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "GetDWORDValue", inParams);
                
                if (WMIHelper.IsMethodCallSuccessful(outParams))
                {
                    return Convert.ToUInt32(outParams?["uValue"] ?? 0);
                }
            }
            catch
            {
                // Return null on error
            }

            return null;
        }

        /// <summary>
        /// Gets a registry QWORD value
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry value or null if not found</returns>
        public static ulong? GetQWORDValue(string computerName, string hive, string subKey, string valueName)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "GetQWORDValue");
                inParams["hDefKey"] = hiveValue;
                inParams["sSubKeyName"] = subKey;
                inParams["sValueName"] = valueName;

                var outParams = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "GetQWORDValue", inParams);
                
                if (WMIHelper.IsMethodCallSuccessful(outParams))
                {
                    return Convert.ToUInt64(outParams?["uValue"] ?? 0);
                }
            }
            catch
            {
                // Return null on error
            }

            return null;
        }

        /// <summary>
        /// Gets a registry multi-string value
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry value or null if not found</returns>
        public static string[]? GetMultiStringValue(string computerName, string hive, string subKey, string valueName)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "GetMultiStringValue");
                inParams["hDefKey"] = hiveValue;
                inParams["sSubKeyName"] = subKey;
                inParams["sValueName"] = valueName;

                var outParams = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "GetMultiStringValue", inParams);
                
                if (WMIHelper.IsMethodCallSuccessful(outParams))
                {
                    return outParams?["sValue"] as string[];
                }
            }
            catch
            {
                // Return null on error
            }

            return null;
        }

        /// <summary>
        /// Gets a registry binary value
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <returns>Registry value or null if not found</returns>
        public static byte[]? GetBinaryValue(string computerName, string hive, string subKey, string valueName)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "GetBinaryValue");
                inParams["hDefKey"] = hiveValue;
                inParams["sSubKeyName"] = subKey;
                inParams["sValueName"] = valueName;

                var outParams = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "GetBinaryValue", inParams);
                
                if (WMIHelper.IsMethodCallSuccessful(outParams))
                {
                    return outParams?["uValue"] as byte[];
                }
            }
            catch
            {
                // Return null on error
            }

            return null;
        }

        /// <summary>
        /// Sets a registry string value
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <param name="value">Value to set</param>
        /// <returns>True if successful</returns>
        public static bool SetStringValue(string computerName, string hive, string subKey, string valueName, string value)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "SetStringValue");
                inParams["hDefKey"] = hiveValue;
                inParams["sSubKeyName"] = subKey;
                inParams["sValueName"] = valueName;
                inParams["sValue"] = value;

                var outParams = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "SetStringValue", inParams);
                return WMIHelper.IsMethodCallSuccessful(outParams);
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Sets a registry DWORD value
        /// </summary>
        /// <param name="computerName">Target computer</param>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey path</param>
        /// <param name="valueName">Value name</param>
        /// <param name="value">Value to set</param>
        /// <returns>True if successful</returns>
        public static bool SetDWORDValue(string computerName, string hive, string subKey, string valueName, uint value)
        {
            try
            {
                var namespacePath = WMIHelper.GetNamespacePath(computerName, "root\\default");
                var hiveValue = GetHiveValue(hive);

                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "StdRegProv", "SetDWORDValue");
                inParams["hDefKey"] = hiveValue;
                inParams["sSubKeyName"] = subKey;
                inParams["sValueName"] = valueName;
                inParams["uValue"] = value;

                var outParams = WMIHelper.InvokeClassMethod(namespacePath, "StdRegProv", "SetDWORDValue", inParams);
                return WMIHelper.IsMethodCallSuccessful(outParams);
            }
            catch
            {
                return false;
            }
        }
    }
}