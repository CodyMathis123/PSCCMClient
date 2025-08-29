using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager maintenance window operations
    /// </summary>
    public interface ICCMMaintenanceWindowService
    {
        /// <summary>
        /// Gets maintenance windows (asynchronous)
        /// </summary>
        /// <returns>List of CCMMaintenanceWindow objects</returns>
        Task<List<CCMMaintenanceWindow>> GetMaintenanceWindowsAsync();

        /// <summary>
        /// Gets maintenance windows (synchronous)
        /// </summary>
        /// <returns>List of CCMMaintenanceWindow objects</returns>
        List<CCMMaintenanceWindow> GetMaintenanceWindows();

        /// <summary>
        /// Gets service windows (asynchronous)
        /// </summary>
        /// <returns>List of CCMServiceWindow objects</returns>
        Task<List<CCMServiceWindow>> GetServiceWindowsAsync();

        /// <summary>
        /// Gets service windows (synchronous)
        /// </summary>
        /// <returns>List of CCMServiceWindow objects</returns>
        List<CCMServiceWindow> GetServiceWindows();

        /// <summary>
        /// Gets current window available time (asynchronous)
        /// </summary>
        /// <returns>CCMCurrentWindowAvailableTime or null</returns>
        Task<CCMCurrentWindowAvailableTime?> GetCurrentWindowAvailableTimeAsync();

        /// <summary>
        /// Gets current window available time (synchronous)
        /// </summary>
        /// <returns>CCMCurrentWindowAvailableTime or null</returns>
        CCMCurrentWindowAvailableTime? GetCurrentWindowAvailableTime();

        /// <summary>
        /// Tests if a window is available now (asynchronous)
        /// </summary>
        /// <returns>True if window is available</returns>
        Task<bool> TestIsWindowAvailableNowAsync();

        /// <summary>
        /// Tests if a window is available now (synchronous)
        /// </summary>
        /// <returns>True if window is available</returns>
        bool TestIsWindowAvailableNow();
    }
}