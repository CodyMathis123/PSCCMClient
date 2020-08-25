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
	$data = [System.Convert]::FromBase64String($inputString)
	$MemoryStream = [System.IO.MemoryStream]::new()
	$MemoryStream.Write($data, 0, $data.length)
	$null = $MemoryStream.Seek(0, 0)
	$streamReader = [System.IO.StreamReader]::new([System.IO.Compression.GZipStream]::new($MemoryStream, [System.IO.Compression.CompressionMode]::Decompress))
	$decompressedData = ConvertFrom-CliXml ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($streamReader.ReadToEnd()))))
	return $decompressedData
}