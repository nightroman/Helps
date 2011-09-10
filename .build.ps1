
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

param
(
	$Culture = 'en-US'
)

# Build the module help, run tests.
task . HelpEn, HelpRu, Test

# Calls Demo\Test-Helps.ps1
task Test {
	Set-Location Demo
	.\Test-Helps.ps1
}

# Build and test en-US help
task HelpEn {
	Import-Module Helps
	Convert-Helps Demo\Helps-Help.ps1 .\en-US\Helps-Help.xml @{ UICulture = 'en-US' }

	Set-Location Demo
	Test-Helps Helps-Help.ps1
}

# Build and test ru-RU help
task HelpRu {
	Import-Module Helps
	Convert-Helps Demo\Helps-Help.ps1 .\ru-RU\Helps-Help.xml @{ UICulture = 'ru-RU' }

	Set-Location Demo
	Test-Helps Helps-Help.ps1
}

# View help using the $Culture
task View {
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

task ConvertMarkdown `
-Inputs { Get-ChildItem -Filter *.md } `
-Outputs {process{ [System.IO.Path]::ChangeExtension($_, 'htm') }} `
{process{
	Convert-Markdown.ps1 $_ $$
}}

# Make the public archive
task Zip ConvertMarkdown, {
	$Version = &{ Import-LocalizedData -FileName Helps -BindingVariable _; $_.ModuleVersion }

	Remove-Item [z] -Force -Recurse
	$null = mkdir z\Helps\Demo, z\Helps\en-US, z\Helps\ru-RU

	Copy-Item -Destination z\Helps @(
		'ConvertTo-Maml.ps1'
		'ConvertTo-MamlCommand.ps1'
		'ConvertTo-MamlProvider.ps1'
		'Helps.psd1'
		'Helps.psm1'
		'License.txt'
		'README.htm'
		'Release Notes.htm'
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

	exec {
		Push-Location z
		& 7z a "..\Helps.$Version.zip" .\*
		Pop-Location
	}

	Remove-Item z -Force -Recurse
	Remove-Item *.htm
}
