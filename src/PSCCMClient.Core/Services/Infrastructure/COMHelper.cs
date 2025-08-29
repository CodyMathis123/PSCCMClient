using System;
using System.Reflection;

namespace PSCCMClient.Core.Services.Infrastructure
{
    /// <summary>
    /// Helper class for safe COM object operations (local operations only)
    /// </summary>
    public static class COMHelper
    {
        /// <summary>
        /// Safely invokes a COM object method
        /// </summary>
        /// <param name="progId">COM object ProgID (e.g., "Microsoft.SMS.Client")</param>
        /// <param name="methodName">Method name to invoke</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>Method result or null</returns>
        /// <exception cref="InvalidOperationException">Thrown when COM object cannot be created</exception>
        public static object? InvokeMethod(string progId, string methodName, params object[] parameters)
        {
            try
            {
                var comType = Type.GetTypeFromProgID(progId);
                if (comType == null)
                {
                    throw new InvalidOperationException($"Could not get COM type for ProgID: {progId}");
                }

                var comInstance = Activator.CreateInstance(comType);
                if (comInstance == null)
                {
                    throw new InvalidOperationException($"Could not create COM instance for ProgID: {progId}");
                }

                try
                {
                    return comInstance.GetType().InvokeMember(
                        methodName,
                        BindingFlags.InvokeMethod,
                        null,
                        comInstance,
                        parameters
                    );
                }
                finally
                {
                    // Release COM object
                    if (System.Runtime.InteropServices.Marshal.IsComObject(comInstance))
                    {
                        System.Runtime.InteropServices.Marshal.ReleaseComObject(comInstance);
                    }
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to invoke COM method '{methodName}' on '{progId}': {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Safely invokes a COM object method and returns true if successful
        /// </summary>
        /// <param name="progId">COM object ProgID</param>
        /// <param name="methodName">Method name to invoke</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>True if method was invoked successfully</returns>
        public static bool TryInvokeMethod(string progId, string methodName, params object[] parameters)
        {
            try
            {
                InvokeMethod(progId, methodName, parameters);
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Safely invokes a COM object method and returns the result as a string
        /// </summary>
        /// <param name="progId">COM object ProgID</param>
        /// <param name="methodName">Method name to invoke</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>Method result as string or empty string if failed</returns>
        public static string InvokeMethodString(string progId, string methodName, params object[] parameters)
        {
            try
            {
                var result = InvokeMethod(progId, methodName, parameters);
                return result?.ToString() ?? "";
            }
            catch
            {
                return "";
            }
        }

        /// <summary>
        /// Safely invokes a COM object method and returns the result as a boolean
        /// </summary>
        /// <param name="progId">COM object ProgID</param>
        /// <param name="methodName">Method name to invoke</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>Method result as boolean or false if failed</returns>
        public static bool InvokeMethodBool(string progId, string methodName, params object[] parameters)
        {
            try
            {
                var result = InvokeMethod(progId, methodName, parameters);
                return Convert.ToBoolean(result ?? false);
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Checks if a COM object is available for the specified ProgID
        /// </summary>
        /// <param name="progId">COM object ProgID</param>
        /// <returns>True if COM object is available</returns>
        public static bool IsAvailable(string progId)
        {
            try
            {
                var comType = Type.GetTypeFromProgID(progId);
                return comType != null;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Common ProgIDs used by CCM services
        /// </summary>
        public static class ProgIds
        {
            public const string SMSClient = "Microsoft.SMS.Client";
            public const string TSEnvironment = "Microsoft.SMS.TSEnvironment";
        }
    }
}