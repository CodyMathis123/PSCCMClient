function Convert-FunctionToString {
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
    [string]::Join("`r`n", $AllFunctions)
}