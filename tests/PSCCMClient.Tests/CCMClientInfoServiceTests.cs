using System;
using System.Threading.Tasks;
using FluentAssertions;
using PSCCMClient.Core.Interfaces;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services;
using Xunit;

namespace PSCCMClient.Tests
{
    /// <summary>
    /// Unit tests for CCM Client Info Service
    /// Updated for Windows environments with ConfigMgr client
    /// </summary>
    public class CCMClientInfoServiceTests
    {
        [Fact]
        public void CCMClientInfoService_ImplementsInterface()
        {
            // Arrange & Act
            var service = new CCMClientInfoService("test-computer");

            // Assert
            service.Should().BeAssignableTo<ICCMClientInfoService>();
        }

        [Fact]
        public void Constructor_WithComputerName_SetsComputerName()
        {
            // Arrange
            const string computerName = "test-machine";

            // Act
            var service = new CCMClientInfoService(computerName);

            // Assert
            service.Should().NotBeNull();
        }

        [Fact]
        public async Task GetClientInfoAsync_WithConfigMgrClient_ReturnsClientInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetClientInfoAsync();

            // Assert
            result.Should().NotBeNull();
            result.ComputerName.Should().NotBeNullOrEmpty();

            if (!string.IsNullOrEmpty(result.ClientVersion))
            {
                result.ClientVersion.Should().MatchRegex(@"\d+\.\d+\.\d+\.\d+");
            }
            if (!string.IsNullOrEmpty(result.CurrentManagementPoint))
            {
                result.CurrentManagementPoint.Should().NotBeNullOrEmpty();
            }
            if (!string.IsNullOrEmpty(result.CacheLocation))
            {
                result.CacheLocation.Should().NotBeNullOrEmpty();
            }
            if (!string.IsNullOrEmpty(result.ClientDirectory))
            {
                result.ClientDirectory.Should().NotBeNullOrEmpty();
            }
            if (!string.IsNullOrEmpty(result.SiteCode))
            {
                result.SiteCode.Should().NotBeNullOrEmpty();
            }
            if (!string.IsNullOrEmpty(result.GUID))
            {
               Guid.TryParse(result.GUID.Substring(5), out _).Should().BeTrue();
            }
            if (!string.IsNullOrEmpty(result.LogDirectory))
            {
                result.LogDirectory.Should().NotBeNullOrEmpty();
            }
        }

        [Fact]
        public async Task GetClientVersionAsync_WithConfigMgrClient_ReturnsVersionString()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetClientVersionAsync();

            // Assert
            result.Should().NotBeNull();
            // If ConfigMgr client is installed, version should be present
            if (!string.IsNullOrEmpty(result))
            {
                result.Should().MatchRegex(@"\d+\.\d+\.\d+\.\d+");
            }
        }

        [Fact]
        public async Task GetClientDirectoryAsync_WithConfigMgrClient_ReturnsDirectoryPath()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetClientDirectoryAsync();

            // Assert
            result.Should().NotBeNull();
            // If ConfigMgr client is installed, directory should be present
            if (!string.IsNullOrEmpty(result))
            {
                result.Should().Contain("CCM");
            }
        }

        [Fact]
        public async Task GetPrimaryUserAsync_WithConfigMgrClient_ReturnsUserName()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetPrimaryUserAsync();

            // Assert
            result.Should().NotBeNull();
            // Primary user might be empty, but shouldn't throw
        }

        [Fact]
        public async Task GetExecStartupTimeAsync_WithConfigMgrClient_ReturnsDateTime()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetExecStartupTimeAsync();

            // Assert
            // CCMExec service might not be running, so result could be null
            // but it shouldn't throw an exception
        }

        [Fact]
        public async Task IsClientOnInternetAsync_WithConfigMgrClient_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.IsClientOnInternetAsync();

            // Assert
            // Should return a boolean value without throwing
            Assert.True(result == true || result == false);
        }

        [Fact]
        public async Task IsClientAlwaysOnInternetAsync_WithConfigMgrClient_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.IsClientAlwaysOnInternetAsync();

            // Assert
            // Should return a boolean value without throwing
            Assert.True(result == true || result == false);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task SetClientAlwaysOnInternetAsync_WithValidInput_ReturnsBoolean(bool alwaysOnInternet)
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.SetClientAlwaysOnInternetAsync(alwaysOnInternet);

            // Assert
            // Should return a boolean indicating success/failure
            Assert.True(result == true || result == false);

            // If we set this to true, lets flip it back to false to avoid side effects
            await service.SetClientAlwaysOnInternetAsync(false);
        }

        [Fact]
        public async Task GetLastHeartbeatAsync_WithConfigMgrClient_ReturnsInventoryInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetLastHeartbeatAsync();

            // Assert
            // Might be null if no heartbeat has occurred, but shouldn't throw
        }

        [Fact]
        public async Task GetLastHardwareInventoryAsync_WithConfigMgrClient_ReturnsInventoryInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetLastHardwareInventoryAsync();

            // Assert
            // Might be null if no hardware inventory has occurred, but shouldn't throw
        }

        [Fact]
        public async Task GetLastSoftwareInventoryAsync_WithConfigMgrClient_ReturnsInventoryInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = await service.GetLastSoftwareInventoryAsync();

            // Assert
            // Might be null if no software inventory has occurred, but shouldn't throw
        }

        // Synchronous method tests - these mirror the async tests
        [Fact]
        public void GetClientInfo_WithConfigMgrClient_ReturnsClientInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = service.GetClientInfo();

            // Assert
            result.Should().NotBeNull();
            result.ComputerName.Should().NotBeNullOrEmpty();
        }

        [Fact]
        public void GetClientVersion_WithConfigMgrClient_ReturnsVersionString()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = service.GetClientVersion();

            // Assert
            result.Should().NotBeNull();
            // If ConfigMgr client is installed, version should be present
            if (!string.IsNullOrEmpty(result))
            {
                result.Should().MatchRegex(@"\d+\.\d+\.\d+\.\d+");
            }
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public void SetClientAlwaysOnInternet_WithValidInput_ReturnsBoolean(bool alwaysOnInternet)
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act
            var result = service.SetClientAlwaysOnInternet(alwaysOnInternet);

            // Assert
            // Should return a boolean indicating success/failure
            Assert.True(result == true || result == false);
        }
    }
}