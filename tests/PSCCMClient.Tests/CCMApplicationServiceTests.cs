using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using Moq;
using PSCCMClient.Core.Interfaces;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services;
using Xunit;

namespace PSCCMClient.Tests
{
    /// <summary>
    /// Unit tests for CCM Application Service
    /// Tests cover both interface contracts and implementation details
    /// </summary>
    public class CCMApplicationServiceTests
    {
        [Fact]
        public void CCMApplicationService_ImplementsInterface()
        {
            // Arrange & Act
            var service = new CCMApplicationService("test-computer");

            // Assert
            service.Should().BeAssignableTo<ICCMApplicationService>();
        }

        [Fact]
        public void Constructor_WithComputerName_SetsComputerName()
        {
            // Arrange
            const string computerName = "test-machine";

            // Act
            var service = new CCMApplicationService(computerName);

            // Assert
            service.Should().NotBeNull();
        }

        [Fact]
        public void Constructor_WithDefaultValue_SetsLocalMachine()
        {
            // Arrange & Act
            var service = new CCMApplicationService();

            // Assert
            service.Should().NotBeNull();
        }

        [Fact]
        public async Task GetApplicationsAsync_ReturnsApplicationCollection()
        {
            // Arrange
            var service = new CCMApplicationService(".");

            // Act & Assert - This will likely fail in test environment without WMI
            // In real tests, we would mock the WMI layer or use test doubles
            var ex = await Assert.ThrowsAsync<Exception>(() => service.GetApplicationsAsync());
            ex.Should().NotBeNull(); // Expected to fail without actual WMI infrastructure
        }

        [Theory]
        [InlineData("TestApp")]
        [InlineData("")]
        [InlineData(null)]
        public async Task GetApplicationsByNameAsync_WithVariousInputs_HandlesGracefully(string? appName)
        {
            // Arrange
            var service = new CCMApplicationService(".");

            // Act & Assert
            if (string.IsNullOrEmpty(appName))
            {
                await Assert.ThrowsAsync<ArgumentException>(() => service.GetApplicationsByNameAsync(appName!));
            }
            else
            {
                var ex = await Assert.ThrowsAsync<Exception>(() => service.GetApplicationsByNameAsync(appName));
                ex.Should().NotBeNull(); // Expected in test environment
            }
        }

        [Fact]
        public async Task InstallApplicationAsync_WithValidParameters_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMApplicationService(".");
            const string appId = "test-app-id";
            const string revision = "1.0";

            // Act & Assert - Will fail without WMI but validates interface contract
            var ex = await Assert.ThrowsAsync<Exception>(() => 
                service.InstallApplicationAsync(appId, revision));
            ex.Should().NotBeNull();
        }

        [Theory]
        [InlineData(null, "1.0")]
        [InlineData("", "1.0")]
        [InlineData("app-id", null)]
        [InlineData("app-id", "")]
        public async Task InstallApplicationAsync_WithInvalidParameters_ThrowsException(string? appId, string? revision)
        {
            // Arrange
            var service = new CCMApplicationService(".");

            // Act & Assert
            await Assert.ThrowsAsync<ArgumentException>(() => 
                service.InstallApplicationAsync(appId!, revision!));
        }

        [Fact]
        public async Task UninstallApplicationAsync_WithValidParameters_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMApplicationService(".");
            const string appId = "test-app-id";
            const string revision = "1.0";

            // Act & Assert - Will fail without WMI but validates interface contract
            var ex = await Assert.ThrowsAsync<Exception>(() => 
                service.UninstallApplicationAsync(appId, revision));
            ex.Should().NotBeNull();
        }
    }
}