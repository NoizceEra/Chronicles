# quest_database.gd
# Chronicles of Midgard - Quest definitions (fetch / kill / deliver / escort types)
# Pure data class. Enemy type strings match enemy.gd load_type_settings() keys.
# Item id strings are plausible matches for item_database.gd (reconcile at integration).
class_name QuestDatabase
extends RefCounted

# ── Objective type constants ─────────────────────────────────────────────────
const OBJ_KILL    := "kill"      # report_kill(enemy_type)
const OBJ_COLLECT := "collect"   # report_item_collected(item_id, qty)
const OBJ_DELIVER := "deliver"   # report_item_collected(item_id, qty) then quest auto-completes
const OBJ_REACH   := "reach"     # world.gd fires quest_log.report_reach(tag) on trigger zone

# ── Quest definitions ────────────────────────────────────────────────────────
# Each entry:
#   id            String  — unique key
#   name          String  — display name
#   giver_npc_id  String  — NPC who hands this out (see npc_database.gd)
#   description   String  — shown in quest log
#   objectives    Array   — list of {type, target, count}
#   rewards       Dict    — {xp, gold, item_ids: Array}
#   prerequisites Array   — quest ids that must be completed first
#   min_level     int     — player base_level requirement
const QUEST_DEFS: Dictionary = {

	# ── Tier 1: Starting area (Levels 1-9) ───────────────────────────────────

	"first_steps": {
		"id": "first_steps",
		"name": "First Steps",
		"giver_npc_id": "guard_captain_rena",
		"description": "Green slimes are overrunning the south fields. Slay five of them to protect the town road.",
		"objectives": [
			{"type": OBJ_KILL, "target": "slime_green", "count": 5}
		],
		"rewards": {"xp": 150, "gold": 80, "item_ids": ["health_potion"]},
		"prerequisites": [],
		"min_level": 1,
	},

	"herbalist_request": {
		"id": "herbalist_request",
		"name": "Herbalist's Request",
		"giver_npc_id": "alchemist_lia",
		"description": "Lia needs red and blue herbs for her brewing stock. Gather them from the fields.",
		"objectives": [
			{"type": OBJ_COLLECT, "target": "red_herb",  "count": 6},
			{"type": OBJ_COLLECT, "target": "blue_herb", "count": 4},
		],
		"rewards": {"xp": 120, "gold": 60, "item_ids": ["health_potion", "mana_potion"]},
		"prerequisites": [],
		"min_level": 1,
	},

	"potion_delivery": {
		"id": "potion_delivery",
		"name": "Potion Delivery",
		"giver_npc_id": "innkeeper_boris",
		"description": "Boris ordered potions from Lia but can't leave the inn. Collect the package from Lia and deliver it.",
		"objectives": [
			{"type": OBJ_COLLECT, "target": "potion_package", "count": 1},
			{"type": OBJ_DELIVER, "target": "potion_package",  "count": 1},
		],
		"rewards": {"xp": 100, "gold": 120, "item_ids": []},
		"prerequisites": [],
		"min_level": 1,
	},

	# ── Tier 2: Field (Levels 5-14) ──────────────────────────────────────────

	"blue_menace": {
		"id": "blue_menace",
		"name": "The Blue Menace",
		"giver_npc_id": "guard_captain_rena",
		"description": "Blue slimes are faster and tougher than their green cousins. Reduce their numbers in the eastern field.",
		"objectives": [
			{"type": OBJ_KILL, "target": "slime_blue", "count": 8}
		],
		"rewards": {"xp": 350, "gold": 180, "item_ids": ["health_potion", "health_potion"]},
		"prerequisites": ["first_steps"],
		"min_level": 5,
	},

	"iron_collection": {
		"id": "iron_collection",
		"name": "Ore for the Forge",
		"giver_npc_id": "blacksmith_krag",
		"description": "Krag's iron supply is running low. Collect iron ore from the rocky outcrops near the field ruins.",
		"objectives": [
			{"type": OBJ_COLLECT, "target": "iron_ore", "count": 10}
		],
		"rewards": {"xp": 280, "gold": 200, "item_ids": ["refine_stone"]},
		"prerequisites": [],
		"min_level": 5,
	},

	"goblin_threat": {
		"id": "goblin_threat",
		"name": "Goblin Threat",
		"giver_npc_id": "guard_captain_rena",
		"description": "Goblin raiding parties have been spotted near the north road. Drive them back.",
		"objectives": [
			{"type": OBJ_KILL, "target": "goblin", "count": 10}
		],
		"rewards": {"xp": 500, "gold": 250, "item_ids": ["health_potion", "iron_ore"]},
		"prerequisites": ["first_steps"],
		"min_level": 7,
	},

	"field_samples": {
		"id": "field_samples",
		"name": "Field Samples",
		"giver_npc_id": "quest_giver_mira",
		"description": "Mira needs slime gel from different slime variants for her research. Collect samples from green and blue slimes.",
		"objectives": [
			{"type": OBJ_COLLECT, "target": "slime_gel",      "count": 5},
			{"type": OBJ_COLLECT, "target": "slime_gel_blue", "count": 3},
		],
		"rewards": {"xp": 320, "gold": 160, "item_ids": ["mana_potion", "mana_potion"]},
		"prerequisites": ["first_steps"],
		"min_level": 5,
	},

	"forging_supplies": {
		"id": "forging_supplies",
		"name": "Forging Supplies",
		"giver_npc_id": "blacksmith_krag",
		"description": "Krag needs goblin bones as hardening agents for a special alloy. Bring him what he needs.",
		"objectives": [
			{"type": OBJ_COLLECT, "target": "goblin_bone", "count": 8},
			{"type": OBJ_DELIVER, "target": "goblin_bone", "count": 8},
		],
		"rewards": {"xp": 440, "gold": 300, "item_ids": ["iron_sword"]},
		"prerequisites": ["iron_collection", "goblin_threat"],
		"min_level": 8,
	},

	# ── Tier 3: Mid-range (Levels 10-19) ─────────────────────────────────────

	"red_tide": {
		"id": "red_tide",
		"name": "Red Tide",
		"giver_npc_id": "guild_master_aldric",
		"description": "Red slimes are dangerously aggressive and appear in larger numbers now. Clear out a significant group.",
		"objectives": [
			{"type": OBJ_KILL, "target": "slime_red", "count": 6}
		],
		"rewards": {"xp": 700, "gold": 350, "item_ids": ["elixir_of_strength"]},
		"prerequisites": ["blue_menace"],
		"min_level": 10,
	},

	"clearing_the_field": {
		"id": "clearing_the_field",
		"name": "Clearing the Field",
		"giver_npc_id": "guild_master_aldric",
		"description": "A mixed monster infestation is blocking the western trade route. Deal with slimes and goblins both.",
		"objectives": [
			{"type": OBJ_KILL, "target": "slime_green", "count": 8},
			{"type": OBJ_KILL, "target": "goblin",      "count": 6},
		],
		"rewards": {"xp": 650, "gold": 320, "item_ids": ["health_potion", "health_potion", "health_potion"]},
		"prerequisites": ["first_steps", "goblin_threat"],
		"min_level": 10,
	},

	"guild_initiation": {
		"id": "guild_initiation",
		"name": "Guild Initiation",
		"giver_npc_id": "guild_master_aldric",
		"description": "To earn your Guild rank, prove yourself by hunting goblins and a red slime. The Guild is watching.",
		"objectives": [
			{"type": OBJ_KILL, "target": "goblin",    "count": 5},
			{"type": OBJ_KILL, "target": "slime_red", "count": 2},
		],
		"rewards": {"xp": 800, "gold": 400, "item_ids": ["guild_badge"]},
		"prerequisites": ["goblin_threat", "blue_menace"],
		"min_level": 10,
	},

	"lost_merchant": {
		"id": "lost_merchant",
		"name": "Lost Merchant",
		"giver_npc_id": "merchant_caravan_otto",
		"description": "Otto's junior trader got separated from the caravan near the ruins. Escort the waypoint to find him and lead him back safely.",
		"objectives": [
			{"type": OBJ_REACH, "target": "escort_waypoint_ruins", "count": 1},
			{"type": OBJ_REACH, "target": "escort_return_town",    "count": 1},
		],
		"rewards": {"xp": 600, "gold": 500, "item_ids": ["magic_scroll"]},
		"prerequisites": [],
		"min_level": 8,
	},

	# ── Tier 4: Dungeon (Levels 15+) ─────────────────────────────────────────

	"skeleton_uprising": {
		"id": "skeleton_uprising",
		"name": "Skeleton Uprising",
		"giver_npc_id": "quest_giver_mira",
		"description": "Undead activity near the old burial ground is escalating. Put down eight skeletons before they reach the road.",
		"objectives": [
			{"type": OBJ_KILL, "target": "skeleton", "count": 8}
		],
		"rewards": {"xp": 1000, "gold": 500, "item_ids": ["holy_water", "health_potion", "health_potion"]},
		"prerequisites": ["field_samples"],
		"min_level": 15,
	},

	"veterans_test": {
		"id": "veterans_test",
		"name": "Veteran's Test",
		"giver_npc_id": "guild_master_aldric",
		"description": "The Guild tests its veterans against Midgard's fiercest field monsters. Hunt goblins, red slimes, and skeletons.",
		"objectives": [
			{"type": OBJ_KILL, "target": "goblin",    "count": 8},
			{"type": OBJ_KILL, "target": "slime_red", "count": 5},
			{"type": OBJ_KILL, "target": "skeleton",  "count": 5},
		],
		"rewards": {"xp": 1800, "gold": 900, "item_ids": ["elixir_of_strength", "chain_mail"]},
		"prerequisites": ["guild_initiation", "skeleton_uprising"],
		"min_level": 18,
	},

	"the_ancient_crypt": {
		"id": "the_ancient_crypt",
		"name": "The Ancient Crypt",
		"giver_npc_id": "quest_giver_mira",
		"description": "Mira has located an ancient crypt filled with powerful undead. Cleanse it — this is no ordinary field run.",
		"objectives": [
			{"type": OBJ_KILL,  "target": "skeleton",           "count": 12},
			{"type": OBJ_REACH, "target": "crypt_inner_chamber", "count": 1},
		],
		"rewards": {"xp": 2500, "gold": 1200, "item_ids": ["ancient_relic", "elixir_of_strength", "health_potion", "health_potion"]},
		"prerequisites": ["skeleton_uprising", "field_samples"],
		"min_level": 20,
	},
}

# ── Query helpers ─────────────────────────────────────────────────────────────

static func get_quest(quest_id: String) -> Dictionary:
	return QUEST_DEFS.get(quest_id, {})

static func get_all_ids() -> Array:
	return QUEST_DEFS.keys()

static func get_quests_for_npc(npc_id: String) -> Array:
	var result: Array = []
	for q_id in QUEST_DEFS:
		if QUEST_DEFS[q_id].get("giver_npc_id", "") == npc_id:
			result.append(QUEST_DEFS[q_id])
	return result

# Returns quest ids the player can accept given their completed list and level.
static func get_available_quests(completed: Array, player_level: int) -> Array:
	var result: Array = []
	for q_id in QUEST_DEFS:
		var q: Dictionary = QUEST_DEFS[q_id]
		if q_id in completed:
			continue
		if player_level < q.get("min_level", 1):
			continue
		var prereqs_met := true
		for prereq in q.get("prerequisites", []):
			if not (prereq in completed):
				prereqs_met = false
				break
		if prereqs_met:
			result.append(q)
	return result

# Returns just the objective targets that match a given type (e.g. all "kill" targets).
static func get_objectives_of_type(quest_id: String, obj_type: String) -> Array:
	var q: Dictionary = QUEST_DEFS.get(quest_id, {})
	var result: Array = []
	for obj in q.get("objectives", []):
		if obj.get("type", "") == obj_type:
			result.append(obj)
	return result
