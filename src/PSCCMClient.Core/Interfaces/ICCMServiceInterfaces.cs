using System;
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

    /// <summary>
    /// Interface for Configuration Manager logging operations
    /// </summary>
    public interface ICCMLoggingService
    {
        /// <summary>
        /// Gets logging configuration (asynchronous)
        /// </summary>
        /// <returns>CCMLoggingConfiguration or null</returns>
        Task<CCMLoggingConfiguration?> GetLoggingConfigurationAsync();

        /// <summary>
        /// Gets logging configuration (synchronous)
        /// </summary>
        /// <returns>CCMLoggingConfiguration or null</returns>
        CCMLoggingConfiguration? GetLoggingConfiguration();

        /// <summary>
        /// Sets logging configuration (asynchronous)
        /// </summary>
        /// <param name="logLevel">Log level</param>
        /// <param name="logMaxSize">Maximum log size</param>
        /// <param name="logMaxHistory">Maximum log history</param>
        /// <returns>True if successful</returns>
        Task<bool> SetLoggingConfigurationAsync(int? logLevel = null, int? logMaxSize = null, int? logMaxHistory = null);

        /// <summary>
        /// Sets logging configuration (synchronous)
        /// </summary>
        /// <param name="logLevel">Log level</param>
        /// <param name="logMaxSize">Maximum log size</param>
        /// <param name="logMaxHistory">Maximum log history</param>
        /// <returns>True if successful</returns>
        bool SetLoggingConfiguration(int? logLevel = null, int? logMaxSize = null, int? logMaxHistory = null);

        /// <summary>
        /// Writes a log entry (asynchronous)
        /// </summary>
        /// <param name="value">Log message</param>
        /// <param name="severity">Log severity level</param>
        /// <param name="component">Component name</param>
        /// <param name="logfile">Log file name</param>
        /// <returns>True if successful</returns>
        Task<bool> WriteLogEntryAsync(string value, int severity = 1, string component = "PSCCMClient", string logfile = "CCMClient.log");

        /// <summary>
        /// Writes a log entry (synchronous)
        /// </summary>
        /// <param name="value">Log message</param>
        /// <param name="severity">Log severity level</param>
        /// <param name="component">Component name</param>
        /// <param name="logfile">Log file name</param>
        /// <returns>True if successful</returns>
        bool WriteLogEntry(string value, int severity = 1, string component = "PSCCMClient", string logfile = "CCMClient.log");

        /// <summary>
        /// Tests for stale logs (asynchronous)
        /// </summary>
        /// <param name="logDirectory">Log directory path</param>
        /// <param name="hoursStale">Hours considered stale</param>
        /// <returns>Dictionary of log files and their stale status</returns>
        Task<Dictionary<string, bool>> TestStaleLogsAsync(string? logDirectory = null, int hoursStale = 24);

        /// <summary>
        /// Tests for stale logs (synchronous)
        /// </summary>
        /// <param name="logDirectory">Log directory path</param>
        /// <param name="hoursStale">Hours considered stale</param>
        /// <returns>Dictionary of log files and their stale status</returns>
        Dictionary<string, bool> TestStaleLogs(string? logDirectory = null, int hoursStale = 24);
    }

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