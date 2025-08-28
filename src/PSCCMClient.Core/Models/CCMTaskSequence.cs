namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a task sequence from Configuration Manager
    /// </summary>
    public class CCMTaskSequence
    {
        /// <summary>
        /// Computer name where the task sequence was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Package ID of the task sequence
        /// </summary>
        public string PackageID { get; set; } = "";

        /// <summary>
        /// Program ID of the task sequence
        /// </summary>
        public string ProgramID { get; set; } = "";

        /// <summary>
        /// Name of the task sequence
        /// </summary>
        public string Name { get; set; } = "";

        /// <summary>
        /// Description of the task sequence
        /// </summary>
        public string Description { get; set; } = "";

        /// <summary>
        /// Scheduled message ID
        /// </summary>
        public string ScheduledMessageID { get; set; } = "";

        /// <summary>
        /// Deadline for the task sequence
        /// </summary>
        public DateTime? Deadline { get; set; }

        /// <summary>
        /// Start time of the task sequence
        /// </summary>
        public DateTime? StartTime { get; set; }

        /// <summary>
        /// Current state of the task sequence
        /// </summary>
        public string State { get; set; } = "";

        /// <summary>
        /// Running state of the task sequence
        /// </summary>
        public string RunningState { get; set; } = "";

        /// <summary>
        /// Last run time of the task sequence
        /// </summary>
        public DateTime? LastRunTime { get; set; }

        /// <summary>
        /// Next run time of the task sequence
        /// </summary>
        public DateTime? NextRunTime { get; set; }

        /// <summary>
        /// Repeat run behavior
        /// </summary>
        public string RepeatRunBehavior { get; set; } = "";

        /// <summary>
        /// Rerun behavior
        /// </summary>
        public string RerunBehavior { get; set; } = "";
    }
}