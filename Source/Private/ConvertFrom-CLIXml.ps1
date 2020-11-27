function ConvertFrom-CliXml {
	# TODO - Add help
	param (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[String[]]$InputObject
	)
	begin {
		$OFS = "`n"
		[String]$xmlString = ""
	}
	process {
		$xmlString += $InputObject
	}
	end {
		$Type = [PSObject].Assembly.GetType('System.Management.Automation.Deserializer')
		$ctor = $Type.GetConstructor('instance,nonpublic', $null, @([xml.xmlreader]), $null)
		$StringReader = [System.IO.StringReader]::new($xmlString)
		$XmlReader = [System.Xml.XmlTextReader]::new($StringReader)
		$Deserializer = $ctor.Invoke($XmlReader)
		$null = $Type.GetMethod('Done', [System.Reflection.BindingFlags]'nonpublic,instance')
		while (!$Type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $Deserializer, @())) {
			try {
				$Type.InvokeMember("Deserialize", "InvokeMethod,NonPublic,Instance", $null, $Deserializer, @())
			}
			catch {
				Write-Warning "Could not deserialize ${string}: $_"
			}
		}
		$XmlReader.Close()
		$StringReader.Dispose()
	}
}