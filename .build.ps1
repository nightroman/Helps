
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

param
(
	$Culture = 'en-US'
)
Set-StrictMode -Version 2

# Working script is located in the path, get its full path
$ScriptFile = (Get-Command Helps.ps1).Definition
$ScriptRoot = Split-Path $ScriptFile

# Remove generated stuff.
task Clean {
	Remove-Item en-US, ru-RU -Force -Recurse
}

# Copy Helps.ps1 from its working location to the repository.
task UpdateScript {
	$target = Get-Item Helps.ps1 -ErrorAction 0
	$source = Get-Item $ScriptFile
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $ScriptFile .
}

# Calls Demo\Test-Helps.ps1
task Test UpdateScript, HelpEn, HelpRu, {
	Set-Location Demo
	.\Test-Helps.ps1
},
Clean

# Build and test en-US help
task HelpEn {
	$null = mkdir en-US -Force

	. Helps.ps1
	Convert-Helps Demo\Helps.ps1-Help.ps1 .\en-US\Helps.ps1-Help.xml @{ UICulture = 'en-US' }

	Copy-Item .\en-US\Helps.ps1-Help.xml $ScriptRoot\Helps.ps1-Help.xml

	Set-Location Demo
	Test-Helps Helps.ps1-Help.ps1
}

# Build and test ru-RU help
task HelpRu {
	$null = mkdir ru-RU -Force

	. Helps.ps1
	Convert-Helps Demo\Helps.ps1-Help.ps1 .\ru-RU\Helps.ps1-Help.xml @{ UICulture = 'ru-RU' }

	Set-Location Demo
	Test-Helps Helps.ps1-Help.ps1
}

# View help using the $Culture
task View {
	[System.Threading.Thread]::CurrentThread.CurrentUICulture = $Culture
	. Helps.ps1
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

# <https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks>
try { Markdown.tasks.ps1 }
catch { task ConvertMarkdown; task RemoveMarkdownHtml }

# Make the public archive
task Zip UpdateScript, ConvertMarkdown, HelpEn, HelpRu, {
	. Helps
	$Version = Get-HelpsVersion

	exec {
		& 7z a Helps.$Version.zip @(
			'Helps.ps1'
			'LICENSE.txt'
			'README.htm'
			'Release Notes.htm'
			'en-US\Helps.ps1-Help.xml'
			'ru-RU\Helps.ps1-Help.xml'
			'Demo\Helps.ps1-Help.ps1'
			'Demo\Test-Helps.ps1'
			'Demo\Test-Helps-Help.ps1'
			'Demo\TestProvider.dll-Help.ps1'
			'Demo\TestProvider.cs'
			'Demo\en-US\Helps.ps1-Help.psd1'
			'Demo\ru-RU\Helps.ps1-Help.psd1'
		)
	}
},
RemoveMarkdownHtml,
Clean

# Build help files, run tests.
task . Test
