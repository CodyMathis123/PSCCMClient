using System.Management;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for invoking Configuration Manager client actions
    /// </summary>
    public class CCMClientActionService
    {
        private readonly string _computerName;

        public CCMClientActionService(string computerName)
        {
            _computerName = computerName ?? ".";
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

                // Trigger the schedule
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\ccm", "SELECT * FROM SMS_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("TriggerSchedule");
                    inParams["sScheduleID"] = scheduleId;
                    
                    var outParams = obj.InvokeMethod("TriggerSchedule", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to invoke client action '{action}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\ccm", "SELECT * FROM SMS_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("TriggerSchedule");
                    inParams["sScheduleID"] = scheduleId;
                    
                    var outParams = obj.InvokeMethod("TriggerSchedule", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to trigger schedule '{scheduleId}' on {_computerName}: {ex.Message}", ex);
            }

            return false;
        }

        /// <summary>
        /// Resets client policy
        /// </summary>
        /// <returns>True if successful</returns>
        public async Task<bool> ResetPolicyAsync()
        {
            return await Task.Run(() => ResetPolicy());
        }

        /// <summary>
        /// Resets client policy (synchronous)
        /// </summary>
        /// <returns>True if successful</returns>
        public bool ResetPolicy()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\ccm", "SELECT * FROM SMS_Client");
                using var results = searcher.Get();

                foreach (ManagementObject obj in results)
                {
                    var inParams = obj.GetMethodParameters("ResetPolicy");
                    inParams["uFlags"] = 1; // Reset policy
                    
                    var outParams = obj.InvokeMethod("ResetPolicy", inParams, null);
                    return Convert.ToInt32(outParams["ReturnValue"]) == 0;
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to reset policy on {_computerName}: {ex.Message}", ex);
            }

            return false;
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
                using var searcher = new ManagementObjectSearcher($@"\\{_computerName}\root\ccm\invagt", 
                    "SELECT * FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000001}'");
                using var results = searcher.Get();

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