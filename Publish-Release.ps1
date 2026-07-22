param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $projectRoot

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
