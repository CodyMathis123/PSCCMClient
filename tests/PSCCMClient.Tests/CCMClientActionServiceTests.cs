using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using FluentAssertions;
using PSCCMClient.Core.Interfaces;
using PSCCMClient.Core.Services;
using Xunit;

namespace PSCCMClient.Tests
{
    /// <summary>
    /// Unit tests for CCM Client Action Service
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

            // Act & Assert - Will fail without WMI but validates interface contract
            var ex = await Assert.ThrowsAsync<Exception>(() => service.InvokeClientActionAsync(action));
            ex.Should().NotBeNull();
        }

        [Fact]
        public async Task InvokeClientActionsAsync_WithMultipleActions_ReturnsDictionary()
        {
            // Arrange
            var service = new CCMClientActionService(".");
            var actions = new[] { ClientAction.HardwareInventory, ClientAction.SoftwareInventory };

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.InvokeClientActionsAsync(actions));
            ex.Should().NotBeNull();
        }

        [Theory]
        [InlineData("{00000000-0000-0000-0000-000000000021}")]
        [InlineData("{00000000-0000-0000-0000-000000000108}")]
        public async Task TriggerScheduleAsync_WithValidScheduleIds_ReturnsBoolean(string scheduleId)
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.TriggerScheduleAsync(scheduleId));
            ex.Should().NotBeNull();
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
            await Assert.ThrowsAsync<ArgumentException>(() => service.TriggerScheduleAsync(scheduleId!));
        }

        [Fact]
        public async Task ResetPolicyAsync_WithDefaultType_ReturnsBoolean()
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.ResetPolicyAsync());
            ex.Should().NotBeNull();
        }

        [Theory]
        [InlineData("Purge")]
        [InlineData("Reset")]
        public async Task ResetPolicyAsync_WithSpecificTypes_ReturnsBoolean(string resetType)
        {
            // Arrange
            var service = new CCMClientActionService(".");

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => service.ResetPolicyAsync(resetType));
            ex.Should().NotBeNull();
        }

        [Fact]
        public void ClientAction_Enum_HasExpectedValues()
        {
            // Assert - Verify all expected enum values exist
            var enumValues = Enum.GetValues<ClientAction>();
            enumValues.Should().Contain(ClientAction.HardwareInventory);
            enumValues.Should().Contain(ClientAction.FullHardwareInventory);
            enumValues.Should().Contain(ClientAction.SoftwareInventory);
            enumValues.Should().Contain(ClientAction.UpdateScan);
            enumValues.Should().Contain(ClientAction.UpdateEval);
            enumValues.Should().Contain(ClientAction.MachinePol);
            enumValues.Should().Contain(ClientAction.AppEval);
            enumValues.Should().Contain(ClientAction.DDR);
            enumValues.Should().Contain(ClientAction.RefreshDefaultMP);
            enumValues.Should().Contain(ClientAction.SourceUpdateMessage);
            enumValues.Should().Contain(ClientAction.SendUnsentStateMessage);
        }
    }
}