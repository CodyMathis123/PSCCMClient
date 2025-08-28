using System.Management;

namespace PSCCMClient.Core.Services.Infrastructure
{
    /// <summary>
    /// Helper class for WMI operations with consistent local vs remote handling
    /// </summary>
    public static class WMIHelper
    {
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
        /// <returns>First ManagementObject or null</returns>
        public static ManagementObject? QueryFirstObject(string namespacePath, string query)
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(namespacePath, query);
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
        /// <returns>Collection of ManagementObjects</returns>
        public static ManagementObjectCollection QueryObjects(string namespacePath, string query)
        {
            using var searcher = new ManagementObjectSearcher(namespacePath, query);
            return searcher.Get();
        }

        /// <summary>
        /// Invokes a WMI class method (static method on the class)
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="className">WMI class name</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters (optional)</param>
        /// <returns>Method output parameters</returns>
        public static ManagementBaseObject? InvokeClassMethod(string namespacePath, string className, string methodName, ManagementBaseObject? parameters = null)
        {
            using var mgmtClass = new ManagementClass(namespacePath, className, null);
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
        /// <returns>Method parameters object</returns>
        public static ManagementBaseObject GetClassMethodParameters(string namespacePath, string className, string methodName)
        {
            using var mgmtClass = new ManagementClass(namespacePath, className, null);
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