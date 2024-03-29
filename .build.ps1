<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param(
	$Culture = 'en-US'
)

Set-StrictMode -Version Latest

# Working script is located in the path, get its full path.
$ScriptFile = (Get-Command Helps.ps1).Definition
$ScriptRoot = Split-Path $ScriptFile

# Synopsis: Convert markdown files to HTML
# <http://johnmacfarlane.net/pandoc/>
task markdown {
	function Convert-Markdown($Name) {pandoc.exe --standalone --from=gfm "--output=$Name.htm" "--metadata=pagetitle=$Name" "$Name.md"}
	exec { Convert-Markdown README }
	exec { Convert-Markdown Release-Notes }
}

# Synopsis: Remove temp files
task clean {
	remove z, z.ps1, en-US, ru-RU, Helps.*.nupkg, README.htm, Release-Notes.htm
}

# Synopsis: Set $script:Version
task version {
	($script:Version = .{ switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {return $Matches[1]}} })
	assert $Version
}

# Synopsis: Copy Helps.ps1 from its working location to the project
task updateScript {
	$target = Get-Item Helps.ps1 -ErrorAction 0
	$source = Get-Item $ScriptFile
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $ScriptFile .
}

# Synopsis: Calls Test\Test-Helps.ps1
task test updateScript, helpEn, helpRu, {
	$ErrorView = 'NormalView'
	Set-Location Test

	.\Test-Helps.ps1

	Invoke-Build * -Result result
	equals $result.Tasks.Count 49
	equals $result.Errors.Count 0
	equals $result.Warnings.Count 2
},
clean

# Synopsis: Tests in PS Core
task test7 {
	exec {pwsh -NoProfile -Command Invoke-Build.ps1 test}
}

# Synopsis: Build and test en-US help
task helpEn {
	$null = mkdir en-US -Force

	. Helps.ps1
	Convert-Helps Help\Helps-Help.ps1 .\en-US\Helps-Help.xml @{ UICulture = 'en-US' }

	Copy-Item .\en-US\Helps-Help.xml $ScriptRoot\Helps-Help.xml

	Set-Location Help
	Test-Helps Helps-Help.ps1
}

# Synopsis: Build and test ru-RU help
task helpRu {
	$null = mkdir ru-RU -Force

	. Helps.ps1
	Convert-Helps Help\Helps-Help.ps1 .\ru-RU\Helps-Help.xml @{ UICulture = 'ru-RU' }

	Set-Location Help
	Test-Helps Helps-Help.ps1
}

# Synopsis: View help using the $Culture
task view {
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
task package markdown, helpEn, helpRu, updateScript, {
	# package directories
	remove z
	$null = mkdir z\tools\en-US, z\tools\ru-RU

	# copy files
	Copy-Item README.md z
	Copy-Item en-US\Helps-Help.xml z\tools\en-US
	Copy-Item ru-RU\Helps-Help.xml z\tools\ru-RU
	Copy-Item -Destination z\tools @(
		'Helps.ps1'
		'LICENSE'
		'README.htm'
		'Release-Notes.htm'
	)
}

# Synopsis: Make the NuGet package
task nuget package, version, {
	$description = @'
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
	    <developmentDependency>true</developmentDependency>
		<license type="expression">Apache-2.0</license>
		<readme>README.md</readme>
		<projectUrl>https://github.com/nightroman/Helps</projectUrl>
		<description>$description</description>
		<releaseNotes>https://github.com/nightroman/Helps/blob/main/Release-Notes.md</releaseNotes>
		<tags>powershell help builder</tags>
	</metadata>
</package>
"@
	# pack
	exec { NuGet pack z\Package.nuspec -NoPackageAnalysis }
}

# Synopsis: Push with a version tag.
task pushRelease version, {
	$changes = exec { git status --short }
	assert (!$changes) "Please, commit changes."

	exec { git push }
	exec { git tag -a "v$Version" -m "v$Version" }
	exec { git push origin "v$Version" }
}

# Synopsis: Push NuGet package.
task pushNuGet nuget, {
	$ApiKey = Read-Host nuget.org-ApiKey
	exec { NuGet.exe push "Helps.$Version.nupkg" -Source nuget.org -ApiKey $ApiKey }
},
clean

# Synopsis: Build help files, run tests.
task . test7, test
