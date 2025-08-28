namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents site information from Configuration Manager
    /// </summary>
    public class CCMSite
    {
        /// <summary>
        /// Computer name where the site was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Site code
        /// </summary>
        public string SiteCode { get; set; } = "";
    }

    /// <summary>
    /// Represents management point information from Configuration Manager
    /// </summary>
    public class CCMManagementPoint
    {
        /// <summary>
        /// Computer name where the MP was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Current management point server name
        /// </summary>
        public string CurrentManagementPoint { get; set; } = "";

        /// <summary>
        /// Version of the management point
        /// </summary>
        public string Version { get; set; } = "";

        /// <summary>
        /// Type of management point
        /// </summary>
        public int Type { get; set; }
    }

    /// <summary>
    /// Represents software update point information from Configuration Manager
    /// </summary>
    public class CCMSoftwareUpdatePoint
    {
        /// <summary>
        /// Computer name where the SUP was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Current software update point server name
        /// </summary>
        public string CurrentSoftwareUpdatePoint { get; set; } = "";

        /// <summary>
        /// Port number for the SUP
        /// </summary>
        public int Port { get; set; }

        /// <summary>
        /// Whether SSL is used
        /// </summary>
        public bool UseSSL { get; set; }
    }

    /// <summary>
    /// Represents DNS suffix information from Configuration Manager
    /// </summary>
    public class CCMDNSSuffix
    {
        /// <summary>
        /// Computer name where the DNS suffix was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// DNS suffix
        /// </summary>
        public string DNSSuffix { get; set; } = "";
    }
}