using System.Collections.Generic;
using System;
using System.Management;
using System.Security;

namespace PSCCMClient.Core.Services.Infrastructure
{
    /// <summary>
    /// Helper class for WMI operations with consistent local vs remote handling
    /// </summary>
    public static class WMIHelper
    {
        /// <summary>
        /// Creates connection options for WMI operations with optional credentials
        /// </summary>
        /// <param name="username">Optional username for authentication</param>
        /// <param name="password">Optional password for authentication</param>
        /// <param name="domain">Optional domain for authentication</param>
        /// <returns>ConnectionOptions object</returns>
        public static ConnectionOptions CreateConnectionOptions(string? username = null, SecureString? password = null, string? domain = null)
        {
            var options = new ConnectionOptions();
            
            if (!string.IsNullOrEmpty(username))
            {
                options.Username = username;
                
                if (password != null)
                {
                    var ptr = System.Runtime.InteropServices.Marshal.SecureStringToBSTR(password);
                    try
                    {
                        options.SecurePassword = password;
                    }
                    finally
                    {
                        System.Runtime.InteropServices.Marshal.ZeroFreeBSTR(ptr);
                    }
                }
                
                if (!string.IsNullOrEmpty(domain))
                {
                    options.Authority = $"ntlmdomain:{domain}";
                }
                
                options.EnablePrivileges = true;
                options.Authentication = AuthenticationLevel.PacketPrivacy;
                options.Impersonation = ImpersonationLevel.Impersonate;
            }
            
            return options;
        }

        /// <summary>
        /// Creates a ManagementScope for WMI operations with optional credentials
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="username">Optional username for authentication</param>
        /// <param name="password">Optional password for authentication</param>
        /// <param name="domain">Optional domain for authentication</param>
        /// <returns>ManagementScope object</returns>
        public static ManagementScope CreateManagementScope(string namespacePath, string? username = null, SecureString? password = null, string? domain = null)
        {
            var scope = new ManagementScope(namespacePath);
            
            if (!string.IsNullOrEmpty(username))
            {
                scope.Options = CreateConnectionOptions(username, password, domain);
            }
            
            scope.Connect();
            return scope;
        }
        /// <summary>
        /// Determines if the specified computer name refers to the local machine
        /// </summary>
        /// <param name="computerName">Computer name to check</param>
        /// <returns>True if local machine</returns>
        public static bool IsLocalComputer(string computerName)
        {
            return computerName == "." || 
                   computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase) ||
                   computerName.Equals("localhost", StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Gets the appropriate WMI namespace path for local or remote operations
        /// </summary>
        /// <param name="computerName">Target computer name</param>
        /// <param name="baseNamespace">Base namespace (e.g., "root\\CCM")</param>
        /// <returns>Full namespace path</returns>
        public static string GetNamespacePath(string computerName, string baseNamespace)
        {
            if (IsLocalComputer(computerName))
            {
                return baseNamespace;
            }
            else
            {
                return $@"\\{computerName}\{baseNamespace}";
            }
        }

        /// <summary>
        /// Converts WMI datetime string to DateTime
        /// </summary>
        /// <param name="wmiDateTime">WMI datetime object</param>
        /// <returns>Converted DateTime or null</returns>
        public static DateTime? ConvertWmiDateTime(object? wmiDateTime)
        {
            try
            {
                if (wmiDateTime == null)
                    return null;

                string? dateTimeString = wmiDateTime.ToString();
                if (string.IsNullOrEmpty(dateTimeString))
                    return null;

                return ManagementDateTimeConverter.ToDateTime(dateTimeString);
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Executes a WMI query and returns the first result
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="query">WMI query</param>
        /// <param name="username">Optional username for authentication</param>
        /// <param name="password">Optional password for authentication</param>
        /// <param name="domain">Optional domain for authentication</param>
        /// <returns>First ManagementObject or null</returns>
        public static ManagementObject? QueryFirstObject(string namespacePath, string query, string? username = null, SecureString? password = null, string? domain = null)
        {
            try
            {
                var scope = CreateManagementScope(namespacePath, username, password, domain);
                using var searcher = new ManagementObjectSearcher(scope, new ObjectQuery(query));
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return obj;
                }
            }
            catch
            {
                // Return null on any error
            }

            return null;
        }

        /// <summary>
        /// Executes a WMI query and returns all results
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="query">WMI query</param>
        /// <param name="username">Optional username for authentication</param>
        /// <param name="password">Optional password for authentication</param>
        /// <param name="domain">Optional domain for authentication</param>
        /// <returns>Collection of ManagementObjects</returns>
        public static ManagementObjectCollection QueryObjects(string namespacePath, string query, string? username = null, SecureString? password = null, string? domain = null)
        {
            var scope = CreateManagementScope(namespacePath, username, password, domain);
            using var searcher = new ManagementObjectSearcher(scope, new ObjectQuery(query));
            return searcher.Get();
        }

        /// <summary>
        /// Invokes a WMI class method (static method on the class)
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="className">WMI class name</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters (optional)</param>
        /// <param name="username">Optional username for authentication</param>
        /// <param name="password">Optional password for authentication</param>
        /// <param name="domain">Optional domain for authentication</param>
        /// <returns>Method output parameters</returns>
        public static ManagementBaseObject? InvokeClassMethod(string namespacePath, string className, string methodName, ManagementBaseObject? parameters = null, string? username = null, SecureString? password = null, string? domain = null)
        {
            var scope = CreateManagementScope(namespacePath, username, password, domain);
            using var mgmtClass = new ManagementClass(scope, new ManagementPath(className), null);
            return mgmtClass.InvokeMethod(methodName, parameters, null);
        }

        /// <summary>
        /// Invokes a method on a WMI object instance
        /// </summary>
        /// <param name="wmiObject">WMI object instance</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters (optional)</param>
        /// <returns>Method output parameters</returns>
        public static ManagementBaseObject? InvokeInstanceMethod(ManagementObject wmiObject, string methodName, ManagementBaseObject? parameters = null)
        {
            return wmiObject.InvokeMethod(methodName, parameters, null);
        }

        /// <summary>
        /// Gets method parameters for a WMI class method
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="className">WMI class name</param>
        /// <param name="methodName">Method name</param>
        /// <param name="username">Optional username for authentication</param>
        /// <param name="password">Optional password for authentication</param>
        /// <param name="domain">Optional domain for authentication</param>
        /// <returns>Method parameters object</returns>
        public static ManagementBaseObject GetClassMethodParameters(string namespacePath, string className, string methodName, string? username = null, SecureString? password = null, string? domain = null)
        {
            var scope = CreateManagementScope(namespacePath, username, password, domain);
            using var mgmtClass = new ManagementClass(scope, new ManagementPath(className), null);
            return mgmtClass.GetMethodParameters(methodName);
        }

        /// <summary>
        /// Gets method parameters for a WMI instance method
        /// </summary>
        /// <param name="wmiObject">WMI object instance</param>
        /// <param name="methodName">Method name</param>
        /// <returns>Method parameters object</returns>
        public static ManagementBaseObject GetInstanceMethodParameters(ManagementObject wmiObject, string methodName)
        {
            return wmiObject.GetMethodParameters(methodName);
        }

        /// <summary>
        /// Checks if a WMI method returned success (ReturnValue = 0)
        /// </summary>
        /// <param name="result">Method result</param>
        /// <returns>True if successful</returns>
        public static bool IsMethodCallSuccessful(ManagementBaseObject? result)
        {
            return result != null && Convert.ToInt32(result["ReturnValue"] ?? -1) == 0;
        }

        /// <summary>
        /// Checks if a WMI method invocation was successful by checking if result object exists
        /// Used for methods that don't return meaningful ReturnValue (like TriggerSchedule, ResetPolicy)
        /// </summary>
        /// <param name="result">Method result</param>
        /// <returns>True if invocation completed (result object exists)</returns>
        public static bool IsMethodInvocationSuccessful(ManagementBaseObject? result)
        {
            return result != null;
        }
    }
}