using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager cache
    /// </summary>
    public class CCMCacheService : CCMServiceBase
    {
        public CCMCacheService(string computerName) : base(computerName)
        {
        }

        /// <summary>
        /// Gets cache information from the client
        /// </summary>
        /// <returns>Cache information</returns>
        public async Task<CCMCacheInfo?> GetCacheInfoAsync()
        {
            return await Task.Run(() => GetCacheInfo());
        }

        /// <summary>
        /// Gets cache information from the client (synchronous)
        /// </summary>
        /// <returns>Cache information</returns>
        public CCMCacheInfo? GetCacheInfo()
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\SoftMgmtAgent");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CacheConfig");

                foreach (ManagementObject obj in results)
                {
                    return new CCMCacheInfo
                    {
                        ComputerName = _computerName,
                        Location = obj["Location"]?.ToString() ?? "",
                        Size = Convert.ToInt32(obj["Size"] ?? 0)
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve cache info", ex);
            }

            return null;
        }

        /// <summary>
        /// Gets cache content from the client
        /// </summary>
        /// <returns>List of cached content</returns>
        public async Task<List<CCMCacheContent>> GetCacheContentAsync()
        {
            return await Task.Run(() => GetCacheContent());
        }

        /// <summary>
        /// Gets cache content from the client (synchronous)
        /// </summary>
        /// <returns>List of cached content</returns>
        public List<CCMCacheContent> GetCacheContent()
        {
            var content = new List<CCMCacheContent>();

            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\SoftMgmtAgent");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CacheInfoEx");

                foreach (ManagementObject obj in results)
                {
                    content.Add(new CCMCacheContent
                    {
                        ComputerName = _computerName,
                        ContentId = obj["ContentId"]?.ToString() ?? "",
                        ContentVersion = obj["ContentVer"]?.ToString() ?? "",
                        Location = obj["Location"]?.ToString() ?? "",
                        LastReferenceTime = obj["LastReferenced"] as DateTime?,
                        ReferenceCount = Convert.ToInt32(obj["ReferenceCount"] ?? 0),
                        ContentSize = Convert.ToInt64(obj["ContentSize"] ?? 0),
                        ContentComplete = Convert.ToBoolean(obj["ContentComplete"] ?? false),
                        CacheElementId = obj["CacheID"]?.ToString() ?? ""
                    });
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve cache content", ex);
            }

            return content;
        }

        /// <summary>
        /// Sets the cache location
        /// </summary>
        /// <param name="location">New cache location</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetCacheLocationAsync(string location)
        {
            return await Task.Run(() => SetCacheLocation(location));
        }

        /// <summary>
        /// Sets the cache location (synchronous)
        /// </summary>
        /// <param name="location">New cache location</param>
        /// <returns>True if successful</returns>
        public bool SetCacheLocation(string location)
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\SoftMgmtAgent");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CacheConfig");

                foreach (ManagementObject obj in results)
                {
                    obj["Location"] = location;
                    obj.Put();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw CreateException("set cache location", ex);
            }

            return false;
        }

        /// <summary>
        /// Sets the cache size
        /// </summary>
        /// <param name="sizeInMB">New cache size in MB</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetCacheSizeAsync(int sizeInMB)
        {
            return await Task.Run(() => SetCacheSize(sizeInMB));
        }

        /// <summary>
        /// Sets the cache size (synchronous)
        /// </summary>
        /// <param name="sizeInMB">New cache size in MB</param>
        /// <returns>True if successful</returns>
        public bool SetCacheSize(int sizeInMB)
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\SoftMgmtAgent");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CacheConfig");

                foreach (ManagementObject obj in results)
                {
                    obj["Size"] = sizeInMB;
                    obj.Put();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw CreateException("set cache size", ex);
            }

            return false;
        }

        /// <summary>
        /// Removes cache content by content ID
        /// </summary>
        /// <param name="contentId">Content ID to remove</param>
        /// <returns>True if successful</returns>
        public async Task<bool> RemoveCacheContentAsync(string contentId)
        {
            return await Task.Run(() => RemoveCacheContent(contentId));
        }

        /// <summary>
        /// Removes cache content by content ID (synchronous)
        /// </summary>
        /// <param name="contentId">Content ID to remove</param>
        /// <returns>True if successful</returns>
        public bool RemoveCacheContent(string contentId)
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\SoftMgmtAgent");
                using var results = QueryWMIObjects(namespacePath, $"SELECT * FROM CacheInfoEx WHERE ContentId = '{contentId}'");

                foreach (ManagementObject obj in results)
                {
                    obj.Delete();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw CreateException($"remove cache content '{contentId}'", ex);
            }

            return false;
        }

        /// <summary>
        /// Repairs cache location by recreating the directory structure
        /// </summary>
        /// <returns>True if successful</returns>
        public async Task<bool> RepairCacheLocationAsync()
        {
            return await Task.Run(() => RepairCacheLocation());
        }

        /// <summary>
        /// Repairs cache location by fixing path issues and recreating directory structure (synchronous)
        /// </summary>
        /// <returns>True if successful</returns>
        public bool RepairCacheLocation()
        {
            try
            {
                var cacheInfo = GetCacheInfo();
                if (cacheInfo != null && !string.IsNullOrEmpty(cacheInfo.Location))
                {
                    string currentLocation = cacheInfo.Location;
                    // Fix common path issues like the PowerShell version: double backslashes and duplicate ccmcache
                    string newLocation = currentLocation
                        .Replace("\\\\", "\\")  // Replace double backslashes
                        .Replace("ccmcache\\ccmcache", "ccmcache"); // Fix duplicate ccmcache
                    
                    // Use regex pattern like PowerShell: -replace '(ccmcache\\?)+', 'ccmcache'
                    newLocation = System.Text.RegularExpressions.Regex.Replace(newLocation, @"(ccmcache\\?)+", "ccmcache");

                    if (!newLocation.Equals(currentLocation, StringComparison.OrdinalIgnoreCase))
                    {
                        // Path was repaired, set the new location
                        if (!SetCacheLocation(newLocation))
                        {
                            return false;
                        }
                    }

                    // Ensure the directory exists
                    if (!Directory.Exists(newLocation))
                    {
                        Directory.CreateDirectory(newLocation);
                    }
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw CreateException("repair cache location", ex);
            }

            return false;
        }
    }
}