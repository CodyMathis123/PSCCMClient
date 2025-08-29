using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager package operations
    /// </summary>
    public interface ICCMPackageService
    {
        /// <summary>
        /// Gets packages (asynchronous)
        /// </summary>
        /// <returns>Collection of CCMPackage objects</returns>
        Task<IEnumerable<CCMPackage>> GetPackagesAsync();

        /// <summary>
        /// Gets packages by name (asynchronous)
        /// </summary>
        /// <param name="packageName">Package name to search for</param>
        /// <returns>Collection of CCMPackage objects</returns>
        Task<IEnumerable<CCMPackage>> GetPackagesByNameAsync(string packageName);

        /// <summary>
        /// Gets packages (synchronous)
        /// </summary>
        /// <returns>Collection of CCMPackage objects</returns>
        IEnumerable<CCMPackage> GetPackages();

        /// <summary>
        /// Gets packages by name (synchronous)
        /// </summary>
        /// <param name="packageName">Package name to search for</param>
        /// <returns>Collection of CCMPackage objects</returns>
        IEnumerable<CCMPackage> GetPackagesByName(string packageName);

        /// <summary>
        /// Invokes a package (asynchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programName">Program name</param>
        /// <returns>True if successful</returns>
        Task<bool> InvokePackageAsync(string packageId, string programName);

        /// <summary>
        /// Invokes a package (synchronous)
        /// </summary>
        /// <param name="packageId">Package ID</param>
        /// <param name="programName">Program name</param>
        /// <returns>True if successful</returns>
        bool InvokePackage(string packageId, string programName);
    }
}