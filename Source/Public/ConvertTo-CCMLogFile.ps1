function ConvertTo-CCMLogFile {
    param(
        [CMLogEntry[]]$CMLogEntries,
        [string]$LogPath
    )
    $LogContent = foreach ($Entry in ($CMLogEntries | Sort-Object -Property Timestamp)) {
        $Entry.ConvertToCMLogLine()
    }

    Set-Content -Path $LogPath -Value $LogContent -Force
}