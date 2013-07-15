
<#
* Helps.ps1 - PowerShell Help Builder
* Copyright (c) 2011-2013 Roman Kuzmin
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
#>

#.ExternalHelp Helps-Help.xml
param()

# The current version.
function Get-HelpsVersion
{[System.Version]'1.0.8'}

#.ExternalHelp Helps-Help.xml
function Convert-Helps(
	[Parameter(Position=0, Mandatory=1)][ValidateNotNullOrEmpty()][string[]]$Script,
	[Parameter(Position=1, Mandatory=1)][string]$Output,
	[Parameter(Position=2)][hashtable]$Parameters=@{}
) {
	$ErrorActionPreference = 'Stop'
	# resolve output now, script may change the location
	$Output = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Output)
	# shared data
	$1 = @{}
	# import and convert
	. Helps.ConvertAll (Helps.Import $Script $Parameters) $Output
}

#.ExternalHelp Helps-Help.xml
function Merge-Helps(
	[Parameter(Position=0, Mandatory=1)][ValidateNotNull()][hashtable]$First,
	[Parameter(Position=1, Mandatory=1)][ValidateNotNull()][hashtable]$Second
) {
	# copy the first table
	$First = @{} + $First

	# join the copy with the second
	foreach($key in $Second.Keys) {
		$value1 = $First[$key]
		$value2 = $Second[$key]
		# add the second value
		if ($null -eq $value1) {
			$First[$key] = $value2
		}
		# merge parameter tables
		elseif ($key -eq 'parameters') {
			if ($value1 -isnot [hashtable]) {Helps.Error "First: 'parameters' must be hashtable." 5}
			if ($value2 -isnot [hashtable]) {Helps.Error "Second: 'parameters' must be hashtable." 5}
			$First[$key] = $value1 + $value2
		}
		# append second arrays to the first
		elseif (('inputs', 'outputs', 'examples', 'links') -contains $key) {
			$First[$key] = @($value1) + @($value2)
		}
		# other second values override
		else {
			$First[$key] = $value2
		}
	}

	# return
	$First
}

#.ExternalHelp Helps-Help.xml
function Test-Helps(
	[Parameter(Position=0, Mandatory=1)][ValidateNotNullOrEmpty()][string[]]$Script,
	[hashtable]$Parameters = @{}
) {
	$ErrorActionPreference = 'Stop'
	${private:-script} = $Script
	${private:-parameters} = $Parameters
	Remove-Variable Script, Parameters

	foreach(${private:-help} in (Helps.Import ${private:-script} ${private:-parameters})) {
		# get examples
		if (${private:-name} = ${private:-help}['command']) {
			${private:-examples} = @(${private:-help}['examples'])
		}
		else {
			${private:-name} = ${private:-help}['provider']
			${private:-examples} = @()
			${private:-tasks} = @(${private:-help}['tasks'])
			foreach(${private:-task} in ${private:-tasks}) {
				${private:-more} = @(${private:-task}['examples'])
				if (${private:-more}) {
					${private:-examples} += ${private:-more}
				}
			}
		}
		if (!${private:-examples}) {continue}

		${private:-number} = 0
		foreach(${private:-example} in ${private:-examples}) {
			++${private:-number}
			${private:-test} = ${private:-example}['test']
			if (${private:-test}) {
				if (${private:-test} -isnot [scriptblock]) {
					Helps.Error "Example ${private:-number} of '${private:-name}': 'test' must be script block."
				}

				${private:-code} = ${private:-example}['code']
				if (${private:-code} -isnot [scriptblock]) {
					Helps.Error "Example ${private:-number} of '${private:-name}': 'code' must be script block."
				}

				'#'*77
				${private:-code}
				${private:-test}
				& ${private:-test} ${private:-code}
			}
		}
	}
}

#.ExternalHelp Helps-Help.xml
function New-Helps(
	[Parameter(Position=0, Mandatory=1, ParameterSetName='Command')]
	[ValidateScript({$_ -is [string] -or $_ -is [System.Management.Automation.CommandInfo]})]
	$Command,
	[Parameter(Mandatory=1, ParameterSetName='Provider')]
	[ValidateScript({$_ -is [string] -or $_ -is [System.Management.Automation.ProviderInfo]})]
	$Provider,
	[string]$Indent = "`t",
	[ValidateNotNullOrEmpty()][string]$LocalizedData
) {
	$ErrorActionPreference = 'Stop'
	switch($PSCmdlet.ParameterSetName) {
		Command { Helps.NewCommand $Command $Indent $LocalizedData }
		Provider { Helps.NewProvider $Provider $Indent $LocalizedData }
	}
}

# Terminating error
function Helps.Error($M, $C=0)
{$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))}

# Filters out common parameters
function Helps.IsParameter($Name) {
	@('Verbose', 'Debug', 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable', 'OutBuffer') -notcontains $Name
}

function Helps.NewCommand(
	$Command,
	[string]$Tab,
	[string]$LocalizedData
) {
	# resolve
	if ($Command -is [string]) {
		$commands = @(Get-Command $Command -ErrorAction 0)
		switch($commands.Count) {
			1 {
				$Command = $commands[0]
				$Name = $Command.Name
			}
			0 {
				$Name = $Command
				$Command = $null
				Write-Warning "Command '$Name' is not found."
			}
			default {
				Helps.Error "There are $($commands.Count) commands '$Command'."
			}
		}
	}
	else {
		$Name = $Command.Name
	}

	# info
	if ($Command) {
		$sets = @($Command.ParameterSets | Sort-Object Name)
		$parameters = @($Command.Parameters.PSBase.Keys | Sort-Object)
		$outputs = @($Command.OutputType)
	}
	else {
		$sets = @()
		$parameters = @()
		$outputs = @()
	}

	$TabTab = $Tab + $Tab
	$TabTabTab = $TabTab + $Tab

	### data script
	if ($LocalizedData) {
		$data = $Tab + ($Name -replace '\W')

		''
		"# $Name command data"
		'$' + $LocalizedData + ' = @{'
		"${data}Synopsis = ''"
		"${data}Description = ''"

		foreach($set in $sets) {
			"${data}Sets$($set.Name) = ''"
		}

		foreach($parameter in $parameters) {
			if (Helps.IsParameter $parameter) {
				"${data}Parameters$parameter = ''"
			}
		}

		"${data}InputsDescription1 = ''"

		if ($outputs) {
			foreach($type in $outputs) {
				"${data}OutputsDescription$($type.Name -replace '\W') = ''"
			}
		}
		else {
			"${data}OutputsDescription1 = ''"
		}

		"${data}Notes = ''"

		"${data}ExamplesRemarks1 = ''"

		'}'
	}

	### help script

	if ($LocalizedData) {
		$data = '$' + $LocalizedData + '.' + ($Name -replace '\W')
	}

	''
	"# $Name command help"
	'@{'

	"${Tab}command = '$Name'"

	if ($LocalizedData) {
		"${Tab}synopsis = ${data}Synopsis"
	} else {
		"${Tab}synopsis = ''"
	}

	if ($LocalizedData) {
		"${Tab}description = ${data}Description"
	}
	else {
		"${Tab}description = ''"
	}

	if ($sets -and $sets.Count -ge 2) {
		"${Tab}sets = @{"
		foreach($set in $sets) {
			if ($LocalizedData) {
				"${TabTab}$($set.Name) = ${data}Sets$($set.Name)"
			}
			else {
				"${TabTab}$($set.Name) = ''"
			}
		}
		"${Tab}}"
	}

	$parameters = foreach($parameter in $parameters) { if (Helps.IsParameter $parameter) { $parameter } }
	if ($parameters) {
		"${Tab}parameters = @{"
		foreach($parameter in $parameters) {
			if ($LocalizedData) {
				"${TabTab}$parameter = ${data}Parameters$parameter"
			}
			else {
				"${TabTab}$parameter = ''"
			}
		}
		"${Tab}}"
	}

	"${Tab}inputs = @("
	"${TabTab}@{"
	"${TabTabTab}type = ''"

	if ($LocalizedData) {
		"${TabTabTab}description = ${data}InputsDescription1"
	}
	else {
		"${TabTabTab}description = ''"
	}

	"${TabTab}}"
	"${Tab})"

	if ($outputs) {
		"${Tab}outputs = @("
		foreach($type in $outputs) {
			"${TabTab}@{"
			"${TabTabTab}type = '$($type.Name)'"

			if ($LocalizedData) {
				"${TabTabTab}description = ${data}OutputsDescription$($type.Name -replace '\W')"
			}
			else {
				"${TabTabTab}description = ''"
			}

			"${TabTab}}"
		}
		"${Tab})"
	}
	else {
		"${Tab}outputs = @("
		"${TabTab}@{"
		"${TabTabTab}type = ''"

		if ($LocalizedData) {
			"${TabTabTab}description = ${data}OutputsDescription1"
		}
		else {
			"${TabTabTab}description = ''"
		}

		"${TabTab}}"
		"${Tab})"
	}

	if ($LocalizedData) {
		"${Tab}notes = ${data}Notes"
	}
	else {
		"${Tab}notes = ''"
	}

	"${Tab}examples = @("
	"${TabTab}@{"
	"${TabTabTab}#title = ''"
	"${TabTabTab}#introduction = ''"
	"${TabTabTab}code = {"
	"${TabTabTab}}"

	if ($LocalizedData) {
		"${TabTabTab}remarks = ${data}ExamplesRemarks1"
	}
	else {
		"${TabTabTab}remarks = ''"
	}

	"${TabTabTab}test = { . `$args[0] }"
	"${TabTab}}"
	"${Tab})"

	"${Tab}links = @("
	"${TabTab}@{ text = ''; URI = '' }"
	"${Tab})"

	'}'
}

function Helps.NewProvider(
	$Provider,
	[string]$Tab,
	[string]$LocalizedData
) {
	# resolve
	if ($Provider -is [string]) {
		$providers = @(Get-PSProvider $Provider -ErrorAction 0)
		switch($providers.Count) {
			1 {
				$Provider = $providers[0]
				$Name = $Provider.Name
			}
			0 {
				$Name = $Provider
				$Provider = $null
				Write-Warning "Provider '$Name' is not found."
			}
			default {
				Helps.Error "There are $($providers.Count) providers '$Provider'."
			}
		}
	}
	else {
		$Name = $Provider.Name
	}

	# info
	if ($Provider) {
		$capabilities = $provider.Capabilities
	}
	else {
		$capabilities = ''
	}

	$TabTab = $Tab + $Tab
	$TabTabTab = $TabTab + $Tab
	$TabTabTabTab = $TabTabTab + $Tab
	$TabTabTabTabTab = $TabTabTabTab + $Tab

	### data script
	if ($LocalizedData) {
		$data = $Tab + ($Name -replace '\W')
		''
		"# $Name provider data"
		'$' + $LocalizedData + ' = @{'
		"${data}Synopsis = ''"
		"${data}Description = ''"
		"${data}TasksTitle1 = ''"
		"${data}TasksDescription1 = ''"
		"${data}TasksExamplesIntroduction1 = ''"
		"${data}TasksExamplesRemarks1 = ''"
		"${data}ParametersDescription1 = ''"
		"${data}ParametersValuesDescription1 = ''"
		'}'
	}

	### help script

	if ($LocalizedData) {
		$data = '$' + $LocalizedData + '.' + ($Name -replace '\W')
	}

	''
	"# $Name provider help"
	'@{'

	"${Tab}provider = '$Name'"
	"${Tab}drives = ''"

	if ($LocalizedData) {
		"${Tab}synopsis = ${data}Synopsis"
	}
	else {
		"${Tab}synopsis = ''"
	}

	if ($LocalizedData) {
		"${Tab}description = ${data}Description"
	}
	else {
		"${Tab}description = ''"
	}

	"${Tab}capabilities = '$capabilities'"

	"${Tab}tasks = @("
	"${TabTab}@{"
	if ($LocalizedData) {
		"${TabTabTab}title = ${data}TasksTitle1"
	}
	else {
		"${TabTabTab}title = ''"
	}
	if ($LocalizedData) {
		"${TabTabTab}description = ${data}TasksDescription1"
	}
	else {
		"${TabTabTab}description = ''"
	}

	"${TabTabTab}examples = @("
	"${TabTabTabTab}@{"
	"${TabTabTabTabTab}#title = ''"
	if ($LocalizedData) {
		"${TabTabTabTabTab}introduction = ${data}TasksExamplesIntroduction1"
	}
	else {
		"${TabTabTabTabTab}introduction = ''"
	}
	"${TabTabTabTabTab}code = {"
	"${TabTabTabTabTab}}"
	if ($LocalizedData) {
		"${TabTabTabTabTab}remarks = ${data}TasksExamplesRemarks1"
	}
	else {
		"${TabTabTabTabTab}remarks = ''"
	}
	"${TabTabTabTabTab}test = { . `$args[0] }"
	"${TabTabTabTab}}"
	"${TabTabTab})"
	"${TabTab}}"
	"${Tab})"

	"${Tab}parameters = @("
	"${TabTab}@{"
	"${TabTabTab}name = ''"
	"${TabTabTab}type = ''"
	if ($LocalizedData) {
		"${TabTabTab}description = ${data}ParametersDescription1"
	}
	else {
		"${TabTabTab}description = ''"
	}
	"${TabTabTab}cmdlets = ''"
	"${TabTabTab}values = @("
	"${TabTabTabTab}@{"
	"${TabTabTabTabTab}value = ''"
	if ($LocalizedData) {
		"${TabTabTabTabTab}description = ${data}ParametersValuesDescription1"
	}
	else {
		"${TabTabTabTabTab}description = ''"
	}
	"${TabTabTabTab}}"
	"${TabTabTab})"
	"${TabTab}}"
	"${Tab})"

	"${Tab}links = @("
	"${TabTab}@{ text = ''; URI = '' }"
	"${Tab})"

	'}'
}

function Helps.Import(
	[string[]]$Script,
	[hashtable]$Parameters = @{}
) {
	$validCommandKeys = @( ###
		'command'
		'synopsis'
		#'copyright' -- help does not show it
		#'version' -- help does not show it
		'description'
		'sets'
		'parameters'
		'inputs'
		'outputs'
		'notes'
		'examples'
		'links'
	)

	$validProviderKeys = @( ###
		'provider'
		'drives'
		'synopsis'
		'description'
		'capabilities'
		#'filters' -- help does not show it
		'notes'
		'tasks'
		'parameters'
		'links'
	)

	# resolve paths before invoking, scripts may change the location
	$Script = foreach($_ in $Script) {
		try { Resolve-Path -LiteralPath $_ }
		catch { Helps.Error $_ 5 }
	}

	# invoke scripts, validate output
	foreach($path in $Script) {
		foreach($hash in (& $path @Parameters)) {
			if ($hash -isnot [hashtable]) {
				Helps.Error "$Script : Help scripts output hashtables. Unexpected output is '$($hash.GetType())'."
			}
			if ($name = $hash['command']) { foreach($key in $hash.Keys) { if ($validCommandKeys -notcontains $key) {
				Helps.Error "$Script : Invalid key '$key' in command '$name'. Valid keys: $validCommandKeys."
			}}}
			elseif ($name = $hash['provider']) { foreach($key in $hash.Keys) { if ($validProviderKeys -notcontains $key) {
				Helps.Error "$Script : Invalid key '$key' in provider '$name'. Valid keys: $validCommandKeys."
			}}}
			else {
				Helps.Error "$Script : Help table must contain either 'command' or 'provider' key."
			}
			if (!$hash['synopsis']) {
				Helps.Error "$Script : Help of '$name': Missing or empty 'synopsis'."
			}
			$hash
		}
	}
}

# Converts all topics to XML.
function Helps.ConvertAll([hashtable[]]$Topics, [string]$Output) {
	### sorting
	$sortParameterInSyntax = @(
		{ if ($_.Position -ge 0) { $_.Position } else { 999 } }
		{ !$_.IsMandatory }
		{ $_.ParameterType -eq [System.Management.Automation.SwitchParameter] }
		'Name'
	)

	function Encode-Xml($Text) {
		$text.Replace('&', '&amp;').Replace("'", '&apos;').Replace('"', '&quot;').Replace('<', '&lt;').Replace('>', '&gt;')
	}

	$tabs = [regex]'^(\ +)'
	$split = [regex]'(?:\ *\r?\n){2,}'
	$replace = [regex]'\ *\r?\n(?=\S)'

	# Replace tabs
	# - unindent preformatted indented block
	# - or split by empty lines, join consequent lines, join all back with empty lines.
	function Format-Line([string]$Line) {
		$Line = $Line.Replace("`t", '    ')
		if ($Line -match $tabs) {
			($Line -replace ("`n" + $matches[1]), "`n").Trim()
		}
		else {
			($split.Split($Line) | .{process{ $replace.Replace($_, ' ') }}) -join "`r`n`r`n"
		}
	}

	function Out-Line($Tag, $Text) {
		"<$Tag>$(Encode-Xml (($Text | .{process{ Format-Line $_ }}) -join "`r`n"))</$Tag>"
	}

	function Out-Text($Tag, $Para, $Text) {
		"<$Tag>"
		foreach($line in $Text) {
			"<$Para>$(Encode-Xml (Format-Line $line))</$Para>"
		}
		"</$Tag>"
	}

	function Out-Types($HelpKey, $TagSet, $TagType, $Types) {
		"<$TagSet>"
		foreach($item in $Types) {
			Test-Hash $item $HelpKey $validTypeKeys

			"<$TagType>"

			'<dev:type>'
			$type = $item['type']
			if ($type) {
				"<maml:name>$(Encode-Xml $type)</maml:name>"
			}
			'</dev:type>'

			$description = @($item['description'])
			if ($description) {
				Out-Text maml:description maml:para $description
			}

			"</$TagType>"
		}
		"</$TagSet>"
	}

	$1.TagsExampleCommand = @{
		examples = 'command:examples'
		example = 'command:example'
		title = 'maml:title'
		introduction = 'maml:introduction'
		para = 'maml:para'
		code = 'dev:code'
		remarks = 'dev:remarks'
	}

	$1.TagsExamplesProvider = @{
		examples = 'Examples'
		example = 'Example'
		title = 'Title'
		introduction = 'Introduction'
		para = 'para'
		code = 'Code'
		remarks = 'Remarks'
	}

	function Out-Examples($examples, $tags) {
		"<$($tags.examples)>"

		$exampleNumber = 0
		foreach($example in $examples) {
			Test-Hash $example examples $validExampleKeys

			++$exampleNumber
			"<$($tags.example)>"

			# title
			$title = @($example['title'])
			if ($title) {
				Out-Line $tags.title $title
			}
			else {
				"<$($tags.title)>-------------------------- EXAMPLE $exampleNumber --------------------------</$($tags.title)>"
			}

			# introduction
			$introduction = @($example['introduction'])
			if ($introduction) {
				Out-Text $tags.introduction $tags.para $introduction
			}

			# code
			$code = $example['code']
			if ($code) {
				# string
				if ($code -is [string]) {
					$code = $code.Replace("`t", '    ')
					if ($code -match $tabs) {
						$code = ($code -replace ("`n" + $matches[1]), "`n").Trim()
					}
				}
				# script
				else {
					$code = $code.ToString()
					if ($code -match '(\n\s+)') {
						$code = $code -replace ($matches[1]), "`n"
					}
					$code = $code.Trim()
				}
				"<$($tags.code)>$(Encode-Xml $code)</$($tags.code)>"
			}

			# remarks
			$remarks = @($example['remarks'])
			if ($remarks) {
				Out-Text $tags.remarks $tags.para $remarks
			}

			"</$($tags.example)>"
		}

		"</$($tags.examples)>"
	}

	$1.TagsLinksCommand = @{
		links = 'maml:relatedLinks'
		link = 'maml:navigationLink'
		text = 'maml:linkText'
		URI = 'maml:uri'
	}

	$1.TagsLinksProvider = @{
		links = 'RelatedLinks'
		link = 'navigationLink'
		text = 'linkText'
		URI = 'uri'
	}

	function Out-Links($links, $tags) {
		"<$($tags.links)>"

		foreach($link in $links) {
			Test-Hash $link links $validLinkKeys

			"<$($tags.link)>"

			$text = $link['text']
			if ($text) {
				"<$($tags.text)>$(Encode-Xml $text)</$($tags.text)>"
			}
			$URI = $link['uri']
			if ($URI) {
				"<$($tags.URI)>$(Encode-Xml $URI)</$($tags.URI)>"
			}

			"</$($tags.link)>"
		}

		"</$($tags.links)>"
	}

	function Get-ParameterSet {
		$1.Command.ParameterSets | Sort-Object { $_.Parameters.Count }, Name
	}

	function Get-CommandParameter($Command, $Sort) {
		$Command.ParameterSets | .{process{ $_.Parameters }} |
		Sort-Object $Sort -Unique | .{process{ if (Helps.IsParameter $_.Name) { $_ }}}
	}

	function Get-ParameterSetParameter($ParameterSet, $Sort) {
		$ParameterSet.Parameters | Sort-Object $Sort | .{process{ if (Helps.IsParameter $_.Name) { $_ }}}
	}

	function Test-Hash($Hash, $HelpKey, $ValidKeys) {
		if ($Hash -isnot [hashtable]) {
			Helps.Error "Help of '$($1.Name)': '$HelpKey' must contain hashtables. Unexpected item is '$($Hash.GetType())'." 7
		}
		if (!$Hash.Count) {
			Helps.Error "Help of '$($1.Name)': '$HelpKey' hashtables must not be empty." 7
		}
		foreach($key in $Hash.Keys) { if ($ValidKeys -notcontains $key) {
			Helps.Error "Help of '$($1.Name)': Invalid '$HelpKey' hashtable key '$key'. Valid keys: $ValidKeys."
		}}
	}

	$validTypeKeys = @(
		'type'
		'description'
	)

	$validExampleKeys = @(
		'title'
		'introduction'
		'code'
		'remarks'
		'test'
	)

	$validLinkKeys = @(
		'text'
		'URI'
	)

	$validTaskKeys = @(
		'title'
		'description'
		'examples'
	)

	$validParameterKeys = @(
		'name'
		'type'
		'description'
		'cmdlets'
		'values'
	)

	$validParameterValueKeys = @(
		'value'
		'description'
	)

	### output to the file
	.{
		@'
<?xml version="1.0" encoding="utf-8"?>
<helpItems xmlns="http://msh" schema="maml">
'@

		# ensured before: either command or provider
		foreach($topic in $Topics) {
			if ($topic['command']) {
				Helps.ConvertCommand $topic
			}
			else {
				Helps.ConvertProvider $topic
			}
		}

		@'
</helpItems>
'@

	} | Out-File -Encoding UTF8 $Output
}

# Converts command help to XML.
function Helps.ConvertCommand($Help) {
	$1.Name = $Help.command
	if ($1.Name -match '^(\w+)-(\w+)$') {
		$verb = $matches[1]
		$noun = $matches[2]
	}
	else {
		$verb = $null
		$noun = $null
	}

	try { $1.Command = @(Get-Command $1.Name -ErrorAction Stop)[0] }
	catch { Helps.Error $_ 13 }

	### command
	@'
<command:command xmlns:maml="http://schemas.microsoft.com/maml/2004/10" xmlns:command="http://schemas.microsoft.com/maml/dev/command/2004/10" xmlns:dev="http://schemas.microsoft.com/maml/dev/2004/10">
<command:details>
'@

	@"
<command:name>$($1.Name)</command:name>
"@

	### synopsis

	$synopsis = @($Help['synopsis'])
	Out-Text maml:description maml:para $synopsis

	### copyright -- help does not show it

	### verb/noun
	if ($verb) {
		@"
<command:verb>$verb</command:verb>
<command:noun>$noun</command:noun>
"@
	}

	### version -- help does not show it

	@'
</command:details>
'@

	### description & sets

	$description = @($Help['description'])
	if (!$description) {
		$description = @($synopsis)
	}

	$sets = $Help['sets']
	if ($sets) {
		if ($sets -isnot [Hashtable]) {
			Helps.Error "Help of '$($1.Name)': 'sets' must be hashtable, not '$($sets.GetType())'."
		}
		$sets = @{} + $sets
		foreach($set in Get-ParameterSet) {
			$remarks = $sets[$set.Name]
			$sets.Remove($set.Name)
			if ($remarks) {
				$description += ''
				$description += "> $($1.Name) " + (Get-ParameterSetParameter $set $sortParameterInSyntax | .{process{
					if ($_.IsMandatory) {
						"-$($_.Name)"
					}
					else {
						"[-$($_.Name)]"
					}
				}})
				$description += $remarks
			}
		}
		if ($sets.Count) {
			Helps.Error "Help of '$($1.Name)': 'sets' contains missing parameter set names: $($sets.Keys)."
		}
	}

	Out-Text maml:description maml:para $description

	### syntax (generated)

	'<command:syntax>'

	foreach($set in Get-ParameterSet) {
		'<command:syntaxItem>'
		"<maml:name>$($1.Name)</maml:name>"
		$set.Parameters | Sort-Object $sortParameterInSyntax | .{process{ if (Helps.IsParameter $_.Name) {
			$start = '<command:parameter '

			# required, position, pipelineInput is not needed
			if ($_.IsMandatory) { $start += 'required="true" ' } else { $start += 'required="false" ' }
			if ($_.Position -ge 0) { $start += 'position="' + ($_.Position + 1) + '" ' } else { $start += 'position="named" ' }

			$start += '>'
			$start

			"<maml:name>$($_.Name)</maml:name>"
			if ($_.ParameterType -ne [System.Management.Automation.SwitchParameter]) {
				@"
<command:parameterValue required="true">$($_.ParameterType.Name)</command:parameterValue>
"@
			}
			'</command:parameter>'
		}}}
		'</command:syntaxItem>'
	}

	'</command:syntax>'

	### parameters

	$parameters = $Help['parameters']
	if ($parameters) {
		if ($parameters -isnot [Hashtable]) {
			Helps.Error "Help of '$($1.Name)': 'parameters' must be hashtable, not '$($parameters.GetType())'."
		}
		$parameters = @{} + $parameters
	}
	else {
		$parameters = @{}
	}

	'<command:parameters>'

	Get-CommandParameter $1.Command { if ($_.Position -ge 0) { $_.Position } else { 999 } }, Name | .{process{
		$start = '<command:parameter '

		# required
		if ($_.IsMandatory) { $start += 'required="true" ' } else { $start += 'required="false" ' }

		# pipelineInput
		if ($_.ValueFromPipeline -and $_.ValueFromPipelineByPropertyName) {
			$start += 'pipelineInput="true (ByValue, ByPropertyName)" '
		}
		elseif ($_.ValueFromPipelineByPropertyName) {
			$start += 'pipelineInput="true (ByPropertyName)" '
		}
		elseif ($_.ValueFromPipeline) {
			$start += 'pipelineInput="true (ByValue)" '
		}

		# position
		if ($_.Position -ge 0) { $start += 'position="' + ($_.Position + 1) + '" ' } else { $start += 'position="named" ' }

		$start += '>'
		$start

		"<maml:name>$($_.Name)</maml:name>"

		$parameterDescription = @($parameters[$_.Name])
		if (!$parameterDescription) {
			Write-Warning "$($1.Name) : missing parameter description : $($_.Name)"
		}
		if ($_.ParameterType.IsEnum) {
			$parameterDescription += 'Values : ' + ([Enum]::GetValues($_.ParameterType) -join ', ')
		}

		Out-Text maml:description maml:para $parameterDescription

		'</command:parameter>'

		$parameters.Remove($_.Name)
	}}

	if ($parameters.Count) {
		Helps.Error "Help of $($1.Name): 'parameters' contains missing parameter names: $($parameters.Keys)."
	}

	'</command:parameters>'

	### inputs - not yet supported type's uri, description

	$inputs = $Help['inputs']
	if ($null -eq $inputs) {
		Write-Warning "Help of '$($1.Name)': Missing 'inputs' entry. If it is empty then set it to @()."
	}
	else {
		$inputs = @($inputs)
		if ($inputs.Count -eq 0) {
			$inputs = , @{ type = '-' }
		}
	}

	if ($inputs) {
		Out-Types inputs command:inputTypes command:inputType $inputs
	}

	### outputs - not yet supported type's uri, description

	$outputs = $Help['outputs']

	$outputs = $Help['outputs']
	if ($null -eq $outputs) {
		Write-Warning "Help of '$($1.Name)': Missing 'outputs' entry. If it is empty then set it to @()."
	}
	else {
		$outputs = @($outputs)
		if ($outputs.Count -eq 0) {
			$outputs = , @{ type = '-' }
		}
	}

	if ($outputs) {
		Out-Types outputs command:returnValues command:returnValue $outputs
	}

	### notes - not standard

	$notes = @($Help['notes'])
	if ($notes) {
		'<maml:alertSet>'
		'<maml:alert>'
		Out-Line maml:para $notes
		'</maml:alert>'
		'</maml:alertSet>'
	}

	### examples

	$examples = @($Help['examples'])
	if ($examples) {
		Out-Examples $examples $1.TagsExampleCommand
	}

	### links

	$links = @($Help['links'])
	if ($links) {
		Out-Links $links $1.TagsLinksCommand
	}

	# complete command
	'</command:command>'
}

# Converts provider help to XML.
function Helps.ConvertProvider($Help) {
	$1.Name = $Help.provider

	### begin provider

	@"
<providerHelp>
<Name>$($1.Name)</Name>
"@

	### drives

	$drives = @($Help['drives'])
	if ($drives) {
		Out-Text Drives Para $drives
	}

	### synopsis

	$synopsis = @($Help['synopsis'])
	Out-Line Synopsis $synopsis

	### description

	$description = @($Help['description'])
	if (!$description) {
		$description = @($synopsis)
	}
	Out-Text DetailedDescription para $description

	### capabilities

	$capabilities = @($Help['capabilities'])
	if ($capabilities) {
		Out-Text Capabilities para $capabilities
	}

	### filters -- omit, help does not show them

	### tasks

	$tasks = @($Help['tasks'])
	if ($tasks) {
		'<Tasks>'

		foreach($task in $tasks) {
			Test-Hash $task tasks $validTaskKeys

			'<Task>'

			$title = @($task['title'])
			if ($title) {
				Out-Line Title $title
			}

			$description = @($task['description'])
			if ($description) {
				Out-Text Description para $description
			}

			### examples

			$examples = @($task['examples'])
			if ($examples) {
				Out-Examples $examples $1.TagsExamplesProvider
			}

			'</Task>'
		}

		'</Tasks>'
	}

	### parameters

	$parameters = @($Help['parameters'])
	if ($parameters) {
		'<DynamicParameters>'

		foreach($parameter in $parameters) {
			Test-Hash $parameter parameters $validParameterKeys

			'<DynamicParameter>'

			### name
			$text = $parameter['name']
			if ($text) {
				"<Name>$(Encode-Xml $text)</Name>"
			}

			### type
			$text = $parameter['type']
			if ($text) {
				"<Type><Name>$(Encode-Xml $text)</Name></Type>"
			}

			### description
			$text = $parameter['description']
			if ($text) {
				Out-Line Description $text
			}

			### cmdlets
			$text = $parameter['cmdlets']
			if ($text) {
				"<CmdletSupported>$(Encode-Xml $text)</CmdletSupported>"
			}

			### values
			$values = @($parameter['values'])
			if ($values) {
				'<PossibleValues>'

				foreach($value in $values) {
					Test-Hash $value parameters.values $validParameterValueKeys

					'<PossibleValue>'

					### value
					$text = $value['value']
					if ($text) {
						"<Value>$(Encode-Xml $text)</Value>"
					}

					### description
					$text = @($value['description'])
					if ($text) {
						Out-Text Description para $text
					}

					'</PossibleValue>'
				}

				'</PossibleValues>'
			}

			'</DynamicParameter>'
		}

		'</DynamicParameters>'
	}

	### notes -- help shows them after parameters

	$notes = @($Help['notes'])
	if ($notes) {
		Out-Line Notes $notes
	}

	### links

	$links = @($Help['links'])
	if ($links) {
		Out-Links $links $1.TagsLinksProvider
	}

	### end provider
	'</providerHelp>'
}
