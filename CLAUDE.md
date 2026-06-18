# DevouringWatch — CLAUDE.md

Void Assault / zone-event tracker for **WoW Midnight 12.0.7+**. Author: Nelnamara.
Scans the current map for timed events, tracks the weekly Void Assault quests and
the Field Accolade / Voidlight Marl currencies, and has a minimap button.

## Files
- `DevouringWatch.lua` — single-file addon (UI, scan, quests, currencies, minimap button, slash).

## Key data / APIs
- POI scan: `C_AreaPoiInfo.GetEventsForMap(mapID)` → `C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)`.
  **`mapID` is REQUIRED** on `GetAreaPOIInfo` — v1.0.0 shipped it without and the whole addon died silently. Don't regress this.
- Currencies: Field Accolade `3405`, Voidlight Marl `3316` (`C_CurrencyInfo.GetCurrencyInfo`).
- Intro unlock quest: `96080`. Weekly Void Assault quests: `94385` (Eversong Woods), `94386` (Zul'Aman).
- `GetTaskQuests()` only catches `isTask`-flagged quests; the weekly assaults are proper weeklies → checked by explicit ID in `GetWeeklyAssaultQuest()`.

## Slash
`/dw` (toggle) · `scan` (print discovered POI IDs) · `lock`/`unlock` · `reset`

## Build / release / deploy
- BigWigs packager on **`v*` tag push**. CurseForge secret: **`CURSFORGE_API_KEY`** (misspelled, leave as-is).
- Local test: copy to `D:\World of Warcraft\_retail_\Interface\AddOns\DevouringWatch\`.
- Current version: **1.0.2** (Interface 120007). Single retail TOC (`DevouringWatch_Mainline.toc`).

## Conventions
- **Never** append a `Co-Authored-By` trailer to commits.
- Branding: minimap/AddOns icon in `Media\` (`icon.png`, `minimap.png`).
