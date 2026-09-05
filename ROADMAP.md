# Chronicles of Midgard — MMORPG Overhaul Roadmap

Decisions locked in with the user on 2026-09-05:
- **Real networked multiplayer** (not just simulated bots) — actual humans log in and share a world.
- **Godot native multiplayer** (ENetMultiplayerPeer, high-level API) on the existing GDScript codebase.
  The `web/index.html` canvas client is retired as the live product; it stays only as a design/UX
  reference (its glassmorphism look is the target aesthetic for the new Godot HUD).
- Simulated/bot players stay, but **small in number** (~10-20), just to make the world feel alive
  alongside real players — not the 65-100 in the old `mmo_engine.gd` prototype.
- Target: 50-100 concurrent **real** players on one persistent map, solo or partied.
- Asset pipeline: keep using the existing local, scriptable PIL generator
  (`scripts/generate_assets.py`) as the primary art pipeline — no Canva unless specifically asked for.

## Already existing and reusable (do not rewrite from scratch)
- `scripts/stat_engine.gd` — 6-stat RO-style formula engine (HP/SP, ATK/MATK, hit/flee/aspd, elements).
- `scripts/skill_database.gd` — 24+ skills across 6 classes (knight/wizard/assassin/high_priest/hunter/blacksmith).
- `scripts/mmo_engine.gd` — bot AI states/behaviors (city chatting, grinding, party dungeon, MVP hunting) — to be
  scaled down and adapted as the small decorative bot crowd, driven server-side.
- `scripts/generate_assets.py` — PIL-based asset generator, already producing the character/tile/FX sprites in
  `assets/`.

## Phase 1 (this pass) — Foundation
Owned directly (not delegated, to avoid merge conflicts on shared files):
- `scripts/network_manager.gd` (new autoload): host/join, ENetMultiplayerPeer setup, player registry.
- `scenes/main_menu.tscn`/`.gd` (new): host/join/character-select entry point.
- `world.gd`/`world.tscn`, `player.gd`/`player.tscn`: converted to multiplayer-authoritative spawning,
  MultiplayerSynchronizer for position/anim, server-authoritative combat RPCs.
- Player now picks a **class** (knight/wizard/assassin/high_priest/hunter/blacksmith) using
  `StatEngine.CLASS_PROFILES` + `SkillDatabase`, instead of the old fixed 4-hero list.

Delegated to parallel subagents, each owning new files only (integrated afterward):
1. **Inventory & Equipment** — `scripts/item_database.gd`, `scripts/inventory.gd`, `scripts/equipment.gd`,
   `scenes/inventory_ui.tscn`.
2. **NPCs, Quests & Bot Crowd** — `scripts/npc.gd`, `scripts/quest_database.gd`, `scripts/quest_log.gd`,
   `scripts/bot_player.gd` (scaled-down decorative crowd adapted from `mmo_engine.gd`).
3. **UI/UX overhaul** — `scenes/hud_v2.tscn`/`.gd`, `assets/theme/ui_theme.tres`, `scenes/character_select.tscn`,
   glassmorphism-inspired look matching `web/index.html`.
4. **World & assets** — `scripts/world_builder.gd` (bigger multi-zone map: town/field/forest/dungeon),
   extensions to `scripts/generate_assets.py` for new tiles/props.

## Known follow-up (not in this pass)
- Persistence (save/load characters) — needs a save file or lightweight DB.
- Dedicated server hosting/deployment (Railway, like the user's other projects).
- Balance pass, more zones/quests/itemization content, guilds, PvP.
