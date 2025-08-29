using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{

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
}