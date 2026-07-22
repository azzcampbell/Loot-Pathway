param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [switch]$ChangelogApproved
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $projectRoot

$changelogPath = Join-Path $projectRoot "CHANGELOG.md"
if (-not (Test-Path -LiteralPath $changelogPath)) {
    throw "CHANGELOG.md is missing. Draft the release notes and ask Aaron to approve them before publishing."
}
$changelog = Get-Content -LiteralPath $changelogPath -Raw
$expectedHeading = "# Loot Pathway $Version"
if ($changelog -notmatch "(?m)^$([regex]::Escape($expectedHeading))\s*$") {
    throw "CHANGELOG.md must begin with the approved heading '$expectedHeading'."
}
if (-not $ChangelogApproved) {
    Write-Output "----- CHANGELOG APPROVAL REQUIRED -----"
    Write-Output $changelog.Trim()
    Write-Output "---------------------------------------"
    throw "Do not publish yet. Show this changelog to Aaron and rerun with -ChangelogApproved only after he approves it."
}

if ((git status --porcelain).Length -ne 0) {
    throw "Commit the addon changes before publishing a release."
}

$tag = "v$Version"
if (git tag --list $tag) {
    throw "Tag $tag already exists. Choose a new version."
}

$tocPath = Join-Path $projectRoot "LootPathway_TBC.toc"
$tocText = Get-Content -LiteralPath $tocPath -Raw
$updatedToc = [regex]::Replace($tocText, '(?m)^## Version:\s*[^\r\n]+', "## Version: $Version")
if ($updatedToc -eq $tocText) {
    throw "Could not update the Version field in LootPathway_TBC.toc."
}
[System.IO.File]::WriteAllText($tocPath, $updatedToc)

& (Join-Path $projectRoot "Build-Release.ps1")

git add -- LootPathway_TBC.toc
git commit -m "Release Loot Pathway $Version"
git tag $tag
git push origin main
git push origin $tag

Write-Output "Published $tag. GitHub and CurseForge will now build the tagged release."
