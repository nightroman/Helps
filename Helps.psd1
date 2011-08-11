
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

@{
	ModuleVersion = '1.0.1'
	CompanyName = 'http://code.google.com/p/helps-powershell-help-builder/'
	Description = 'Helps module - PowerShell help builder '
	Copyright = '(C) 2011 Roman Kuzmin. All rights reserved.'
	Author = 'Roman Kuzmin'

	GUID = '8f653001-f35b-4c76-9439-a8e932a10245'
	PowerShellVersion = '2.0'
	NestedModules = 'Helps.psm1'
	FunctionsToExport = @(
		'Convert-Helps'
		'Merge-Helps'
		'New-Helps'
		'Test-Helps'
	)
}
