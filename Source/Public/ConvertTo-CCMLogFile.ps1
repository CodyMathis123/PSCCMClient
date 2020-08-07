function ConvertTo-CCMLogFile {
    param(
        [CMLogEntry[]]$CMLogEntries,
        [string]$LogPath
    )
    $LogContent = foreach ($Entry in $CMLogEntries) {
        $Entry.ConvertToCMLogLine()
    }

    Set-Content -Path $LogPath -Value ($LogContent | Sort-Object -Property Timestamp) -Force
}