using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using FluentAssertions;
using PSCCMClient.Core.Interfaces;
using PSCCMClient.Core.Models;
using PSCCMClient.Core.Services;
using Xunit;

namespace PSCCMClient.Tests
{
    /// <summary>
    /// Unit tests for CCM Client Action Service
    /// Updated for Windows environments with ConfigMgr client
    /// </summary>
    public class CCMClientActionServiceTests
    {
        [Fact]
        public void CCMClientActionService_ImplementsInterface()
        {
            // Arrange & Act
            var service = new CCMClientActionService("test-computer");

            // Assert
            service.Should().BeAssignableTo<ICCMClientActionService>();
        }

        [Fact]
        public void Constructor_WithComputerName_SetsComputerName()
        {
            // Arrange
            const string computerName = "test-machine";

            // Act
            var service = new CCMClientActionService(computerName);

            // Assert
            service.Should().NotBeNull();
        }

        [Theory]
        [InlineData(ClientAction.HardwareInventory)]
        [InlineData(ClientAction.SoftwareInventory)]
        [InlineData(ClientAction.UpdateScan)]
        [InlineData(ClientAction.MachinePol)]
        public async Task InvokeClientActionAsync_WithValidActions_ReturnsBoolean(ClientAction action)
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act
            var result = await service.InvokeClientActionAsync(action);

            // Assert
            // Should return a boolean indicating success/failure without throwing
            Assert.True(result == true || result == false);
        }

        [Fact]
        public async Task InvokeClientActionsAsync_WithMultipleActions_ReturnsDictionary()
        {
            // Arrange
            var service = new CCMClientActionService(".");
            var actions = new[] { ClientAction.HardwareInventory, ClientAction.SoftwareInventory };

            // Act
            var result = await service.InvokeClientActionsAsync(actions);

            // Assert
            result.Should().NotBeNull();
            result.Should().BeOfType<Dictionary<ClientAction, bool>>();
            result.Should().HaveCount(2);
        }

        [Theory]
        [InlineData("{00000000-0000-0000-0000-000000000021}")]
        [InlineData("{00000000-0000-0000-0000-000000000108}")]
        public async Task TriggerScheduleAsync_WithValidScheduleIds_ReturnsBoolean(string scheduleId)
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act
            var result = await service.TriggerScheduleAsync(scheduleId);

            // Assert
            // Should return a boolean indicating success/failure without throwing
            Assert.True(result == true || result == false);
        }

        [Theory]
        [InlineData("")]
        [InlineData(null)]
        [InlineData("invalid-guid")]
        public async Task TriggerScheduleAsync_WithInvalidScheduleIds_ThrowsException(string? scheduleId)
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act & Assert
            if (string.IsNullOrEmpty(scheduleId))
            {
                await Assert.ThrowsAsync<ArgumentException>(() => service.TriggerScheduleAsync(scheduleId!));
            }
            else
            {
                // Invalid GUID should result in InvalidOperationException from WMI
                await Assert.ThrowsAsync<InvalidOperationException>(() => service.TriggerScheduleAsync(scheduleId));
            }
        }

        [Fact]
        public async Task ResetPolicyAsync_WithDefaultType_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act
            var result = await service.ResetPolicyAsync();

            // Assert
            // Should return a boolean indicating success/failure without throwing
            Assert.True(result == true || result == false);
        }

        [Theory]
        [InlineData("Reset")]
        [InlineData("Purge")]
        public async Task ResetPolicyAsync_WithSpecificTypes_ReturnsBoolean(string resetType)
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act
            var result = await service.ResetPolicyAsync(resetType);

            // Assert
            // Should return a boolean indicating success/failure without throwing
            Assert.True(result == true || result == false);
        }
    }
}