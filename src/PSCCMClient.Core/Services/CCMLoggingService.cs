using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager logging
    /// </summary>
    public class CCMLoggingService : CCMServiceBase
    {
        public CCMLoggingService(string computerName) : base(computerName)
        {
        }

        /// <summary>
        /// Gets logging configuration
        /// </summary>
        /// <returns>Logging configuration</returns>
        public async Task<CCMLoggingConfiguration?> GetLoggingConfigurationAsync()
        {
            return await Task.Run(() => GetLoggingConfiguration());
        }

        /// <summary>
        /// Gets logging configuration (synchronous)
        /// </summary>
        /// <returns>Logging configuration</returns>
        public CCMLoggingConfiguration? GetLoggingConfiguration()
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_Logging_GlobalConfiguration");

                foreach (ManagementObject obj in results)
                {
                    return new CCMLoggingConfiguration
                    {
                        ComputerName = ActualComputerName,
                        LogDirectory = obj["LogDirectory"]?.ToString() ?? "",
                        LogMaxSize = Convert.ToInt32(obj["LogMaxSize"] ?? 0),
                        LogMaxHistory = Convert.ToInt32(obj["LogMaxHistory"] ?? 0),
                        LogLevel = Convert.ToInt32(obj["LogLevel"] ?? 0),
                        LogEnabled = Convert.ToBoolean(obj["LogEnabled"] ?? false)
                    };
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve logging configuration", ex);
            }

            return null;
        }

        /// <summary>
        /// Sets logging configuration
        /// </summary>
        /// <param name="logLevel">Log level (0=Off, 1=Error, 2=Warning, 3=Info, 4=Verbose)</param>
        /// <param name="logMaxSize">Maximum log file size in bytes</param>
        /// <param name="logMaxHistory">Maximum number of log history files</param>
        /// <returns>True if successful</returns>
        public async Task<bool> SetLoggingConfigurationAsync(int? logLevel = null, int? logMaxSize = null, int? logMaxHistory = null)
        {
            return await Task.Run(() => SetLoggingConfiguration(logLevel, logMaxSize, logMaxHistory));
        }

        /// <summary>
        /// Sets logging configuration (synchronous)
        /// </summary>
        /// <param name="logLevel">Log level (0=Off, 1=Error, 2=Warning, 3=Info, 4=Verbose)</param>
        /// <param name="logMaxSize">Maximum log file size in bytes</param>
        /// <param name="logMaxHistory">Maximum number of log history files</param>
        /// <returns>True if successful</returns>
        public bool SetLoggingConfiguration(int? logLevel = null, int? logMaxSize = null, int? logMaxHistory = null)
        {
            try
            {
                var namespacePath = GetNamespacePath("root\\CCM");
                using var results = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_Logging_GlobalConfiguration");

                foreach (ManagementObject obj in results)
                {
                    if (logLevel.HasValue)
                        obj["LogLevel"] = logLevel.Value;
                    if (logMaxSize.HasValue)
                        obj["LogMaxSize"] = logMaxSize.Value;
                    if (logMaxHistory.HasValue)
                        obj["LogMaxHistory"] = logMaxHistory.Value;

                    obj.Put();
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw CreateException("set logging configuration", ex);
            }

            return false;
        }

        /// <summary>
        /// Writes an entry to the CCM log
        /// </summary>
        /// <param name="value">Message to log</param>
        /// <param name="severity">Severity level (1=Informational, 2=Warning, 3=Error)</param>
        /// <param name="component">Component name</param>
        /// <param name="logfile">Log file name</param>
        /// <returns>True if successful</returns>
        public async Task<bool> WriteLogEntryAsync(string value, int severity = 1, string component = "PSCCMClient", string logfile = "CCMClient.log")
        {
            return await Task.Run(() => WriteLogEntry(value, severity, component, logfile));
        }

        /// <summary>
        /// Writes an entry to the CCM log (synchronous)
        /// </summary>
        /// <param name="value">Message to log</param>
        /// <param name="severity">Severity level (1=Informational, 2=Warning, 3=Error)</param>
        /// <param name="component">Component name</param>
        /// <param name="logfile">Log file name</param>
        /// <returns>True if successful</returns>
        public bool WriteLogEntry(string value, int severity = 1, string component = "PSCCMClient", string logfile = "CCMClient.log")
        {
            try
            {
                var logConfig = GetLoggingConfiguration();
                if (logConfig != null && !string.IsNullOrEmpty(logConfig.LogDirectory))
                {
                    var logPath = Path.Combine(logConfig.LogDirectory, logfile);
                    var timestamp = DateTime.Now.ToString("MM-dd-yyyy HH:mm:ss.fff");
                    var severityText = severity switch
                    {
                        1 => "INFO",
                        2 => "WARN",
                        3 => "ERROR",
                        _ => "INFO"
                    };

                    var logEntry = $"{timestamp} [{severityText}] {component}: {value}";
                    
                    // Ensure directory exists
                    Directory.CreateDirectory(Path.GetDirectoryName(logPath) ?? "");
                    
                    File.AppendAllText(logPath, logEntry + Environment.NewLine);
                    return true;
                }
            }
            catch (Exception ex)
            {
                throw CreateException("write log entry", ex);
            }

            return false;
        }

        /// <summary>
        /// Tests if log files are stale
        /// </summary>
        /// <param name="logDirectory">Directory to check (optional, uses client log directory if not specified)</param>
        /// <param name="hoursStale">Number of hours to consider stale (default 24)</param>
        /// <returns>Dictionary of log files and their stale status</returns>
        public async Task<Dictionary<string, bool>> TestStaleLogsAsync(string? logDirectory = null, int hoursStale = 24)
        {
            return await Task.Run(() => TestStaleLogs(logDirectory, hoursStale));
        }

        /// <summary>
        /// Tests if log files are stale (synchronous)
        /// </summary>
        /// <param name="logDirectory">Directory to check (optional, uses client log directory if not specified)</param>
        /// <param name="hoursStale">Number of hours to consider stale (default 24)</param>
        /// <returns>Dictionary of log files and their stale status</returns>
        public Dictionary<string, bool> TestStaleLogs(string? logDirectory = null, int hoursStale = 24)
        {
            var results = new Dictionary<string, bool>();

            try
            {
                if (string.IsNullOrEmpty(logDirectory))
                {
                    var logConfig = GetLoggingConfiguration();
                    logDirectory = logConfig?.LogDirectory;
                }

                if (!string.IsNullOrEmpty(logDirectory) && Directory.Exists(logDirectory))
                {
                    var cutoffTime = DateTime.Now.AddHours(-hoursStale);
                    var logFiles = Directory.GetFiles(logDirectory, "*.log");

                    foreach (var logFile in logFiles)
                    {
                        var lastWriteTime = File.GetLastWriteTime(logFile);
                        results[Path.GetFileName(logFile)] = lastWriteTime < cutoffTime;
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException("test stale logs", ex);
            }

            return results;
        }
    }
}