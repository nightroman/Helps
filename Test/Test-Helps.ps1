<#
.Synopsis
	Builds exhaustive help from Test-Helps-Help.ps1, TestProvider.dll-Help.ps1

.Description
	This script should be invoked from its location.

.Outputs
	* $HOME\data\Helps-Test.V.txt - sample files for v2 and v3.
	* $HOME\data\Helps-Test.new.txt - temp log, removed if not stopped.
	* TestProvider.dll is created for the dummy TestProvider being tested.
#>

Set-StrictMode -Version 3
$ErrorActionPreference = 1

if (!(Test-Path Test-Helps.ps1)) { throw 'Run me from my location.' }
$log = "$HOME\data\Helps-Test.new.txt"
$sample = "$HOME\data\Helps-Test.$($PSVersionTable.PSVersion.Major).txt"

# load the script
. Helps.ps1

#.ExternalHelp Test-Helps-Help.xml
function global:Test-Function1(
	[Parameter(Mandatory = $true, ParameterSetName = 'Set1')]
	[string]$Param1,
	[Parameter(Mandatory = $true, ParameterSetName = 'Set2')]
	[string]$Param2,
	[Nullable[int]]$Param3,
	[Tuple[string, object]]$Param4
)
{}

#.ExternalHelp Test-Helps-Help.xml
function global:Test-Function2
{}

#.ExternalHelp Test-Helps-Help.xml
function Test-FunctionDynamicParam(
	[Parameter()]
	[string]$Param1
)
{
	dynamicparam {
		$param = New-Object Management.Automation.RuntimeDefinedParameterDictionary
		$attrs = New-Object Collections.ObjectModel.Collection[Attribute]
		$a1 = New-Object Management.Automation.ParameterAttribute
		$attrs.Add($a1)
		$name = 'DynamicParam1'
		$param.Add($name, (New-Object Management.Automation.RuntimeDefinedParameter $name, ([object]), $attrs))
		$param
	}
	end {
	}
}

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
	'Test-FunctionDynamicParam'
	'TestProvider'
) | .{process{
	'#'*77
	Get-Help $_ -Full | Out-String -Width 80
}} | Out-File $log

### get New-Helps
.{
	New-Helps NEW-HELPS -Indent '  '
	New-Helps -Command NEW-HELPS -LocalizedData data
	New-Helps -Provider FILESYSTEM -Indent '  '
	New-Helps -Provider FILESYSTEM -LocalizedData data
} | Out-File -Width 80 $log -Append

### compare sample
Assert-SameFile $sample $log $env:MERGE
Remove-Item $log

### remove XML files, see the result help in Helps-Test.txt
Remove-Item Test-Helps-Help.xml, TestProvider.dll-Help.xml
