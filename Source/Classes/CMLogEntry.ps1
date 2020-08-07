class CMLogEntry {
    [string]$Message
    [Severity]$Type
    [string]$Component
    [int]$Thread
    [datetime]$Timestamp

    CMLogEntry() {
    }

    CMLogEntry([string]$Message, [Severity]$Type, [string]$Component, [int]$Thread) {
        $this.Message = $Message
        $this.Type = $Type
        $this.Component = $Component
        $this.Thread = $Thread
    }

    [void]ResolveTimestamp([array]$LogLineSubArray, [CMLogType]$Type) {
        [string]$DateString = [string]::Empty
        [string]$TimeString = [string]::Empty

        try {
            switch ($Type) {
                FullCMTrace {
                    $DateString = $LogLineSubArray[3]
                    $TimeString = $LogLineSubArray[1].Split([char]43, [char]45, [System.StringSplitOptions]::RemoveEmptyEntries)[0].Substring(0, 12)
                }
                SimpleCMTrace {
                    $DateTimeString = $LogLineSubArray[1]
                    $DateTimeStringArray = $DateTimeString.Split([char]32, [System.StringSplitOptions]::RemoveEmptyEntries)
                    $DateString = $DateTimeStringArray[0]
                    $TimeString = $DateTimeStringArray[1].Split([char]43, [char]45, [System.StringSplitOptions]::RemoveEmptyEntries)[0].Substring(0, 12)
                }
            }
        }
        catch {
            if ($null -eq $DateString) {
                Write-Warning "Failed to split DateString [LogLineSubArray: $LogLineSubArray] [Error: $($_.Exception.Message)]"
            }
            elseif ($null -eq $TimeString) {
                Write-Warning "Failed to split TimeString [LogLineSubArray: $LogLineSubArray] [Error: $($_.Exception.Message)]"
            }
        }
        $DateStringArray = $DateString.Split([char]45)

        $MonthParser = $DateStringArray[0] -replace '\d', 'M'
        $DayParser = $DateStringArray[1] -replace '\d', 'd'

        $DateTimeFormat = [string]::Format('{0}-{1}-yyyyHH:mm:ss.fff', $MonthParser, $DayParser)
        $DateTimeString = [string]::Format('{0}{1}', $DateString, $TimeString)
        try {
            $This.Timestamp = [datetime]::ParseExact($DateTimeString, $DateTimeFormat, $null)
        }
        catch {
            Write-Warning "Failed to parse [DateString: $DateString] [TimeString: $TimeString] with [Parser: $DateTimeFormat] [Error: $($_.Exception.Message)]"
        }
    }
}