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
        }

        /// <summary>
        /// Tests connectivity to the Configuration Manager client
        /// </summary>
        /// <returns>True if the client is accessible</returns>
        public async Task<bool> TestConnectionAsync()
        {
            try
            {
                var apps = await Applications.GetApplicationsAsync();
                return true;
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
                var apps = Applications.GetApplications();
                return true;
            }
            catch
            {
                return false;
            }
        }
    }
}