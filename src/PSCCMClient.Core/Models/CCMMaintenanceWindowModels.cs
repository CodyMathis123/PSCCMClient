using System;
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
        /// Time zone of the computer
        /// </summary>
        public string TimeZone { get; set; } = "";

        /// <summary>
        /// Start time of the window (in UTC)
        /// </summary>
        public DateTime? StartTime { get; set; }

        /// <summary>
        /// End time of the window (in UTC)
        /// </summary>
        public DateTime? EndTime { get; set; }

        /// <summary>
        /// Duration of the window in seconds
        /// </summary>
        public int Duration { get; set; }

        /// <summary>
        /// Human-readable duration description
        /// </summary>
        public string DurationDescription { get; set; } = "";

        /// <summary>
        /// Maintenance window ID
        /// </summary>
        public string MWID { get; set; } = "";

        /// <summary>
        /// Type of maintenance window
        /// </summary>
        public string Type { get; set; } = "";
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
        /// Service window schedules
        /// </summary>
        public string Schedules { get; set; } = "";

        /// <summary>
        /// Service window ID
        /// </summary>
        public string ServiceWindowID { get; set; } = "";

        /// <summary>
        /// Type of service window
        /// </summary>
        public string ServiceWindowType { get; set; } = "";
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