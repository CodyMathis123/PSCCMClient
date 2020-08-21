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
	$tempString = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([management.automation.psserializer]::Serialize($inputObject)))
	$memoryStream = New-Object System.IO.MemoryStream
	$compressionStream = New-Object System.IO.Compression.GZipStream($memoryStream, [System.io.compression.compressionmode]::Compress)
	$streamWriter = New-Object System.IO.streamwriter($compressionStream)
	$streamWriter.write($tempString)
	$streamWriter.close()
	$compressedData = [System.convert]::ToBase64String($memoryStream.ToArray())
	return $compressedData
}