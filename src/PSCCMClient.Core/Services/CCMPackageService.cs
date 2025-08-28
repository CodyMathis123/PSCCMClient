using System.Management;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services.Infrastructure;

namespace PSCCMClient.Core.Services
{
    /// <summary>
    /// Service for managing Configuration Manager packages
    /// </summary>
    public class CCMPackageService : CCMServiceBase
    {
        public CCMPackageService(string computerName = ".") : base(computerName)
        {
        }

        /// <summary>
        /// Gets all packages from the Configuration Manager client
        /// </summary>
        /// <returns>A collection of CCMPackage objects</returns>
        public async Task<IEnumerable<CCMPackage>> GetPackagesAsync()
        {
            return await Task.Run(() => GetPackages());
        }

        /// <summary>
        /// Gets packages by name from the Configuration Manager client
        /// </summary>
        /// <param name="packageName">The name of the package to search for</param>
        /// <returns>A collection of CCMPackage objects matching the name</returns>
        public async Task<IEnumerable<CCMPackage>> GetPackagesByNameAsync(string packageName)
        {
            return await Task.Run(() => GetPackagesByName(packageName));
        }

        /// <summary>
        /// Gets all packages from the Configuration Manager client (synchronous)
        /// </summary>
        /// <returns>A collection of CCMPackage objects</returns>
        public IEnumerable<CCMPackage> GetPackages()
        {
            var packages = new List<CCMPackage>();

            try
            {
                var namespacePath = GetNamespacePath("root\\CCM\\Policy\\Machine\\ActualConfig");
                using var collection = QueryWMIObjects(namespacePath, "SELECT * FROM CCM_SoftwareDistribution");

                foreach (ManagementObject obj in collection)
                {
                    using (obj)
                    {
                        var package = CCMPackage.FromManagementObject(obj);
                        package.ComputerName = _computerName;
                        packages.Add(package);
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve packages", ex);
            }

            return packages;
        }

        /// <summary>
        /// Gets packages by name from the Configuration Manager client (synchronous)
        /// </summary>
        /// <param name="packageName">The name of the package to search for</param>
        /// <returns>A collection of CCMPackage objects matching the name</returns>
        public IEnumerable<CCMPackage> GetPackagesByName(string packageName)
        {
            var packages = new List<CCMPackage>();

            try
            {
                var scope = new ManagementScope($@"\\{_computerName}\root\CCM\Policy\Machine\ActualConfig");
                scope.Connect();

                var query = $"SELECT * FROM CCM_SoftwareDistribution WHERE PKG_Name LIKE '%{packageName}%'";
                using var searcher = new ManagementObjectSearcher(scope, new ObjectQuery(query));
                using var collection = searcher.Get();

                foreach (ManagementObject obj in collection)
                {
                    using (obj)
                    {
                        var package = CCMPackage.FromManagementObject(obj);
                        package.ComputerName = _computerName;
                        packages.Add(package);
                    }
                }
            }
            catch (Exception ex)
            {
                throw CreateException("retrieve packages by name '{packageName}'", ex);
            }

            return packages;
        }

        /// <summary>
        /// Executes a package program on the Configuration Manager client
        /// </summary>
        /// <param name="packageId">The ID of the package to execute</param>
        /// <param name="programName">The name of the program to execute</param>
        /// <returns>True if the execution was initiated successfully</returns>
        public async Task<bool> InvokePackageAsync(string packageId, string programName)
        {
            return await Task.Run(() => InvokePackage(packageId, programName));
        }

        /// <summary>
        /// Executes a package program on the Configuration Manager client (synchronous)
        /// </summary>
        /// <param name="packageId">The ID of the package to execute</param>
        /// <param name="programName">The name of the program to execute</param>
        /// <returns>True if the execution was initiated successfully</returns>
        public bool InvokePackage(string packageId, string programName)
        {
            try
            {
                var scope = new ManagementScope($@"\\{_computerName}\root\CCM\ClientSDK");
                scope.Connect();

                using var progClass = new ManagementClass(scope, new ManagementPath("CCM_ProgramsManager"), null);
                using var inParams = progClass.GetMethodParameters("ExecuteProgram");
                
                inParams["PackageID"] = packageId;
                inParams["ProgramID"] = programName;

                using var outParams = progClass.InvokeMethod("ExecuteProgram", inParams, null);
                var returnValue = Convert.ToInt32(outParams["ReturnValue"]);
                
                return returnValue == 0;
            }
            catch (Exception ex)
            {
                throw CreateException("invoke package {packageId}/{programName}", ex);
            }
        }
    }
}