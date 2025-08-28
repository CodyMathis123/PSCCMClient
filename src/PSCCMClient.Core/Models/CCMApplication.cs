using System.Management;

namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a Configuration Manager application
    /// </summary>
    public class CCMApplication
    {
        public string? Id { get; set; }
        public string? Name { get; set; }
        public string? Publisher { get; set; }
        public string? Version { get; set; }
        public string? Description { get; set; }
        public DateTime? InstallDate { get; set; }
        public string? InstallState { get; set; }
        public string? EvaluationState { get; set; }
        public bool IsMachineTarget { get; set; }
        public string? ComputerName { get; set; }

        /// <summary>
        /// Creates a CCMApplication instance from a WMI Management Object
        /// </summary>
        /// <param name="managementObject">The WMI object containing application data</param>
        /// <returns>A new CCMApplication instance</returns>
        public static CCMApplication FromManagementObject(ManagementObject managementObject)
        {
            return new CCMApplication
            {
                Id = managementObject["Id"]?.ToString(),
                Name = managementObject["Name"]?.ToString(),
                Publisher = managementObject["Publisher"]?.ToString(),
                Version = managementObject["SoftwareVersion"]?.ToString(),
                Description = managementObject["Description"]?.ToString(),
                InstallDate = ParseDateTime(managementObject["InstallDate"]),
                InstallState = managementObject["InstallState"]?.ToString(),
                EvaluationState = managementObject["EvaluationState"]?.ToString(),
                IsMachineTarget = Convert.ToBoolean(managementObject["IsMachineTarget"] ?? false)
            };
        }

        private static DateTime? ParseDateTime(object? dateTimeValue)
        {
            if (dateTimeValue == null) return null;
            
            var dateString = dateTimeValue.ToString();
            if (string.IsNullOrWhiteSpace(dateString)) return null;

            // Handle WMI datetime format (YYYYMMDDHHMMSS.000000+000)
            if (dateString.Length >= 14 && DateTime.TryParseExact(
                dateString[..14], 
                "yyyyMMddHHmmss", 
                null, 
                System.Globalization.DateTimeStyles.None, 
                out DateTime result))
            {
                return result;
            }

            // Fallback to standard DateTime parsing
            return DateTime.TryParse(dateString, out DateTime fallbackResult) ? fallbackResult : null;
        }
    }
}