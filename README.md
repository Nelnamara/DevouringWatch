# DevouringWatch

Void Assault tracker for World of Warcraft: Midnight 12.0.7+.

DevouringWatch monitors the Void Assault world events in Eversong and Zul'Aman — showing active event countdowns, Void Strike task quest progress, and your weekly Field Accolade and Voidlight Marl currency totals.

## Features

- **Zone event scanner** — auto-detects active timed events on the current map using `C_AreaPoiInfo.GetEventsForMap` and `GetAreaPOISecondsLeft`. No hardcoded IDs required — picks up Void Assault events automatically when you enter the zone
- **Void Strike progress** — displays active task quest progress bars (the escalating strike phases) pulled from the quest log
- **Currency display** — live totals for Field Accolade and Voidlight Marl
- **Void Incursion escalation** — detects escalated Incursion events via the same POI timer system
- **Weekly assault quests** — tracks the Eversong Woods and Zul'Aman weekly Void Assault quests by explicit ID (they aren't `isTask`-flagged, so a generic task scan misses them)
- **Draggable panel** — position saved per character
- **Minimap button** — quick toggle from the minimap, with a matching AddOns-list icon

## Slash Commands

| Command | Effect |
|---|---|
| `/dw` | Toggle panel visibility |
| `/dw scan` | Print all timed POIs on the current map with IDs and timer values |
| `/dw lock` / `/dw unlock` | Lock or unlock frame position |
| `/dw reset` | Reset to default position |

## Day 1 Usage

DevouringWatch works without any configuration. Log in, fly to Eversong or Zul'Aman, and the panel will automatically detect and display active Void Assault events. Use `/dw scan` to see raw POI IDs if you want to report them or verify detection.

## Compatibility

- WoW Midnight 12.0.7+
- No library dependencies
- Uses `C_AreaPoiInfo` and `C_QuestLog` — both fully accessible in Midnight

## Changelog

### v1.0.2
- Minimap button and AddOns-list icon (addon artwork, standard 24px)

### v1.0.1
- Fixed the silent failure behind "/dw scan does nothing" — `C_AreaPoiInfo.GetAreaPOIInfo` requires the `mapID` argument; it was being called without one
- Added explicit weekly Void Assault quest tracking (Eversong Woods, Zul'Aman)
- Interface bumped to 120007

### v1.0.0
- Initial release: zone event scanner, Void Strike progress, currency display

## Roadmap

- [ ] **More event types** — broaden coverage as new Void content lands
- [ ] **Configurable display** — show/hide individual sections (events, quests, currencies)
- [ ] **Per-realm weekly reset awareness** — clearer "done this week" state across alts

## Author

Nelnamara — [CurseForge](https://www.curseforge.com/wow/addons/devouringwatch) · [GitHub](https://github.com/Nelnamara/DevouringWatch)
