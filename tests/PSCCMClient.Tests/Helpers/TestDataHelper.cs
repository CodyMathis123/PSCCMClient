using System;
using System.Collections.Generic;
using PSCCMClient.Core.Models;

namespace PSCCMClient.Tests.Helpers
{
    /// <summary>
    /// Test data helper class for creating mock CCM objects
    /// </summary>
    public static class TestDataHelper
    {
        /// <summary>
        /// Creates a sample CCMApplication for testing
        /// </summary>
        public static CCMApplication CreateSampleApplication()
        {
            return new CCMApplication
            {
                Id = "test-app-123",
                Name = "Test Application",
                Revision = "1.0",
                IsMachineTarget = true,
                InstallState = "Available",
                EvaluationState = "0",
                ErrorCode = "0",
                ComputerName = "test-computer"
            };
        }

        /// <summary>
        /// Creates a collection of sample CCMApplications for testing
        /// </summary>
        public static List<CCMApplication> CreateSampleApplications()
        {
            return new List<CCMApplication>
            {
                new CCMApplication
                {
                    Id = "app-001",
                    Name = "Office 365",
                    Revision = "2.0",
                    IsMachineTarget = true,
                    InstallState = "Installed",
                    ComputerName = "test-computer"
                },
                new CCMApplication
                {
                    Id = "app-002", 
                    Name = "Visual Studio",
                    Revision = "1.5",
                    IsMachineTarget = true,
                    InstallState = "Available",
                    ComputerName = "test-computer"
                },
                new CCMApplication
                {
                    Id = "app-003",
                    Name = "Chrome Browser",
                    Revision = "3.0",
                    IsMachineTarget = false,
                    InstallState = "Unknown",
                    ComputerName = "test-computer"
                }
            };
        }

        /// <summary>
        /// Creates a sample CCMClientInfo for testing
        /// </summary>
        public static CCMClientInfo CreateSampleClientInfo()
        {
            return new CCMClientInfo
            {
                ComputerName = "test-computer",
                ClientVersion = "5.00.9088.1000",
                ClientDirectory = @"C:\Windows\CCM",
                IsClientOnInternet = false,
                IsClientAlwaysOnInternet = false
            };
        }

        /// <summary>
        /// Creates a sample CCMCacheInfo for testing
        /// </summary>
        public static CCMCacheInfo CreateSampleCacheInfo()
        {
            return new CCMCacheInfo
            {
                ComputerName = "test-computer",
                Location = @"C:\Windows\ccmcache",
                Size = 5120
            };
        }

        /// <summary>
        /// Creates a collection of sample cache content for testing
        /// </summary>
        public static List<CCMCacheContent> CreateSampleCacheContent()
        {
            return new List<CCMCacheContent>
            {
                new CCMCacheContent
                {
                    ComputerName = "test-computer",
                    ContentId = "content-001",
                    ContentVersion = "1",
                    Location = @"C:\Windows\ccmcache\1",
                    ContentSize = 1024,
                    ContentComplete = true,
                    CacheElementId = "cache-001",
                    LastReferenceTime = DateTime.Now.AddHours(-2)
                },
                new CCMCacheContent
                {
                    ComputerName = "test-computer", 
                    ContentId = "content-002",
                    ContentVersion = "2",
                    Location = @"C:\Windows\ccmcache\2",
                    ContentSize = 512,
                    ContentComplete = false,
                    CacheElementId = "cache-002",
                    LastReferenceTime = DateTime.Now.AddHours(-1)
                }
            };
        }

        /// <summary>
        /// Creates sample maintenance windows for testing
        /// </summary>
        public static List<CCMMaintenanceWindow> CreateSampleMaintenanceWindows()
        {
            return new List<CCMMaintenanceWindow>
            {
                new CCMMaintenanceWindow
                {
                    ComputerName = "test-computer",
                    MWID = "MW-001",
                    Type = "Software Update",
                    TimeZone = "Pacific Standard Time",
                    StartTime = DateTime.Now.AddHours(1),
                    EndTime = DateTime.Now.AddHours(3),
                    Duration = 7200,
                    DurationDescription = "2 hours"
                }
            };
        }

        /// <summary>
        /// Creates sample software updates for testing
        /// </summary>
        public static List<CCMSoftwareUpdate> CreateSampleSoftwareUpdates()
        {
            return new List<CCMSoftwareUpdate>
            {
                new CCMSoftwareUpdate
                {
                    ComputerName = "test-computer",
                    ArticleID = "KB123456",
                    BulletinID = "MS21-001",
                    Name = "Security Update for Windows",
                    ComplianceState = "0"
                }
            };
        }

        /// <summary>
        /// Valid schedule IDs for testing client actions
        /// </summary>
        public static class ScheduleIds
        {
            public const string HardwareInventory = "{00000000-0000-0000-0000-000000000001}";
            public const string SoftwareInventory = "{00000000-0000-0000-0000-000000000002}";
            public const string MachinePolicyRetrieval = "{00000000-0000-0000-0000-000000000021}";
            public const string MachinePolicyEvaluation = "{00000000-0000-0000-0000-000000000022}";
            public const string SoftwareUpdatesScan = "{00000000-0000-0000-0000-000000000113}";
            public const string SoftwareUpdatesDeployment = "{00000000-0000-0000-0000-000000000108}";
        }

        /// <summary>
        /// Common test computer names
        /// </summary>
        public static class ComputerNames
        {
            public const string Local = ".";
            public const string LocalHost = "localhost";
            public const string RemoteComputer = "remote-computer";
            public const string TestMachine = "test-machine";
        }
    }
}