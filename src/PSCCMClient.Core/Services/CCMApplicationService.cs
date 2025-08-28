using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager applications
    /// </summary>
    public class CCMApplicationService : CCMServiceBase
    {
        public CCMApplicationService(string computerName = ".") : base(computerName)
        {
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
                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                using var collection = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_Application");

                foreach (ManagementObject obj in collection)
                {
                    using (obj)
                    {
                        applications.Add(new CCMApplication
                        {
                            ComputerName = _computerName,
                            Name = obj["Name"]?.ToString() ?? "",
                            FullName = obj["FullName"]?.ToString() ?? "",
                            SoftwareVersion = obj["SoftwareVersion"]?.ToString() ?? "",
                            Publisher = obj["Publisher"]?.ToString() ?? "",
                            Description = obj["Description"]?.ToString() ?? "",
                            Id = obj["Id"]?.ToString() ?? "",
                            Revision = obj["Revision"]?.ToString() ?? "",
                            EvaluationState = obj["EvaluationState"]?.ToString() ?? "",
                            ErrorCode = obj["ErrorCode"]?.ToString() ?? "",
                            AllowedActions = obj["AllowedActions"]?.ToString() ?? "",
                            ResolvedState = obj["ResolvedState"]?.ToString() ?? "",
                            InstallState = obj["InstallState"]?.ToString() ?? "",
                            ApplicabilityState = obj["ApplicabilityState"]?.ToString() ?? "",
                            ConfigureState = obj["ConfigureState"]?.ToString() ?? "",
                            LastEvalTime = obj["LastEvalTime"] as DateTime?,
                            LastInstallTime = obj["LastInstallTime"] as DateTime?,
                            StartTime = obj["StartTime"] as DateTime?,
                            Deadline = obj["Deadline"] as DateTime?,
                            NextUserScheduledTime = obj["NextUserScheduledTime"] as DateTime?,
                            IsMachineTarget = Convert.ToBoolean(obj["IsMachineTarget"] ?? false),
                            IsPreflightOnly = Convert.ToBoolean(obj["IsPreflightOnly"] ?? false),
                            NotifyUser = Convert.ToBoolean(obj["NotifyUser"] ?? false),
                            UserUIExperience = Convert.ToBoolean(obj["UserUIExperience"] ?? false),
                            OverrideServiceWindow = Convert.ToBoolean(obj["OverrideServiceWindow"] ?? false),
                            RebootOutsideServiceWindow = Convert.ToBoolean(obj["RebootOutsideServiceWindow"] ?? false),
                            AppDTs = obj["AppDTs"]?.ToString() ?? "",
                            ContentSize = Convert.ToInt64(obj["ContentSize"] ?? 0),
                            DeploymentReport = obj["DeploymentReport"]?.ToString() ?? "",
                            EnforcePreference = obj["EnforcePreference"]?.ToString() ?? "",
                            EstimatedInstallTime = Convert.ToInt32(obj["EstimatedInstallTime"] ?? 0),
                            FileTypes = obj["FileTypes"]?.ToString() ?? "",
                            HighImpactDeployment = Convert.ToBoolean(obj["HighImpactDeployment"] ?? false),
                            InformativeUrl = obj["InformativeUrl"]?.ToString() ?? "",
                            InProgressActions = obj["InProgressActions"]?.ToString() ?? "",
                            PercentComplete = Convert.ToInt32(obj["PercentComplete"] ?? 0),
                            ReleaseDate = obj["ReleaseDate"] as DateTime?,
                            SupersessionState = obj["SupersessionState"]?.ToString() ?? "",
                            Type = obj["Type"]?.ToString() ?? ""
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve applications", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                var query = $"SELECT * FROM CCM_Application WHERE Name LIKE '%{applicationName}%'";
                using var collection = QueryWMIObjects(namespacePath, query);

                foreach (ManagementObject obj in collection)
                {
                    using (obj)
                    {
                        applications.Add(new CCMApplication
                        {
                            ComputerName = _computerName,
                            Name = obj["Name"]?.ToString() ?? "",
                            FullName = obj["FullName"]?.ToString() ?? "",
                            SoftwareVersion = obj["SoftwareVersion"]?.ToString() ?? "",
                            Publisher = obj["Publisher"]?.ToString() ?? "",
                            Description = obj["Description"]?.ToString() ?? "",
                            Id = obj["Id"]?.ToString() ?? "",
                            Revision = obj["Revision"]?.ToString() ?? "",
                            EvaluationState = obj["EvaluationState"]?.ToString() ?? "",
                            ErrorCode = obj["ErrorCode"]?.ToString() ?? "",
                            AllowedActions = obj["AllowedActions"]?.ToString() ?? "",
                            ResolvedState = obj["ResolvedState"]?.ToString() ?? "",
                            InstallState = obj["InstallState"]?.ToString() ?? "",
                            ApplicabilityState = obj["ApplicabilityState"]?.ToString() ?? "",
                            ConfigureState = obj["ConfigureState"]?.ToString() ?? "",
                            LastEvalTime = obj["LastEvalTime"] as DateTime?,
                            LastInstallTime = obj["LastInstallTime"] as DateTime?,
                            StartTime = obj["StartTime"] as DateTime?,
                            Deadline = obj["Deadline"] as DateTime?,
                            NextUserScheduledTime = obj["NextUserScheduledTime"] as DateTime?,
                            IsMachineTarget = Convert.ToBoolean(obj["IsMachineTarget"] ?? false),
                            IsPreflightOnly = Convert.ToBoolean(obj["IsPreflightOnly"] ?? false),
                            NotifyUser = Convert.ToBoolean(obj["NotifyUser"] ?? false),
                            UserUIExperience = Convert.ToBoolean(obj["UserUIExperience"] ?? false),
                            OverrideServiceWindow = Convert.ToBoolean(obj["OverrideServiceWindow"] ?? false),
                            RebootOutsideServiceWindow = Convert.ToBoolean(obj["RebootOutsideServiceWindow"] ?? false),
                            AppDTs = obj["AppDTs"]?.ToString() ?? "",
                            ContentSize = Convert.ToInt64(obj["ContentSize"] ?? 0),
                            DeploymentReport = obj["DeploymentReport"]?.ToString() ?? "",
                            EnforcePreference = obj["EnforcePreference"]?.ToString() ?? "",
                            EstimatedInstallTime = Convert.ToInt32(obj["EstimatedInstallTime"] ?? 0),
                            FileTypes = obj["FileTypes"]?.ToString() ?? "",
                            HighImpactDeployment = Convert.ToBoolean(obj["HighImpactDeployment"] ?? false),
                            InformativeUrl = obj["InformativeUrl"]?.ToString() ?? "",
                            InProgressActions = obj["InProgressActions"]?.ToString() ?? "",
                            PercentComplete = Convert.ToInt32(obj["PercentComplete"] ?? 0),
                            ReleaseDate = obj["ReleaseDate"] as DateTime?,
                            SupersessionState = obj["SupersessionState"]?.ToString() ?? "",
                            Type = obj["Type"]?.ToString() ?? ""
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException($"retrieve applications by name '{applicationName}'", ex);
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
                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "CCM_Application", "Install");
                
                inParams["Id"] = applicationId;
                inParams["IsMachineTarget"] = true;
                inParams["EnforcePreference"] = 0; // Immediate
                inParams["Priority"] = "High";
                inParams["IsRebootIfNeeded"] = false;

                var outParams = InvokeWMIClassMethod(namespacePath, "CCM_Application", "Install", inParams);
                return WMIHelper.IsMethodCallSuccessful(outParams);
            }
            catch (Exception ex)
            {
                throw CreateException($"install application {applicationId}", ex);
            }
        }
    }
}