# NPC, Quest & Bot Crowd — Integration Guide

This document tells `world.gd` and `player.gd` exactly what to add to wire in
the new systems. All code below is meant to be pasted/adapted into those files;
do not duplicate the logic into the new scripts.

---

## 1. Autoload / Project Settings

No new autoloads are required. `NPCDatabase`, `QuestDatabase`, `WorldBotSpawner`,
`NPC`, `BotPlayer`, and `QuestLog` all use `class_name` — Godot resolves them
globally without autoload registration.

---

## 2. world.gd — What to Add

### 2a. Declare the spawner

```gdscript
# At the top of world.gd, alongside existing node refs:
@onready var _bot_spawner: WorldBotSpawner = WorldBotSpawner.new()

# Bounds — adjust to match your actual map layout.
const TOWN_BOUNDS  := Rect2(-384.0, -384.0,  768.0,  768.0)
const FIELD_BOUNDS := Rect2( 384.0, -768.0, 1536.0, 1536.0)
```

### 2b. Spawn NPCs in _ready()

Each NPC is a bare CharacterBody2D with npc.gd as its script.
Place them by id; positions are in world-space coordinates matching your tilemap.

```gdscript
func _spawn_npcs() -> void:
    var npc_placements: Dictionary = {
        "kafra_elena":           Vector2( 64,  -32),
        "merchant_doran":        Vector2(128,    0),
        "blacksmith_krag":       Vector2(-96,   16),
        "alchemist_lia":         Vector2( 32,   80),
        "guild_master_aldric":   Vector2(  0, -128),
        "guard_captain_rena":    Vector2(192,  -64),
        "quest_giver_mira":      Vector2(-64,  -80),
        "innkeeper_boris":       Vector2(-128,   32),
        "merchant_caravan_otto": Vector2( 96,   96),
    }

    var npc_script = preload("res://scripts/npc.gd")
    for npc_id in npc_placements:
        var npc_node := CharacterBody2D.new()
        npc_node.set_script(npc_script)
        npc_node.npc_id = npc_id
        npc_node.global_position = npc_placements[npc_id]
        add_child(npc_node)

        # Connect NPC signals to your UI layer (hud_v2, dialogue panel, etc.)
        npc_node.dialogue_requested.connect(_on_npc_dialogue)
        npc_node.shop_requested.connect(_on_npc_shop)
        npc_node.quest_board_requested.connect(_on_npc_quests)
```

### 2c. Spawn bots in _ready() (server only)

```gdscript
func _spawn_bots() -> void:
    # Only the server runs bot AI; call with is_authority=true on the server.
    if not multiplayer.is_server():
        return

    add_child(_bot_spawner)
    _bot_spawner.bot_chat.connect(_on_bot_chat)

    # Spread bots across a few town locations.
    var town_spawn_points: Array = [
        Vector2(  0,   0), Vector2( 80, -40), Vector2(-80,  40),
        Vector2( 40,  80), Vector2(-40, -80), Vector2(120,  20),
    ]

    # Count 14 by default; pass a lower number if the world is small.
    _bot_spawner.spawn_bots(self, 14, town_spawn_points, TOWN_BOUNDS, FIELD_BOUNDS, true)
```

### 2d. UI signal handlers (stubs — fill in with actual UI calls)

```gdscript
func _on_npc_dialogue(npc_id: String, lines: Array) -> void:
    # e.g. $HUD/DialoguePanel.open(npc_id, lines)
    pass

func _on_npc_shop(npc_id: String, inventory: Array) -> void:
    # e.g. $HUD/ShopPanel.open(npc_id, inventory)
    pass

func _on_npc_quests(npc_id: String, quests: Array) -> void:
    # e.g. $HUD/QuestPanel.open(npc_id, quests)
    pass

func _on_bot_chat(bot_name: String, bot_position: Vector2, message: String) -> void:
    # e.g. spawn a floating speech-bubble label near bot_position
    pass
```

### 2e. Trigger zones for escort / reach quests

For `OBJ_REACH` objectives (e.g. "escort_waypoint_ruins", "crypt_inner_chamber"):

```gdscript
# In the scene or in code: Area2D trigger zones.
# When a player enters, call:
func _on_trigger_zone_body_entered(body: Node2D, location_tag: String) -> void:
    if body.is_in_group("player") and body.has_node("QuestLog"):
        body.get_node("QuestLog").report_reach(location_tag)
```

---

## 3. player.gd — What to Add

### 3a. Add QuestLog as a child node

In player.gd `_ready()`:

```gdscript
var _quest_log: QuestLog = QuestLog.new()
_quest_log.name = "QuestLog"
add_child(_quest_log)
_quest_log.setup(base_level)          # base_level comes from StatEngine attrs

# Connect rewards signal so XP/gold are applied automatically.
_quest_log.quest_completed.connect(_on_quest_completed)
_quest_log.quest_accepted.connect(func(id, _d): print("Quest accepted: ", id))
```

### 3b. Hook enemy deaths into quest_log

In enemy.gd `die()`, after awarding XP/gold to the player:

```gdscript
# Inside enemy.die():
if target_player and is_instance_valid(target_player):
    if target_player.has_node("QuestLog"):
        target_player.get_node("QuestLog").report_kill(enemy_type)
```

### 3c. Hook item pickups into quest_log

In pickup.gd `_on_body_entered()` (or wherever items are granted), after adding
the item to inventory:

```gdscript
# Inside pickup logic, after the item is given:
if body.has_node("QuestLog"):
    body.get_node("QuestLog").report_item_collected(item_id, quantity)
```

### 3d. Apply quest rewards on completion

```gdscript
func _on_quest_completed(quest_id: String, rewards: Dictionary) -> void:
    add_xp(rewards.get("xp", 0))
    add_gold(rewards.get("gold", 0))
    # Item rewards: hand the array to inventory.gd's add_item() loop.
    for item_id in rewards.get("item_ids", []):
        if has_node("Inventory"):
            get_node("Inventory").add_item(item_id, 1)
    # Optionally show a "Quest Complete!" notification in the HUD.
```

### 3e. Interact key handling

In player.gd `_unhandled_input()` or `_input()`:

```gdscript
if event.is_action_pressed("interact"):   # define "interact" in Input Map
    var nearby_npc = NPC.get_nearest_npc(self, 64.0)
    if nearby_npc:
        nearby_npc.interact(self)
```

### 3f. Notify QuestLog on level-up

```gdscript
func _level_up() -> void:
    base_level += 1
    # ... existing level-up logic ...
    if has_node("QuestLog"):
        get_node("QuestLog").notify_level_change(base_level)
```

---

## 4. Bot crowd — client mirror nodes

When the network manager spawns a player peer it does NOT call
`setup(is_authority: true)` on the client's copy of bot nodes.
The server's WorldBotSpawner owns all bot instances with `is_authority=true`;
clients receive position/velocity via MultiplayerSynchronizer (configured
the same way as real player synchronisers) and call `setup(false)` so the AI
tick is skipped on their end.

```gdscript
# In NetworkManager or world.gd, after receiving a bot spawn RPC on the client:
func _on_remote_bot_spawned(bot_node: BotPlayer) -> void:
    bot_node.setup(false, TOWN_BOUNDS, FIELD_BOUNDS)
```

---

## 5. Bot count guidance

| Scenario                        | Recommended count |
|---------------------------------|-------------------|
| Small alpha test (1-5 players)  | 6-10              |
| Normal play (10-30 players)     | 12-16             |
| Max server (50-100 players)     | 10-14 (keep low to leave headroom for real player bandwidth) |

Never exceed 20 bot instances on a single map. The old `mmo_engine.gd`
simulation (65-100 bots) was purely local/demo; these bots share server
budget with real players and their network replication.

---

## 6. Quest id / Item id reconciliation

Quest rewards and shop inventories reference item ids like `"health_potion"`,
`"iron_sword"`, `"chain_mail"`, etc. These are intentionally forward-compatible
strings — match them against whatever ids `item_database.gd` (Inventory &
Equipment workstream) defines. A one-time reconciliation pass in that database
is all that is needed; no changes to quest_database.gd are required unless the
item ids diverge significantly.
