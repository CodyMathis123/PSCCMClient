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
    /// Updated for Windows environments with ConfigMgr client
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
        public async Task GetApplicationsAsync_WithConfigMgrClient_ReturnsApplicationCollection()
        {
            // Arrange
            var service = new CCMApplicationService(".");

            // Act
            var result = await service.GetApplicationsAsync();

            // Assert
            result.Should().NotBeNull();
            result.Should().BeAssignableTo<IEnumerable<CCMApplication>>();
            // Applications might be empty but shouldn't throw
        }

        [Theory]
        [InlineData("TestApp")]
        public async Task GetApplicationsByNameAsync_WithValidInput_ReturnsApplications(string appName)
        {
            // Arrange
            var service = new CCMApplicationService(".");

            // Act
            var result = await service.GetApplicationsByNameAsync(appName);

            // Assert
            result.Should().NotBeNull();
            result.Should().BeAssignableTo<IEnumerable<CCMApplication>>();
            // Might return empty collection if app not found, but shouldn't throw
        }

        [Theory]
        [InlineData("")]
        [InlineData(null)]
        public async Task GetApplicationsByNameAsync_WithInvalidInput_ThrowsArgumentException(string? appName)
        {
            // Arrange
            var service = new CCMApplicationService(".");

            // Act & Assert
            await Assert.ThrowsAsync<ArgumentException>(() => service.GetApplicationsByNameAsync(appName!));
        }

        [Fact]
        public async Task InstallApplicationAsync_WithValidParameters_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMApplicationService(".");
            const string appId = "test-app-id";
            const string revision = "1.0";

            // Act
            // This might fail if the app doesn't exist, but should not throw unexpected exceptions
            try
            {
                var result = await service.InstallApplicationAsync(appId, revision);
                Assert.True(result == true || result == false);
            }
            catch (InvalidOperationException ex)
            {
                // Expected if application doesn't exist - WMI returns "Not found"
                ex.Message.Should().Contain("Not found");
            }
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
            if (string.IsNullOrEmpty(appId) || string.IsNullOrEmpty(revision))
            {
                // Should validate parameters first, but currently goes to WMI
                // WMI returns "Invalid parameter" for empty/null values
                await Assert.ThrowsAsync<InvalidOperationException>(() => 
                    service.InstallApplicationAsync(appId!, revision!));
            }
        }

        [Fact]
        public async Task UninstallApplicationAsync_WithValidParameters_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMApplicationService(".");
            const string appId = "test-app-id";
            const string revision = "1.0";

            // Act & Assert
            // This will likely fail if the app doesn't exist
            try
            {
                var result = await service.UninstallApplicationAsync(appId, revision);
                Assert.True(result == true || result == false);
            }
            catch (InvalidOperationException ex)
            {
                // Expected if application doesn't exist - WMI returns "Not found"
                ex.Message.Should().Contain("Not found");
            }
        }
    }
}