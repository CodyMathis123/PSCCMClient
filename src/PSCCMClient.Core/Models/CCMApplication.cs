using System;
namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a Configuration Manager application
    /// </summary>
    public class CCMApplication
    {
        /// <summary>
        /// Computer name where the application was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Application name
        /// </summary>
        public string Name { get; set; } = "";

        /// <summary>
        /// Full application name
        /// </summary>
        public string FullName { get; set; } = "";

        /// <summary>
        /// Software version
        /// </summary>
        public string SoftwareVersion { get; set; } = "";

        /// <summary>
        /// Publisher
        /// </summary>
        public string Publisher { get; set; } = "";

        /// <summary>
        /// Description
        /// </summary>
        public string Description { get; set; } = "";

        /// <summary>
        /// Application ID
        /// </summary>
        public string Id { get; set; } = "";

        /// <summary>
        /// Revision
        /// </summary>
        public string Revision { get; set; } = "";

        /// <summary>
        /// Evaluation state
        /// </summary>
        public string EvaluationState { get; set; } = "";

        /// <summary>
        /// Error code
        /// </summary>
        public string ErrorCode { get; set; } = "";

        /// <summary>
        /// Allowed actions
        /// </summary>
        public string AllowedActions { get; set; } = "";

        /// <summary>
        /// Resolved state
        /// </summary>
        public string ResolvedState { get; set; } = "";

        /// <summary>
        /// Install state
        /// </summary>
        public string InstallState { get; set; } = "";

        /// <summary>
        /// Applicability state
        /// </summary>
        public string ApplicabilityState { get; set; } = "";

        /// <summary>
        /// Configure state
        /// </summary>
        public string ConfigureState { get; set; } = "";

        /// <summary>
        /// Last evaluation time
        /// </summary>
        public DateTime? LastEvalTime { get; set; }

        /// <summary>
        /// Last install time
        /// </summary>
        public DateTime? LastInstallTime { get; set; }

        /// <summary>
        /// Start time
        /// </summary>
        public DateTime? StartTime { get; set; }

        /// <summary>
        /// Deadline
        /// </summary>
        public DateTime? Deadline { get; set; }

        /// <summary>
        /// Next user scheduled time
        /// </summary>
        public DateTime? NextUserScheduledTime { get; set; }

        /// <summary>
        /// Is machine target
        /// </summary>
        public bool IsMachineTarget { get; set; }

        /// <summary>
        /// Is preflight only
        /// </summary>
        public bool IsPreflightOnly { get; set; }

        /// <summary>
        /// Notify user
        /// </summary>
        public bool NotifyUser { get; set; }

        /// <summary>
        /// User UI experience
        /// </summary>
        public bool UserUIExperience { get; set; }

        /// <summary>
        /// Override service window
        /// </summary>
        public bool OverrideServiceWindow { get; set; }

        /// <summary>
        /// Reboot outside service window
        /// </summary>
        public bool RebootOutsideServiceWindow { get; set; }

        /// <summary>
        /// Application deployment types
        /// </summary>
        public string AppDTs { get; set; } = "";

        /// <summary>
        /// Content size
        /// </summary>
        public long ContentSize { get; set; }

        /// <summary>
        /// Deployment report
        /// </summary>
        public string DeploymentReport { get; set; } = "";

        /// <summary>
        /// Enforce preference
        /// </summary>
        public string EnforcePreference { get; set; } = "";

        /// <summary>
        /// Estimated install time
        /// </summary>
        public int EstimatedInstallTime { get; set; }

        /// <summary>
        /// File types
        /// </summary>
        public string FileTypes { get; set; } = "";

        /// <summary>
        /// High impact deployment
        /// </summary>
        public bool HighImpactDeployment { get; set; }

        /// <summary>
        /// Informative URL
        /// </summary>
        public string InformativeUrl { get; set; } = "";

        /// <summary>
        /// In progress actions
        /// </summary>
        public string InProgressActions { get; set; } = "";

        /// <summary>
        /// Percent complete
        /// </summary>
        public int PercentComplete { get; set; }

        /// <summary>
        /// Release date
        /// </summary>
        public DateTime? ReleaseDate { get; set; }

        /// <summary>
        /// Supersession state
        /// </summary>
        public string SupersessionState { get; set; } = "";

        /// <summary>
        /// Type
        /// </summary>
        public string Type { get; set; } = "";

        /// <summary>
        /// Icon (optional)
        /// </summary>
        public string? Icon { get; set; }
    }
}