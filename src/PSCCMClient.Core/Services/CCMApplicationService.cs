using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;
using PSCCMClient.Core.Interfaces;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager applications
    /// </summary>
    public class CCMApplicationService : CCMServiceBase, ICCMApplicationService
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
                            ComputerName = ActualComputerName,
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
                            LastEvalTime = ConvertWmiDateTime(obj["LastEvalTime"]),
                            LastInstallTime = ConvertWmiDateTime(obj["LastInstallTime"]),
                            StartTime = ConvertWmiDateTime(obj["StartTime"]),
                            Deadline = ConvertWmiDateTime(obj["Deadline"]),
                            NextUserScheduledTime = ConvertWmiDateTime(obj["NextUserScheduledTime"]),
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
                            ReleaseDate = ConvertWmiDateTime(obj["ReleaseDate"]),
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
                            ComputerName = ActualComputerName,
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
                            LastEvalTime = ConvertWmiDateTime(obj["LastEvalTime"]),
                            LastInstallTime = ConvertWmiDateTime(obj["LastInstallTime"]),
                            StartTime = ConvertWmiDateTime(obj["StartTime"]),
                            Deadline = ConvertWmiDateTime(obj["Deadline"]),
                            NextUserScheduledTime = ConvertWmiDateTime(obj["NextUserScheduledTime"]),
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
                            ReleaseDate = ConvertWmiDateTime(obj["ReleaseDate"]),
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
        /// <param name="revision">The revision of the application</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">When to enforce the installation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Installation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the installation was initiated successfully</returns>
        public async Task<bool> InstallApplicationAsync(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            return await Task.Run(() => InstallApplication(applicationId, revision, isMachineTarget, enforcePreference, priority, isRebootIfNeeded));
        }

        /// <summary>
        /// Installs an application on the Configuration Manager client (simplified overload)
        /// This method requires getting the application first to obtain the revision
        /// </summary>
        /// <param name="application">The application object containing ID, revision, and machine target info</param>
        /// <param name="enforcePreference">When to enforce the installation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Installation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the installation was initiated successfully</returns>
        public async Task<bool> InstallApplicationAsync(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            return await InstallApplicationAsync(application.Id, application.Revision, application.IsMachineTarget, 
                enforcePreference, priority, isRebootIfNeeded);
        }

        /// <summary>
        /// Installs an application on the Configuration Manager client (synchronous)
        /// </summary>
        /// <param name="applicationId">The ID of the application to install</param>
        /// <param name="revision">The revision of the application</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">When to enforce the installation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Installation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the installation was initiated successfully</returns>
        public bool InstallApplication(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "CCM_Application", "Install");
                
                inParams["ID"] = applicationId;
                inParams["Revision"] = revision;
                inParams["IsMachineTarget"] = isMachineTarget;
                inParams["EnforcePreference"] = (uint)enforcePreference;
                inParams["Priority"] = priority;
                inParams["IsRebootIfNeeded"] = isRebootIfNeeded;

                var outParams = InvokeWMIClassMethod(namespacePath, "CCM_Application", "Install", inParams);
                return WMIHelper.IsMethodCallSuccessful(outParams);
            }
            catch (Exception ex)
            {
                throw CreateException($"install application {applicationId}", ex);
            }
        }

        /// <summary>
        /// Installs an application on the Configuration Manager client (simplified overload)
        /// This method requires getting the application first to obtain the revision
        /// </summary>
        /// <param name="application">The application object containing ID, revision, and machine target info</param>
        /// <param name="enforcePreference">When to enforce the installation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Installation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the installation was initiated successfully</returns>
        public bool InstallApplication(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            return InstallApplication(application.Id, application.Revision, application.IsMachineTarget, 
                enforcePreference, priority, isRebootIfNeeded);
        }

        /// <summary>
        /// Uninstalls an application on the Configuration Manager client
        /// </summary>
        /// <param name="applicationId">The ID of the application to uninstall</param>
        /// <param name="revision">The revision of the application</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">When to enforce the uninstallation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Uninstallation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the uninstallation was initiated successfully</returns>
        public async Task<bool> UninstallApplicationAsync(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            return await Task.Run(() => UninstallApplication(applicationId, revision, isMachineTarget, enforcePreference, priority, isRebootIfNeeded));
        }

        /// <summary>
        /// Uninstalls an application on the Configuration Manager client (simplified overload)
        /// This method requires getting the application first to obtain the revision
        /// </summary>
        /// <param name="application">The application object containing ID, revision, and machine target info</param>
        /// <param name="enforcePreference">When to enforce the uninstallation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Uninstallation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the uninstallation was initiated successfully</returns>
        public async Task<bool> UninstallApplicationAsync(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            return await UninstallApplicationAsync(application.Id, application.Revision, application.IsMachineTarget, 
                enforcePreference, priority, isRebootIfNeeded);
        }

        /// <summary>
        /// Uninstalls an application on the Configuration Manager client (synchronous)
        /// </summary>
        /// <param name="applicationId">The ID of the application to uninstall</param>
        /// <param name="revision">The revision of the application</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">When to enforce the uninstallation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Uninstallation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the uninstallation was initiated successfully</returns>
        public bool UninstallApplication(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                var inParams = WMIHelper.GetClassMethodParameters(namespacePath, "CCM_Application", "Uninstall");
                
                inParams["ID"] = applicationId;
                inParams["Revision"] = revision;
                inParams["IsMachineTarget"] = isMachineTarget;
                inParams["EnforcePreference"] = (uint)enforcePreference;
                inParams["Priority"] = priority;
                inParams["IsRebootIfNeeded"] = isRebootIfNeeded;

                var outParams = InvokeWMIClassMethod(namespacePath, "CCM_Application", "Uninstall", inParams);
                return WMIHelper.IsMethodCallSuccessful(outParams);
            }
            catch (Exception ex)
            {
                throw CreateException($"uninstall application {applicationId}", ex);
            }
        }

        /// <summary>
        /// Uninstalls an application on the Configuration Manager client (simplified overload)
        /// This method requires getting the application first to obtain the revision
        /// </summary>
        /// <param name="application">The application object containing ID, revision, and machine target info</param>
        /// <param name="enforcePreference">When to enforce the uninstallation (Immediate=0, NonBusinessHours=1, AdminSchedule=2)</param>
        /// <param name="priority">Uninstallation priority (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to allow reboot if needed</param>
        /// <returns>True if the uninstallation was initiated successfully</returns>
        public bool UninstallApplication(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false)
        {
            return UninstallApplication(application.Id, application.Revision, application.IsMachineTarget, 
                enforcePreference, priority, isRebootIfNeeded);
        }
    }
}