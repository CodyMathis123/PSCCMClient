namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents cache information from Configuration Manager client
    /// </summary>
    public class CCMCacheInfo
    {
        /// <summary>
        /// Computer name where the cache info was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Location of the cache directory
        /// </summary>
        public string Location { get; set; } = "";

        /// <summary>
        /// Size of the cache in MB
        /// </summary>
        public int Size { get; set; }
    }

    /// <summary>
    /// Represents cached content in Configuration Manager client
    /// </summary>
    public class CCMCacheContent
    {
        /// <summary>
        /// Computer name where the cache content was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Content identifier
        /// </summary>
        public string ContentId { get; set; } = "";

        /// <summary>
        /// Content version
        /// </summary>
        public string ContentVersion { get; set; } = "";

        /// <summary>
        /// Location of the cached content
        /// </summary>
        public string Location { get; set; } = "";

        /// <summary>
        /// Size of the cached content in bytes
        /// </summary>
        public long Size { get; set; }

        /// <summary>
        /// Last time the content was referenced
        /// </summary>
        public DateTime? LastReferenceTime { get; set; }

        /// <summary>
        /// Number of references to this content
        /// </summary>
        public int ReferenceCount { get; set; }

        /// <summary>
        /// Type of content (numeric value)
        /// </summary>
        public int ContentType { get; set; }

        /// <summary>
        /// Cache identifier
        /// </summary>
        public string CacheId { get; set; } = "";
    }
}