using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager application management operations
    /// </summary>
    public interface ICCMApplicationService
    {
        /// <summary>
        /// Gets all applications from the Configuration Manager client (asynchronous)
        /// </summary>
        /// <returns>A collection of CCMApplication objects</returns>
        Task<IEnumerable<CCMApplication>> GetApplicationsAsync();

        /// <summary>
        /// Gets applications by name from the Configuration Manager client (asynchronous)
        /// </summary>
        /// <param name="applicationName">The name of the application to search for</param>
        /// <returns>A collection of CCMApplication objects matching the name</returns>
        Task<IEnumerable<CCMApplication>> GetApplicationsByNameAsync(string applicationName);

        /// <summary>
        /// Gets all applications from the Configuration Manager client (synchronous)
        /// </summary>
        /// <returns>A collection of CCMApplication objects</returns>
        IEnumerable<CCMApplication> GetApplications();

        /// <summary>
        /// Gets applications by name from the Configuration Manager client (synchronous)
        /// </summary>
        /// <param name="applicationName">The name of the application to search for</param>
        /// <returns>A collection of CCMApplication objects matching the name</returns>
        IEnumerable<CCMApplication> GetApplicationsByName(string applicationName);

        /// <summary>
        /// Installs an application (asynchronous)
        /// </summary>
        /// <param name="applicationId">Application ID</param>
        /// <param name="revision">Application revision</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">Enforcement preference (0=Immediate, 1=NonBusinessHours, 2=AdminSchedule)</param>
        /// <param name="priority">Priority level (Foreground, High, Normal, Low)</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        Task<bool> InstallApplicationAsync(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);

        /// <summary>
        /// Installs an application using a CCMApplication object (asynchronous)
        /// </summary>
        /// <param name="application">CCMApplication object</param>
        /// <param name="enforcePreference">Enforcement preference</param>
        /// <param name="priority">Priority level</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        Task<bool> InstallApplicationAsync(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);

        /// <summary>
        /// Installs an application (synchronous)
        /// </summary>
        /// <param name="applicationId">Application ID</param>
        /// <param name="revision">Application revision</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">Enforcement preference</param>
        /// <param name="priority">Priority level</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        bool InstallApplication(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);

        /// <summary>
        /// Installs an application using a CCMApplication object (synchronous)
        /// </summary>
        /// <param name="application">CCMApplication object</param>
        /// <param name="enforcePreference">Enforcement preference</param>
        /// <param name="priority">Priority level</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        bool InstallApplication(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);

        /// <summary>
        /// Uninstalls an application (asynchronous)
        /// </summary>
        /// <param name="applicationId">Application ID</param>
        /// <param name="revision">Application revision</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">Enforcement preference</param>
        /// <param name="priority">Priority level</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        Task<bool> UninstallApplicationAsync(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);

        /// <summary>
        /// Uninstalls an application using a CCMApplication object (asynchronous)
        /// </summary>
        /// <param name="application">CCMApplication object</param>
        /// <param name="enforcePreference">Enforcement preference</param>
        /// <param name="priority">Priority level</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        Task<bool> UninstallApplicationAsync(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);

        /// <summary>
        /// Uninstalls an application (synchronous)
        /// </summary>
        /// <param name="applicationId">Application ID</param>
        /// <param name="revision">Application revision</param>
        /// <param name="isMachineTarget">Whether this is a machine-targeted application</param>
        /// <param name="enforcePreference">Enforcement preference</param>
        /// <param name="priority">Priority level</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        bool UninstallApplication(string applicationId, string revision, bool isMachineTarget = true, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);

        /// <summary>
        /// Uninstalls an application using a CCMApplication object (synchronous)
        /// </summary>
        /// <param name="application">CCMApplication object</param>
        /// <param name="enforcePreference">Enforcement preference</param>
        /// <param name="priority">Priority level</param>
        /// <param name="isRebootIfNeeded">Whether to reboot if needed</param>
        /// <returns>True if successful</returns>
        bool UninstallApplication(CCMApplication application, 
            int enforcePreference = 0, string priority = "High", bool isRebootIfNeeded = false);
    }
}