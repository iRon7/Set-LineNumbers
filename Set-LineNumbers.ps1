<#PSScriptInfo
.Version 0.1.0
.Guid 19631007-d664-4cb5-85ab-a532b893b3a3
.Author Ronald Bode (iRon)
.CompanyName PowerSnippets.com
.Copyright Ronald Bode (iRon)
.Tags Script Line Numbers Example Analyze
.LicenseUri https://github.com/iRon7/Set-LineNumbers/LICENSE
.ProjectUri https://github.com/iRon7/Set-LineNumbers
.IconUri https://raw.githubusercontent.com/iRon7/Set-LineNumbers/master/Set-LineNumbers.png
.ExternalModuleDependencies
.RequiredScripts
.ExternalScriptDependencies
.ReleaseNotes
.PrivateData
#>

# .SYNOPSIS
# Adds, updates or removes line numbers in a script.
#
# .DESCRIPTION
# Set-LineNumbers adds, update or remove line numbers to a powershell script
# without affecting the functionality of the code.
# This might come in handy when you want to analyze a script or share it with others.
#
# .INPUTS
# String
#
# .OUTPUTS
# String
#
# .EXAMPLE
# # Adding line numbers
#
# Given a script that might look like:
#
#     $Script = @'
#     function CountChar([String]$Text, [Char]$Char) {
#         $Text.ToCharArray() | Where-Object { $_ -eq $Char } | Measure-Object | Select-Object -ExpandProperty Count
#     }
#
#     $Text = @"
#     Finished files are the result of years
#     of scientific study combined with the
#     experience of many years.
#     "@
#     CountChar -Text $Text -Char 'f'
#     '@
#
# The following command will add line numbers to the script:
#
#     $Numbered = $Script | Set-LineNumbers
#     $Numbered
#
#     <# 01 #> function CountChar([String]$Text, [Char]$Char) {
#     <# 02 #>     $Text.ToCharArray() | Where-Object { $_ -eq $Char } | Measure-Object | Select-Object -ExpandProperty Count
#     <# 03 #> }
#     <# 04 #>
#     <# 05 #> $Text = @"
#     Finished files are the result of years
#     of scientific study combined with the
#     experience of many years.
#     "@
#     <# 10 #> CountChar -Text $Text -Char 'f'
#
# > [!Note]
# > Line numbers `06` till `09` are suppressed as line `05` is a multiline here-string.
#
# .EXAMPLE
# # updated line numbers
#
# In case you have changed a script with line numbers and would like to renumber the script,
# you might simply call the invoke the `Set-LineNumbers` cmdlet again.
# The example below adds the comment "# Count the F's" to the script and renumbers it:
#
#     "# Count the F's", $Numbered | Set-LineNumbers
#
# .EXAMPLE
# # Removing line numbers
#
# In case you copy or download a script with line numbers and would like to remove them:
#
#     $Numbered | Set-LineNumbers -Remove
#
# .PARAMETER Script
# A string that contains the script to add, update or remove line numbers.
#
# .PARAMETER Remove
# If set, the line numbers will be removed from the script.

[CmdletBinding()]Param(
    [Parameter(ValueFromPipeline = $True)][String]$Script,
    [Switch]$Remove
)

if ($Input) { $Content = $Input -Join [Environment]::NewLine } else { $Content = $Script }
$Tokens = [System.Management.Automation.PSParser]::Tokenize($Content, [ref]$Null)
$Format = "<# {0:D$($Tokens[-1].StartLine.ToString().Length)} #>"
$StringBuilder = [System.Text.StringBuilder]::new()
$Start = 0
$LineNumber = 1
foreach ($Token in $Tokens) {
    if ($LineNumber) {
        if ($Token.Type -eq 'Comment' -and $Token.Content -match '^<\#\ \d+\ \#>$') {
            $Start = $Token.Start + $Token.Length + 1
            continue
        }
        else {
            if ($Start -gt $Token.Start) { $Start = $Token.Start }
            if (-not $Remove) {
                $Null = $StringBuilder.Append(($Format -f $LineNumber))
                if ($Token.Type -ne 'NewLine') { $Null = $StringBuilder.Append(' ') }
            }
            $LineNumber = $Null
        }
    }
    if ($Token.Type -eq 'NewLine') {
        $End = if ($Token) { $Token.Start + $Token.Length } else { $Content.Length }
        $Length = $End - $Start
        $Null = $StringBuilder.Append($Content.SubString($Start, $Length))
        $Start = $End
        $LineNumber = $Token.EndLine
    }
}
if ($Start -lt $Content.Length) { $Null = $StringBuilder.Append($Content.SubString($Start)) }
$StringBuilder.ToString()