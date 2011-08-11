
<#
* Helps module - PowerShell help builder
* Copyright 2011 Roman Kuzmin
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

# The scripts exports command and provider help to the PowerShell help file.
param
(
	[Parameter(Mandatory = $true)]
	# Input help topics.
	[hashtable[]]$Topics
	,
	[Parameter(Mandatory = $true)]
	[string]
	# Output MAML help file.
	$Output
)

# to watch cmdlet or non-cmdlet, mixed help is not allowed
$script:CommandType = $null

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

$tabs = [regex]'^([\ \t]+)'
$split = [regex]'(?:[ \t]*\r?\n){2,}'
$replace = [regex]'[ \t]*\r?\n(?=\S)'

<#
.Synopsis
	Unindent preformatted indented block.
	Splits by empty lines, joins consequent lines, joins all back with empty lines.
#>
function Format-Line($Line) {
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

function Out-Types($TagSet, $TagType, $Types) {
	"<$TagSet>"
	foreach($item in $Types) {
		Test-Type $item

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

$script:TagsExampleCommand = @{
	examples = 'command:examples'
	example = 'command:example'
	title = 'maml:title'
	introduction = 'maml:introduction'
	para = 'maml:para'
	code = 'dev:code'
	remarks = 'dev:remarks'
}

$script:TagsExamplesProvider = @{
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
		Test-Example $example

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

$script:TagsLinksCommand = @{
	links = 'maml:relatedLinks'
	link = 'maml:navigationLink'
	text = 'maml:linkText'
	URI = 'maml:uri'
}

$script:TagsLinksProvider = @{
	links = 'RelatedLinks'
	link = 'navigationLink'
	text = 'linkText'
	URI = 'uri'
}

function Out-Links($links, $tags) {
	"<$($tags.links)>"

	foreach($link in $links) {
		Test-Link $link

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
	$script:Command.ParameterSets | Sort-Object { $_.Parameters.Count }, Name
}

function Get-CommandParameter($Command, $Sort) {
	$Command.ParameterSets | .{process{ $_.Parameters }} |
	Sort-Object $Sort -Unique | .{process{ if ($script:CommonParameters -notcontains $_.Name) { $_ }}}
}

function Get-ParameterSetParameter($ParameterSet, $Sort) {
	$ParameterSet.Parameters | Sort-Object $Sort | .{process{ if ($script:CommonParameters -notcontains $_.Name) { $_ }}}
}

$validTypeKeys = @(
	'type'
	'description'
)
function Test-Type($Hash) {
	if ($Hash -isnot [hashtable]) {
		throw "$script:Name : Invalid input/output type. Expected : Hashtable. Actual : $($Hash.GetType())."
	}
	foreach($key in $Hash.Keys) {
		if ($validTypeKeys -notcontains $key) {
			throw "$script:Name : Invalid input/output key : $key. Valid keys : $validTypeKeys."
		}
	}
}

$validExampleKeys = @(
	'title'
	'introduction'
	'code'
	'remarks'
	'test'
)
function Test-Example($Hash) {
	if ($Hash -isnot [hashtable]) {
		throw "$script:Name : Invalid example type. Expected : Hashtable. Actual : $($Hash.GetType())."
	}
	foreach($key in $Hash.Keys) {
		if ($validExampleKeys -notcontains $key) {
			throw "$script:Name : Invalid example key : $key. Valid keys : $validExampleKeys."
		}
	}
}

$validLinkKeys = @(
	'text'
	'URI'
)
function Test-Link($Hash) {
	if ($Hash -isnot [hashtable]) {
		throw "$script:Name : Invalid link type. Expected : Hashtable. Actual : $($Hash.GetType())."
	}
	foreach($key in $Hash.Keys) {
		if ($validLinkKeys -notcontains $key) {
			throw "$script:Name : Invalid link key : $key. Valid keys : $validLinkKeys."
		}
	}
}

$validTaskKeys = @(
	'title'
	'description'
	'examples'
)
function Test-Task($Hash) {
	if ($Hash -isnot [hashtable]) {
		throw "$script:Name : Invalid task type. Expected : Hashtable. Actual : $($Hash.GetType())."
	}
	foreach($key in $Hash.Keys) {
		if ($validTaskKeys -notcontains $key) {
			throw "$script:Name : Invalid task key : $key. Valid keys : $validTaskKeys."
		}
	}
}

$validParameterKeys = @(
	'name'
	'type'
	'description'
	'cmdlets'
	'values'
)
function Test-Parameter($Hash) {
	if ($Hash -isnot [hashtable]) {
		throw "$script:Name : Invalid 'parameters' type. Expected : Hashtable. Actual : $($Hash.GetType())."
	}
	foreach($key in $Hash.Keys) {
		if ($validParameterKeys -notcontains $key) {
			throw "$script:Name : Invalid parameter key : $key. Valid keys : $validParameterKeys."
		}
	}
}

$validParameterValueKeys = @(
	'value'
	'description'
)
function Test-ParameterValue($Hash) {
	if ($Hash -isnot [hashtable]) {
		throw "$script:Name : Invalid parameter value type. Expected : Hashtable. Actual : $($Hash.GetType())."
	}
	foreach($key in $Hash.Keys) {
		if ($validParameterValueKeys -notcontains $key) {
			throw "$script:Name : Invalid parameter value key : $key. Valid keys : $validParameterValueKeys."
		}
	}
}

### output to the file
.{
	@'
<?xml version="1.0" encoding="utf-8"?>
<helpItems xmlns="http://msh" schema="maml">
'@

	foreach($topic in $Topics) {
		if ($topic['command']) {
			ConvertTo-MamlCommand $topic
		}
		elseif ($topic['provider']) {
			ConvertTo-MamlProvider $topic
		}
		else {
			throw "Expected either 'command' or 'provider' keys."
		}
	}

	@'
</helpItems>
'@

} | Out-File -Encoding UTF8 $Output
