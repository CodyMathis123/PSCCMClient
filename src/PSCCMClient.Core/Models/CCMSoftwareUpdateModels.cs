namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a software update from Configuration Manager
    /// </summary>
    public class CCMSoftwareUpdate
    {
        /// <summary>
        /// Computer name where the update was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Article ID of the update
        /// </summary>
        public string ArticleID { get; set; } = "";

        /// <summary>
        /// Bulletin ID of the update
        /// </summary>
        public string BulletinID { get; set; } = "";

        /// <summary>
        /// Compliance state of the update
        /// </summary>
        public string ComplianceState { get; set; } = "";

        /// <summary>
        /// Content size in bytes
        /// </summary>
        public long ContentSize { get; set; }

        /// <summary>
        /// Deadline for the update
        /// </summary>
        public DateTime? Deadline { get; set; }

        /// <summary>
        /// Description of the update
        /// </summary>
        public string Description { get; set; } = "";

        /// <summary>
        /// Error code if any
        /// </summary>
        public int ErrorCode { get; set; }

        /// <summary>
        /// Evaluation state of the update
        /// </summary>
        public string EvaluationState { get; set; } = "";

        /// <summary>
        /// Whether this is an exclusive update
        /// </summary>
        public bool ExclusiveUpdate { get; set; }

        /// <summary>
        /// Full name of the update
        /// </summary>
        public string FullName { get; set; } = "";

        /// <summary>
        /// Whether this is an upgrade
        /// </summary>
        public bool IsUpgrade { get; set; }

        /// <summary>
        /// Maximum execution time in minutes
        /// </summary>
        public int MaxExecutionTime { get; set; }

        /// <summary>
        /// Name of the update
        /// </summary>
        public string Name { get; set; } = "";

        /// <summary>
        /// Next user scheduled time
        /// </summary>
        public DateTime? NextUserScheduledTime { get; set; }

        /// <summary>
        /// Whether to notify the user
        /// </summary>
        public bool NotifyUser { get; set; }

        /// <summary>
        /// Whether to override service windows
        /// </summary>
        public bool OverrideServiceWindows { get; set; }

        /// <summary>
        /// Percent complete
        /// </summary>
        public int PercentComplete { get; set; }

        /// <summary>
        /// Publisher of the update
        /// </summary>
        public string Publisher { get; set; } = "";

        /// <summary>
        /// Whether reboot is allowed outside service windows
        /// </summary>
        public bool RebootOutsideServiceWindows { get; set; }

        /// <summary>
        /// Restart deadline
        /// </summary>
        public DateTime? RestartDeadline { get; set; }

        /// <summary>
        /// Start time of the update
        /// </summary>
        public DateTime? StartTime { get; set; }

        /// <summary>
        /// Update identifier
        /// </summary>
        public string UpdateID { get; set; } = "";

        /// <summary>
        /// URL for more information
        /// </summary>
        public string URL { get; set; } = "";

        /// <summary>
        /// User UI experience setting
        /// </summary>
        public bool UserUIExperience { get; set; }
    }

    /// <summary>
    /// Represents a software update group from Configuration Manager
    /// </summary>
    public class CCMSoftwareUpdateGroup
    {
        /// <summary>
        /// Computer name where the group was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Name of the update group
        /// </summary>
        public string GroupName { get; set; } = "";

        /// <summary>
        /// Description of the update group
        /// </summary>
        public string Description { get; set; } = "";

        /// <summary>
        /// Number of updates in the group
        /// </summary>
        public int UpdateCount { get; set; }
    }

    /// <summary>
    /// Represents software update settings from Configuration Manager
    /// </summary>
    public class CCMSoftwareUpdateSettings
    {
        /// <summary>
        /// Computer name where the settings were retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// WSUS location server
        /// </summary>
        public string WSUSLocationServer { get; set; } = "";

        /// <summary>
        /// WSUS location server port
        /// </summary>
        public int WSUSLocationServerPort { get; set; }

        /// <summary>
        /// WSUS status server
        /// </summary>
        public string WSUSStatusServer { get; set; } = "";

        /// <summary>
        /// WSUS status server port
        /// </summary>
        public int WSUSStatusServerPort { get; set; }

        /// <summary>
        /// Group policy refresh delay
        /// </summary>
        public int GroupPolicyRefreshDelay { get; set; }

        /// <summary>
        /// Scan suppression setting
        /// </summary>
        public bool ScanSuppression { get; set; }

        /// <summary>
        /// Compliance evaluation schedule
        /// </summary>
        public string ComplianceEvaluationSchedule { get; set; } = "";

        /// <summary>
        /// Scheduled installation day (0-7, where 0=everyday, 1=Sunday, etc.)
        /// </summary>
        public int ScheduledInstallationDay { get; set; }

        /// <summary>
        /// Scheduled installation time (in hours)
        /// </summary>
        public int ScheduledInstallationTime { get; set; }
    }
}