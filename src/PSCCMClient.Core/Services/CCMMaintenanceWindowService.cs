using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager maintenance windows
    /// </summary>
    public class CCMMaintenanceWindowService : CCMServiceBase
    {
        public CCMMaintenanceWindowService(string computerName) : base(computerName)
        {
        }

        /// <summary>
        /// Gets maintenance windows
        /// </summary>
        /// <returns>List of maintenance windows</returns>
        public async Task<List<CCMMaintenanceWindow>> GetMaintenanceWindowsAsync()
        {
            return await Task.Run(() => GetMaintenanceWindows());
        }

        /// <summary>
        /// Gets maintenance windows (synchronous)
        /// </summary>
        /// <returns>List of maintenance windows</returns>
        public List<CCMMaintenanceWindow> GetMaintenanceWindows()
        {
            var windows = new List<CCMMaintenanceWindow>();

            try
            {
                // Get the time zone first
                string timeZone = GetTimeZone();

                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_ServiceWindow");

                foreach (ManagementObject obj in results)
                {
                    var startTime = ConvertWmiDateTime(obj["StartTime"]);
                    var endTime = ConvertWmiDateTime(obj["EndTime"]);
                    
                    windows.Add(new CCMMaintenanceWindow
                    {
                        ComputerName = ActualComputerName,
                        TimeZone = timeZone,
                        StartTime = startTime?.ToUniversalTime(),
                        EndTime = endTime?.ToUniversalTime(),
                        Duration = Convert.ToInt32(obj["Duration"] ?? 0),
                        DurationDescription = GetDurationDescription(Convert.ToInt32(obj["Duration"] ?? 0)),
                        MWID = obj["ID"]?.ToString() ?? "",
                        Type = GetMaintenanceWindowType(obj["Type"])
                    });
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve maintenance windows", ex);
            }

            return windows;
        }

        /// <summary>
        /// Gets service windows
        /// </summary>
        /// <returns>List of service windows</returns>
        public async Task<List<CCMServiceWindow>> GetServiceWindowsAsync()
        {
            return await Task.Run(() => GetServiceWindows());
        }

        /// <summary>
        /// Gets service windows (synchronous)
        /// </summary>
        /// <returns>List of service windows</returns>
        public List<CCMServiceWindow> GetServiceWindows()
        {
            var windows = new List<CCMServiceWindow>();

            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\Policy\\Machine\\ActualConfig");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_ServiceWindow");

                foreach (ManagementObject obj in results)
                {
                    windows.Add(new CCMServiceWindow
                    {
                        ComputerName = ActualComputerName,
                        Schedules = obj["Schedules"]?.ToString() ?? "",
                        ServiceWindowID = obj["ServiceWindowID"]?.ToString() ?? "",
                        ServiceWindowType = GetServiceWindowType(obj["ServiceWindowType"])
                    });
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve service windows", ex);
            }

            return windows;
        }

        /// <summary>
        /// Gets current window available time
        /// </summary>
        /// <returns>Available time information</returns>
        public async Task<CCMCurrentWindowAvailableTime?> GetCurrentWindowAvailableTimeAsync()
        {
            return await Task.Run(() => GetCurrentWindowAvailableTime());
        }

        /// <summary>
        /// Gets current window available time (synchronous)
        /// </summary>
        /// <returns>Available time information</returns>
        public CCMCurrentWindowAvailableTime? GetCurrentWindowAvailableTime()
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_ServiceWindowManager");

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("GetCurrentWindowAvailableTime");
                    var outParams = obj.InvokeMethod("GetCurrentWindowAvailableTime", inParams, null);

                    if (outParams != null)
                    {
                        return new CCMCurrentWindowAvailableTime
                        {
                            ComputerName = ActualComputerName,
                            AvailableTime = Convert.ToInt32(outParams["AvailableTime"] ?? 0),
                            WindowType = Convert.ToInt32(outParams["WindowType"] ?? 0),
                            ReturnValue = Convert.ToInt32(outParams["ReturnValue"] ?? 0)
                        };
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException("get current window available time", ex);
            }

            return null;
        }

        /// <summary>
        /// Tests if a maintenance window is available now
        /// </summary>
        /// <returns>True if a window is available</returns>
        public async Task<bool> TestIsWindowAvailableNowAsync()
        {
            return await Task.Run(() => TestIsWindowAvailableNow());
        }

        /// <summary>
        /// Tests if a maintenance window is available now (synchronous)
        /// </summary>
        /// <returns>True if a window is available</returns>
        public bool TestIsWindowAvailableNow()
        {
            try
            {
                var currentTime = DateTime.UtcNow;
                var windows = GetMaintenanceWindows();

                foreach (var window in windows)
                {
                    if (window.StartTime.HasValue && 
                        window.EndTime.HasValue &&
                        currentTime >= window.StartTime.Value && 
                        currentTime <= window.EndTime.Value)
                    {
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException("test window availability", ex);
            }

            return false;
        }

        private string GetTimeZone()
        {
            try
            {
                using var results = QueryWMIObjects("root\\cimv2", "SELECT Caption FROM Win32_TimeZone");
                foreach (ManagementObject obj in results)
                {
                    return obj["Caption"]?.ToString() ?? "";
                }
            }
            catch
            {
                // Fallback to local time zone if WMI query fails
                return TimeZoneInfo.Local.DisplayName;
            }
            return "";
        }

        private static string GetDurationDescription(int durationInSeconds)
        {
            var timeSpan = TimeSpan.FromSeconds(durationInSeconds);
            
            if (timeSpan.TotalDays >= 1)
            {
                return $"{(int)timeSpan.TotalDays} day(s) {timeSpan.Hours:D2}:{timeSpan.Minutes:D2}:{timeSpan.Seconds:D2}";
            }
            
            return $"{timeSpan.Hours:D2}:{timeSpan.Minutes:D2}:{timeSpan.Seconds:D2}";
        }

        private static string GetMaintenanceWindowType(object? typeValue)
        {
            if (typeValue == null) return "Unknown";

            return Convert.ToInt32(typeValue) switch
            {
                1 => "All Deployment Service Window",
                2 => "Program Service Window",
                3 => "Reboot Required Service Window",
                4 => "Software Update Service Window",
                5 => "Task Sequences Service Window",
                6 => "Corresponds to non-working hours",
                _ => "Unknown"
            };
        }

        private static string GetServiceWindowType(object? typeValue)
        {
            if (typeValue == null) return "Unknown";

            return Convert.ToInt32(typeValue) switch
            {
                1 => "All Deployment Service Window",
                2 => "Program Service Window",
                3 => "Reboot Required Service Window",
                4 => "Software Update Service Window",
                5 => "Task Sequences Service Window",
                6 => "Corresponds to non-working hours",
                _ => "Unknown"
            };
        }
    }
}