
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

param(
	$Culture = 'en-US'
)

Set-StrictMode -Version Latest

# Working script is located in the path, get its full path.
$ScriptFile = (Get-Command Helps.ps1).Definition
$ScriptRoot = Split-Path $ScriptFile

# Import markdown tasks ConvertMarkdown and RemoveMarkdownHtml.
# <https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks>
Markdown.tasks.ps1

# Synopsis: Remove temp files
task Clean RemoveMarkdownHtml, {
	Remove-Item z, z.ps1, en-US, ru-RU, Helps.*.nupkg -Force -Recurse -ErrorAction 0
}

# Synopsis: Set $script:Version
task Version {
	. Helps
	($script:Version = Get-HelpsVersion)
}

# Synopsis: Copy Helps.ps1 from its working location to the project.
task UpdateScript {
	$target = Get-Item Helps.ps1 -ErrorAction 0
	$source = Get-Item $ScriptFile
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $ScriptFile .
}

# Synopsis: Calls Demo\Test-Helps.ps1
task Test UpdateScript, HelpEn, HelpRu, {
	Set-Location Demo

	.\Test-Helps.ps1

	Invoke-Build * -Result result
	assert (46 -eq $result.Tasks.Count) $result.Tasks.Count
	assert (0 -eq $result.Errors.Count) $result.Errors.Count
	assert (2 -eq $result.Warnings.Count) $result.Warnings.Count
},
Clean

# Synopsis: Build and test en-US help
task HelpEn {
	$null = mkdir en-US -Force

	. Helps.ps1
	Convert-Helps Demo\Helps-Help.ps1 .\en-US\Helps-Help.xml @{ UICulture = 'en-US' }

	Copy-Item .\en-US\Helps-Help.xml $ScriptRoot\Helps-Help.xml

	Set-Location Demo
	Test-Helps Helps-Help.ps1
}

# Synopsis: Build and test ru-RU help
task HelpRu {
	$null = mkdir ru-RU -Force

	. Helps.ps1
	Convert-Helps Demo\Helps-Help.ps1 .\ru-RU\Helps-Help.xml @{ UICulture = 'ru-RU' }

	Set-Location Demo
	Test-Helps Helps-Help.ps1
}

# Synopsis: View help using the $Culture
task View {
	$file = "$env:TEMP\help.txt"
	[System.Threading.Thread]::CurrentThread.CurrentUICulture = $Culture
	. Helps.ps1
	@(
		'Helps.ps1'
		'Convert-Helps'
		'Merge-Helps'
		'New-Helps'
		'Test-Helps'
	) | %{
		'#'*77
		Get-Help $_ -Full | Out-String -Width 80
	} | Out-File $file
	notepad $file
}

# Synopsis: Make the package in z\tools for NuGet
task Package ConvertMarkdown, HelpEn, HelpRu, UpdateScript, {
	# package directories
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\tools\en-US, z\tools\ru-RU, z\tools\Demo\en-US, z\tools\Demo\ru-RU

	# copy project files
	Copy-Item -Destination z\tools @(
		'Helps.ps1'
		'LICENSE.txt'
	)
	Copy-Item -Destination z\tools\en-US 'en-US\Helps-Help.xml'
	Copy-Item -Destination z\tools\ru-RU 'ru-RU\Helps-Help.xml'

	# move generated files
	Move-Item -Destination z\tools @(
		'README.htm'
		'Release-Notes.htm'
	)
}

# Synopsis: Make the NuGet package
task NuGet Package, Version, {
	$text = @'
Helps.ps1 provides functions for building PowerShell XML help files from help
scripts and for creating help script templates for existing objects. Help can
be created for everything that supports XML help: cmdlets, providers, scripts,
and functions in scripts or modules.
'@
	Set-Content z\Package.nuspec @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata>
		<id>Helps</id>
		<version>$Version</version>
		<authors>Roman Kuzmin</authors>
		<owners>Roman Kuzmin</owners>
		<projectUrl>https://github.com/nightroman/Helps</projectUrl>
		<licenseUrl>http://www.apache.org/licenses/LICENSE-2.0</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<summary>$text</summary>
		<description>$text</description>
		<tags>powershell help builder</tags>
		<releaseNotes>https://github.com/nightroman/Helps/blob/master/Release-Notes.md</releaseNotes>
	</metadata>
</package>
"@
	# pack
	exec { NuGet pack z\Package.nuspec -NoPackageAnalysis }
}

# Synopsis: Build help files, run tests.
task . Test
