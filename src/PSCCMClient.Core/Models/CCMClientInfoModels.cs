namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents comprehensive client information from Configuration Manager
    /// </summary>
    public class CCMClientInfo
    {
        /// <summary>
        /// Computer name
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Site code the client is assigned to
        /// </summary>
        public string SiteCode { get; set; } = "";

        /// <summary>
        /// Current management point
        /// </summary>
        public string CurrentManagementPoint { get; set; } = "";

        /// <summary>
        /// Current software update point
        /// </summary>
        public string CurrentSoftwareUpdatePoint { get; set; } = "";

        /// <summary>
        /// Cache location
        /// </summary>
        public string CacheLocation { get; set; } = "";

        /// <summary>
        /// Cache size in MB
        /// </summary>
        public int CacheSize { get; set; }

        /// <summary>
        /// Client directory
        /// </summary>
        public string ClientDirectory { get; set; } = "";

        /// <summary>
        /// DNS suffix
        /// </summary>
        public string DNSSuffix { get; set; } = "";

        /// <summary>
        /// Client GUID
        /// </summary>
        public string GUID { get; set; } = "";

        /// <summary>
        /// Client GUID change date
        /// </summary>
        public DateTime? ClientGUIDChangeDate { get; set; }

        /// <summary>
        /// Previous GUID
        /// </summary>
        public string PreviousGUID { get; set; } = "";

        /// <summary>
        /// Client version
        /// </summary>
        public string ClientVersion { get; set; } = "";

        /// <summary>
        /// DDR last cycle started date
        /// </summary>
        public DateTime? DDRLastCycleStartedDate { get; set; }

        /// <summary>
        /// DDR last report date
        /// </summary>
        public DateTime? DDRLastReportDate { get; set; }

        /// <summary>
        /// Hardware inventory last cycle started date
        /// </summary>
        public DateTime? HINVLastCycleStartedDate { get; set; }

        /// <summary>
        /// Hardware inventory last report date
        /// </summary>
        public DateTime? HINVLastReportDate { get; set; }

        /// <summary>
        /// Software inventory last cycle started date
        /// </summary>
        public DateTime? SINVLastCycleStartedDate { get; set; }

        /// <summary>
        /// Software inventory last report date
        /// </summary>
        public DateTime? SINVLastReportDate { get; set; }

        /// <summary>
        /// Log directory
        /// </summary>
        public string LogDirectory { get; set; } = "";

        /// <summary>
        /// Log max size
        /// </summary>
        public int LogMaxSize { get; set; }

        /// <summary>
        /// Log max history
        /// </summary>
        public int LogMaxHistory { get; set; }

        /// <summary>
        /// Log level
        /// </summary>
        public int LogLevel { get; set; }

        /// <summary>
        /// Log enabled
        /// </summary>
        public bool LogEnabled { get; set; }

        /// <summary>
        /// Is client on internet
        /// </summary>
        public bool IsClientOnInternet { get; set; }

        /// <summary>
        /// Is client always on internet
        /// </summary>
        public bool IsClientAlwaysOnInternet { get; set; }
    }

    /// <summary>
    /// Represents GUID information from Configuration Manager client
    /// </summary>
    public class CCMGuidInfo
    {
        /// <summary>
        /// Client GUID
        /// </summary>
        public string GUID { get; set; } = "";

        /// <summary>
        /// Client GUID change date
        /// </summary>
        public DateTime? ClientGUIDChangeDate { get; set; }

        /// <summary>
        /// Previous GUID
        /// </summary>
        public string PreviousGUID { get; set; } = "";
    }

    /// <summary>
    /// Represents inventory information from Configuration Manager client
    /// </summary>
    public class CCMInventoryInfo
    {
        /// <summary>
        /// Last cycle started date
        /// </summary>
        public DateTime? LastCycleStartedDate { get; set; }

        /// <summary>
        /// Last report date
        /// </summary>
        public DateTime? LastReportDate { get; set; }
    }

    /// <summary>
    /// Represents logging configuration from Configuration Manager client
    /// </summary>
    public class CCMLoggingConfiguration
    {
        /// <summary>
        /// Computer name where the configuration was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Log directory
        /// </summary>
        public string LogDirectory { get; set; } = "";

        /// <summary>
        /// Log max size
        /// </summary>
        public int LogMaxSize { get; set; }

        /// <summary>
        /// Log max history
        /// </summary>
        public int LogMaxHistory { get; set; }

        /// <summary>
        /// Log level
        /// </summary>
        public int LogLevel { get; set; }

        /// <summary>
        /// Log enabled
        /// </summary>
        public bool LogEnabled { get; set; }
    }
}