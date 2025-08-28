namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a maintenance window from Configuration Manager
    /// </summary>
    public class CCMMaintenanceWindow
    {
        /// <summary>
        /// Computer name where the window was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Name of the maintenance window
        /// </summary>
        public string Name { get; set; } = "";

        /// <summary>
        /// Description of the maintenance window
        /// </summary>
        public string Description { get; set; } = "";

        /// <summary>
        /// Start time of the window
        /// </summary>
        public DateTime? StartTime { get; set; }

        /// <summary>
        /// End time of the window
        /// </summary>
        public DateTime? EndTime { get; set; }

        /// <summary>
        /// Duration of the window in minutes
        /// </summary>
        public int Duration { get; set; }

        /// <summary>
        /// Type of service window
        /// </summary>
        public string ServiceWindowType { get; set; } = "";

        /// <summary>
        /// Service window schedules
        /// </summary>
        public string ServiceWindowSchedules { get; set; } = "";

        /// <summary>
        /// Whether the window is enabled
        /// </summary>
        public bool IsEnabled { get; set; }
    }

    /// <summary>
    /// Represents a service window from Configuration Manager
    /// </summary>
    public class CCMServiceWindow
    {
        /// <summary>
        /// Computer name where the window was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Service window ID
        /// </summary>
        public string ServiceWindowID { get; set; } = "";

        /// <summary>
        /// Name of the service window
        /// </summary>
        public string Name { get; set; } = "";

        /// <summary>
        /// Description of the service window
        /// </summary>
        public string Description { get; set; } = "";

        /// <summary>
        /// Start time of the window
        /// </summary>
        public string StartTime { get; set; } = "";

        /// <summary>
        /// End time of the window
        /// </summary>
        public string EndTime { get; set; } = "";

        /// <summary>
        /// Duration of the window in minutes
        /// </summary>
        public int Duration { get; set; }

        /// <summary>
        /// Recurrence type
        /// </summary>
        public int RecurrenceType { get; set; }

        /// <summary>
        /// Type of service window
        /// </summary>
        public string Type { get; set; } = "";

        /// <summary>
        /// Whether the window is enabled
        /// </summary>
        public bool IsEnabled { get; set; }
    }

    /// <summary>
    /// Represents current window available time information
    /// </summary>
    public class CCMCurrentWindowAvailableTime
    {
        /// <summary>
        /// Computer name where the info was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Available time in minutes
        /// </summary>
        public int AvailableTime { get; set; }

        /// <summary>
        /// Window type
        /// </summary>
        public int WindowType { get; set; }

        /// <summary>
        /// Return value from the WMI method
        /// </summary>
        public int ReturnValue { get; set; }
    }
}