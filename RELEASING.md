# Releasing AuralinGmProf

## Branch Model

- `main`: stable release branch.
- `develop`: integration branch for alpha/beta iteration.

## Version Tag Rules

- Alpha: `vX.Y.Z-alpha.N` (example: `v0.2.0-alpha.3`)
- Beta: `vX.Y.Z-beta.N` (example: `v0.2.0-beta.1`)
- Release: `vX.Y.Z` (example: `v0.2.0`)

## Required GitHub Secrets

- `CF_API_KEY`: CurseForge upload token.
- `GITHUB_TOKEN`: provided automatically by GitHub Actions.

Optional:

- `WOWI_API_TOKEN` if you add WoWInterface publishing.

## Pre-Release Checklist

1. Confirm `## Interface` value in `AuralinGmProf.toc` matches current Retail.
2. Confirm `## X-Curse-Project-ID` is set to your new CurseForge project ID.
3. Update `CHANGELOG.md`.
4. Validate local Lua syntax and in-game load behavior.
5. Merge to `develop` for alpha/beta tagging, or `main` for release.

## Tag and Publish

1. Create and push tag:
   - `git tag v0.1.0-alpha.1`
   - `git push origin v0.1.0-alpha.1`
2. GitHub Actions runs `.github/workflows/release.yml`.
3. BigWigs packager builds zip and uploads by channel according to tag suffix.

## Manual Rollback

1. Mark broken file as archived/unlisted on CurseForge.
2. Push a hotfix tag with higher version (example: `v0.1.0-alpha.2`).
