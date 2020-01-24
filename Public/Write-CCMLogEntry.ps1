Function Write-CCMLogEntry {
    <#
        .SYNOPSIS
            Write to a log file in the CMTrace Format
        .DESCRIPTION
            The function is used to write to a log file in a CMTrace compatible format. This ensures that CMTrace or OneTrace can parse the log
            and provide data in a familiar format.
        .PARAMETER Value
            String to be added it to the log file as the message, or value
        .PARAMETER Severity
            Severity for the log entry. 1 for Informational, 2 for Warning, and 3 for Error.
        .PARAMETER Component
            Stage that the log entry is occuring in, log refers to as 'component.'
        .PARAMETER FileName
            Name of the log file that the entry will written to - note this should not be the full path.
        .PARAMETER Folder
            Path to the folder where the log will be stored.
        .PARAMETER Bias
            Set timezone Bias to ensure timestamps are accurate. This defaults to the local machines bias, but one can be provided. It can be
            helperful to gather the bias once, and store it in a variable that is passed to this parameter as part of a splat, or $PSDefaultParameterValues
        .PARAMETER MaxLogFileSize
            Maximum size of log file before it rolls over. Set to 0 to disable log rotation. Defaults to 5MB
        .PARAMETER LogsToKeep
            Maximum number of rotated log files to keep. Set to 0 for unlimited rotated log files. Defaults to 0.
        .EXAMPLE
            C:\PS> Write-CCMLogEntry -Value 'Testing Function' -Component 'Test Script' -FileName 'LogTest.Log' -Folder 'c:\temp'
                Write out 'Testing Function' to the c:\temp\LogTest.Log file in a CMTrace format, noting 'Test Script' as the component.
        .NOTES
            FileName:    Write-CCMLogEntry.ps1
            Author:      Cody Mathis, Adam Cook
            Contact:     @CodyMathis123, @codaamok
            Created:     2020-01-23
            Updated:     2020-01-23
    #>
    param (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Message', 'ToLog')]
        [string[]]$Value,
        [parameter(Mandatory = $false)]
        [ValidateSet(1, 2, 3)]
        [int]$Severity = 1,
        [parameter(Mandatory = $false)]
        [string]$Component,
        [parameter(Mandatory = $true)]
        [string]$FileName,
        [parameter(Mandatory = $true)]
        [string]$Folder,
        [parameter(Mandatory = $false)]
        [int]$Bias = (Get-CimInstance -Query "SELECT Bias FROM Win32_TimeZone").Bias,
        [parameter(Mandatory = $false)]
        [int]$MaxLogFileSize = 5MB,
        [parameter(Mandatory = $false)]
        [int]$LogsToKeep = 0
    )
    begin {
        # Determine log file location
        $LogFilePath = Join-Path -Path $Folder -ChildPath $FileName

        #region log rollover check if $MaxLogFileSize is greater than 0
        switch (([System.IO.FileInfo]$LogFilePath).Exists -and $MaxLogFileSize -gt 0) {
            $true {
                #region rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
                switch (([System.IO.FileInfo]$LogFilePath).Length -ge $MaxLogFileSize) {
                    $true {
                        # Get log file name without extension
                        $LogFileNameWithoutExt = $FileName -replace ([System.IO.Path]::GetExtension($FileName))

                        # Get already rolled over logs
                        $AllLogs = Get-ChildItem -Path $Folder -Name "$($LogFileNameWithoutExt)_*" -File

                        # Sort them numerically (so the oldest is first in the list)
                        $AllLogs = Sort-Object -InputObject $AllLogs -Descending -Property { $_ -replace '_\d+\.lo_$' }, { [int]($_ -replace '^.+\d_|\.lo_$') } -ErrorAction Ignore

                        foreach ($Log in $AllLogs) {
                            # Get log number
                            $LogFileNumber = [int][Regex]::Matches($Log, "_([0-9]+)\.lo_$").Groups[1].Value
                            switch (($LogFileNumber -eq $LogsToKeep) -and ($LogsToKeep -ne 0)) {
                                $true {
                                    # Delete log if it breaches $LogsToKeep parameter value
                                    [System.IO.File]::Delete("$($Folder)\$($Log)")
                                }
                                $false {
                                    # Rename log to +1
                                    $NewFileName = $Log -replace "_([0-9]+)\.lo_$", "_$($LogFileNumber+1).lo_"
                                    [System.IO.File]::Copy("$($Folder)\$($Log)", "$($Folder)\$($NewFileName)", $true)
                                }
                            }
                        }

                        # Copy main log to _1.lo_
                        [System.IO.File]::Copy($LogFilePath, "$($Folder)\$($LogFileNameWithoutExt)_1.lo_", $true)

                        # Blank the main log
                        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, $false
                        $StreamWriter.Close()
                    }
                }
                #endregion rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
            }
        }
        #endregion log rollover check if $MaxLogFileSize is greater than 0

        # Construct date for log entry
        $Date = (Get-Date -Format 'MM-dd-yyyy')

        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    }
    process {
        foreach ($MSG in $Value) {
            #region construct time stamp for log entry based on $Bias and current time
            $Time = switch -regex ($Bias) {
                '-' {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), $Bias)
                }
                Default {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), '+', $Bias)
                }
            }
            #endregion construct time stamp for log entry based on $Bias and current time

            #region construct the log entry according to CMTrace format
            $LogText = [string]::Format('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">', $MSG, $Time, $Date, $Component, $Context, $Severity, $PID)
            #endregion construct the log entry according to CMTrace format

            #region add value to log file
            try {
                $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, 'Append'
                $StreamWriter.WriteLine($LogText)
                $StreamWriter.Close()
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"
            }
            #endregion add value to log file
        }
    }
}