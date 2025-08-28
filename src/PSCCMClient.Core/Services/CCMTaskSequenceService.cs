using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager task sequences
    /// </summary>
    public class CCMTaskSequenceService
    {
        private readonly string _computerName;

        public CCMTaskSequenceService(string computerName)
        {
            _computerName = computerName ?? ".";
        }

        /// <summary>
        /// Gets available task sequences
        /// </summary>
        /// <returns>List of task sequences</returns>
        public async Task<List<CCMTaskSequence>> GetTaskSequencesAsync()
        {
            return await Task.Run(() => GetTaskSequences());
        }

        /// <summary>
        /// Gets available task sequences (synchronous)
        /// </summary>
        /// <returns>List of task sequences</returns>
        public List<CCMTaskSequence> GetTaskSequences()
        {
            var taskSequences = new List<CCMTaskSequence>();

            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", "SELECT * FROM CCM_Program WHERE PackageType = 4");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    taskSequences.Add(new CCMTaskSequence
                    {
                        ComputerName = _computerName,
                        PackageID = obj["PackageID"]?.ToString() ?? "",
                        ProgramID = obj["ProgramID"]?.ToString() ?? "",
                        Name = obj["Name"]?.ToString() ?? "",
                        Description = obj["Description"]?.ToString() ?? "",
                        ScheduledMessageID = obj["ScheduledMessageID"]?.ToString() ?? "",
                        Deadline = obj["Deadline"] as DateTime?,
                        StartTime = obj["StartTime"] as DateTime?,
                        State = obj["State"]?.ToString() ?? "",
                        RunningState = obj["RunningState"]?.ToString() ?? "",
                        LastRunTime = obj["LastRunTime"] as DateTime?,
                        NextRunTime = obj["NextRunTime"] as DateTime?,
                        RepeatRunBehavior = obj["RepeatRunBehavior"]?.ToString() ?? "",
                        RerunBehavior = obj["RerunBehavior"]?.ToString() ?? ""
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve task sequences from {_computerName}: {ex.Message}", ex);
            }

            return taskSequences;
        }

        /// <summary>
        /// Gets a specific task sequence by package and program ID
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>Task sequence or null if not found</returns>
        public async Task<CCMTaskSequence?> GetTaskSequenceAsync(string packageId, string programId)
        {
            return await Task.Run(() => GetTaskSequence(packageId, programId));
        }

        /// <summary>
        /// Gets a specific task sequence by package and program ID (synchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>Task sequence or null if not found</returns>
        public CCMTaskSequence? GetTaskSequence(string packageId, string programId)
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", 
                    $"SELECT * FROM CCM_Program WHERE PackageID = '{packageId}' AND ProgramID = '{programId}' AND PackageType = 4");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    return new CCMTaskSequence
                    {
                        ComputerName = _computerName,
                        PackageID = obj["PackageID"]?.ToString() ?? "",
                        ProgramID = obj["ProgramID"]?.ToString() ?? "",
                        Name = obj["Name"]?.ToString() ?? "",
                        Description = obj["Description"]?.ToString() ?? "",
                        ScheduledMessageID = obj["ScheduledMessageID"]?.ToString() ?? "",
                        Deadline = obj["Deadline"] as DateTime?,
                        StartTime = obj["StartTime"] as DateTime?,
                        State = obj["State"]?.ToString() ?? "",
                        RunningState = obj["RunningState"]?.ToString() ?? "",
                        LastRunTime = obj["LastRunTime"] as DateTime?,
                        NextRunTime = obj["NextRunTime"] as DateTime?,
                        RepeatRunBehavior = obj["RepeatRunBehavior"]?.ToString() ?? "",
                        RerunBehavior = obj["RerunBehavior"]?.ToString() ?? ""
                    };
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve task sequence '{packageId}\\{programId}' from {_computerName}: {ex.Message}", ex);
            }

            return null;
        }

        /// <summary>
        /// Invokes a task sequence
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>True if successful</returns>
        public async Task<bool> InvokeTaskSequenceAsync(string packageId, string programId)
        {
            return await Task.Run(() => InvokeTaskSequence(packageId, programId));
        }

        /// <summary>
        /// Invokes a task sequence (synchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>True if successful</returns>
        public bool InvokeTaskSequence(string packageId, string programId)
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", 
                    $"SELECT * FROM CCM_Program WHERE PackageID = '{packageId}' AND ProgramID = '{programId}' AND PackageType = 4");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("Execute");
                    var outParams = obj.InvokeMethod("Execute", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to invoke task sequence '{packageId}\\{programId}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        /// <summary>
        /// Gets task sequences by name
        /// </summary>
        /// <param name="name">Task sequence name to search for</param>
        /// <returns>List of matching task sequences</returns>
        public async Task<List<CCMTaskSequence>> GetTaskSequencesByNameAsync(string name)
        {
            return await Task.Run(() => GetTaskSequencesByName(name));
        }

        /// <summary>
        /// Gets task sequences by name (synchronous)
        /// </summary>
        /// <param name="name">Task sequence name to search for</param>
        /// <returns>List of matching task sequences</returns>
        public List<CCMTaskSequence> GetTaskSequencesByName(string name)
        {
            var taskSequences = new List<CCMTaskSequence>();

            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\CCM\ClientSDK", 
                    $"SELECT * FROM CCM_Program WHERE Name LIKE '%{name}%' AND PackageType = 4");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    taskSequences.Add(new CCMTaskSequence
                    {
                        ComputerName = _computerName,
                        PackageID = obj["PackageID"]?.ToString() ?? "",
                        ProgramID = obj["ProgramID"]?.ToString() ?? "",
                        Name = obj["Name"]?.ToString() ?? "",
                        Description = obj["Description"]?.ToString() ?? "",
                        ScheduledMessageID = obj["ScheduledMessageID"]?.ToString() ?? "",
                        Deadline = obj["Deadline"] as DateTime?,
                        StartTime = obj["StartTime"] as DateTime?,
                        State = obj["State"]?.ToString() ?? "",
                        RunningState = obj["RunningState"]?.ToString() ?? "",
                        LastRunTime = obj["LastRunTime"] as DateTime?,
                        NextRunTime = obj["NextRunTime"] as DateTime?,
                        RepeatRunBehavior = obj["RepeatRunBehavior"]?.ToString() ?? "",
                        RerunBehavior = obj["RerunBehavior"]?.ToString() ?? ""
                    });
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to retrieve task sequences with name '{name}' from {_computerName}: {ex.Message}", ex);
            }

            return taskSequences;
        }
    }
}