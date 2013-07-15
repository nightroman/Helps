
<#
.Synopsis
	Tests of Helps.

.Notes
	Do not use ${*}.Warnings[-1] -- it fails in PS v2.
#>

function Enter-Build {
	. Helps
}

function Exit-Build {
	if (Test-Path z.ps1) {Remove-Item z.ps1}
	if (Test-Path z.xml) {Remove-Item z.xml}
}

function Test-Error([string]$Expected, [scriptblock]$Script) {
	$err = ''
	try { & $Script }
	catch { $err = $_ | Out-String }
	Write-Build Magenta $err
	assert ($err -like $Expected)
}

task ConvertMissingScript {
	Test-Error "Convert-Helps : Cannot find path 'Missing.ps1' because it does not exist.*At *\Test.build.ps1:*" {
		Convert-Helps Missing.ps1 z.xml
	}
}
task TestMissingScript {
	Test-Error "Test-Helps : Cannot find path 'Missing.ps1' because it does not exist.*At *\Test.build.ps1:*" {
		Test-Helps Missing.ps1
	}
}

task ConvertBadType {
	@'
'unexpected'
'@ > z.ps1
	Test-Error "Convert-Helps : *\z.ps1 : Help scripts output hashtables. Unexpected output is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}
task TestBadType {
	@'
'unexpected'
'@ > z.ps1
	Test-Error "Test-Helps : *\z.ps1 : Help scripts output hashtables. Unexpected output is 'string'.*At *\Test.build.ps1:*" {
		Test-Helps z.ps1
	}
}

task ConvertBadCommand {
	@'
@{
	command = 'foo'
	bad = 42
}
'@ > z.ps1
	Test-Error "Convert-Helps : *\z.ps1 : Invalid key 'bad' in command 'foo'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}
task TestBadCommand {
	@'
@{
	command = 'foo'
	bad = 42
}
'@ > z.ps1
	Test-Error "Test-Helps : *\z.ps1 : Invalid key 'bad' in command 'foo'. Valid keys:*At *\Test.build.ps1:*" {
		Test-Helps z.ps1
	}
}

task ConvertBadProvider {
	@'
@{
	provider = 'foo'
	bad = 42
}
'@ > z.ps1
	Test-Error "Convert-Helps : *\z.ps1 : Invalid key 'bad' in provider 'foo'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}
task TestBadProvider {
	@'
@{
	provider = 'foo'
	bad = 42
}
'@ > z.ps1
	Test-Error "Test-Helps : *\z.ps1 : Invalid key 'bad' in provider 'foo'. Valid keys:*At *\Test.build.ps1:*" {
		Test-Helps z.ps1
	}
}

task ConvertNoMainKey {
	'@{}' > z.ps1

	Test-Error "Convert-Helps : *\z.ps1 : Help table must contain either 'command' or 'provider' key.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}
task TestNoMainKey {
	'@{}' > z.ps1

	Test-Error "Test-Helps : *\z.ps1 : Help table must contain either 'command' or 'provider' key.*At *\Test.build.ps1:*" {
		Test-Helps z.ps1
	}
}

task MergeNullFirst {
	Test-Error "Merge-Helps : Cannot validate argument on parameter 'First'. The argument is null.*At *\Test.build.ps1:*" {
		Merge-Helps $null @{}
	}
}
task MergeNullSecond {
	Test-Error "Merge-Helps : Cannot validate argument on parameter 'Second'. The argument is null.*At *\Test.build.ps1:*" {
		Merge-Helps @{} $null
	}
}

task MergeBadParametersFirst {
	Test-Error "Merge-Helps : First: 'parameters' must be hashtable.*At *\Test.build.ps1:*" {
		$help = @{ parameters = 'invalid' }
		Merge-Helps $help @{ parameters = @{} }
	}
}
task MergeBadParametersSecond {
	Test-Error "Merge-Helps : Second: 'parameters' must be hashtable.*At *\Test.build.ps1:*" {
		$help = @{ parameters = @{} }
		Merge-Helps $help @{ parameters = 'invalid' }
	}
}

task TestBadTestType {
	@'
@{
	command = 'Helps'; synopsis = '...'
	examples = @(
		@{
			test = 42
		}
	)
}
'@ > z.ps1
	Test-Error "Test-Helps : Example 1 of 'Helps': 'test' must be script block.*At *\Test.build.ps1:*" {
		Test-Helps z.ps1
	}
}

task TestBadCodeType {
	@'
@{
	command = 'Helps'; synopsis = '...'
	examples = @(
		@{
			test = {}
			code = 42
		}
	)
}
'@ > z.ps1
	Test-Error "Test-Helps : Example 1 of 'Helps': 'code' must be script block.*At *\Test.build.ps1:*" {
		Test-Helps z.ps1
	}
}

task NewMissingCommandWarningAndOutput {
	$nWarning = ${*}.Warnings.Count
	$out = (New-Helps Missing-Command | Out-String).Trim()
	assert (${*}.Warnings.Count -eq $nWarning + 1)
	assert (${*}.Warnings[$nWarning] -eq "WARNING: Command 'Missing-Command' is not found.")
	assert ($out -like @'
# Missing-Command command help
@{
*
}
'@)
}

task NewMissingProviderWarningAndOutput {
	$nWarning = ${*}.Warnings.Count
	$out = (New-Helps -Provider MissingProvider | Out-String).Trim()
	assert (${*}.Warnings.Count -eq $nWarning + 1)
	assert (${*}.Warnings[$nWarning] -eq "WARNING: Provider 'MissingProvider' is not found.")
	assert ($out -like @'
# MissingProvider provider help
@{
*
}
'@)
}

task ConvertUnknownCommandName {
	@'
@{
	command = 'Missing-Command'; synopsis = '...'
}
'@ > z.ps1
	Test-Error "Convert-Helps : The term 'Missing-Command' is not recognized as the name of a cmdlet,*.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertMissingCommandSynopsis {
	@'
@{
	command = 'Helps'
}
'@ > z.ps1
	Test-Error "Convert-Helps : *\z.ps1 : Help of 'Helps': Missing or empty 'synopsis'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadInputs {
	@'
@{
	command = 'Helps'; synopsis = '...'
	inputs = 'bad'
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'inputs' must contain hashtables. Unexpected item is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertMissingInputsAndBadOutputs {
	@'
@{
	command = 'Helps'; synopsis = '...'
	outputs = 'bad'
}
'@ > z.ps1
	$nWarning = ${*}.Warnings.Count
	Test-Error "Convert-Helps : Help of 'Helps': 'outputs' must contain hashtables. Unexpected item is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
	assert (${*}.Warnings.Count -eq $nWarning + 1)
	assert (${*}.Warnings[$nWarning] -eq "WARNING: Help of 'Helps': Missing 'inputs' entry. If it is empty then set it to @().")
}

task ConvertMissingOutputs {
	@'
@{
	command = 'Helps'; synopsis = '...';
	inputs = @()
}
'@ > z.ps1
	$nWarning = ${*}.Warnings.Count
	Convert-Helps z.ps1 z.xml
	assert (${*}.Warnings.Count -eq $nWarning + 1)
	assert (${*}.Warnings[$nWarning] -eq "WARNING: Help of 'Helps': Missing 'outputs' entry. If it is empty then set it to @().")
}

task ConvertEmptyInputsHashtable {
	@'
@{
	command = 'Helps'; synopsis = '...';
	inputs = @{}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'inputs' hashtables must not be empty.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadInputsKey {
	@'
@{
	command = 'Helps'; synopsis = '...'
	inputs = @{bad = 42}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': Invalid 'inputs' hashtable key 'bad'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertEmptyOutputsHashtable {
	@'
@{
	command = 'Helps'; synopsis = '...'
	inputs = @{type = '...'}
	outputs = @{}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'outputs' hashtables must not be empty.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadOutputsKey {
	@'
@{
	command = 'Helps'; synopsis = '...'
	inputs = @{type = '...'}
	outputs = @{bad = 42}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': Invalid 'outputs' hashtable key 'bad'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadExamplesType {
	@'
@{
	command = 'Helps'; synopsis = '...'; inputs = @(); outputs = @()
	examples = 'bad'
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'examples' must contain hashtables. Unexpected item is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertEmptyExamplesHashtable {
	@'
@{
	command = 'Helps'; synopsis = '...'; inputs = @(); outputs = @()
	examples = @{}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'examples' hashtables must not be empty.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadExamplesKey {
	@'
@{
	command = 'Helps'; synopsis = '...'; inputs = @(); outputs = @()
	examples = @{bad = 42}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': Invalid 'examples' hashtable key 'bad'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadLinksType {
	@'
@{
	command = 'Helps'; synopsis = '...'; inputs = @(); outputs = @()
	links = 'bad'
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'links' must contain hashtables. Unexpected item is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertEmptyLinksHashtable {
	@'
@{
	command = 'Helps'; synopsis = '...'; inputs = @(); outputs = @()
	links = @{}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'links' hashtables must not be empty.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadLinksKey {
	@'
@{
	command = 'Helps'; synopsis = '...'; inputs = @(); outputs = @()
	links = @{bad = 42}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': Invalid 'links' hashtable key 'bad'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadTasksType {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	tasks = 'bad'
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': 'tasks' must contain hashtables. Unexpected item is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertEmptyTasksHashtable {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	tasks = @{}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': 'tasks' hashtables must not be empty.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadTasksKey {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	tasks = @{bad = 42}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': Invalid 'tasks' hashtable key 'bad'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadProviderParametersType {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	parameters = 'bad'
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': 'parameters' must contain hashtables. Unexpected item is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertEmptyParametersHashtable {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	parameters = @{}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': 'parameters' hashtables must not be empty.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadParametersKey {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	parameters = @{bad = 42}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': Invalid 'parameters' hashtable key 'bad'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadParametersValuesType {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	parameters = @{
		values = 'bad'
	}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': 'parameters.values' must contain hashtables. Unexpected item is 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertEmptyParametersValuesHashtable {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	parameters = @{
		values = @{}
	}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': 'parameters.values' hashtables must not be empty.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadParametersValuesKey {
	@'
@{
	provider = 'FileSystem'; synopsis = '...'
	parameters = @{
		values = @{bad = 42}
	}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'FileSystem': Invalid 'parameters.values' hashtable key 'bad'. Valid keys:*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadSetsType {
	@'
@{
	command = 'Helps'; synopsis = '...'
	sets = 'bad'
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'sets' must be hashtable, not 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertMissingSetsNames {
	@'
@{
	command = 'Helps'; synopsis = '...'
	sets = @{bad1=''; bad2=''}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'sets' contains missing parameter set names: bad1 bad2.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertBadCommandParametersType {
	@'
@{
	command = 'Helps'; synopsis = '...'
	parameters = 'bad'
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of 'Helps': 'parameters' must be hashtable, not 'string'.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

task ConvertMissingCommandParametersNames {
	@'
@{
	command = 'Helps'; synopsis = '...'
	parameters = @{bad1=''; bad2=''}
}
'@ > z.ps1
	Test-Error "Convert-Helps : Help of Helps: 'parameters' contains missing parameter names: bad1 bad2.*At *\Test.build.ps1:*" {
		Convert-Helps z.ps1 z.xml
	}
}

# PSBase is needed in $Command.Parameters.PSBase.Keys, see https://github.com/nightroman/Helps/issues/2
function Test-ProblemParameterNames
{
	param(
		[Parameter()]
		$Comparer,
		$Count,
		$IsFixedSize,
		$IsReadOnly,
		$IsSynchronized,
		$Keys,
		$SyncRoot,
		$Values
	)
	{ write-host "test" }
}
task ProblemParameterNames {
	# generate help
	$res = New-Helps -Command Test-ProblemParameterNames
	assert ($res -match "\t\tComparer = ''")
	assert ($res -match "\t\tCount = ''")
	assert ($res -match "\t\tIsFixedSize = ''")
	assert ($res -match "\t\tIsReadOnly = ''")
	assert ($res -match "\t\tIsSynchronized = ''")
	assert ($res -match "\t\tKeys = ''")
	assert ($res -match "\t\tSyncRoot = ''")
	assert ($res -match "\t\tValues = ''")

	# "edit" and save help script
	$res = $res -replace "synopsis = ''", "synopsis = 'synopsis'"
	$res = $res -replace "Comparer = ''", "Comparer = '1'"
	$res = $res -replace "Count = ''", "Count = '1'"
	$res = $res -replace "IsFixedSize = ''", "IsFixedSize = '1'"
	$res = $res -replace "IsReadOnly = ''", "IsReadOnly = '1'"
	$res = $res -replace "IsSynchronized = ''", "IsSynchronized = '1'"
	$res = $res -replace "Keys = ''", "Keys = '1'"
	$res = $res -replace "SyncRoot = ''", "SyncRoot = '1'"
	$res = $res -replace "Values = ''", "Values = '1'"
	$res | Set-Content $env:TEMP\z.ps1 -Encoding UTF8

	# convert and get the result XML
	Convert-Helps $env:TEMP\z.ps1 $env:TEMP\z.ps1.xml
	$res = [IO.File]::ReadAllText("$env:TEMP\z.ps1.xml")

	assert ($res -match "<maml:name>Comparer</maml:name>")
	assert ($res -match "<maml:name>Count</maml:name>")
	assert ($res -match "<maml:name>IsFixedSize</maml:name>")
	assert ($res -match "<maml:name>IsReadOnly</maml:name>")
	assert ($res -match "<maml:name>IsSynchronized</maml:name>")
	assert ($res -match "<maml:name>Keys</maml:name>")
	assert ($res -match "<maml:name>SyncRoot</maml:name>")
	assert ($res -match "<maml:name>Values</maml:name>")

	Remove-Item -LiteralPath $env:TEMP\z.ps1, $env:TEMP\z.ps1.xml
}
