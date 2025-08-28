using PSCCMClient.Core.Services;

namespace PSCCMClient.Core
{
    /// <summary>
    /// Main client for interacting with Configuration Manager
    /// </summary>
    public class CCMClient
    {
        private readonly string _computerName;

        /// <summary>
        /// Gets the application service for this client
        /// </summary>
        public CCMApplicationService Applications { get; }

        /// <summary>
        /// Gets the package service for this client
        /// </summary>
        public CCMPackageService Packages { get; }

        /// <summary>
        /// Gets the baseline service for this client
        /// </summary>
        public CCMBaselineService Baselines { get; }

        /// <summary>
        /// Gets the cache service for this client
        /// </summary>
        public CCMCacheService Cache { get; }

        /// <summary>
        /// Gets the client information service for this client
        /// </summary>
        public CCMClientInfoService ClientInfo { get; }

        /// <summary>
        /// Gets the software update service for this client
        /// </summary>
        public CCMSoftwareUpdateService SoftwareUpdates { get; }

        /// <summary>
        /// Gets the client action service for this client
        /// </summary>
        public CCMClientActionService ClientActions { get; }

        /// <summary>
        /// Gets the task sequence service for this client
        /// </summary>
        public CCMTaskSequenceService TaskSequences { get; }

        /// <summary>
        /// Gets the maintenance window service for this client
        /// </summary>
        public CCMMaintenanceWindowService MaintenanceWindows { get; }

        /// <summary>
        /// Gets the site and connectivity service for this client
        /// </summary>
        public CCMSiteService Site { get; }

        /// <summary>
        /// Gets the logging service for this client
        /// </summary>
        public CCMLoggingService Logging { get; }

        /// <summary>
        /// Gets the registry and provisioning service for this client
        /// </summary>
        public CCMRegistryService Registry { get; }

        /// <summary>
        /// Gets the computer name this client is connected to
        /// </summary>
        public string ComputerName => _computerName;

        /// <summary>
        /// Initializes a new CCMClient for the local computer
        /// </summary>
        public CCMClient() : this(".")
        {
        }

        /// <summary>
        /// Initializes a new CCMClient for the specified computer
        /// </summary>
        /// <param name="computerName">The name of the computer to connect to</param>
        public CCMClient(string computerName)
        {
            _computerName = computerName ?? ".";
            Applications = new CCMApplicationService(_computerName);
            Packages = new CCMPackageService(_computerName);
            Baselines = new CCMBaselineService(_computerName);
            Cache = new CCMCacheService(_computerName);
            ClientInfo = new CCMClientInfoService(_computerName);
            SoftwareUpdates = new CCMSoftwareUpdateService(_computerName);
            ClientActions = new CCMClientActionService(_computerName);
            TaskSequences = new CCMTaskSequenceService(_computerName);
            MaintenanceWindows = new CCMMaintenanceWindowService(_computerName);
            Site = new CCMSiteService(_computerName);
            Logging = new CCMLoggingService(_computerName);
            Registry = new CCMRegistryService(_computerName);
        }

        /// <summary>
        /// Tests connectivity to the Configuration Manager client
        /// </summary>
        /// <returns>True if the client is accessible</returns>
        public async Task<bool> TestConnectionAsync()
        {
            try
            {
                var clientVersion = await ClientInfo.GetClientVersionAsync();
                return !string.IsNullOrEmpty(clientVersion);
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Tests connectivity to the Configuration Manager client (synchronous)
        /// </summary>
        /// <returns>True if the client is accessible</returns>
        public bool TestConnection()
        {
            try
            {
                var clientVersion = ClientInfo.GetClientVersion();
                return !string.IsNullOrEmpty(clientVersion);
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Gets comprehensive client information
        /// </summary>
        /// <returns>Complete client information</returns>
        public async Task<Models.CCMClientInfo> GetClientInfoAsync()
        {
            return await ClientInfo.GetClientInfoAsync();
        }

        /// <summary>
        /// Gets comprehensive client information (synchronous)
        /// </summary>
        /// <returns>Complete client information</returns>
        public Models.CCMClientInfo GetClientInfo()
        {
            return ClientInfo.GetClientInfo();
        }

        /// <summary>
        /// Performs a hardware inventory
        /// </summary>
        /// <param name="fullInventory">Whether to perform a full hardware inventory</param>
        /// <returns>True if successful</returns>
        public async Task<bool> InvokeHardwareInventoryAsync(bool fullInventory = false)
        {
            var action = fullInventory 
                ? CCMClientActionService.ClientAction.FullHardwareInventory 
                : CCMClientActionService.ClientAction.HardwareInventory;
            return await ClientActions.InvokeClientActionAsync(action);
        }

        /// <summary>
        /// Performs a software inventory
        /// </summary>
        /// <returns>True if successful</returns>
        public async Task<bool> InvokeSoftwareInventoryAsync()
        {
            return await ClientActions.InvokeClientActionAsync(CCMClientActionService.ClientAction.SoftwareInventory);
        }

        /// <summary>
        /// Performs a software update scan
        /// </summary>
        /// <returns>True if successful</returns>
        public async Task<bool> InvokeUpdateScanAsync()
        {
            return await ClientActions.InvokeClientActionAsync(CCMClientActionService.ClientAction.UpdateScan);
        }

        /// <summary>
        /// Performs a machine policy refresh
        /// </summary>
        /// <returns>True if successful</returns>
        public async Task<bool> InvokeMachinePolicyAsync()
        {
            return await ClientActions.InvokeClientActionAsync(CCMClientActionService.ClientAction.MachinePol);
        }
    }
}