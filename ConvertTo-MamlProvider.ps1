
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

<#
.Synopsis
	Converts provider help to MAML.
	It is not designed for direct calls.
#>
function ConvertTo-MamlProvider
(
	[Parameter(Mandatory = $true)]
	$Help
)
{
	$script:Name = $Help.provider

	### begin provider

	@"
<providerHelp>
<Name>$script:Name</Name>
"@

	### drives

	$drives = @($Help['drives'])
	if ($drives) {
		Out-Text Drives Para $drives
	}

	### synopsis

	$synopsis = @($Help['synopsis'])
	if (!$synopsis) {
		throw "$script:Name : Synopsis should not be empty."
	}
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
			Test-Task $task

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
				Out-Examples $examples $script:TagsExamplesProvider
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
			Test-Parameter $parameter

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
					Test-ParameterValue $value

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
		Out-Links $links $script:TagsLinksProvider
	}

	### end provider
	'</providerHelp>'
}
