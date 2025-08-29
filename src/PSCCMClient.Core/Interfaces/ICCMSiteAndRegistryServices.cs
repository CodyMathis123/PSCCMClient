using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Core.Interfaces
{
    /// <summary>
    /// Interface for Configuration Manager registry operations
    /// </summary>
    public interface ICCMRegistryService
    {
        /// <summary>
        /// Gets a registry property (asynchronous)
        /// </summary>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey</param>
        /// <param name="valueName">Value name</param>
        /// <returns>CCMRegistryProperty or null</returns>
        Task<CCMRegistryProperty?> GetRegistryPropertyAsync(string hive, string subKey, string valueName);

        /// <summary>
        /// Gets a registry property (synchronous)
        /// </summary>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey</param>
        /// <param name="valueName">Value name</param>
        /// <returns>CCMRegistryProperty or null</returns>
        CCMRegistryProperty? GetRegistryProperty(string hive, string subKey, string valueName);

        /// <summary>
        /// Sets a registry property (asynchronous)
        /// </summary>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey</param>
        /// <param name="valueName">Value name</param>
        /// <param name="value">Value to set</param>
        /// <param name="valueType">Value type</param>
        /// <returns>True if successful</returns>
        Task<bool> SetRegistryPropertyAsync(string hive, string subKey, string valueName, object value, string valueType = "String");

        /// <summary>
        /// Sets a registry property (synchronous)
        /// </summary>
        /// <param name="hive">Registry hive</param>
        /// <param name="subKey">Registry subkey</param>
        /// <param name="valueName">Value name</param>
        /// <param name="value">Value to set</param>
        /// <param name="valueType">Value type</param>
        /// <returns>True if successful</returns>
        bool SetRegistryProperty(string hive, string subKey, string valueName, object value, string valueType = "String");

        /// <summary>
        /// Gets provisioning mode (asynchronous)
        /// </summary>
        /// <returns>CCMProvisioningMode or null</returns>
        Task<CCMProvisioningMode?> GetProvisioningModeAsync();

        /// <summary>
        /// Gets provisioning mode (synchronous)
        /// </summary>
        /// <returns>CCMProvisioningMode or null</returns>
        CCMProvisioningMode? GetProvisioningMode();

        /// <summary>
        /// Sets provisioning mode (asynchronous)
        /// </summary>
        /// <param name="enabled">Whether to enable provisioning mode</param>
        /// <returns>True if successful</returns>
        Task<bool> SetProvisioningModeAsync(bool enabled);

        /// <summary>
        /// Sets provisioning mode (synchronous)
        /// </summary>
        /// <param name="enabled">Whether to enable provisioning mode</param>
        /// <returns>True if successful</returns>
        bool SetProvisioningMode(bool enabled);

        /// <summary>
        /// Gets GUID information (asynchronous)
        /// </summary>
        /// <returns>CCMGuidInfo or null</returns>
        Task<CCMGuidInfo?> GetGuidAsync();

        /// <summary>
        /// Gets GUID information (synchronous)
        /// </summary>
        /// <returns>CCMGuidInfo or null</returns>
        CCMGuidInfo? GetGuid();

        /// <summary>
        /// Gets primary user information (asynchronous)
        /// </summary>
        /// <returns>CCMPrimaryUser or null</returns>
        Task<CCMPrimaryUser?> GetPrimaryUserAsync();

        /// <summary>
        /// Gets primary user information (synchronous)
        /// </summary>
        /// <returns>CCMPrimaryUser or null</returns>
        CCMPrimaryUser? GetPrimaryUser();

        /// <summary>
        /// Gets execution startup time (asynchronous)
        /// </summary>
        /// <returns>CCMExecStartupTime or null</returns>
        Task<CCMExecStartupTime?> GetExecStartupTimeAsync();

        /// <summary>
        /// Gets execution startup time (synchronous)
        /// </summary>
        /// <returns>CCMExecStartupTime or null</returns>
        CCMExecStartupTime? GetExecStartupTime();
    }

    /// <summary>
    /// Interface for Configuration Manager site operations
    /// </summary>
    public interface ICCMSiteService
    {
        /// <summary>
        /// Gets site information (asynchronous)
        /// </summary>
        /// <returns>CCMSite or null</returns>
        Task<CCMSite?> GetSiteAsync();

        /// <summary>
        /// Gets site information (synchronous)
        /// </summary>
        /// <returns>CCMSite or null</returns>
        CCMSite? GetSite();

        /// <summary>
        /// Sets site code (asynchronous)
        /// </summary>
        /// <param name="siteCode">Site code to set</param>
        /// <returns>True if successful</returns>
        Task<bool> SetSiteAsync(string siteCode);

        /// <summary>
        /// Sets site code (synchronous)
        /// </summary>
        /// <param name="siteCode">Site code to set</param>
        /// <returns>True if successful</returns>
        bool SetSite(string siteCode);

        /// <summary>
        /// Gets current management point (asynchronous)
        /// </summary>
        /// <returns>CCMManagementPoint or null</returns>
        Task<CCMManagementPoint?> GetCurrentManagementPointAsync();

        /// <summary>
        /// Gets current management point (synchronous)
        /// </summary>
        /// <returns>CCMManagementPoint or null</returns>
        CCMManagementPoint? GetCurrentManagementPoint();

        /// <summary>
        /// Sets management point (asynchronous)
        /// </summary>
        /// <param name="managementPoint">Management point to set</param>
        /// <returns>True if successful</returns>
        Task<bool> SetManagementPointAsync(string managementPoint);

        /// <summary>
        /// Sets management point (synchronous)
        /// </summary>
        /// <param name="managementPoint">Management point to set</param>
        /// <returns>True if successful</returns>
        bool SetManagementPoint(string managementPoint);

        /// <summary>
        /// Gets current software update point (asynchronous)
        /// </summary>
        /// <returns>CCMSoftwareUpdatePoint or null</returns>
        Task<CCMSoftwareUpdatePoint?> GetCurrentSoftwareUpdatePointAsync();

        /// <summary>
        /// Gets current software update point (synchronous)
        /// </summary>
        /// <returns>CCMSoftwareUpdatePoint or null</returns>
        CCMSoftwareUpdatePoint? GetCurrentSoftwareUpdatePoint();

        /// <summary>
        /// Gets DNS suffix (asynchronous)
        /// </summary>
        /// <returns>CCMDNSSuffix or null</returns>
        Task<CCMDNSSuffix?> GetDNSSuffixAsync();

        /// <summary>
        /// Gets DNS suffix (synchronous)
        /// </summary>
        /// <returns>CCMDNSSuffix or null</returns>
        CCMDNSSuffix? GetDNSSuffix();

        /// <summary>
        /// Sets DNS suffix (asynchronous)
        /// </summary>
        /// <param name="dnsSuffix">DNS suffix to set</param>
        /// <returns>True if successful</returns>
        Task<bool> SetDNSSuffixAsync(string dnsSuffix);

        /// <summary>
        /// Sets DNS suffix (synchronous)
        /// </summary>
        /// <param name="dnsSuffix">DNS suffix to set</param>
        /// <returns>True if successful</returns>
        bool SetDNSSuffix(string dnsSuffix);

        /// <summary>
        /// Tests if client is on internet (asynchronous)
        /// </summary>
        /// <returns>True if on internet</returns>
        Task<bool> TestIsClientOnInternetAsync();

        /// <summary>
        /// Tests if client is on internet (synchronous)
        /// </summary>
        /// <returns>True if on internet</returns>
        bool TestIsClientOnInternet();

        /// <summary>
        /// Tests if client is always on internet (asynchronous)
        /// </summary>
        /// <returns>True if always on internet</returns>
        Task<bool> TestIsClientAlwaysOnInternetAsync();

        /// <summary>
        /// Tests if client is always on internet (synchronous)
        /// </summary>
        /// <returns>True if always on internet</returns>
        bool TestIsClientAlwaysOnInternet();

        /// <summary>
        /// Sets client always on internet (asynchronous)
        /// </summary>
        /// <param name="alwaysOnInternet">Whether to enable always on internet</param>
        /// <returns>True if successful</returns>
        Task<bool> SetClientAlwaysOnInternetAsync(bool alwaysOnInternet);

        /// <summary>
        /// Sets client always on internet (synchronous)
        /// </summary>
        /// <param name="alwaysOnInternet">Whether to enable always on internet</param>
        /// <returns>True if successful</returns>
        bool SetClientAlwaysOnInternet(bool alwaysOnInternet);
    }
}