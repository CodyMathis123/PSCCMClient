class CMLogEntry {
    [string]$Message
    [Severity]$Type
    [string]$Component
    [int]$Thread
    [datetime]$Timestamp
    hidden [string]$Offset

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
        [string]$TimeStringRaw = [string]::Empty

        try {
            switch ($Type) {
                FullCMTrace {
                    $DateString = $LogLineSubArray[3]
                    $TimeStringRaw = $LogLineSubArray[1]
                    $TimeString = $TimeStringRaw.Substring(0, 12)
                }
                SimpleCMTrace {
                    $DateTimeString = $LogLineSubArray[1]
                    $DateTimeStringArray = $DateTimeString.Split([char]32, [System.StringSplitOptions]::RemoveEmptyEntries)
                    $DateString = $DateTimeStringArray[0]
                    $TimeStringRaw = $DateTimeStringArray[1]
                    $TimeString = $TimeStringRaw.Substring(0, 12)
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

        $DateTimeFormat = [string]::Format('{0}-{1}-yyyyHH:mm:ss.fffzz', $MonthParser, $DayParser)
        $DateTimeString = [string]::Format('{0}{1}', $DateString, $TimeString)
        try {
            $This.Timestamp = [datetime]::ParseExact($DateTimeString, $DateTimeFormat, $null)
            # try{
                $this.Offset = $TimeStringRaw.Substring(12, 4)
            # }
            # catch {
                # $this.Offset = "+000"
            # }
        }
        catch {
            Write-Warning "Failed to parse [DateString: $DateString] [TimeString: $TimeString] with [Parser: $DateTimeFormat] [Error: $($_.Exception.Message)]"
        }
    }

    [bool]TestTimestampFilter([datetime]$TimestampGreaterThan, [datetime]$TimestampLessThan) {
        return $this.Timestamp -ge $TimestampGreaterThan -and $this.Timestamp -le $TimestampLessThan 
    }

    [string]ConvertToCMLogLine() {
        return [string]::Format('<![LOG[{0}]LOG]!><time="{1}{2}" date="{3}" component="{4}" context="" type="{5}" thread="{6}" file="">'
            , $this.Message
            , $this.Timestamp.ToString('HH:mm:ss.fffzz')
            , $this.Offset
            , $this.Timestamp.ToString('MM-dd-yyyy')
            , $this.Component
            , [int]$this.Type
            , $this.Thread)
    }
}
