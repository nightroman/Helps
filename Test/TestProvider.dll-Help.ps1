
<#
.Synopsis
	Help source script for exhaustive testing of provider help features.

.Description
	It is used by Test-Helps.ps1.
#>

@{
	provider = 'TestProvider'
	drives = '<drives>...<drives>'
	synopsis = '<synopsis>...<synopsis>'
	description = @'
<description>
text text text text text text text text text
text text text text text text text text text
	text text text text
	text text text text

text text text text text text text text text
text text text text text text text text text
	text text text text
	text text text text
	<description>
'@
	capabilities = '> sample', 'remarks', @'
New line.
Joined line.

	Indented line.

New block.
Joined line.
'@

	tasks = @(
		@{
			title = '<title>...<title>'
			description = '> sample', 'remarks', @'
New line.
Joined line.

	Indented line.

New block.
Joined line.
'@
			examples = @(
				@{
					#title -- omitted 'title' gets --- EXAMPLE 1, 2... ---
					introduction = @'
<introduction> Unlike in command help
it is not joined with the code <introduction>
'@
					code = {
						$result1 = $x + $y
						$result2 = $x - $y
					}
					remarks = @'
<remarks> text text text text text text text
text text text text text text text text text
	text text text
	text text text

text text text text text text text text text
text text text text text text text text text
	text text text
	text text text <remarks>
'@
					test = {
						$x = 5
						$y = 1
						. $args[0]
						if ($result1 -ne 6) { throw }
						if ($result2 -ne 4) { throw }
						'Tested provider example.'
					}
				}
			)
		}
	)
	parameters = @(
		@{
			name = 'Param1'
			type = 'string'
			description = @'
<description> text text text text text text
text text text text text text text text text
	text text text
	text text text

text text text text text text text text text
text text text text text text text text text
	text text text
	text text text <description>
'@
			cmdlets = 'Get-Item, Set-Item'
			values = @(
				@{
					value = 'value1'
					description = '<description>...<description>'
				}
				@{
					value = 'value2'
					description = @'
<description> text text text text text text text
text text text text text text text text text text
	text text text
	text text text

text text text text text text text text text text
text text text text text text text text text text
	text text text
	text text text <description>
'@
				}
				@{
					value = 'value3'
					description = @(
						'<description> line 1'
						'line 2'
						'line 3 <description>'
					)
				}
			)
		}
	)
	notes = @'
1.1
1.2

	2.indent

3.1
3.2
'@
	links = @(
		@{
			text = '<text>Both text<text>'
			URI = '<URI>and URI<URI>'
		}
		@{
			text = '<text>Just text<text>'
		}
		@{
			URI = '<URI>Just URI. Note an extra leading space.<URI>'
		}
	)
}
