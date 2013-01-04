
<#
.Synopsis
	Builds exhaustive help from Test-Helps-Help.ps1, TestProvider.dll-Help.ps1

.Description
	This script should be invoked from its home directory.

.Outputs
	* The result help is normally saved as %TEMP%\Helps-Test.txt.
	* Helps-Test.log is new help file which different from the old.
	* TestProvider.dll is created for the dummy TestProvider being tested.
#>

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

if (!(Test-Path Test-Helps.ps1)) { throw 'Run me from my location.' }
$log = 'Helps-Test.log'
$expected = "$env:LOCALAPPDATA\Helps-Test.$($PSVersionTable.PSVersion.Major).txt"

# load the script
. Helps.ps1

#.ExternalHelp Test-Helps-Help.xml
function global:Test-Function1
(
	[Parameter(Mandatory = $true, ParameterSetName = 'Set1')]
	[string]$Param1
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'Set2')]
	[string]$Param2
	,
	[Parameter()]
	[string]$Param3
)
{}

#.ExternalHelp Test-Helps-Help.xml
function global:Test-Function2
{}

### build/test command help
Convert-Helps Test-Helps-Help.ps1 Test-Helps-Help.xml
Test-Helps Test-Helps-Help.ps1

### make the provider assembly if not yet
if (!(Test-Path TestProvider.dll)) {
	Add-Type -Path TestProvider.cs -ReferencedAssemblies System.Data, System.Xml -OutputAssembly TestProvider.dll
	Remove-Item TestProvider.pdb
}

### make the provider available and build/test provider help
Import-Module .\TestProvider.dll
Convert-Helps TestProvider.dll-Help.ps1 TestProvider.dll-Help.xml
Test-Helps TestProvider.dll-Help.ps1

### get full help of Helps, extra test commands and the test provider.
@(
	'Helps.ps1'
	'Convert-Helps'
	'Merge-Helps'
	'New-Helps'
	'Test-Helps'
	'Test-Function1'
	'Test-Function2'
	'TestProvider'
) | %{
	'#'*77
	Get-Help $_ -Full | Out-String -Width 80
} | Out-File $log

### get New-Helps
.{
	New-Helps NEW-HELPS -Indent '  '
	New-Helps -Command NEW-HELPS -LocalizedData data
	New-Helps -Provider FILESYSTEM -Indent '  '
	New-Helps -Provider FILESYSTEM -LocalizedData data
} | Out-File -Width 80 $log -Append

### compare actual with expected
$toCopy = $false
if (Test-Path $expected) {
	$new = (Get-Content $log) -join "`n"
	$val = (Get-Content $expected) -join "`n"
	if ($new -ceq $val) {
		'The result is expected.'
		Remove-Item $log
	}
	else {
		Write-Warning 'The result is not the same as expected.'
		if ($env:MERGE) {
			& $env:MERGE $log $expected
		}
		$toCopy = 1 -eq (Read-Host 'Save the result as expected? [1] Yes [Enter] No')
	}
}
else {
	$toCopy = $true
}

### copy actual to expected
if ($toCopy) {
	Write-Host -ForegroundColor Cyan 'Saving the result as expected.'
	Move-Item $log $expected -Force
}

### remove XML files, see the result help in Helps-Test.txt
Remove-Item Test-Helps-Help.xml, TestProvider.dll-Help.xml
