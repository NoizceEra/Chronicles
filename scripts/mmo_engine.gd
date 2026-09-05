# mmo_engine.gd
# Chronicles of Midgard - 50-100 Concurrent Player Simulator & MMO Ecosystem Engine
class_name MMOEngine
extends Node2D

const SkillDatabase = preload("res://scripts/skill_database.gd")
const StatEngine = preload("res://scripts/stat_engine.gd")

signal mmo_event_broadcast(event_type: String, message: String, data: Dictionary)
signal party_updated(party_id: String, party_data: Dictionary)
signal mvp_spawned(boss_name: String, position: Vector2)
signal mvp_defeated(boss_name: String, mvp_player_name: String, guild: String)

enum AIState {
	CITY_CHATTING,
	SOLO_GRINDING,
	PARTY_DUNGEON,
	MVP_HUNTING,
	DEAD_RESPAWNING
}

# Configurable constants
const DEFAULT_PLAYER_COUNT: int = 65
const MAX_PLAYER_COUNT: int = 100
const SPATIAL_CELL_SIZE: float = 128.0

const FIRST_NAMES: Array[String] = [
	"Valkyrie", "Shadow", "Grand", "Loki", "Saint", "Sniper", "Katar", "Zeny",
	"Lord", "Frost", "Cart", "Arcane", "Holy", "Iron", "Elven", "Crimson",
	"Silver", "Rune", "Mystic", "Ares", "Diana", "Zero", "Nova", "Vesper",
	"Chrono", "Aegis", "Klaus", "Freya", "Thor", "Odin", "Gwen", "Sora"
]

const LAST_NAMES: Array[String] = [
	"Rose", "Striker", "Templar", "Dagger", "Maiden", "Wolf", "Master", "Merchant",
	"Ares", "Mage", "Drifter", "Sage", "Blade", "Forgemaster", "Marksman", "Theresa",
	"Knight", "Healer", "Sniper", "Hunter", "Cross", "Walker", "Bane", "Heart",
	"Storm", "Gale", "Shadow", "Soul", "Fang", "Seeker", "Shield", "Falcon"
]

const GUILD_NAMES: Array[String] = [
	"[Valhalla]", "[Prontera Knights]", "[Shadow Syndicate]", "[Morroc Assassins]",
	"[Geffen Arcana]", "[Midgard Crusaders]", "[Payon Rangers]", "[Alberta Merchants]",
	"[Einbroch Guild]", "[Niflheim Phantoms]", "[Sanctuary of Light]", "[Odin's Oath]"
]

const HEADGEARS: Array[String] = [
	"Angel Wings", "Majestic Goat", "Crown of Glory", "Elven Ears", "Wizard Hat",
	"Corsair", "Bunny Band", "Pirate Bandana", "Sakkat", "Gossip Raven", "None"
]

const CHAT_BANTER_CITY: Array[String] = [
	"Need Priest for Catacombs dungeon run!",
	"Buying Elunium and Oridecon PM me!",
	"Selling +8 Infiltrator and +7 Gakkung Bow!",
	"Looking for active Guild [Valhalla] rec!",
	"Where does the MVP boss spawn next?",
	"AFK vending in Prontera center ^^",
	"Trading Lv.70 Knight for High Priest gear!",
	"/sit enjoying the fountain vibes~",
	"Congrats to guild for winning Emperium castle!"
]

const CHAT_BANTER_COMBAT: Array[String] = [
	"Tank pull 3 more mobs, I got AOE ready!",
	"Level UP! Stat points into DEX & INT!",
	"Storm Gust freezing the mob pack!",
	"Mammonite smash!! $$$ spent!",
	"Out of Blue Potions, Priest bless please!",
	"Sonic Blow burst is insane!",
	"Sanctuary carpet placed, stay inside!",
	"Falcon auto-blitz procced!",
	"Grand Cross holy light purify them!"
]

const CHAT_BANTER_MVP: Array[String] = [
	"MVP Baphomet is casting Earthquake, dodge!",
	"Taunting MVP, dps go all out!",
	"Healers focus tank! Keep Sanctuary up!",
	"Storm Gust the MVP adds!",
	"Falcon Assault DEF-ignore dpsing!",
	"MVP is at 10% HP! Execute!!"
]

const CHAT_BANTER_DEATH: Array[String] = [
	"Oof, lagged right into the mob train x_x",
	"Resurrection please or running back...",
	"Respawning at Prontera Cathedral!",
	"Don't release, Priest has Yggdrasil Leaf!"
]

# Simulated Player Inner Class
class SimulatedPlayer extends RefCounted:
	var id: String
	var name: String
	var guild: String
	var class_id: String
	var headgear: String
	var weapon_refine: int = 0
	var is_bot: bool = true
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var facing_dir: Vector2 = Vector2.DOWN
	
	var base_level: int = 1
	var job_level: int = 1
	var xp: int = 0
	var xp_to_next: int = 100
	var gold: int = 1000
	
	var raw_attributes: Dictionary = {}
	var stats: Dictionary = {}
	
	var hp: int = 100
	var max_hp: int = 100
	var sp: int = 50
	var max_sp: int = 50
	
	var state: AIState = AIState.SOLO_GRINDING
	var state_timer: float = 0.0
	var target_position: Vector2 = Vector2.ZERO
	var target_entity_id: String = ""
	var party_id: String = ""
	
	var attack_cooldown_timer: float = 0.0
	var skill_cooldown_timer: float = 0.0
	var cast_timer: float = 0.0
	var is_casting: bool = false
	var casting_skill_id: String = ""
	
	# Active Buffs: { "blessing": 240.0, "increase_agi": 240.0, "two_hand_quicken": 180.0, ... }
	var active_buffs: Dictionary = {}
	
	# Overhead Chat Bubble
	var current_chat_text: String = ""
	var chat_bubble_timer: float = 0.0
	var chat_channel: String = "Local"
	
	# Threat / Aggro
	var threat_target_id: String = ""
	var is_alive: bool = true

# Party Structure
class Party extends RefCounted:
	var party_id: String
	var name: String
	var leader_id: String
	var member_ids: Array[String] = []
	var target_zone: String = "Catacombs"
	var exp_share: bool = true
	
	func get_member_count() -> int:
		return member_ids.size()
	
	func get_exp_bonus() -> float:
		# 20% bonus per extra member
		return 1.0 + float(max(0, member_ids.size() - 1)) * 0.20

# Simulated MVP Boss
class MVPBoss extends RefCounted:
	var id: String = "mvp_baphomet"
	var name: String = "Baphomet [MVP]"
	var position: Vector2 = Vector2(1150, 850)
	var hp: int = 15000
	var max_hp: int = 15000
	var base_level: int = 88
	var hard_def: int = 35
	var hard_mdef: int = 40
	var element: int = SkillDatabase.Element.SHADOW
	var is_alive: bool = true
	var aggro_table: Dictionary = {} # player_id -> threat score
	var attack_cooldown: float = 0.0
	var skill_timer: float = 0.0

# MMO Engine State Properties
var simulated_players: Array[SimulatedPlayer] = []
var parties: Dictionary = {} # party_id -> Party
var mvp_boss: MVPBoss = null
var spatial_grid: Dictionary = {} # "cx,cy" -> Array[SimulatedPlayer]
var chat_log: Array[Dictionary] = []
var map_bounds: Rect2 = Rect2(32, 32, 1536, 1216)
var city_center: Vector2 = Vector2(300, 300)
var dungeon_center: Vector2 = Vector2(1150, 850)
var cathedral_pos: Vector2 = Vector2(180, 180)

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	initialize_ecosystem(DEFAULT_PLAYER_COUNT)

# Initialize the 50-100 player simulation
func initialize_ecosystem(player_count: int = 65) -> void:
	simulated_players.clear()
	parties.clear()
	spatial_grid.clear()
	chat_log.clear()
	
	var count = clampi(player_count, 20, MAX_PLAYER_COUNT)
	var class_keys = StatEngine.CLASS_PROFILES.keys()
	
	for i in range(count):
		var player = SimulatedPlayer.new()
		player.id = "player_%03d" % (i + 1)
		var fn = FIRST_NAMES[rng.randi() % FIRST_NAMES.size()]
		var ln = LAST_NAMES[rng.randi() % LAST_NAMES.size()]
		player.name = "%s_%s" % [fn, ln]
		player.guild = GUILD_NAMES[rng.randi() % GUILD_NAMES.size()]
		player.class_id = class_keys[i % class_keys.size()]
		player.headgear = HEADGEARS[rng.randi() % HEADGEARS.size()]
		player.weapon_refine = rng.randi_range(4, 10)
		
		# Generate level (variety of levels: 15 to 95)
		player.base_level = rng.randi_range(25, 95)
		player.job_level = clampi(int(float(player.base_level) * 0.55), 10, 50)
		player.gold = rng.randi_range(5000, 250000)
		
		# Allocate stats according to class archetype
		setup_player_stats(player)
		
		# Initial positioning and behavior distribution
		var state_roll = rng.randf()
		if state_roll < 0.25:
			player.state = AIState.CITY_CHATTING
			player.position = city_center + Vector2(rng.randf_range(-140, 140), rng.randf_range(-140, 140))
		elif state_roll < 0.70:
			player.state = AIState.SOLO_GRINDING
			player.position = Vector2(rng.randf_range(200, 1400), rng.randf_range(200, 1100))
		else:
			player.state = AIState.PARTY_DUNGEON
			player.position = dungeon_center + Vector2(rng.randf_range(-200, 200), rng.randf_range(-200, 200))
			
		player.target_position = player.position
		player.hp = player.max_hp
		player.sp = player.max_sp
		
		simulated_players.append(player)
	
	# Form parties
	form_initial_parties()
	
	# Spawn World MVP Boss
	spawn_world_boss()
	
	broadcast_chat("Server", "Chronicles of Midgard MMO Server initialized with %d simulated adventurers!" % count, "World")

func setup_player_stats(player: SimulatedPlayer) -> void:
	var total_points = player.base_level * 5 + 40
	var p_str = 5
	var p_agi = 5
	var p_vit = 5
	var p_int = 5
	var p_dex = 5
	var p_luk = 5
	
	match player.class_id:
		"knight":
			p_str += int(total_points * 0.45)
			p_vit += int(total_points * 0.35)
			p_dex += int(total_points * 0.15)
			p_agi += int(total_points * 0.05)
		"wizard":
			p_int += int(total_points * 0.55)
			p_dex += int(total_points * 0.35)
			p_vit += int(total_points * 0.10)
		"assassin":
			p_agi += int(total_points * 0.45)
			p_str += int(total_points * 0.30)
			p_luk += int(total_points * 0.15)
			p_dex += int(total_points * 0.10)
		"high_priest":
			p_int += int(total_points * 0.45)
			p_vit += int(total_points * 0.35)
			p_dex += int(total_points * 0.20)
		"hunter":
			p_dex += int(total_points * 0.55)
			p_agi += int(total_points * 0.30)
			p_luk += int(total_points * 0.15)
		"blacksmith":
			p_str += int(total_points * 0.45)
			p_dex += int(total_points * 0.30)
			p_vit += int(total_points * 0.20)
			p_agi += int(total_points * 0.05)
	
	var raw = StatEngine.create_default_attributes(
		player.class_id,
		player.base_level,
		player.job_level,
		p_str, p_agi, p_vit, p_int, p_dex, p_luk
	)
	raw["refine_atk"] = player.weapon_refine * 7
	raw["armor_def"] = 15 + player.weapon_refine * 2
	
	player.raw_attributes = raw
	player.stats = StatEngine.compute_derived_stats(raw)
	player.max_hp = player.stats["max_hp"]
	player.max_sp = player.stats["max_sp"]

func form_initial_parties() -> void:
	var party_index = 1
	var unassigned_dungeon_players: Array[SimulatedPlayer] = []
	for p in simulated_players:
		if p.state == AIState.PARTY_DUNGEON:
			unassigned_dungeon_players.append(p)
			
	while unassigned_dungeon_players.size() >= 3:
		var p_obj = Party.new()
		p_obj.party_id = "party_%02d" % party_index
		p_obj.name = "%s Raid Team %d" % [unassigned_dungeon_players[0].guild, party_index]
		p_obj.leader_id = unassigned_dungeon_players[0].id
		
		# Take 3 to 5 players per party
		var size = min(unassigned_dungeon_players.size(), rng.randi_range(3, 5))
		for _j in range(size):
			var member = unassigned_dungeon_players.pop_front()
			member.party_id = p_obj.party_id
			p_obj.member_ids.append(member.id)
			
		parties[p_obj.party_id] = p_obj
		party_index += 1

func spawn_world_boss() -> void:
	mvp_boss = MVPBoss.new()
	mvp_boss.position = dungeon_center
	emit_signal("mvp_spawned", mvp_boss.name, mvp_boss.position)
	broadcast_chat("MVP Broadcaster", "Warning: [MVP] %s has spawned in the Magma Caverns!" % mvp_boss.name, "World")

# Main simulation tick
func update_simulation(delta: float) -> void:
	# 1. Update Spatial Partitioning Grid
	rebuild_spatial_grid()
	
	# 2. Update all active simulated adventurers
	for player in simulated_players:
		update_player(player, delta)
		
	# 3. Update MVP Boss
	if mvp_boss and mvp_boss.is_alive:
		update_mvp_boss(delta)

# Spatial Partitioning
func rebuild_spatial_grid() -> void:
	spatial_grid.clear()
	for p in simulated_players:
		if not p.is_alive:
			continue
		var cx = int(p.position.x / SPATIAL_CELL_SIZE)
		var cy = int(p.position.y / SPATIAL_CELL_SIZE)
		var key = "%d,%d" % [cx, cy]
		if not spatial_grid.has(key):
			spatial_grid[key] = []
		spatial_grid[key].append(p)

func query_nearby_players(pos: Vector2, radius: float) -> Array[SimulatedPlayer]:
	var result: Array[SimulatedPlayer] = []
	var min_cx = int((pos.x - radius) / SPATIAL_CELL_SIZE)
	var max_cx = int((pos.x + radius) / SPATIAL_CELL_SIZE)
	var min_cy = int((pos.y - radius) / SPATIAL_CELL_SIZE)
	var max_cy = int((pos.y + radius) / SPATIAL_CELL_SIZE)
	var r_sq = radius * radius
	
	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var key = "%d,%d" % [cx, cy]
			if spatial_grid.has(key):
				for other in spatial_grid[key]:
					if pos.distance_squared_to(other.position) <= r_sq:
						result.append(other)
	return result

# Update individual player state and AI
func update_player(player: SimulatedPlayer, delta: float) -> void:
	# Tick timers
	player.state_timer -= delta
	player.attack_cooldown_timer = maxf(0.0, player.attack_cooldown_timer - delta)
	player.skill_cooldown_timer = maxf(0.0, player.skill_cooldown_timer - delta)
	
	if player.chat_bubble_timer > 0.0:
		player.chat_bubble_timer -= delta
		if player.chat_bubble_timer <= 0.0:
			player.current_chat_text = ""
			
	# Update active buffs
	var buff_keys = player.active_buffs.keys()
	for b in buff_keys:
		player.active_buffs[b] -= delta
		if player.active_buffs[b] <= 0.0:
			player.active_buffs.erase(b)
			# Recalculate stats when buff expires
			apply_buff_modifiers(player)
			
	# State Machine Execution
	match player.state:
		AIState.CITY_CHATTING:
			process_city_chatting(player, delta)
		AIState.SOLO_GRINDING:
			process_solo_grinding(player, delta)
		AIState.PARTY_DUNGEON:
			process_party_dungeon(player, delta)
		AIState.MVP_HUNTING:
			process_mvp_hunting(player, delta)
		AIState.DEAD_RESPAWNING:
			process_dead_respawning(player, delta)

func process_city_chatting(player: SimulatedPlayer, delta: float) -> void:
	# Regenerate HP and SP faster when resting in city
	player.hp = mini(player.max_hp, player.hp + int(player.stats["hp_regen"] * delta * 2.0))
	player.sp = mini(player.max_sp, player.sp + int(player.stats["sp_regen"] * delta * 2.0))
	
	# Occasional wandering around town square
	if player.position.distance_to(player.target_position) < 10.0 or player.state_timer <= 0.0:
		player.target_position = city_center + Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120))
		player.state_timer = rng.randf_range(8.0, 18.0)
		
		# Chance to say something in chat
		if rng.randf() < 0.40:
			var banter = CHAT_BANTER_CITY[rng.randi() % CHAT_BANTER_CITY.size()]
			set_player_chat(player, banter, "Local")
			
		# Chance to switch to solo grinding
		if rng.randf() < 0.15:
			player.state = AIState.SOLO_GRINDING
			player.target_position = Vector2(rng.randf_range(400, 1300), rng.randf_range(300, 1000))
			
	move_towards(player, player.target_position, player.stats["move_speed"] * 0.4, delta)

func process_solo_grinding(player: SimulatedPlayer, delta: float) -> void:
	# Natural regen
	player.hp = mini(player.max_hp, player.hp + int(player.stats["hp_regen"] * delta * 0.3))
	player.sp = mini(player.max_sp, player.sp + int(player.stats["sp_regen"] * delta * 0.3))
	
	# Priest / Support AI auto-assisting nearby allies
	if player.class_id == "high_priest":
		handle_healer_ai(player)
		
	# Tank AI holding aggro
	if player.class_id == "knight":
		handle_tank_ai(player)
		
	# Patrol or combat
	if player.position.distance_to(player.target_position) < 20.0 or player.state_timer <= 0.0:
		player.target_position = Vector2(rng.randf_range(200, 1400), rng.randf_range(200, 1100))
		player.state_timer = rng.randf_range(4.0, 10.0)
		
		# Simulated monster combat engagement
		if rng.randf() < 0.60:
			execute_class_combat_action(player)
			
		# Banter chance
		if rng.randf() < 0.12:
			var banter = CHAT_BANTER_COMBAT[rng.randi() % CHAT_BANTER_COMBAT.size()]
			set_player_chat(player, banter, "Party")
			
	move_towards(player, player.target_position, player.stats["move_speed"], delta)

func process_party_dungeon(player: SimulatedPlayer, delta: float) -> void:
	# Priest / Support AI
	if player.class_id == "high_priest":
		handle_healer_ai(player)
	elif player.class_id == "knight":
		handle_tank_ai(player)
		
	# Formations: Follow party leader
	if parties.has(player.party_id):
		var party = parties[player.party_id]
		var leader = get_player_by_id(party.leader_id)
		if leader and leader.id != player.id:
			# Stay in formation offset based on class
			var offset = Vector2.ZERO
			match player.class_id:
				"knight": offset = Vector2(0, -32) # Frontline
				"assassin", "blacksmith": offset = Vector2(32, 0) # Flank
				"hunter", "wizard": offset = Vector2(-32, 32) # Backline
				"high_priest": offset = Vector2(0, 48) # Safe rear
			player.target_position = leader.position + offset
		else:
			# Leader seeks dungeon center or boss
			if player.position.distance_to(player.target_position) < 25.0 or player.state_timer <= 0.0:
				player.target_position = dungeon_center + Vector2(rng.randf_range(-150, 150), rng.randf_range(-150, 150))
				player.state_timer = rng.randf_range(5.0, 12.0)
				
	# Combat engagement in dungeon
	if player.skill_cooldown_timer <= 0.0:
		execute_class_combat_action(player)
		
	move_towards(player, player.target_position, player.stats["move_speed"], delta)

func process_mvp_hunting(player: SimulatedPlayer, delta: float) -> void:
	if not mvp_boss or not mvp_boss.is_alive:
		player.state = AIState.PARTY_DUNGEON
		return
		
	var dist_to_boss = player.position.distance_to(mvp_boss.position)
	var optimal_range = 48.0 if player.class_id in ["knight", "assassin", "blacksmith"] else 180.0
	
	if dist_to_boss > optimal_range:
		move_towards(player, mvp_boss.position, player.stats["move_speed"], delta)
	else:
		# Attack MVP Boss!
		if player.attack_cooldown_timer <= 0.0:
			execute_mvp_attack(player)
			
	# Healer priority
	if player.class_id == "high_priest":
		handle_healer_ai(player)
	elif player.class_id == "knight":
		handle_tank_ai(player, true)

func process_dead_respawning(player: SimulatedPlayer, delta: float) -> void:
	if player.state_timer > 0.0:
		# Waiting in cathedral to recover
		player.hp = mini(player.max_hp, player.hp + int(player.max_hp * delta * 0.35))
		if player.hp >= player.max_hp * 0.8:
			player.is_alive = true
			player.state = AIState.SOLO_GRINDING
			player.target_position = city_center + Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100))
	else:
		# Teleport to cathedral on death
		player.position = cathedral_pos + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
		player.state_timer = 5.0
		var banter = CHAT_BANTER_DEATH[rng.randi() % CHAT_BANTER_DEATH.size()]
		set_player_chat(player, banter, "Party")

# AI Healer logic: Auto heals and buffs nearby wounded allies
func handle_healer_ai(healer: SimulatedPlayer) -> void:
	var nearby = query_nearby_players(healer.position, 240.0)
	var lowest_hp_player: SimulatedPlayer = null
	var lowest_hp_percent: float = 1.0
	
	for ally in nearby:
		if not ally.is_alive:
			continue
		var hp_pct = float(ally.hp) / float(ally.max_hp)
		if hp_pct < lowest_hp_percent:
			lowest_hp_percent = hp_pct
			lowest_hp_player = ally
			
	if lowest_hp_player and lowest_hp_percent < 0.75 and healer.sp >= 25 and healer.skill_cooldown_timer <= 0.0:
		# Cast Heal
		var heal_amount = StatEngine.calculate_heal_amount(healer.stats, 10)
		lowest_hp_player.hp = mini(lowest_hp_player.max_hp, lowest_hp_player.hp + heal_amount)
		healer.sp -= 25
		healer.skill_cooldown_timer = 0.5
		if rng.randf() < 0.25:
			set_player_chat(healer, "Heal -> %s (+%d HP)" % [lowest_hp_player.name, heal_amount], "Party")
		return
		
	# Auto Blessing & Increase AGI
	for ally in nearby:
		if not ally.active_buffs.has("blessing") and healer.sp >= 40 and healer.skill_cooldown_timer <= 0.0:
			ally.active_buffs["blessing"] = 240.0
			healer.sp -= 40
			healer.skill_cooldown_timer = 0.4
			apply_buff_modifiers(ally)
			return
		if not ally.active_buffs.has("increase_agi") and healer.sp >= 30 and healer.skill_cooldown_timer <= 0.0:
			ally.active_buffs["increase_agi"] = 240.0
			healer.sp -= 30
			healer.skill_cooldown_timer = 0.4
			apply_buff_modifiers(ally)
			return

# AI Tank logic: Taunts enemies and holds aggro
func handle_tank_ai(tank: SimulatedPlayer, is_mvp: bool = false) -> void:
	if is_mvp and mvp_boss and mvp_boss.is_alive and tank.skill_cooldown_timer <= 0.0:
		if tank.sp >= 10:
			tank.sp -= 10
			tank.skill_cooldown_timer = 1.5
			# Increase threat on boss aggro table
			var cur_threat = mvp_boss.aggro_table.get(tank.id, 0)
			mvp_boss.aggro_table[tank.id] = cur_threat + 1500
			if rng.randf() < 0.35:
				set_player_chat(tank, "Provoke! Holding MVP aggro!", "Party")

# Apply buffs to raw attributes
func apply_buff_modifiers(player: SimulatedPlayer) -> void:
	player.raw_attributes["bonus_str"] = 10 if player.active_buffs.has("blessing") else 0
	player.raw_attributes["bonus_int"] = 10 if player.active_buffs.has("blessing") else 0
	player.raw_attributes["bonus_dex"] = 10 if player.active_buffs.has("blessing") else 0
	player.raw_attributes["bonus_agi"] = 12 if player.active_buffs.has("increase_agi") else 0
	player.raw_attributes["aspd_buff_percent"] = 30.0 if player.active_buffs.has("two_hand_quicken") or player.active_buffs.has("adrenaline_rush") else 0.0
	
	player.stats = StatEngine.compute_derived_stats(player.raw_attributes)

# Execute signature combat action for player's class
func execute_class_combat_action(player: SimulatedPlayer) -> void:
	player.attack_cooldown_timer = player.stats["attack_delay"]
	player.skill_cooldown_timer = 1.2
	
	# Simulate EXP and Gold reward from grinding
	var exp_gained = rng.randi_range(30, 85)
	if parties.has(player.party_id):
		var p_obj = parties[player.party_id]
		exp_gained = int(exp_gained * p_obj.get_exp_bonus())
		
	player.xp += exp_gained
	player.gold += rng.randi_range(10, 50)
	
	if player.xp >= player.xp_to_next:
		level_up_player(player)

func execute_mvp_attack(player: SimulatedPlayer) -> void:
	player.attack_cooldown_timer = player.stats["attack_delay"]
	
	# Choose skill or normal attack
	var dmg_result: Dictionary = {}
	var skill_used = ""
	
	match player.class_id:
		"knight": skill_used = "bash"
		"wizard": skill_used = "storm_gust"
		"assassin": skill_used = "sonic_blow"
		"high_priest": skill_used = "holy_light"
		"hunter": skill_used = "falcon_assault"
		"blacksmith": skill_used = "mammonite"
		
	if player.class_id == "wizard" or player.class_id == "high_priest":
		dmg_result = StatEngine.calculate_magic_damage(player.stats, {"hard_mdef": mvp_boss.hard_mdef, "soft_mdef": 30, "element": mvp_boss.element}, skill_used, 10)
	else:
		dmg_result = StatEngine.calculate_physical_damage(player.stats, {"hard_def": mvp_boss.hard_def, "soft_def": 40, "element": mvp_boss.element, "perfect_dodge": 5.0, "flee": 140}, skill_used, 10)
		
	var dmg = dmg_result.get("damage", 100)
	mvp_boss.hp = maxi(0, mvp_boss.hp - dmg)
	
	# Record threat
	var cur = mvp_boss.aggro_table.get(player.id, 0)
	mvp_boss.aggro_table[player.id] = cur + dmg
	
	if mvp_boss.hp <= 0 and mvp_boss.is_alive:
		defeat_mvp_boss()

func update_mvp_boss(delta: float) -> void:
	mvp_boss.attack_cooldown = maxf(0.0, mvp_boss.attack_cooldown - delta)
	
	if mvp_boss.attack_cooldown <= 0.0:
		mvp_boss.attack_cooldown = 1.0
		# Find highest threat target
		var highest_threat: int = -1
		var target_player: SimulatedPlayer = null
		
		for pid in mvp_boss.aggro_table:
			var threat = mvp_boss.aggro_table[pid]
			var p = get_player_by_id(pid)
			if p and p.is_alive and threat > highest_threat:
				highest_threat = threat
				target_player = p
				
		if target_player:
			# Boss attacks tank/top threat
			var boss_dmg = rng.randi_range(120, 280)
			# Reduce by player DEF
			var final_dmg = int(boss_dmg * maxf(0.1, (100.0 - target_player.stats["hard_def"]) / 100.0))
			target_player.hp = maxi(0, target_player.hp - final_dmg)
			
			if target_player.hp <= 0:
				target_player.is_alive = false
				target_player.state = AIState.DEAD_RESPAWNING
				mvp_boss.aggro_table.erase(target_player.id)

func defeat_mvp_boss() -> void:
	mvp_boss.is_alive = false
	# Determine MVP (highest threat / damage dealer)
	var max_threat: int = -1
	var mvp_winner: SimulatedPlayer = null
	
	for pid in mvp_boss.aggro_table:
		if mvp_boss.aggro_table[pid] > max_threat:
			max_threat = mvp_boss.aggro_table[pid]
			mvp_winner = get_player_by_id(pid)
			
	var winner_name = mvp_winner.name if mvp_winner else "Unknown Hero"
	var winner_guild = mvp_winner.guild if mvp_winner else "[Solo]"
	
	emit_signal("mvp_defeated", mvp_boss.name, winner_name, winner_guild)
	broadcast_chat("MVP System", "★ MVP! %s has slain %s for %s! [Rare Drops: Baphomet Card, +9 Crescent Scythe] ★" % [winner_name, mvp_boss.name, winner_guild], "World")

func level_up_player(player: SimulatedPlayer) -> void:
	player.base_level = mini(StatEngine.MAX_BASE_LEVEL, player.base_level + 1)
	player.job_level = mini(StatEngine.MAX_JOB_LEVEL, player.job_level + 1)
	player.xp = 0
	player.xp_to_next = int(player.xp_to_next * 1.25)
	
	setup_player_stats(player)
	player.hp = player.max_hp
	player.sp = player.max_sp
	
	if rng.randf() < 0.30:
		set_player_chat(player, "Level UP!! Base Lv.%d / Job Lv.%d!" % [player.base_level, player.job_level], "Party")

func move_towards(player: SimulatedPlayer, target: Vector2, speed: float, delta: float) -> void:
	var diff = target - player.position
	if diff.length() > 4.0:
		var dir = diff.normalized()
		player.facing_dir = dir
		player.position += dir * speed * delta
		player.position.x = clampf(player.position.x, map_bounds.position.x, map_bounds.end.x)
		player.position.y = clampf(player.position.y, map_bounds.position.y, map_bounds.end.y)

func set_player_chat(player: SimulatedPlayer, text: String, channel: String = "Local") -> void:
	player.current_chat_text = text
	player.chat_bubble_timer = 4.5
	player.chat_channel = channel
	broadcast_chat(player.name, text, channel)

func broadcast_chat(sender: String, message: String, channel: String = "Local") -> void:
	var entry = {
		"time": Time.get_time_string_from_system(),
		"sender": sender,
		"message": message,
		"channel": channel
	}
	chat_log.append(entry)
	if chat_log.size() > 100:
		chat_log.pop_front()
	emit_signal("mmo_event_broadcast", "chat", message, entry)

func get_player_by_id(id: String) -> SimulatedPlayer:
	for p in simulated_players:
		if p.id == id:
			return p
	return null
