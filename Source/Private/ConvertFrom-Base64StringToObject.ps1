function ConvertFrom-Base64ToObject {
	# TODO - Add help
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
			Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Alias('string')]
		[string]$inputString
	)
	$data = [System.convert]::FromBase64String($inputString)
	$memoryStream = New-Object System.Io.MemoryStream
	$memoryStream.write($data, 0, $data.length)
	$memoryStream.seek(0, 0) | Out-Null
	$streamReader = New-Object System.IO.StreamReader(New-Object System.IO.Compression.GZipStream($memoryStream, [System.IO.Compression.CompressionMode]::Decompress))
	$decompressedData = ConvertFrom-CliXml ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($streamReader.readtoend()))))
	return $decompressedData
}