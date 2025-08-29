using System;
using System.Management;

namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Represents a Configuration Manager package
    /// </summary>
    public class CCMPackage
    {
        public string? PackageID { get; set; }
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? Publisher { get; set; }
        public string? Language { get; set; }
        public DateTime? LastRunTime { get; set; }
        public string? ProgramName { get; set; }
        public string? ComputerName { get; set; }

        /// <summary>
        /// Creates a CCMPackage instance from a WMI Management Object
        /// </summary>
        /// <param name="managementObject">The WMI object containing package data</param>
        /// <returns>A new CCMPackage instance</returns>
        public static CCMPackage FromManagementObject(ManagementObject managementObject)
        {
            return new CCMPackage
            {
                PackageID = managementObject["PKG_PackageID"]?.ToString(),
                Name = managementObject["PKG_Name"]?.ToString(),
                Version = managementObject["PKG_SourceVersion"]?.ToString(),
                Publisher = managementObject["PKG_Publisher"]?.ToString(),
                Language = managementObject["PKG_Language"]?.ToString(),
                LastRunTime = ParseDateTime(managementObject["PRG_LastRunTime"]),
                ProgramName = managementObject["PRG_ProgramName"]?.ToString()
            };
        }

        private static DateTime? ParseDateTime(object? dateTimeValue)
        {
            if (dateTimeValue == null) return null;
            
            var dateString = dateTimeValue.ToString();
            if (string.IsNullOrWhiteSpace(dateString)) return null;

            // Handle WMI datetime format (YYYYMMDDHHMMSS.000000+000)
            if (dateString.Length >= 14 && DateTime.TryParseExact(
                dateString.Substring(0, 14), 
                "yyyyMMddHHmmss", 
                null, 
                System.Globalization.DateTimeStyles.None, 
                out DateTime result))
            {
                return result;
            }

            // Fallback to standard DateTime parsing
            return DateTime.TryParse(dateString, out DateTime fallbackResult) ? (DateTime?)fallbackResult : null;
        }
    }
}