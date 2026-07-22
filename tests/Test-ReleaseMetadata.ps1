$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$toc = Get-Content -LiteralPath (Join-Path $projectRoot "LootPathway_TBC.toc") -Raw
$readme = Get-Content -LiteralPath (Join-Path $projectRoot "README.md") -Raw
$curseForge = Get-Content -LiteralPath (Join-Path $projectRoot "CURSEFORGE.md") -Raw
$releaseGuide = Get-Content -LiteralPath (Join-Path $projectRoot "RELEASING.md") -Raw
$publisher = Get-Content -LiteralPath (Join-Path $projectRoot "Publish-Release.ps1") -Raw
$playerFiles = @("BisData.lua", "Data.lua", "WowheadCorrections.lua", "README.md", "CURSEFORGE.md")
$errors = [System.Collections.Generic.List[string]]::new()

if ($toc -notmatch '(?m)^## Interface:\s*20506\s*$') { $errors.Add("TOC does not target TBC Anniversary interface 20506.") }
if ($toc -notmatch '(?m)^## Author:\s*Mozley\s*$') { $errors.Add("TOC author metadata is not Mozley.") }
if ($toc -notmatch '(?m)^## Version:\s*\d+\.\d+\.\d+\s*$') { $errors.Add("TOC version is not semantic.") }
if ($toc -notmatch '(?im)^## Notes:.*level 70') { $errors.Add("TOC description does not state the level 70 scope.") }
if ($readme -notmatch '(?is)max-level\s*\(level 70\).*not a levelling addon') { $errors.Add("README does not state the level 70-only scope.") }
if ($curseForge -notmatch '(?is)max-level\s*\(level 70\).*not a levelling addon') { $errors.Add("CurseForge description does not state the level 70-only scope.") }
if ($releaseGuide -notmatch 'Show the complete changelog to Aaron') { $errors.Add("Release guide does not require Aaron's changelog approval.") }
if ($readme -notmatch 'Publish-Release\.ps1 -Version 1\.0\.0 -ChangelogApproved') { $errors.Add("README publish instructions omit the changelog approval switch.") }
if ($readme -notmatch 'uses the approved `CHANGELOG\.md` verbatim') { $errors.Add("README does not describe the approved changelog as the release notes source.") }
foreach ($playerFile in $playerFiles) {
    $playerText = Get-Content -LiteralPath (Join-Path $projectRoot $playerFile) -Raw
    if ($playerText -match '(?i)\bLoon\b') { $errors.Add("Player-facing file '$playerFile' still refers to Loon.") }
}
if ($publisher -notmatch '\[switch\]\$ChangelogApproved' -or $publisher -notmatch 'if \(-not \$ChangelogApproved\)') {
    $errors.Add("Publisher does not enforce the changelog approval switch.")
}

if ($errors.Count -gt 0) { throw "Release metadata validation failed:`n - $($errors -join "`n - ")" }
Write-Output "Release metadata valid: level 70 scope and changelog approval gate are explicit."
