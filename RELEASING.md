# Publishing Loot Pathway

Every release uses one approved `CHANGELOG.md` for both GitHub and CurseForge.

1. Update `CHANGELOG.md` with the new version and concise player-facing changes.
2. Confirm the live GitHub README matches `README.md`, the repository summary carries the same simple next-gear/source message, and the live CurseForge description matches `CURSEFORGE.md`, including the level 70-only notice.
3. Show the complete changelog to Aaron and wait for explicit approval.
4. Commit the approved addon and changelog changes locally.
5. Run `Publish-Release.ps1 -Version X.Y.Z -ChangelogApproved`.
6. Confirm that the GitHub release succeeds and that CurseForge receives the package.

Never use `-ChangelogApproved` based on an assumption. If the wording changes after approval, show the revised changelog again before publishing.
