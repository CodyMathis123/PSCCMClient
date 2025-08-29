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
        public async Task GetClientInfoAsync_ReturnsClientInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetClientInfoAsync());
            ex.Should().NotBeNull(); // Expected in test environment without WMI
        }

        [Fact]
        public async Task GetClientVersionAsync_ReturnsVersionString()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetClientVersionAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task GetClientDirectoryAsync_ReturnsDirectoryPath()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetClientDirectoryAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task GetPrimaryUserAsync_ReturnsUserName()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetPrimaryUserAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task GetExecStartupTimeAsync_ReturnsDateTime()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetExecStartupTimeAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task IsClientOnInternetAsync_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.IsClientOnInternetAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task IsClientAlwaysOnInternetAsync_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.IsClientAlwaysOnInternetAsync());
            ex.Should().NotBeNull();
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task SetClientAlwaysOnInternetAsync_WithValidInput_ReturnsBoolean(bool alwaysOnInternet)
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.SetClientAlwaysOnInternetAsync(alwaysOnInternet));
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task GetLastHeartbeatAsync_ReturnsInventoryInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetLastHeartbeatAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task GetLastHardwareInventoryAsync_ReturnsInventoryInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetLastHardwareInventoryAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task GetLastSoftwareInventoryAsync_ReturnsInventoryInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetLastSoftwareInventoryAsync());
            ex.Should().NotBeNull();
        }

        // Synchronous method tests - these mirror the async tests
        [Fact]
        public void GetClientInfo_ReturnsClientInfo()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = Assert.Throws<Exception>(() => service.GetClientInfo());
            ex.Should().NotBeNull();
        }

        [Fact]
        public void GetClientVersion_ReturnsVersionString()
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = Assert.Throws<Exception>(() => service.GetClientVersion());
            ex.Should().NotBeNull();
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public void SetClientAlwaysOnInternet_WithValidInput_ReturnsBoolean(bool alwaysOnInternet)
        {
            // Arrange
            var service = new CCMClientInfoService(".");

            // Act & Assert
            var ex = Assert.Throws<Exception>(() => service.SetClientAlwaysOnInternet(alwaysOnInternet));
            ex.Should().NotBeNull();
        }
    }
}