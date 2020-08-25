function ConvertTo-Base64StringFromObject {
	# TODO - Add help
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true,
			Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Alias('object', 'data', 'input')]
		[psobject]$inputObject
	)
	$tempString = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([Management.Automation.PsSerializer]::Serialize($inputObject)))
	$MemoryStream = [System.IO.MemoryStream]::new()
	$CompressionStream = [System.IO.Compression.GZipStream]::new($MemoryStream, [System.IO.Compression.CompressionMode]::Compress)
	$StreamWriter = [System.IO.StreamWriter]::new($CompressionStream)
	$StreamWriter.Write($tempString)
	$StreamWriter.Close()
	$CompressedData = [System.Convert]::ToBase64String($MemoryStream.ToArray())
	return $CompressedData
}