
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
$sample = "$HOME\data\Helps-Test.$($PSVersionTable.PSVersion.Major).txt"

# load the script
. Helps.ps1

#.ExternalHelp Test-Helps-Help.xml
function global:Test-Function1
(
	[Parameter(Mandatory = $true, ParameterSetName = 'Set1')]
	[string]$Param1,
	[Parameter(Mandatory = $true, ParameterSetName = 'Set2')]
	[string]$Param2,
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

### compare sample
Assert-SameFile $sample $log $env:MERGE

### remove XML files, see the result help in Helps-Test.txt
Remove-Item Test-Helps-Help.xml, TestProvider.dll-Help.xml
