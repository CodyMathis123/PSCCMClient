using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager cache
    /// </summary>
    public class CCMCacheService
    {
        private readonly string _computerName;

        public CCMCacheService(string computerName)
        {
            _computerName = computerName ?? ".";
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\SoftMgmtAgent", "SELECT * FROM CacheConfig");
                using var results = searcher.Get();

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
                throw new InvalidOperationException($"Failed to retrieve cache info from {_computerName}: {ex.Message}", ex);
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\SoftMgmtAgent", "SELECT * FROM CacheInfoEx");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    content.Add(new CCMCacheContent
                    {
                        ComputerName = _computerName,
                        ContentId = obj["ContentId"]?.ToString() ?? "",
                        ContentVersion = obj["ContentVersion"]?.ToString() ?? "",
                        Location = obj["Location"]?.ToString() ?? "",
                        Size = Convert.ToInt64(obj["ContentSize"] ?? 0),
                        LastReferenceTime = obj["LastReferenceTime"] as DateTime?,
                        ReferenceCount = Convert.ToInt32(obj["ReferenceCount"] ?? 0),
                        ContentType = Convert.ToInt32(obj["ContentType"] ?? 0),
                        CacheId = obj["CacheId"]?.ToString() ?? ""
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve cache content from {_computerName}: {ex.Message}", ex);
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\SoftMgmtAgent", "SELECT * FROM CacheConfig");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    obj["Location"] = location;
                    obj.Put();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to set cache location on {_computerName}: {ex.Message}", ex);
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\SoftMgmtAgent", "SELECT * FROM CacheConfig");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    obj["Size"] = sizeInMB;
                    obj.Put();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to set cache size on {_computerName}: {ex.Message}", ex);
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\SoftMgmtAgent", 
                    $"SELECT * FROM CacheInfoEx WHERE ContentId = '{contentId}'");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    obj.Delete();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to remove cache content '{contentId}' from {_computerName}: {ex.Message}", ex);
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
        /// Repairs cache location by recreating the directory structure (synchronous)
        /// </summary>
        /// <returns>True if successful</returns>
        public bool RepairCacheLocation()
        {
            try
            {
                var cacheInfo = GetCacheInfo();
                if (cacheInfo != null && !string.IsNullOrEmpty(cacheInfo.Location))
                {
                    if (!Directory.Exists(cacheInfo.Location))
                    {
                        Directory.CreateDirectory(cacheInfo.Location);
                    }
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to repair cache location on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }
    }
}