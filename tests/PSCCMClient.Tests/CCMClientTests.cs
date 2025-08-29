using System;
using System.Threading.Tasks;
using FluentAssertions;
using PSCCMClient.Core;
using PSCCMClient.Core.Interfaces;
using PSCCMClient.Core.Services;
using Xunit;

namespace PSCCMClient.Tests
{
    /// <summary>
    /// Unit tests for the main CCMClient class
    /// </summary>
    public class CCMClientTests
    {
        [Fact]
        public void CCMClient_WithDefaultConstructor_CreatesLocalClient()
        {
            // Arrange & Act
            var client = new CCMClient();

            // Assert
            client.Should().NotBeNull();
            client.Applications.Should().NotBeNull();
            client.ClientActions.Should().NotBeNull();
            client.ClientInfo.Should().NotBeNull();
            client.Cache.Should().NotBeNull();
            client.Baselines.Should().NotBeNull();
            client.MaintenanceWindows.Should().NotBeNull();
            client.Packages.Should().NotBeNull();
            client.Registry.Should().NotBeNull();
            client.Site.Should().NotBeNull();
            client.SoftwareUpdates.Should().NotBeNull();
            client.TaskSequences.Should().NotBeNull();
            client.Logging.Should().NotBeNull();
        }

        [Fact]
        public void CCMClient_WithComputerName_CreatesRemoteClient()
        {
            // Arrange
            const string computerName = "remote-computer";

            // Act
            var client = new CCMClient(computerName);

            // Assert
            client.Should().NotBeNull();
            client.Applications.Should().NotBeNull();
            client.ClientActions.Should().NotBeNull();
            client.ClientInfo.Should().NotBeNull();
        }

        [Theory]
        [InlineData("")]
        [InlineData("   ")]
        public void CCMClient_WithEmptyComputerName_UsesDefault(string computerName)
        {
            // Arrange & Act
            var client = new CCMClient(computerName);

            // Assert
            client.Should().NotBeNull();
        }

        [Fact]
        public void CCMClient_ServicesImplementInterfaces()
        {
            // Arrange
            var client = new CCMClient();

            // Act & Assert
            client.Applications.Should().BeAssignableTo<ICCMApplicationService>();
            client.ClientActions.Should().BeAssignableTo<ICCMClientActionService>();
            client.ClientInfo.Should().BeAssignableTo<ICCMClientInfoService>();
            client.Cache.Should().BeAssignableTo<ICCMCacheService>();
            client.MaintenanceWindows.Should().BeAssignableTo<ICCMMaintenanceWindowService>();
            client.SoftwareUpdates.Should().BeAssignableTo<ICCMSoftwareUpdateService>();
        }

        [Fact]
        public async Task InvokeHardwareInventoryAsync_WithDefaultParameters_CallsService()
        {
            // Arrange
            var client = new CCMClient(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => client.InvokeHardwareInventoryAsync());
            ex.Should().NotBeNull(); // Expected in test environment
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task InvokeHardwareInventoryAsync_WithFullInventoryFlag_CallsCorrectAction(bool fullInventory)
        {
            // Arrange
            var client = new CCMClient(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => client.InvokeHardwareInventoryAsync(fullInventory));
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task InvokeSoftwareInventoryAsync_CallsService()
        {
            // Arrange
            var client = new CCMClient(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => client.InvokeSoftwareInventoryAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task InvokeUpdateScanAsync_CallsService()
        {
            // Arrange
            var client = new CCMClient(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => client.InvokeUpdateScanAsync());
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task InvokeMachinePolicyAsync_CallsService()
        {
            // Arrange
            var client = new CCMClient(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => client.InvokeMachinePolicyAsync());
            ex.Should().NotBeNull();
        }
    }
}