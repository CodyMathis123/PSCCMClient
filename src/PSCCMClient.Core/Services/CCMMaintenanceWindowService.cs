using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager maintenance windows
    /// </summary>
    public class CCMMaintenanceWindowService
    {
        private readonly string _computerName;

        public CCMMaintenanceWindowService(string computerName)
        {
            _computerName = computerName ?? ".";
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", "SELECT * FROM CCM_ServiceWindow");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    windows.Add(new CCMMaintenanceWindow
                    {
                        ComputerName = _computerName,
                        Name = obj["Name"]?.ToString() ?? "",
                        Description = obj["Description"]?.ToString() ?? "",
                        StartTime = obj["StartTime"] as DateTime?,
                        EndTime = obj["EndTime"] as DateTime?,
                        Duration = Convert.ToInt32(obj["Duration"] ?? 0),
                        ServiceWindowType = GetServiceWindowType(obj["Type"]),
                        ServiceWindowSchedules = obj["ServiceWindowSchedules"]?.ToString() ?? "",
                        IsEnabled = Convert.ToBoolean(obj["IsEnabled"] ?? false)
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve maintenance windows from {_computerName}: {ex.Message}", ex);
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\Policy\Machine\ActualConfig", "SELECT * FROM CCM_ServiceWindow");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    windows.Add(new CCMServiceWindow
                    {
                        ComputerName = _computerName,
                        ServiceWindowID = obj["ServiceWindowID"]?.ToString() ?? "",
                        Name = obj["Name"]?.ToString() ?? "",
                        Description = obj["Description"]?.ToString() ?? "",
                        StartTime = obj["StartTime"]?.ToString() ?? "",
                        EndTime = obj["EndTime"]?.ToString() ?? "",
                        Duration = Convert.ToInt32(obj["Duration"] ?? 0),
                        RecurrenceType = Convert.ToInt32(obj["RecurrenceType"] ?? 0),
                        Type = GetServiceWindowType(obj["Type"]),
                        IsEnabled = Convert.ToBoolean(obj["IsEnabled"] ?? false)
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve service windows from {_computerName}: {ex.Message}", ex);
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", "SELECT * FROM CCM_ServiceWindowManager");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("GetCurrentWindowAvailableTime");
                    var outParams = obj.InvokeMethod("GetCurrentWindowAvailableTime", inParams, null);

                    if (outParams != null)
                    {
                        return new CCMCurrentWindowAvailableTime
                        {
                            ComputerName = _computerName,
                            AvailableTime = Convert.ToInt32(outParams["AvailableTime"] ?? 0),
                            WindowType = Convert.ToInt32(outParams["WindowType"] ?? 0),
                            ReturnValue = Convert.ToInt32(outParams["ReturnValue"] ?? 0)
                        };
                    }
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to get current window available time from {_computerName}: {ex.Message}", ex);
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
                var currentTime = DateTime.Now;
                var windows = GetMaintenanceWindows();

                foreach (var window in windows)
                {
                    if (window.IsEnabled && 
                        window.StartTime.HasValue && 
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
                throw new InvalidOperationException($"Failed to test window availability on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        private static string GetServiceWindowType(object? typeValue)
        {
            if (typeValue == null) return "Unknown";

            return Convert.ToInt32(typeValue) switch
            {
                1 => "All Deployments",
                2 => "Program",
                3 => "Reboot Required",
                4 => "Software Update",
                5 => "Task Sequence",
                6 => "Correspondence",
                _ => "Unknown"
            };
        }
    }
}