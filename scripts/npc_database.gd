# npc_database.gd
# Chronicles of Midgard - Town NPC definitions (storage clerks, merchants, quest givers, etc.)
# Pure data class — no scene node required. Use static methods to query entries.
class_name NPCDatabase
extends RefCounted

# ── NPC role constants ──────────────────────────────────────────────────────
const ROLE_STORAGE    := "storage_clerk"
const ROLE_MERCHANT   := "merchant"
const ROLE_BLACKSMITH := "blacksmith"
const ROLE_ALCHEMIST  := "alchemist"
const ROLE_GUILD      := "guild_npc"
const ROLE_QUEST      := "quest_giver"
const ROLE_GUARD      := "guard"

# ── Master NPC table ────────────────────────────────────────────────────────
# Each entry:
#   id            String   — matches npc.npc_id @export
#   name          String   — display name shown in dialogue header
#   role          String   — one of the ROLE_* constants above
#   sprite_hint   String   — asset path hint (integrator swaps in real SpriteFrames)
#   wanders       bool     — whether the NPC should use idle wander movement
#   dialogue      Array    — lines shown in order; cycle if interacted repeatedly
#   shop_inventory Array   — item_id strings sold; empty means no shop
#   quest_ids     Array    — quests this NPC can hand out (matched in quest_database.gd)
const NPC_DEFS: Dictionary = {
	"kafra_elena": {
		"id": "kafra_elena",
		"name": "Kafra Elena",
		"role": ROLE_STORAGE,
		"sprite_hint": "res://assets/sprites/npc_kafra.tres",
		"wanders": false,
		"dialogue": [
			"Welcome to Kafra Storage Services! I can hold items safely for you.",
			"Need to store something? I'm here whenever you need me!",
			"Our storage is linked across all Kafra branches. Safe and reliable.",
		],
		"shop_inventory": [],
		"quest_ids": [],
	},
	"merchant_doran": {
		"id": "merchant_doran",
		"name": "Doran the Trader",
		"role": ROLE_MERCHANT,
		"sprite_hint": "res://assets/sprites/npc_merchant.tres",
		"wanders": false,
		"dialogue": [
			"Best prices in Midgard, guaranteed! What can I do for you?",
			"Just got a new shipment in. Take a look!",
			"Buy low, sell high — that's the merchant's creed.",
		],
		"shop_inventory": [
			"health_potion",
			"mana_potion",
			"red_herb",
			"blue_herb",
			"arrow_bundle",
			"empty_bottle",
			"monster_feed",
		],
		"quest_ids": [],
	},
	"blacksmith_krag": {
		"id": "blacksmith_krag",
		"name": "Krag the Smith",
		"role": ROLE_BLACKSMITH,
		"sprite_hint": "res://assets/sprites/npc_blacksmith.tres",
		"wanders": false,
		"dialogue": [
			"You want weapons or armor? Bring me the ore and I'll forge it.",
			"Refinement isn't cheap, but a +7 weapon speaks for itself.",
			"Iron's the backbone of any proper fighter. Don't leave home without good gear.",
		],
		"shop_inventory": [
			"iron_sword",
			"iron_mace",
			"short_bow",
			"iron_buckler",
			"chain_mail",
			"iron_ore",
			"refine_stone",
		],
		"quest_ids": ["forging_supplies", "iron_collection"],
	},
	"alchemist_lia": {
		"id": "alchemist_lia",
		"name": "Lia the Alchemist",
		"role": ROLE_ALCHEMIST,
		"sprite_hint": "res://assets/sprites/npc_alchemist.tres",
		"wanders": false,
		"dialogue": [
			"Potions, elixirs, antidotes — I brew them all.",
			"Slime gel is surprisingly useful as a crafting reagent. Do bring some if you find any.",
			"A well-stocked pouch keeps adventurers alive. Don't scrimp on potions.",
		],
		"shop_inventory": [
			"health_potion",
			"mana_potion",
			"elixir_of_strength",
			"antidote_vial",
			"slime_gel",
			"bone_powder",
		],
		"quest_ids": ["herbalist_request"],
	},
	"guild_master_aldric": {
		"id": "guild_master_aldric",
		"name": "Aldric, Guild Master",
		"role": ROLE_GUILD,
		"sprite_hint": "res://assets/sprites/npc_guild_master.tres",
		"wanders": false,
		"dialogue": [
			"Midgard Adventurers' Guild, at your service. Quests, rankings, party boards — all here.",
			"Guild membership opens doors. Complete quests to raise your rank.",
			"The Guild Board lists bounties from all across Midgard. Take your pick.",
		],
		"shop_inventory": [],
		"quest_ids": ["guild_initiation", "clearing_the_field", "veterans_test"],
	},
	"guard_captain_rena": {
		"id": "guard_captain_rena",
		"name": "Captain Rena",
		"role": ROLE_GUARD,
		"sprite_hint": "res://assets/sprites/npc_guard.tres",
		"wanders": false,
		"dialogue": [
			"Keep the peace and watch for monsters near the gate — that's my job.",
			"Slime activity south of town has been unusually high lately.",
			"If you're heading into the field, watch your back. Goblins raid in groups.",
		],
		"shop_inventory": [],
		"quest_ids": ["first_steps", "goblin_threat"],
	},
	"quest_giver_mira": {
		"id": "quest_giver_mira",
		"name": "Mira the Scholar",
		"role": ROLE_QUEST,
		"sprite_hint": "res://assets/sprites/npc_scholar.tres",
		"wanders": true,
		"dialogue": [
			"I've been researching monster behaviour in the eastern ruins. Fascinating stuff.",
			"The undead congregate around old burial sites. Dangerous, but scientifically invaluable.",
			"Would you help me gather some field samples? I'll make it worth your while.",
		],
		"shop_inventory": [],
		"quest_ids": ["field_samples", "the_ancient_crypt"],
	},
	"innkeeper_boris": {
		"id": "innkeeper_boris",
		"name": "Boris the Innkeeper",
		"role": ROLE_MERCHANT,
		"sprite_hint": "res://assets/sprites/npc_innkeeper.tres",
		"wanders": false,
		"dialogue": [
			"Rest up, traveller! A good night's sleep restores more than just HP.",
			"I hear strange things from adventurers passing through. Midgard never gets dull.",
			"Food and board — simple pleasures for the road-weary soul.",
		],
		"shop_inventory": [
			"cooked_meat",
			"bread_loaf",
			"apple_juice",
		],
		"quest_ids": ["potion_delivery"],
	},
	"merchant_caravan_otto": {
		"id": "merchant_caravan_otto",
		"name": "Otto of the Caravan",
		"role": ROLE_MERCHANT,
		"sprite_hint": "res://assets/sprites/npc_merchant.tres",
		"wanders": true,
		"dialogue": [
			"Just arrived with a fresh caravan from Geffen! Rare goods at fair prices.",
			"The roads are getting dangerous. Monsters everywhere between cities.",
			"Buy now — I move on tomorrow at dawn.",
		],
		"shop_inventory": [
			"magic_scroll",
			"elemental_gem",
			"silver_arrow_bundle",
			"wind_stone",
		],
		"quest_ids": ["lost_merchant"],
	},
}

# ── Query helpers ────────────────────────────────────────────────────────────

static func get_npc(npc_id: String) -> Dictionary:
	return NPC_DEFS.get(npc_id, {})

static func get_all_ids() -> Array:
	return NPC_DEFS.keys()

static func get_npcs_by_role(role: String) -> Array:
	var result: Array = []
	for npc_id in NPC_DEFS:
		if NPC_DEFS[npc_id].get("role", "") == role:
			result.append(NPC_DEFS[npc_id])
	return result

static func get_quest_giver_for_quest(quest_id: String) -> Dictionary:
	for npc_id in NPC_DEFS:
		var entry: Dictionary = NPC_DEFS[npc_id]
		if quest_id in entry.get("quest_ids", []):
			return entry
	return {}

static func has_shop(npc_id: String) -> bool:
	var entry: Dictionary = NPC_DEFS.get(npc_id, {})
	return entry.get("shop_inventory", []).size() > 0
