namespace PSCCMClient.Core.Models
{
    /// <summary>
    /// Available client actions
    /// </summary>
    public enum ClientAction
    {
        HardwareInventory,
        FullHardwareInventory,
        SoftwareInventory,
        UpdateScan,
        UpdateEval,
        MachinePol,
        AppEval,
        DDR,
        RefreshDefaultMP,
        SourceUpdateMessage,
        SendUnsentStateMessage
    }
}