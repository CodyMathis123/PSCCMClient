using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager software updates
    /// </summary>
    public class CCMSoftwareUpdateService
    {
        private readonly string _computerName;

        public CCMSoftwareUpdateService(string computerName)
        {
            _computerName = computerName ?? ".";
        }

        /// <summary>
        /// Gets available software updates
        /// </summary>
        /// <param name="includeDefs">Include definition updates</param>
        /// <returns>List of software updates</returns>
        public async Task<List<CCMSoftwareUpdate>> GetSoftwareUpdatesAsync(bool includeDefs = false)
        {
            return await Task.Run(() => GetSoftwareUpdates(includeDefs));
        }

        /// <summary>
        /// Gets available software updates (synchronous)
        /// </summary>
        /// <param name="includeDefs">Include definition updates</param>
        /// <returns>List of software updates</returns>
        public List<CCMSoftwareUpdate> GetSoftwareUpdates(bool includeDefs = false)
        {
            var updates = new List<CCMSoftwareUpdate>();

            var filter = includeDefs
                ? "ComplianceState=0"
                : "NOT (Name LIKE '%Definition%' OR Name Like 'Security Intelligence Update%') and ComplianceState=0";

            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", 
                    $"SELECT * FROM CCM_SoftwareUpdate WHERE {filter}");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    updates.Add(new CCMSoftwareUpdate
                    {
                        ComputerName = _computerName,
                        ArticleID = obj["ArticleID"]?.ToString() ?? "",
                        BulletinID = obj["BulletinID"]?.ToString() ?? "",
                        ComplianceState = GetComplianceState(obj["ComplianceState"]),
                        ContentSize = Convert.ToInt64(obj["ContentSize"] ?? 0),
                        Deadline = obj["Deadline"] as DateTime?,
                        Description = obj["Description"]?.ToString() ?? "",
                        ErrorCode = Convert.ToInt32(obj["ErrorCode"] ?? 0),
                        EvaluationState = GetEvaluationState(obj["EvaluationState"]),
                        ExclusiveUpdate = Convert.ToBoolean(obj["ExclusiveUpdate"] ?? false),
                        FullName = obj["FullName"]?.ToString() ?? "",
                        IsUpgrade = Convert.ToBoolean(obj["IsUpgrade"] ?? false),
                        MaxExecutionTime = Convert.ToInt32(obj["MaxExecutionTime"] ?? 0),
                        Name = obj["Name"]?.ToString() ?? "",
                        NextUserScheduledTime = obj["NextUserScheduledTime"] as DateTime?,
                        NotifyUser = Convert.ToBoolean(obj["NotifyUser"] ?? false),
                        OverrideServiceWindows = Convert.ToBoolean(obj["OverrideServiceWindows"] ?? false),
                        PercentComplete = Convert.ToInt32(obj["PercentComplete"] ?? 0),
                        Publisher = obj["Publisher"]?.ToString() ?? "",
                        RebootOutsideServiceWindows = Convert.ToBoolean(obj["RebootOutsideServiceWindows"] ?? false),
                        RestartDeadline = obj["RestartDeadline"] as DateTime?,
                        StartTime = obj["StartTime"] as DateTime?,
                        UpdateID = obj["UpdateID"]?.ToString() ?? "",
                        URL = obj["URL"]?.ToString() ?? "",
                        UserUIExperience = Convert.ToBoolean(obj["UserUIExperience"] ?? false)
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve software updates from {_computerName}: {ex.Message}", ex);
            }

            return updates;
        }

        /// <summary>
        /// Gets software update groups
        /// </summary>
        /// <returns>List of software update groups</returns>
        public async Task<List<CCMSoftwareUpdateGroup>> GetSoftwareUpdateGroupsAsync()
        {
            return await Task.Run(() => GetSoftwareUpdateGroups());
        }

        /// <summary>
        /// Gets software update groups (synchronous)
        /// </summary>
        /// <returns>List of software update groups</returns>
        public List<CCMSoftwareUpdateGroup> GetSoftwareUpdateGroups()
        {
            var groups = new List<CCMSoftwareUpdateGroup>();

            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", "SELECT * FROM CCM_UpdateStore");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    groups.Add(new CCMSoftwareUpdateGroup
                    {
                        ComputerName = _computerName,
                        GroupName = obj["Name"]?.ToString() ?? "",
                        Description = obj["Description"]?.ToString() ?? "",
                        UpdateCount = Convert.ToInt32(obj["UpdateCount"] ?? 0)
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve software update groups from {_computerName}: {ex.Message}", ex);
            }

            return groups;
        }

        /// <summary>
        /// Gets software update settings
        /// </summary>
        /// <returns>Software update settings</returns>
        public async Task<CCMSoftwareUpdateSettings?> GetSoftwareUpdateSettingsAsync()
        {
            return await Task.Run(() => GetSoftwareUpdateSettings());
        }

        /// <summary>
        /// Gets software update settings (synchronous)
        /// </summary>
        /// <returns>Software update settings</returns>
        public CCMSoftwareUpdateSettings? GetSoftwareUpdateSettings()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\Policy\Machine\ActualConfig", "SELECT * FROM CCM_SoftwareUpdatesClientConfig");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMSoftwareUpdateSettings
                    {
                        ComputerName = _computerName,
                        WSUSLocationServer = obj["WSUSLocationServer"]?.ToString() ?? "",
                        WSUSLocationServerPort = Convert.ToInt32(obj["WSUSLocationServerPort"] ?? 0),
                        WSUSStatusServer = obj["WSUSStatusServer"]?.ToString() ?? "",
                        WSUSStatusServerPort = Convert.ToInt32(obj["WSUSStatusServerPort"] ?? 0),
                        GroupPolicyRefreshDelay = Convert.ToInt32(obj["GroupPolicyRefreshDelay"] ?? 0),
                        ScanSuppression = Convert.ToBoolean(obj["ScanSuppression"] ?? false),
                        ComplianceEvaluationSchedule = obj["ComplianceEvaluationSchedule"]?.ToString() ?? "",
                        ScheduledInstallationDay = Convert.ToInt32(obj["ScheduledInstallationDay"] ?? 0),
                        ScheduledInstallationTime = Convert.ToInt32(obj["ScheduledInstallationTime"] ?? 0)
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve software update settings from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Invokes software update installation
        /// </summary>
        /// <param name="updateID">Update ID to install</param>
        /// <returns>True if successful</returns>
        public async Task<bool> InvokeSoftwareUpdateAsync(string updateID)
        {
            return await Task.Run(() => InvokeSoftwareUpdate(updateID));
        }

        /// <summary>
        /// Invokes software update installation (synchronous)
        /// </summary>
        /// <param name="updateID">Update ID to install</param>
        /// <returns>True if successful</returns>
        public bool InvokeSoftwareUpdate(string updateID)
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", 
                    $"SELECT * FROM CCM_SoftwareUpdate WHERE UpdateID = '{updateID}'");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("Install");
                    var outParams = obj.InvokeMethod("Install", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to invoke software update '{updateID}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        private static string GetEvaluationState(object? stateValue)
        {
            if (stateValue == null) return "Unknown";

            return Convert.ToInt32(stateValue) switch
            {
                23 => "WaitForOrchestration",
                22 => "WaitPresModeOff",
                21 => "WaitingRetry",
                20 => "PendingUpdate",
                19 => "PendingUserLogoff",
                18 => "WaitUserReconnect",
                17 => "WaitJobUserLogon",
                16 => "WaitUserLogoff",
                15 => "WaitUserLogon",
                14 => "WaitServiceWindow",
                13 => "Error",
                12 => "InstallComplete",
                11 => "Verifying",
                10 => "WaitReboot",
                9 => "PendingHardReboot",
                8 => "PendingSoftReboot",
                7 => "Installing",
                6 => "WaitInstall",
                5 => "Downloading",
                4 => "PreDownload",
                3 => "Detecting",
                2 => "Submitted",
                1 => "Available",
                0 => "None",
                _ => "Unknown"
            };
        }

        private static string GetComplianceState(object? stateValue)
        {
            if (stateValue == null) return "Unknown";

            return Convert.ToInt32(stateValue) switch
            {
                0 => "NotPresent",
                1 => "Present",
                2 => "PresenceUnknown/NotApplicable",
                3 => "EvaluationError",
                4 => "NotEvaluated",
                5 => "NotUpdated",
                6 => "NotConfigured",
                _ => "Unknown"
            };
        }
    }
}