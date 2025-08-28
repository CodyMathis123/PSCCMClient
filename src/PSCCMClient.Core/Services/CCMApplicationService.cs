using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager applications
    /// </summary>
    public class CCMApplicationService
    {
        private readonly string _computerName;

        public CCMApplicationService(string computerName = ".")
        {
            _computerName = computerName;
        }

        /// <summary>
        /// Helper method to get the correct namespace path for local or remote operations
        /// </summary>
        private string GetNamespacePath(string baseNamespace)
        {
            bool isLocal = _computerName == "." || _computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase);
            return isLocal ? baseNamespace : $@"\\{_computerName}\{baseNamespace}";
        }

        /// <summary>
        /// Gets all applications from the Configuration Manager client
        /// </summary>
        /// <returns>A collection of CCMApplication objects</returns>
        public async Task<IEnumerable<CCMApplication>> GetApplicationsAsync()
        {
            return await Task.Run(() => GetApplications());
        }

        /// <summary>
        /// Gets applications by name from the Configuration Manager client
        /// </summary>
        /// <param name="applicationName">The name of the application to search for</param>
        /// <returns>A collection of CCMApplication objects matching the name</returns>
        public async Task<IEnumerable<CCMApplication>> GetApplicationsByNameAsync(string applicationName)
        {
            return await Task.Run(() => GetApplicationsByName(applicationName));
        }

        /// <summary>
        /// Gets all applications from the Configuration Manager client (synchronous)
        /// </summary>
        /// <returns>A collection of CCMApplication objects</returns>
        public IEnumerable<CCMApplication> GetApplications()
        {
            var applications = new List<CCMApplication>();

            try
            {
                var scope = new ManagementScope(GetNamespacePath("root\\CCM\\ClientSDK"));
                scope.Connect();

                using var searcher = new ManagementObjectSearcher(scope, new ObjectQuery("SELECT * FROM CCM_Application"));
                using var collection = searcher.Get();

                foreach (ManagementObject obj in collection)
                {
                    using (obj)
                    {
                        var application = CCMApplication.FromManagementObject(obj);
                        application.ComputerName = _computerName;
                        applications.Add(application);
                    }
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve applications from {_computerName}: {ex.Message}", ex);
            }

            return applications;
        }

        /// <summary>
        /// Gets applications by name from the Configuration Manager client (synchronous)
        /// </summary>
        /// <param name="applicationName">The name of the application to search for</param>
        /// <returns>A collection of CCMApplication objects matching the name</returns>
        public IEnumerable<CCMApplication> GetApplicationsByName(string applicationName)
        {
            var applications = new List<CCMApplication>();

            try
            {
                var scope = new ManagementScope(GetNamespacePath("root\\CCM\\ClientSDK"));
                scope.Connect();

                var query = $"SELECT * FROM CCM_Application WHERE Name LIKE '%{applicationName}%'";
                using var searcher = new ManagementObjectSearcher(scope, new ObjectQuery(query));
                using var collection = searcher.Get();

                foreach (ManagementObject obj in collection)
                {
                    using (obj)
                    {
                        var application = CCMApplication.FromManagementObject(obj);
                        application.ComputerName = _computerName;
                        applications.Add(application);
                    }
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve applications by name '{applicationName}' from {_computerName}: {ex.Message}", ex);
            }

            return applications;
        }

        /// <summary>
        /// Installs an application on the Configuration Manager client
        /// </summary>
        /// <param name="applicationId">The ID of the application to install</param>
        /// <returns>True if the installation was initiated successfully</returns>
        public async Task<bool> InstallApplicationAsync(string applicationId)
        {
            return await Task.Run(() => InstallApplication(applicationId));
        }

        /// <summary>
        /// Installs an application on the Configuration Manager client (synchronous)
        /// </summary>
        /// <param name="applicationId">The ID of the application to install</param>
        /// <returns>True if the installation was initiated successfully</returns>
        public bool InstallApplication(string applicationId)
        {
            try
            {
                var scope = new ManagementScope(GetNamespacePath("root\\CCM\\ClientSDK"));
                scope.Connect();

                using var appClass = new ManagementClass(scope, new ManagementPath("CCM_Application"), null);
                using var inParams = appClass.GetMethodParameters("Install");
                
                inParams["Id"] = applicationId;
                inParams["IsMachineTarget"] = true;
                inParams["EnforcePreference"] = 0; // Immediate
                inParams["Priority"] = "High";
                inParams["IsRebootIfNeeded"] = false;

                using var outParams = appClass.InvokeMethod("Install", inParams, null);
                var returnValue = Convert.ToInt32(outParams["ReturnValue"]);
                
                return returnValue == 0;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to install application {applicationId} on {_computerName}: {ex.Message}", ex);
            }
        }
    }
}