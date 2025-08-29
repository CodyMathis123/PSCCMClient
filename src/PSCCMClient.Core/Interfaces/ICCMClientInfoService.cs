using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager client information operations
    /// </summary>
    public interface ICCMClientInfoService
    {
        /// <summary>
        /// Gets client information (asynchronous)
        /// </summary>
        /// <returns>CCMClientInfo object</returns>
        Task<CCMClientInfo> GetClientInfoAsync();

        /// <summary>
        /// Gets client information (synchronous)
        /// </summary>
        /// <returns>CCMClientInfo object</returns>
        CCMClientInfo GetClientInfo();

        /// <summary>
        /// Gets client version (asynchronous)
        /// </summary>
        /// <returns>Client version string</returns>
        Task<string> GetClientVersionAsync();

        /// <summary>
        /// Gets client version (synchronous)
        /// </summary>
        /// <returns>Client version string</returns>
        string GetClientVersion();

        /// <summary>
        /// Gets client directory path (asynchronous)
        /// </summary>
        /// <returns>Client directory path</returns>
        Task<string> GetClientDirectoryAsync();

        /// <summary>
        /// Gets client directory path (synchronous)
        /// </summary>
        /// <returns>Client directory path</returns>
        string GetClientDirectory();

        /// <summary>
        /// Gets primary user (asynchronous)
        /// </summary>
        /// <returns>Primary user name</returns>
        Task<string> GetPrimaryUserAsync();

        /// <summary>
        /// Gets primary user (synchronous)
        /// </summary>
        /// <returns>Primary user name</returns>
        string GetPrimaryUser();

        /// <summary>
        /// Gets execution startup time (asynchronous)
        /// </summary>
        /// <returns>Startup time or null</returns>
        Task<DateTime?> GetExecStartupTimeAsync();

        /// <summary>
        /// Gets execution startup time (synchronous)
        /// </summary>
        /// <returns>Startup time or null</returns>
        DateTime? GetExecStartupTime();

        /// <summary>
        /// Checks if client is on internet (asynchronous)
        /// </summary>
        /// <returns>True if on internet</returns>
        Task<bool> IsClientOnInternetAsync();

        /// <summary>
        /// Checks if client is on internet (synchronous)
        /// </summary>
        /// <returns>True if on internet</returns>
        bool IsClientOnInternet();

        /// <summary>
        /// Checks if client is always on internet (asynchronous)
        /// </summary>
        /// <returns>True if always on internet</returns>
        Task<bool> IsClientAlwaysOnInternetAsync();

        /// <summary>
        /// Checks if client is always on internet (synchronous)
        /// </summary>
        /// <returns>True if always on internet</returns>
        bool IsClientAlwaysOnInternet();

        /// <summary>
        /// Sets client always on internet setting (asynchronous)
        /// </summary>
        /// <param name="alwaysOnInternet">Whether to enable always on internet</param>
        /// <returns>True if successful</returns>
        Task<bool> SetClientAlwaysOnInternetAsync(bool alwaysOnInternet);

        /// <summary>
        /// Sets client always on internet setting (synchronous)
        /// </summary>
        /// <param name="alwaysOnInternet">Whether to enable always on internet</param>
        /// <returns>True if successful</returns>
        bool SetClientAlwaysOnInternet(bool alwaysOnInternet);

        /// <summary>
        /// Gets last heartbeat information (asynchronous)
        /// </summary>
        /// <returns>CCMInventoryInfo or null</returns>
        Task<CCMInventoryInfo?> GetLastHeartbeatAsync();

        /// <summary>
        /// Gets last heartbeat information (synchronous)
        /// </summary>
        /// <returns>CCMInventoryInfo or null</returns>
        CCMInventoryInfo? GetLastHeartbeat();

        /// <summary>
        /// Gets last hardware inventory information (asynchronous)
        /// </summary>
        /// <returns>CCMInventoryInfo or null</returns>
        Task<CCMInventoryInfo?> GetLastHardwareInventoryAsync();

        /// <summary>
        /// Gets last hardware inventory information (synchronous)
        /// </summary>
        /// <returns>CCMInventoryInfo or null</returns>
        CCMInventoryInfo? GetLastHardwareInventory();

        /// <summary>
        /// Gets last software inventory information (asynchronous)
        /// </summary>
        /// <returns>CCMInventoryInfo or null</returns>
        Task<CCMInventoryInfo?> GetLastSoftwareInventoryAsync();

        /// <summary>
        /// Gets last software inventory information (synchronous)
        /// </summary>
        /// <returns>CCMInventoryInfo or null</returns>
        CCMInventoryInfo? GetLastSoftwareInventory();
    }
}