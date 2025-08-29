using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager task sequence operations
    /// </summary>
    public interface ICCMTaskSequenceService
    {
        /// <summary>
        /// Gets task sequences (asynchronous)
        /// </summary>
        /// <returns>List of CCMTaskSequence objects</returns>
        Task<List<CCMTaskSequence>> GetTaskSequencesAsync();

        /// <summary>
        /// Gets task sequences (synchronous)
        /// </summary>
        /// <returns>List of CCMTaskSequence objects</returns>
        List<CCMTaskSequence> GetTaskSequences();

        /// <summary>
        /// Gets a specific task sequence (asynchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>CCMTaskSequence or null</returns>
        Task<CCMTaskSequence?> GetTaskSequenceAsync(string packageId, string programId);

        /// <summary>
        /// Gets a specific task sequence (synchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>CCMTaskSequence or null</returns>
        CCMTaskSequence? GetTaskSequence(string packageId, string programId);

        /// <summary>
        /// Invokes a task sequence (asynchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>True if successful</returns>
        Task<bool> InvokeTaskSequenceAsync(string packageId, string programId);

        /// <summary>
        /// Invokes a task sequence (synchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programId">Program ID</param>
        /// <returns>True if successful</returns>
        bool InvokeTaskSequence(string packageId, string programId);

        /// <summary>
        /// Gets task sequences by name (asynchronous)
        /// </summary>
        /// <param name="name">Task sequence name to search for</param>
        /// <returns>List of CCMTaskSequence objects</returns>
        Task<List<CCMTaskSequence>> GetTaskSequencesByNameAsync(string name);

        /// <summary>
        /// Gets task sequences by name (synchronous)
        /// </summary>
        /// <param name="name">Task sequence name to search for</param>
        /// <returns>List of CCMTaskSequence objects</returns>
        List<CCMTaskSequence> GetTaskSequencesByName(string name);
    }
}