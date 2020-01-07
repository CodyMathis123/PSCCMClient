function Convert-FunctionToString {
    <#
        .SYNOPSIS
        Convert function to string
        .DESCRIPTION
            This function is used to take a function, and convert it to a string. This allows it to be
            moved around more easily
        .PARAMETER FunctionToConvert
            The name of the function(s) you wish to convert to a string. You can provide multiple
        .EXAMPLE
            PS C:\> Convert-FunctionTostring -FunctionToConvert 'Get-CMClientMaintenanceWindow'
        .NOTES
            FileName:    Convert-FunctionTostring.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-07
            Updated:     2020-01-07
#>
    param(
        [Parameter(Mandatory = $True)]
        [string[]]$FunctionToConvert
    )
    $AllFunctions = foreach ($FunctionName in $FunctionToConvert) {
        try {
            $Function = Get-Command -Name $FunctionName -CommandType Function -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to find the specified function [Name = '$FunctionName']"
            continue
        }
        $ScriptBlock = $Function.ScriptBlock
        if ($null -ne $ScriptBlock) {
            [string]::Format("`r`nfunction {0} {{{1}}}", $FunctionName, $ScriptBlock)
        }
        else {
            Write-Error "Function $FunctionName does not have a Script Block and cannot be converted."
        }
    }
    $AllFunctions -join "`r`n"
}