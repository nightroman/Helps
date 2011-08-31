
<#
.Synopsis
	Invoke-Build script (https://github.com/nightroman/Invoke-Build)
#>

param
(
	$Culture = 'en-US'
)

task . help-en-US, help-ru-RU, test

# Calls Demo\Test-Helps.ps1
task test {
	Set-Location Demo
	.\Test-Helps.ps1
}

# Builds/tests en-US help
task help-en-US {
	Import-Module Helps
	Convert-Helps Demo\Helps-Help.ps1 .\en-US\Helps-Help.xml @{ UICulture = 'en-US' }

	Set-Location Demo
	Test-Helps Helps-Help.ps1
}

# Builds/tests ru-RU help
task help-ru-RU {
	Import-Module Helps
	Convert-Helps Demo\Helps-Help.ps1 .\ru-RU\Helps-Help.xml @{ UICulture = 'ru-RU' }

	Set-Location Demo
	Test-Helps Helps-Help.ps1
}

# View help using the $Culture
task view {
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

# Make the public archive
task zip {
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
}
