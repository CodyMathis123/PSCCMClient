using System;
namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a Configuration Manager configuration baseline
    /// </summary>
    public class CCMBaseline
    {
        /// <summary>
        /// Computer name where the baseline was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Display name of the configuration baseline
        /// </summary>
        public string BaselineName { get; set; } = "";

        /// <summary>
        /// Version of the configuration baseline
        /// </summary>
        public string Version { get; set; } = "";

        /// <summary>
        /// Last compliance status of the baseline
        /// </summary>
        public string LastComplianceStatus { get; set; } = "";

        /// <summary>
        /// Last evaluation time of the baseline
        /// </summary>
        public DateTime? LastEvalTime { get; set; }
    }
}