function Test-CimKnownError {
    param (
        [string]$FullyQualifiedErrorId
    )
    $KnownErrors = [System.Collections.Generic.List[string]]::new()
    $KnownErrors.Add('HRESULT 0x8033801a,Microsoft.Management.Infrastructure.CimCmdlets.InvokeCimMethodCommand'.ToLowerInvariant())
    
    return $KnownErrors.Contains($FullyQualifiedErrorId.ToLowerInvariant())
}