# AuralinGmProf

AuralinGmProf is a modern Retail revival of the discontinued `gmProf` addon.

## Attribution

- Revived from **gmProf**.
- Original design and code: **gmarco** (also known as **Wexen** on WoWInterface).
- Historical thanks retained: **Phanx** for addon localization guidance.

## What It Does

- Provides a profession launcher for Retail WoW.
- Supports LDB displays (TitanPanel, ChocolateBar, Bazooka, etc.).
- Supports AddOn Compartment click/hover behavior.
- Supports optional minimap icon via LibDBIcon.
- Supports optional ElvUI DataText registration.
- Supports slash commands and a Blizzard settings category.

## Dynamic DataText

DataText can show concentration state instead of only profession count.

Modes:

- `focused`: concentration for your last opened crafting profession.
- `lowest`: lowest concentration pool across discovered professions.
- `portfolio`: a compact multi-profession concentration view.
- `count`: legacy profession count display.

## Slash Commands

- `/agmp help`
- `/agmp open`
- `/agmp spellbook`
- `/agmp minimap`
- `/agmp config`
- `/agmp left|right|middle open|tooltip|spellbook`
- `/agmp datatext focused|lowest|portfolio|count`
- `/agmp warn <number>`
- `/agmp percent`
- `/agmp reset`

## Compatibility Targets

- Retail Mainline (current baseline: Interface `120001`).
- ElvUI compatibility via DataText registration.
- Compatible with LDB consumers and common bar/UI addons that do not block Blizzard profession APIs.

## Release Channels

- `vX.Y.Z-alpha.N` -> alpha
- `vX.Y.Z-beta.N` -> beta
- `vX.Y.Z` -> release

## Packaging

- Uses CurseForge/WowAce style packaging metadata (`.pkgmeta`).
- Uses GitHub Actions + BigWigs packager for automated channel uploads.

## Project Status

This repository is in active revival mode and will ship iteratively through alpha, beta, and release gates.
