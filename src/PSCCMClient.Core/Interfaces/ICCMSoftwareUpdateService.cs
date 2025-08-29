using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager software update operations
    /// </summary>
    public interface ICCMSoftwareUpdateService
    {
        /// <summary>
        /// Gets software updates (asynchronous)
        /// </summary>
        /// <param name="includeDefs">Whether to include definition updates</param>
        /// <returns>List of CCMSoftwareUpdate objects</returns>
        Task<List<CCMSoftwareUpdate>> GetSoftwareUpdatesAsync(bool includeDefs = false);

        /// <summary>
        /// Gets software updates (synchronous)
        /// </summary>
        /// <param name="includeDefs">Whether to include definition updates</param>
        /// <returns>List of CCMSoftwareUpdate objects</returns>
        List<CCMSoftwareUpdate> GetSoftwareUpdates(bool includeDefs = false);

        /// <summary>
        /// Gets software update groups (asynchronous)
        /// </summary>
        /// <returns>List of CCMSoftwareUpdateGroup objects</returns>
        Task<List<CCMSoftwareUpdateGroup>> GetSoftwareUpdateGroupsAsync();

        /// <summary>
        /// Gets software update groups (synchronous)
        /// </summary>
        /// <returns>List of CCMSoftwareUpdateGroup objects</returns>
        List<CCMSoftwareUpdateGroup> GetSoftwareUpdateGroups();

        /// <summary>
        /// Gets software update settings (asynchronous)
        /// </summary>
        /// <returns>CCMSoftwareUpdateSettings or null</returns>
        Task<CCMSoftwareUpdateSettings?> GetSoftwareUpdateSettingsAsync();

        /// <summary>
        /// Gets software update settings (synchronous)
        /// </summary>
        /// <returns>CCMSoftwareUpdateSettings or null</returns>
        CCMSoftwareUpdateSettings? GetSoftwareUpdateSettings();

        /// <summary>
        /// Invokes a software update (asynchronous)
        /// </summary>
        /// <param name="updateID">Update ID to invoke</param>
        /// <returns>True if successful</returns>
        Task<bool> InvokeSoftwareUpdateAsync(string updateID);

        /// <summary>
        /// Invokes a software update (synchronous)
        /// </summary>
        /// <param name="updateID">Update ID to invoke</param>
        /// <returns>True if successful</returns>
        bool InvokeSoftwareUpdate(string updateID);
    }
}