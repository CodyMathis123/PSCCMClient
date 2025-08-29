using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager client action operations
    /// </summary>
    public interface ICCMClientActionService
    {
        /// <summary>
        /// Invokes a client action (asynchronous)
        /// </summary>
        /// <param name="action">The action to invoke</param>
        /// <returns>True if successful</returns>
        Task<bool> InvokeClientActionAsync(ClientAction action);

        /// <summary>
        /// Invokes a client action (synchronous)
        /// </summary>
        /// <param name="action">The action to invoke</param>
        /// <returns>True if successful</returns>
        bool InvokeClientAction(ClientAction action);

        /// <summary>
        /// Invokes multiple client actions (asynchronous)
        /// </summary>
        /// <param name="actions">The actions to invoke</param>
        /// <returns>Dictionary mapping each action to its success status</returns>
        Task<Dictionary<ClientAction, bool>> InvokeClientActionsAsync(params ClientAction[] actions);

        /// <summary>
        /// Invokes multiple client actions (synchronous)
        /// </summary>
        /// <param name="actions">The actions to invoke</param>
        /// <returns>Dictionary mapping each action to its success status</returns>
        Dictionary<ClientAction, bool> InvokeClientActions(params ClientAction[] actions);

        /// <summary>
        /// Triggers a schedule by ID (asynchronous)
        /// </summary>
        /// <param name="scheduleId">Schedule ID to trigger</param>
        /// <returns>True if successful</returns>
        Task<bool> TriggerScheduleAsync(string scheduleId);

        /// <summary>
        /// Triggers a schedule by ID (synchronous)
        /// </summary>
        /// <param name="scheduleId">Schedule ID to trigger</param>
        /// <returns>True if successful</returns>
        bool TriggerSchedule(string scheduleId);

        /// <summary>
        /// Resets the client policy (asynchronous)
        /// </summary>
        /// <returns>True if successful</returns>
        Task<bool> ResetPolicyAsync();

        /// <summary>
        /// Resets the client policy with specified type (asynchronous)
        /// </summary>
        /// <param name="resetType">Type of reset (default: "Purge")</param>
        /// <returns>True if successful</returns>
        Task<bool> ResetPolicyAsync(string resetType);

        /// <summary>
        /// Resets the client policy (synchronous)
        /// </summary>
        /// <param name="resetType">Type of reset (default: "Purge")</param>
        /// <returns>True if successful</returns>
        bool ResetPolicy(string resetType = "Purge");

        /// <summary>
        /// Resets the client policy using legacy method (synchronous)
        /// </summary>
        /// <returns>True if successful</returns>
        bool ResetPolicyLegacy();
    }
}