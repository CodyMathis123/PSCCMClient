using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for invoking Configuration Manager client actions
    /// </summary>
    public class CCMClientActionService : CCMServiceBase
    {
        public CCMClientActionService(string computerName) : base(computerName)
        {
        }

        /// <summary>
        /// Available client actions
        /// </summary>
        public enum ClientAction
        {
            HardwareInventory,
            FullHardwareInventory,
            SoftwareInventory,
            UpdateScan,
            UpdateEval,
            MachinePol,
            AppEval,
            DDR,
            RefreshDefaultMP,
            SourceUpdateMessage,
            SendUnsentStateMessage
        }

        /// <summary>
        /// Invokes a client action
        /// </summary>
        /// <param name="action">The action to invoke</param>
        /// <returns>True if successful</returns>
        public async Task<bool> InvokeClientActionAsync(ClientAction action)
        {
            return await Task.Run(() => InvokeClientAction(action));
        }

        /// <summary>
        /// Invokes a client action (synchronous)
        /// </summary>
        /// <param name="action">The action to invoke</param>
        /// <returns>True if successful</returns>
        public bool InvokeClientAction(ClientAction action)
        {
            try
            {
                var scheduleId = GetScheduleId(action);

                // Handle full hardware inventory special case
                if (action == ClientAction.FullHardwareInventory)
                {
                    // Delete hardware inventory history first
                    DeleteHardwareInventoryHistory();
                }

                // Use the base class to determine if it's a local computer and get the namespace path
                var namespacePath = GetNamespacePath("root\\ccm");
                var mgmtClass = new ManagementClass(namespacePath, "sms_client", null);
                var inParams = mgmtClass.GetMethodParameters("TriggerSchedule");
                inParams["sScheduleID"] = scheduleId;
                
                var outParams = mgmtClass.InvokeMethod("TriggerSchedule", inParams, null);
                return Convert.ToInt32(outParams["ReturnValue"]) == 0;
            }
            catch (Exception ex)
            {
                throw CreateException($"invoke client action '{action}'", ex);
            }
        }

        /// <summary>
        /// Invokes multiple client actions
        /// </summary>
        /// <param name="actions">The actions to invoke</param>
        /// <returns>Dictionary of action results</returns>
        public async Task<Dictionary<ClientAction, bool>> InvokeClientActionsAsync(params ClientAction[] actions)
        {
            return await Task.Run(() => InvokeClientActions(actions));
        }

        /// <summary>
        /// Invokes multiple client actions (synchronous)
        /// </summary>
        /// <param name="actions">The actions to invoke</param>
        /// <returns>Dictionary of action results</returns>
        public Dictionary<ClientAction, bool> InvokeClientActions(params ClientAction[] actions)
        {
            var results = new Dictionary<ClientAction, bool>();

            foreach (var action in actions)
            {
                try
                {
                    results[action] = InvokeClientAction(action);
                }
                catch
                {
                    results[action] = false;
                }
            }

            return results;
        }

        /// <summary>
        /// Triggers a custom schedule by ID
        /// </summary>
        /// <param name="scheduleId">The schedule ID to trigger</param>
        /// <returns>True if successful</returns>
        public async Task<bool> TriggerScheduleAsync(string scheduleId)
        {
            return await Task.Run(() => TriggerSchedule(scheduleId));
        }

        /// <summary>
        /// Triggers a custom schedule by ID (synchronous)
        /// </summary>
        /// <param name="scheduleId">The schedule ID to trigger</param>
        /// <returns>True if successful</returns>
        public bool TriggerSchedule(string scheduleId)
        {
            try
            {
                // Use the base class to determine if it's a local computer and get the namespace path
                var namespacePath = GetNamespacePath("root\\ccm");
                var mgmtClass = new ManagementClass(namespacePath, "sms_client", null);
                var inParams = mgmtClass.GetMethodParameters("TriggerSchedule");
                inParams["sScheduleID"] = scheduleId;
                
                var outParams = mgmtClass.InvokeMethod("TriggerSchedule", inParams, null);
                return Convert.ToInt32(outParams["ReturnValue"]) == 0;
            }
            catch (Exception ex)
            {
                throw CreateException($"trigger schedule '{scheduleId}'", ex);
            }
        }

        /// <summary>
        /// Resets client policy with default options
        /// </summary>
        /// <returns>True if successful</returns>
        public async Task<bool> ResetPolicyAsync()
        {
            return await Task.Run(() => ResetPolicy());
        }

        /// <summary>
        /// Resets client policy with specified type
        /// </summary>
        /// <param name="resetType">Reset type: "Purge" or "ForceFull"</param>
        /// <returns>True if successful</returns>
        public async Task<bool> ResetPolicyAsync(string resetType = "Purge")
        {
            return await Task.Run(() => ResetPolicy(resetType));
        }

        /// <summary>
        /// Resets client policy with specified type (synchronous)
        /// </summary>
        /// <param name="resetType">Reset type: "Purge" or "ForceFull"</param>
        /// <returns>True if successful</returns>
        public bool ResetPolicy(string resetType = "Purge")
        {
            try
            {
                uint uFlags = resetType.ToLowerInvariant() switch
                {
                    "purge" => 1,
                    "forcefull" => 0,
                    _ => 1
                };

                // For local computer, use different approach like PowerShell does
                bool isLocal = _computerName == "." || _computerName.Equals(Environment.MachineName, StringComparison.OrdinalIgnoreCase);
                
                string namespacePath = isLocal ? "root\\ccm" : $@"\\{_computerName}\root\ccm";
                
                // Use ManagementClass to call method on the class, not on instances
                using var mgmtClass = new ManagementClass(namespacePath, "sms_client", null);
                var inParams = mgmtClass.GetMethodParameters("ResetPolicy");
                inParams["uFlags"] = uFlags;
                
                var outParams = mgmtClass.InvokeMethod("ResetPolicy", inParams, null);
                return Convert.ToInt32(outParams["ReturnValue"]) == 0;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to reset policy on {_computerName}: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Resets client policy (legacy method for backward compatibility)
        /// </summary>
        /// <returns>True if successful</returns>
        public bool ResetPolicyLegacy()
        {
            return ResetPolicy("Purge");
        }

        private string GetScheduleId(ClientAction action)
        {
            return action switch
            {
                ClientAction.HardwareInventory or ClientAction.FullHardwareInventory => "{00000000-0000-0000-0000-000000000001}",
                ClientAction.SoftwareInventory => "{00000000-0000-0000-0000-000000000002}",
                ClientAction.UpdateScan => "{00000000-0000-0000-0000-000000000113}",
                ClientAction.UpdateEval => "{00000000-0000-0000-0000-000000000108}",
                ClientAction.MachinePol => "{00000000-0000-0000-0000-000000000021}",
                ClientAction.AppEval => "{00000000-0000-0000-0000-000000000121}",
                ClientAction.DDR => "{00000000-0000-0000-0000-000000000003}",
                ClientAction.RefreshDefaultMP => "{00000000-0000-0000-0000-000000000023}",
                ClientAction.SourceUpdateMessage => "{00000000-0000-0000-0000-000000000032}",
                ClientAction.SendUnsentStateMessage => "{00000000-0000-0000-0000-000000000111}",
                _ => throw new ArgumentException($"Unknown client action: {action}")
            };
        }

        private void DeleteHardwareInventoryHistory()
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\ccm\\invagt");
                using var results = QueryWMIObjects(namespacePath, 
                    "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000001}'");

                foreach (ManagementObject obj in results)
                {
                    obj.Delete();
                }
            }
            catch
            {
                // Ignore errors when deleting hardware inventory history
            }
        }
    }
}