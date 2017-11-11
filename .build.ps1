
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

param(
	$Culture = 'en-US'
)

$ModuleName = 'Helps'
$ModuleRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) WindowsPowerShell\Modules\$ModuleName

Set-StrictMode -Version Latest

$TargetFiles = @(
	"$ModuleRoot/Helps.ps1"
	"$ModuleRoot/Helps.psd1"
	"$ModuleRoot/Helps.psm1"
	"$ModuleRoot/en-US/about_$ModuleName.help.txt"
	"$ModuleRoot/en-US/Helps-Help.xml"
	"$ModuleRoot/ru-RU/about_$ModuleName.help.txt"
	"$ModuleRoot/ru-RU/Helps-Help.xml"
)

# Synopsis: Assembles files in the target module folder.
# Target directories are created by help tasks.
task Build Version, HelpEn, HelpRu, {
	Copy-Item -Destination $ModuleRoot @(
		"Helps.ps1"
		"Helps.psm1"
	)
	Copy-Item -Destination $ModuleRoot/en-US @(
		"Help/en-US/about_$ModuleName.help.txt"
	)
	Copy-Item -Destination $ModuleRoot/ru-RU @(
		"Help/ru-RU/about_$ModuleName.help.txt"
	)

	# make manifest
	$Summary = 'PowerShell help file builder'
	Set-Content "$ModuleRoot/Helps.psd1" @"
@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '$Version'
	Description = '$Summary'
	CompanyName = 'https://github.com/nightroman/$ModuleName'
	Copyright = 'Copyright (c) 2011-2017 Roman Kuzmin'

	ModuleToProcess = 'Helps.psm1'
	PowerShellVersion = '2.0'
	GUID = '8b45439c-46eb-459e-a090-3b7bbc1af1b1'

	FunctionsToExport = 'Convert-Helps', 'Merge-Helps', 'New-Helps', 'Test-Helps'
	VariablesToExport = @()
	CmdletsToExport = @()
	AliasesToExport = @()

	PrivateData = @{
		PSData = @{
			Tags = 'help', 'build', 'MAML', 'XML'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ProjectUri = 'https://github.com/nightroman/$ModuleName'
			ReleaseNotes = 'https://github.com/nightroman/$ModuleName/blob/master/Release-Notes.md'
		}
	}
}
"@
}

# Synopsis: Convert markdown files to HTML
# <http://johnmacfarlane.net/pandoc/>
task Markdown {
	exec { pandoc.exe --standalone --from=markdown_strict --output=README.htm README.md }
	exec { pandoc.exe --standalone --from=markdown_strict --output=Release-Notes.htm Release-Notes.md }
}

# Synopsis: Remove temp files
task Clean {
	Remove-Item z, z.ps1, en-US, ru-RU, Helps.*.nupkg, README.htm, Release-Notes.htm -Force -Recurse -ErrorAction 0
}

# Synopsis: Set $script:Version
task Version {
	($script:Version = .{ switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {return $Matches[1]}} })
	assert $Version
}

# Synopsis: Copy Helps.ps1 from its working location to the project
task UpdateScript {
	$target = Get-Item Helps.ps1 -ErrorAction 0
	$source = Get-Item $ScriptFile
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $ScriptFile .
}

# Synopsis: Calls Test\Test-Helps.ps1
task Test UpdateScript, HelpEn, HelpRu, {
	Set-Location Test

	.\Test-Helps.ps1

	Invoke-Build * -Result result
	equals $result.Tasks.Count 49
	equals $result.Errors.Count 0
	equals $result.Warnings.Count 2
},
Clean

# Synopsis: Tests in PS v2
task Test2 {
	exec {PowerShell.exe -Version 2 -NoProfile Invoke-Build.ps1 Test}
}

# Synopsis: Build en-US help
task HelpEn {
	$null = mkdir "$ModuleRoot/en-US" -Force

	. ./Helps.ps1
	Convert-Helps Help/Helps-Help.ps1 "$ModuleRoot/en-US/Helps-Help.xml" @{ UICulture = 'en-US' }

	#??Set-Location Help
	#??Test-Helps Helps-Help.ps1
}

# Synopsis: Build and test ru-RU help
task HelpRu {
	$null = mkdir "$ModuleRoot/ru-RU" -Force

	. ./Helps.ps1
	Convert-Helps Help/Helps-Help.ps1 "$ModuleRoot/ru-RU/Helps-Help.xml" @{ UICulture = 'ru-RU' }

	#??Set-Location Help
	#??Test-Helps Helps-Help.ps1
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
	) | .{process{
		'#'*77
		Get-Help $_ -Full | Out-String -Width 80
	}} | Out-File $file
	notepad $file
}

# Synopsis: Make the package in z\tools for NuGet
task Package Markdown, HelpEn, HelpRu, UpdateScript, {
	# package directories
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\tools\en-US, z\tools\ru-RU

	# copy files
	Copy-Item en-US\Helps-Help.xml z\tools\en-US
	Copy-Item ru-RU\Helps-Help.xml z\tools\ru-RU
	Copy-Item -Destination z\tools `
	Helps.ps1,
	LICENSE.txt,
	README.htm,
	Release-Notes.htm
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
		<developmentDependency>true</developmentDependency>
	</metadata>
</package>
"@
	# pack
	exec { NuGet pack z\Package.nuspec -NoPackageAnalysis }
}

# Synopsis: Push with a version tag.
task PushRelease Version, {
	$changes = exec { git status --short }
	assert (!$changes) "Please, commit changes."

	exec { git push }
	exec { git tag -a "v$Version" -m "v$Version" }
	exec { git push origin "v$Version" }
}

# Synopsis: Push NuGet package.
task PushNuGet NuGet, {
	exec { NuGet push "Helps.$Version.nupkg" }
},
Clean

# Synopsis: Build help files, run tests.
task . Test2, Test
