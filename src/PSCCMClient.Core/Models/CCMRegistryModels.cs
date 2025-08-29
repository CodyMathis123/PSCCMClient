using System;
namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a registry property from Configuration Manager
    /// </summary>
    public class CCMRegistryProperty
    {
        /// <summary>
        /// Computer name where the property was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Registry hive
        /// </summary>
        public string Hive { get; set; } = "";

        /// <summary>
        /// Registry subkey path
        /// </summary>
        public string SubKey { get; set; } = "";

        /// <summary>
        /// Value name
        /// </summary>
        public string ValueName { get; set; } = "";

        /// <summary>
        /// Value data (actual object - could be string, uint, ulong, string[], byte[])
        /// </summary>
        public object? Value { get; set; }

        /// <summary>
        /// Value type (String, DWORD, QWORD, MultiString, Binary, etc.)
        /// </summary>
        public string ValueType { get; set; } = "";
    }

    /// <summary>
    /// Represents provisioning mode status from Configuration Manager
    /// </summary>
    public class CCMProvisioningMode
    {
        /// <summary>
        /// Computer name where the status was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Whether provisioning mode is enabled
        /// </summary>
        public bool ProvisioningMode { get; set; }

        /// <summary>
        /// When provisioning mode was started
        /// </summary>
        public DateTime? ProvisioningModeStartTime { get; set; }
    }

    /// <summary>
    /// Represents primary user information from Configuration Manager
    /// </summary>
    public class CCMPrimaryUser
    {
        /// <summary>
        /// Computer name where the user was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// Primary user name
        /// </summary>
        public string PrimaryUser { get; set; } = "";

        /// <summary>
        /// Sources that determined the primary user
        /// </summary>
        public string Sources { get; set; } = "";
    }

    /// <summary>
    /// Represents CCM execution startup time information
    /// </summary>
    public class CCMExecStartupTime
    {
        /// <summary>
        /// Computer name where the info was retrieved from
        /// </summary>
        public string ComputerName { get; set; } = "";

        /// <summary>
        /// CCM service startup time
        /// </summary>
        public DateTime StartupTime { get; set; }

        /// <summary>
        /// Service status
        /// </summary>
        public string ServiceStatus { get; set; } = "";
    }
}