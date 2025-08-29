using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager baseline operations
    /// </summary>
    public interface ICCMBaselineService
    {
        /// <summary>
        /// Gets baselines (asynchronous)
        /// </summary>
        /// <param name="baselineName">Optional baseline name to filter</param>
        /// <returns>List of CCMBaseline objects</returns>
        Task<List<CCMBaseline>> GetBaselinesAsync(string? baselineName = null);

        /// <summary>
        /// Gets baselines (synchronous)
        /// </summary>
        /// <param name="baselineName">Optional baseline name to filter</param>
        /// <returns>List of CCMBaseline objects</returns>
        List<CCMBaseline> GetBaselines(string? baselineName = null);

        /// <summary>
        /// Invokes a baseline (asynchronous)
        /// </summary>
        /// <param name="baselineName">Baseline name to invoke</param>
        /// <returns>True if successful</returns>
        Task<bool> InvokeBaselineAsync(string baselineName);

        /// <summary>
        /// Invokes a baseline (synchronous)
        /// </summary>
        /// <param name="baselineName">Baseline name to invoke</param>
        /// <returns>True if successful</returns>
        bool InvokeBaseline(string baselineName);
    }
}