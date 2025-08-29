using System.Management;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services.Infrastructure
{
    /// <summary>
    /// Abstract base class for all CCM services providing common functionality
    /// </summary>
    public abstract class CCMServiceBase
    {
        protected readonly string _computerName;

        protected CCMServiceBase(string computerName)
        {
            _computerName = computerName ?? ".";
        }

        /// <summary>
        /// Determines if the target computer is the local machine
        /// </summary>
        protected bool IsLocalComputer => WMIHelper.IsLocalComputer(_computerName);

        /// <summary>
        /// Gets the actual computer name (converts "." to actual machine name)
        /// </summary>
        protected string ActualComputerName => _computerName == "." ? Environment.MachineName : _computerName;

        /// <summary>
        /// Gets the appropriate WMI namespace path for local or remote operations
        /// </summary>
        /// <param name="baseNamespace">Base namespace (e.g., "root\\CCM")</param>
        /// <returns>Full namespace path</returns>
        protected string GetNamespacePath(string baseNamespace)
        {
            return WMIHelper.GetNamespacePath(_computerName, baseNamespace);
        }

        /// <summary>
        /// Converts WMI datetime string to DateTime
        /// </summary>
        /// <param name="wmiDateTime">WMI datetime string</param>
        /// <returns>Converted DateTime or null</returns>
        protected DateTime? ConvertWmiDateTime(object? wmiDateTime)
        {
            return WMIHelper.ConvertWmiDateTime(wmiDateTime);
        }

        /// <summary>
        /// Executes a WMI query and returns the first result
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="query">WMI query</param>
        /// <returns>First ManagementObject or null</returns>
        protected ManagementObject? QueryFirstWMIObject(string namespacePath, string query)
        {
            return WMIHelper.QueryFirstObject(namespacePath, query);
        }

        /// <summary>
        /// Executes a WMI query and returns all results
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="query">WMI query</param>
        /// <returns>Collection of ManagementObjects</returns>
        protected ManagementObjectCollection QueryWMIObjects(string namespacePath, string query)
        {
            return WMIHelper.QueryObjects(namespacePath, query);
        }

        /// <summary>
        /// Invokes a WMI class method (static method on the class)
        /// </summary>
        /// <param name="namespacePath">WMI namespace path</param>
        /// <param name="className">WMI class name</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>Method output parameters</returns>
        protected ManagementBaseObject? InvokeWMIClassMethod(string namespacePath, string className, string methodName, ManagementBaseObject? parameters = null)
        {
            return WMIHelper.InvokeClassMethod(namespacePath, className, methodName, parameters);
        }

        /// <summary>
        /// Invokes a method on a WMI object instance
        /// </summary>
        /// <param name="wmiObject">WMI object instance</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>Method output parameters</returns>
        protected ManagementBaseObject? InvokeWMIInstanceMethod(ManagementObject wmiObject, string methodName, ManagementBaseObject? parameters = null)
        {
            return WMIHelper.InvokeInstanceMethod(wmiObject, methodName, parameters);
        }

        /// <summary>
        /// Safely invokes a COM object method for local operations only
        /// </summary>
        /// <param name="progId">COM object ProgID</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>Method result or null</returns>
        protected object? InvokeCOMMethod(string progId, string methodName, params object[] parameters)
        {
            if (!IsLocalComputer)
            {
                throw new InvalidOperationException("COM object methods can only be invoked on the local computer");
            }

            return COMHelper.InvokeMethod(progId, methodName, parameters);
        }

        /// <summary>
        /// Safely invokes a COM object method for local operations only, returning a boolean result
        /// </summary>
        /// <param name="progId">COM object ProgID</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>True if successful, false otherwise</returns>
        protected bool InvokeCOMMethodBool(string progId, string methodName, params object[] parameters)
        {
            try
            {
                InvokeCOMMethod(progId, methodName, parameters);
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Safely invokes a COM object method for local operations only, returning a string result
        /// </summary>
        /// <param name="progId">COM object ProgID</param>
        /// <param name="methodName">Method name</param>
        /// <param name="parameters">Method parameters</param>
        /// <returns>Method result as string or empty string</returns>
        protected string InvokeCOMMethodString(string progId, string methodName, params object[] parameters)
        {
            if (!IsLocalComputer)
            {
                return "";
            }

            return COMHelper.InvokeMethodString(progId, methodName, parameters);
        }

        /// <summary>
        /// Creates a standard exception with computer name context
        /// </summary>
        /// <param name="operation">The operation that failed</param>
        /// <param name="innerException">The inner exception</param>
        /// <returns>InvalidOperationException with context</returns>
        protected InvalidOperationException CreateException(string operation, Exception innerException)
        {
            return new InvalidOperationException($"Failed to {operation} on {_computerName}: {innerException.Message}", innerException);
        }

        /// <summary>
        /// Creates a standard exception with computer name context
        /// </summary>
        /// <param name="operation">The operation that failed</param>
        /// <param name="message">Custom error message</param>
        /// <returns>InvalidOperationException with context</returns>
        protected InvalidOperationException CreateException(string operation, string message)
        {
            return new InvalidOperationException($"Failed to {operation} on {_computerName}: {message}");
        }
    }
}