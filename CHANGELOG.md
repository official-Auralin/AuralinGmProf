# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and this project uses semantic versioning with channel suffixes.

## [Unreleased]

### Fixed

- ElvUI bridge now uses the Retail `C_AddOns.IsAddOnLoaded()` API with a legacy fallback, preventing startup errors on current WoW clients.

### Added

- Retail-first modular rewrite:
  - `ProfessionService` for profession discovery/opening wrappers.
  - LDB launcher + LibQTip tooltip + LibDBIcon minimap support.
  - AddOn Compartment callbacks.
  - ElvUI DataText registration bridge.
  - Blizzard settings category and slash command controls.
- New SavedVariables schema: `AuralinGmProfDB`.
- CurseForge/GitHub packaging scaffolding (`.pkgmeta`, workflow, releasing docs).
- MIT license.
- New README with original-author attribution.
- Added zhCN localization (contributed by XingDvD).

### Changed

- Addon identity migrated to `AuralinGmProf`.
- TOC modernized for Retail interface and packaging substitutions.
- Localization source cleaned up to remove mojibake text.
- DataText now supports dynamic concentration modes (`focused`, `lowest`, `portfolio`, `count`).
- Added slash/config controls for DataText mode, low-concentration threshold, and percentage display.
- Added `CURRENCY_DISPLAY_UPDATE` refresh handling for live concentration updates.
- Corrected default click mapping so right click opens spellbook and middle click toggles tooltip.

### Removed

- Legacy TOC file removed.
- Legacy single-file addon core.
- Legacy `readme.txt`.
