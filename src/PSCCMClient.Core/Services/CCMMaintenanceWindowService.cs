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
                var namespacePath = GetNamespacePath("root\\CCM\\ClientSDK");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_ServiceWindow");

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
                throw CreateException("test window availability", ex);
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