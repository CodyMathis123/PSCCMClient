using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager cache operations
    /// </summary>
    public interface ICCMCacheService
    {
        /// <summary>
        /// Gets cache information (asynchronous)
        /// </summary>
        /// <returns>CCMCacheInfo or null</returns>
        Task<CCMCacheInfo?> GetCacheInfoAsync();

        /// <summary>
        /// Gets cache information (synchronous)
        /// </summary>
        /// <returns>CCMCacheInfo or null</returns>
        CCMCacheInfo? GetCacheInfo();

        /// <summary>
        /// Gets cache content (asynchronous)
        /// </summary>
        /// <returns>List of CCMCacheContent objects</returns>
        Task<List<CCMCacheContent>> GetCacheContentAsync();

        /// <summary>
        /// Gets cache content (synchronous)
        /// </summary>
        /// <returns>List of CCMCacheContent objects</returns>
        List<CCMCacheContent> GetCacheContent();

        /// <summary>
        /// Sets cache location (asynchronous)
        /// </summary>
        /// <param name="location">New cache location path</param>
        /// <returns>True if successful</returns>
        Task<bool> SetCacheLocationAsync(string location);

        /// <summary>
        /// Sets cache location (synchronous)
        /// </summary>
        /// <param name="location">New cache location path</param>
        /// <returns>True if successful</returns>
        bool SetCacheLocation(string location);

        /// <summary>
        /// Sets cache size (asynchronous)
        /// </summary>
        /// <param name="sizeInMB">New cache size in MB</param>
        /// <returns>True if successful</returns>
        Task<bool> SetCacheSizeAsync(int sizeInMB);

        /// <summary>
        /// Sets cache size (synchronous)
        /// </summary>
        /// <param name="sizeInMB">New cache size in MB</param>
        /// <returns>True if successful</returns>
        bool SetCacheSize(int sizeInMB);

        /// <summary>
        /// Removes cache content (asynchronous)
        /// </summary>
        /// <param name="contentId">Content ID to remove</param>
        /// <returns>True if successful</returns>
        Task<bool> RemoveCacheContentAsync(string contentId);

        /// <summary>
        /// Removes cache content (synchronous)
        /// </summary>
        /// <param name="contentId">Content ID to remove</param>
        /// <returns>True if successful</returns>
        bool RemoveCacheContent(string contentId);

        /// <summary>
        /// Repairs cache location (asynchronous)
        /// </summary>
        /// <returns>True if successful</returns>
        Task<bool> RepairCacheLocationAsync();

        /// <summary>
        /// Repairs cache location (synchronous)
        /// </summary>
        /// <returns>True if successful</returns>
        bool RepairCacheLocation();
    }
}