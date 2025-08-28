using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager configuration baselines
    /// </summary>
    public class CCMBaselineService : CCMServiceBase
    {
        public CCMBaselineService(string computerName) : base(computerName)
        {
        }

        /// <summary>
        /// Gets configuration baselines from the client
        /// </summary>
        /// <param name="baselineName">Optional baseline name filter</param>
        /// <returns>List of configuration baselines</returns>
        public async Task<List<CCMBaseline>> GetBaselinesAsync(string? baselineName = null)
        {
            return await Task.Run(() => GetBaselines(baselineName));
        }

        /// <summary>
        /// Gets configuration baselines from the client (synchronous)
        /// </summary>
        /// <param name="baselineName">Optional baseline name filter</param>
        /// <returns>List of configuration baselines</returns>
        public List<CCMBaseline> GetBaselines(string? baselineName = null)
        {
            var baselines = new List<CCMBaseline>();
            
            var query = string.IsNullOrEmpty(baselineName)
                ? "SELECT * FROM SMS_DesiredConfiguration"
                : $"SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName = '{baselineName}'";

            try
            {
                var namespacePath = GetNamespacePath("root\\ccm\\dcm");
                using var results = QueryWMIObjects(namespacePath, query);

                foreach (ManagementObject obj in results)
                {
                    baselines.Add(new CCMBaseline
                    {
                        ComputerName = _computerName,
                        BaselineName = obj["DisplayName"]?.ToString() ?? "",
                        Version = obj["Version"]?.ToString() ?? "",
                        LastComplianceStatus = GetComplianceStatus(obj["LastComplianceStatus"]),
                        LastEvalTime = obj["LastEvalTime"] as DateTime?
                    });
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve baselines", ex);
            }

            return baselines;
        }

        /// <summary>
        /// Invokes evaluation of a configuration baseline
        /// </summary>
        /// <param name="baselineName">Name of the baseline to evaluate</param>
        /// <returns>True if evaluation was triggered successfully</returns>
        public async Task<bool> InvokeBaselineAsync(string baselineName)
        {
            return await Task.Run(() => InvokeBaseline(baselineName));
        }

        /// <summary>
        /// Invokes evaluation of a configuration baseline (synchronous)
        /// </summary>
        /// <param name="baselineName">Name of the baseline to evaluate</param>
        /// <returns>True if evaluation was triggered successfully</returns>
        public bool InvokeBaseline(string baselineName)
        {
            try
            {
                var query = $"SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName = '{baselineName}'";
                var namespacePath = GetNamespacePath("root\\ccm\\dcm");
                using var results = QueryWMIObjects(namespacePath, query);

                foreach (ManagementObject obj in results)
                {
                    // Build arguments for TriggerEvaluation method
                    var inParams = obj.GetMethodParameters("TriggerEvaluation");
                    
                    // Copy properties that exist
                    var propertyOptions = new[] { "IsEnforced", "IsMachineTarget", "Name", "PolicyType", "Version" };
                    foreach (var property in propertyOptions)
                    {
                        try
                        {
                            var value = obj[property];
                            if (value != null)
                            {
                                inParams[property] = value;
                            }
                        }
                        catch
                        {
                            // Property doesn't exist, skip it
                        }
                    }

                    var outParams = obj.InvokeMethod("TriggerEvaluation", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw CreateException($"invoke baseline '{baselineName}'", ex);
            }

            return false;
        }

        private static string GetComplianceStatus(object? statusValue)
        {
            if (statusValue == null) return "Unknown";

            return Convert.ToInt32(statusValue) switch
            {
                0 => "Non-Compliant",
                1 => "Compliant",
                2 => "Compliance State Unknown",
                4 => "Error",
                _ => "Unknown"
            };
        }
    }
}