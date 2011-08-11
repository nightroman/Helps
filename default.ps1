
# psake build script.

properties {
	$Culture = 'en-US'
}

task default -depends help-en-US, help-ru-RU, test

task test -description 'Calls Demo\Test-Helps.ps1' {
	Push-Location Demo
	.\Test-Helps.ps1
	Pop-Location
}

task help-en-US -description 'Builds/tests en-US help' {
	Import-Module Helps
	Convert-Helps Demo\Helps-Help.ps1 .\en-US\Helps-Help.xml @{ UICulture = 'en-US' }

	Push-Location Demo
	Test-Helps Helps-Help.ps1
	Pop-Location
}

task help-ru-RU -description 'Builds/tests ru-RU help' {
	Import-Module Helps
	Convert-Helps Demo\Helps-Help.ps1 .\ru-RU\Helps-Help.xml @{ UICulture = 'ru-RU' }

	Push-Location Demo
	Test-Helps Helps-Help.ps1
	Pop-Location
}

task view -description 'View help using the $Culture' {
	[System.Threading.Thread]::CurrentThread.CurrentUICulture = $Culture
	Import-Module Helps
	@(
		'about_Helps'
		'Convert-Helps'
		'Merge-Helps'
		'New-Helps'
		'Test-Helps'
	) | %{
		'#'*77
		Get-Help $_ -Full | Out-String -Width 80
	} | Out-File \temp\help.txt
	notepad \temp\help.txt
}

task zip -description 'Make the public archive' {
	$Version = &{ Import-LocalizedData -FileName Helps -BindingVariable _; $_.ModuleVersion }

	Remove-Item [z] -Force -Recurse
	$null = mkdir z\Helps\Demo, z\Helps\en-US, z\Helps\ru-RU

	Copy-Item -Destination z\Helps @(
		'ConvertTo-Maml.ps1'
		'ConvertTo-MamlCommand.ps1'
		'ConvertTo-MamlProvider.ps1'
		'Helps.psd1'
		'Helps.psm1'
		'History.txt'
		'License.txt'
		'QuickStart.txt'
	)
	Copy-Item -Destination z\Helps\Demo @(
		'Demo\Helps-Help.ps1'
		'Demo\Test-Helps.ps1'
		'Demo\Test-Helps-Help.ps1'
		'Demo\TestProvider.dll-Help.ps1'
		'Demo\TestProvider.cs'
	)
	Copy-Item -Destination z\Helps\Demo\en-US Demo\en-US*
	Copy-Item -Destination z\Helps\Demo\ru-RU Demo\ru-RU*
	Copy-Item -Destination z\Helps\en-US en-US\*
	Copy-Item -Destination z\Helps\ru-RU ru-RU\*

	Exec {
		Push-Location z
		& 7z a "..\Helps.$Version.zip" .\*
		Pop-Location
	}

	Remove-Item z -Force -Recurse
}
