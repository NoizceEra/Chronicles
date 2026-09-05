# stat_engine.gd
# Chronicles of Midgard - 6-Stat Attribute Formula Engine (Ragnarok Online x Final Fantasy)
class_name StatEngine
extends RefCounted

const SkillDatabase = preload("res://scripts/skill_database.gd")

const MAX_BASE_LEVEL: int = 99
const MAX_JOB_LEVEL: int = 50
const MAX_STAT_VAL: int = 99

# Class-specific stat & growth modifiers
const CLASS_PROFILES: Dictionary = {
	"knight": {
		"name": "Knight",
		"title": "Lord Knight",
		"base_aspd": 145.0,
		"hp_mod": 1.5,
		"sp_mod": 0.6,
		"is_ranged": false,
		"primary_stat": "str",
		"job_bonuses_lv50": {"str": 8, "agi": 2, "vit": 10, "int": 0, "dex": 6, "luk": 4}
	},
	"wizard": {
		"name": "Wizard",
		"title": "High Wizard",
		"base_aspd": 130.0,
		"hp_mod": 0.7,
		"sp_mod": 1.8,
		"is_ranged": false,
		"primary_stat": "int",
		"job_bonuses_lv50": {"str": 1, "agi": 3, "vit": 1, "int": 12, "dex": 10, "luk": 3}
	},
	"assassin": {
		"name": "Assassin",
		"title": "Assassin Cross",
		"base_aspd": 155.0,
		"hp_mod": 1.1,
		"sp_mod": 0.8,
		"is_ranged": false,
		"primary_stat": "agi",
		"job_bonuses_lv50": {"str": 6, "agi": 10, "vit": 2, "int": 0, "dex": 8, "luk": 4}
	},
	"high_priest": {
		"name": "High Priest",
		"title": "Arch-Bishop",
		"base_aspd": 135.0,
		"hp_mod": 0.9,
		"sp_mod": 1.6,
		"is_ranged": false,
		"primary_stat": "int",
		"job_bonuses_lv50": {"str": 2, "agi": 2, "vit": 5, "int": 10, "dex": 8, "luk": 3}
	},
	"hunter": {
		"name": "Hunter",
		"title": "Sniper",
		"base_aspd": 150.0,
		"hp_mod": 0.95,
		"sp_mod": 0.9,
		"is_ranged": true,
		"primary_stat": "dex",
		"job_bonuses_lv50": {"str": 2, "agi": 9, "vit": 2, "int": 2, "dex": 12, "luk": 3}
	},
	"blacksmith": {
		"name": "Blacksmith",
		"title": "Mastersmith",
		"base_aspd": 140.0,
		"hp_mod": 1.25,
		"sp_mod": 0.8,
		"is_ranged": false,
		"primary_stat": "str",
		"job_bonuses_lv50": {"str": 9, "agi": 3, "vit": 6, "int": 2, "dex": 8, "luk": 2}
	}
}

# Element Matchup Matrix: Attacker Element -> Defender Element -> Multiplier
const ELEMENT_TABLE: Dictionary = {
	SkillDatabase.Element.NEUTRAL: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 1.0,
		SkillDatabase.Element.WATER: 1.0,
		SkillDatabase.Element.WIND: 1.0,
		SkillDatabase.Element.EARTH: 1.0,
		SkillDatabase.Element.HOLY: 1.0,
		SkillDatabase.Element.SHADOW: 1.0,
		SkillDatabase.Element.POISON: 1.0,
		SkillDatabase.Element.UNDEAD: 1.0
	},
	SkillDatabase.Element.FIRE: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 0.25,
		SkillDatabase.Element.WATER: 0.50,
		SkillDatabase.Element.WIND: 1.0,
		SkillDatabase.Element.EARTH: 1.75,
		SkillDatabase.Element.HOLY: 1.0,
		SkillDatabase.Element.SHADOW: 1.0,
		SkillDatabase.Element.POISON: 1.0,
		SkillDatabase.Element.UNDEAD: 1.50
	},
	SkillDatabase.Element.WATER: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 1.75,
		SkillDatabase.Element.WATER: 0.25,
		SkillDatabase.Element.WIND: 0.50,
		SkillDatabase.Element.EARTH: 1.0,
		SkillDatabase.Element.HOLY: 1.0,
		SkillDatabase.Element.SHADOW: 1.0,
		SkillDatabase.Element.POISON: 1.0,
		SkillDatabase.Element.UNDEAD: 1.0
	},
	SkillDatabase.Element.WIND: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 1.0,
		SkillDatabase.Element.WATER: 1.75,
		SkillDatabase.Element.WIND: 0.25,
		SkillDatabase.Element.EARTH: 0.50,
		SkillDatabase.Element.HOLY: 1.0,
		SkillDatabase.Element.SHADOW: 1.0,
		SkillDatabase.Element.POISON: 1.0,
		SkillDatabase.Element.UNDEAD: 1.0
	},
	SkillDatabase.Element.EARTH: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 0.50,
		SkillDatabase.Element.WATER: 1.0,
		SkillDatabase.Element.WIND: 1.75,
		SkillDatabase.Element.EARTH: 0.25,
		SkillDatabase.Element.HOLY: 1.0,
		SkillDatabase.Element.SHADOW: 1.0,
		SkillDatabase.Element.POISON: 1.25,
		SkillDatabase.Element.UNDEAD: 1.0
	},
	SkillDatabase.Element.HOLY: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 1.0,
		SkillDatabase.Element.WATER: 1.0,
		SkillDatabase.Element.WIND: 1.0,
		SkillDatabase.Element.EARTH: 1.0,
		SkillDatabase.Element.HOLY: 0.0,
		SkillDatabase.Element.SHADOW: 1.75,
		SkillDatabase.Element.POISON: 1.0,
		SkillDatabase.Element.UNDEAD: 2.0
	},
	SkillDatabase.Element.SHADOW: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 1.0,
		SkillDatabase.Element.WATER: 1.0,
		SkillDatabase.Element.WIND: 1.0,
		SkillDatabase.Element.EARTH: 1.0,
		SkillDatabase.Element.HOLY: 1.75,
		SkillDatabase.Element.SHADOW: 0.0,
		SkillDatabase.Element.POISON: 0.5,
		SkillDatabase.Element.UNDEAD: 0.0
	},
	SkillDatabase.Element.POISON: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 1.0,
		SkillDatabase.Element.WATER: 1.0,
		SkillDatabase.Element.WIND: 1.0,
		SkillDatabase.Element.EARTH: 1.0,
		SkillDatabase.Element.HOLY: 0.75,
		SkillDatabase.Element.SHADOW: 0.75,
		SkillDatabase.Element.POISON: 0.0,
		SkillDatabase.Element.UNDEAD: 0.5
	},
	SkillDatabase.Element.UNDEAD: {
		SkillDatabase.Element.NEUTRAL: 1.0,
		SkillDatabase.Element.FIRE: 0.5,
		SkillDatabase.Element.WATER: 1.0,
		SkillDatabase.Element.WIND: 1.0,
		SkillDatabase.Element.EARTH: 1.0,
		SkillDatabase.Element.HOLY: 0.0,
		SkillDatabase.Element.SHADOW: 0.0,
		SkillDatabase.Element.POISON: 0.0,
		SkillDatabase.Element.UNDEAD: 0.0
	}
}

# Create a default raw character attribute dict
static func create_default_attributes(
	class_id: String = "knight",
	base_level: int = 1,
	job_level: int = 1,
	p_str: int = 1,
	p_agi: int = 1,
	p_vit: int = 1,
	p_int: int = 1,
	p_dex: int = 1,
	p_luk: int = 1
) -> Dictionary:
	return {
		"class_id": class_id,
		"base_level": clampi(base_level, 1, MAX_BASE_LEVEL),
		"job_level": clampi(job_level, 1, MAX_JOB_LEVEL),
		"str": clampi(p_str, 1, MAX_STAT_VAL),
		"agi": clampi(p_agi, 1, MAX_STAT_VAL),
		"vit": clampi(p_vit, 1, MAX_STAT_VAL),
		"int": clampi(p_int, 1, MAX_STAT_VAL),
		"dex": clampi(p_dex, 1, MAX_STAT_VAL),
		"luk": clampi(p_luk, 1, MAX_STAT_VAL),
		# Bonus points & buffs
		"bonus_str": 0,
		"bonus_agi": 0,
		"bonus_vit": 0,
		"bonus_int": 0,
		"bonus_dex": 0,
		"bonus_luk": 0,
		# Gear equipment
		"weapon_atk": 25,
		"weapon_matk": 10,
		"refine_atk": 0,
		"armor_def": 10,
		"shield_def": 5,
		"gear_mdef": 5,
		"bonus_hit": 0,
		"bonus_flee": 0,
		"bonus_crit": 0,
		"aspd_buff_percent": 0.0,
		"cast_reduc_percent": 0.0,
		"element": SkillDatabase.Element.NEUTRAL
	}

# Compute all derived attributes
static func compute_derived_stats(attr: Dictionary) -> Dictionary:
	var class_id: String = attr.get("class_id", "knight")
	var profile: Dictionary = CLASS_PROFILES.get(class_id, CLASS_PROFILES["knight"])
	
	var base_lv: int = attr.get("base_level", 1)
	var job_lv: int = attr.get("job_level", 1)
	
	# Job stat bonuses scaled by Job Level (1 to 50)
	var job_bonus_ratio: float = float(job_lv) / float(MAX_JOB_LEVEL)
	var job_bonuses = profile.get("job_bonuses_lv50", {})
	
	var total_str: int = attr.get("str", 1) + attr.get("bonus_str", 0) + int(job_bonuses.get("str", 0) * job_bonus_ratio)
	var total_agi: int = attr.get("agi", 1) + attr.get("bonus_agi", 0) + int(job_bonuses.get("agi", 0) * job_bonus_ratio)
	var total_vit: int = attr.get("vit", 1) + attr.get("bonus_vit", 0) + int(job_bonuses.get("vit", 0) * job_bonus_ratio)
	var total_int: int = attr.get("int", 1) + attr.get("bonus_int", 0) + int(job_bonuses.get("int", 0) * job_bonus_ratio)
	var total_dex: int = attr.get("dex", 1) + attr.get("bonus_dex", 0) + int(job_bonuses.get("dex", 0) * job_bonus_ratio)
	var total_luk: int = attr.get("luk", 1) + attr.get("bonus_luk", 0) + int(job_bonuses.get("luk", 0) * job_bonus_ratio)
	
	# 1. Max HP
	var hp_mod: float = profile.get("hp_mod", 1.0)
	var base_hp: float = 60.0 + (float(base_lv) * hp_mod * 22.0)
	var max_hp: int = int(floor(base_hp * (1.0 + float(total_vit) * 0.01)))
	
	# 2. Max SP / MP
	var sp_mod: float = profile.get("sp_mod", 1.0)
	var base_sp: float = 15.0 + (float(base_lv) * sp_mod * 8.0)
	var max_sp: int = int(floor(base_sp * (1.0 + float(total_int) * 0.01)))
	
	# 3. Status ATK (Melee vs Ranged)
	var is_ranged: bool = profile.get("is_ranged", false)
	var status_atk: int = 0
	if is_ranged:
		status_atk = total_dex + int(pow(total_dex / 10.0, 2)) + int(total_str / 5.0) + int(total_luk / 5.0)
	else:
		status_atk = total_str + int(pow(total_str / 10.0, 2)) + int(total_dex / 5.0) + int(total_luk / 5.0)
		
	var weapon_atk: int = attr.get("weapon_atk", 0)
	var refine_atk: int = attr.get("refine_atk", 0)
	var min_atk: int = status_atk + int(weapon_atk * 0.8) + refine_atk
	var max_atk: int = status_atk + int(weapon_atk * 1.2) + refine_atk
	var avg_atk: int = (min_atk + max_atk) / 2
	
	# 4. MATK (Magic Attack)
	var weapon_matk: int = attr.get("weapon_matk", 0)
	var min_matk: int = total_int + int(pow(total_int / 7.0, 2)) + weapon_matk
	var max_matk: int = total_int + int(pow(total_int / 5.0, 2)) + weapon_matk
	var avg_matk: int = (min_matk + max_matk) / 2
	
	# 5. Hit Rate (Accuracy)
	var hit: int = 175 + base_lv + total_dex + int(total_luk / 5.0) + attr.get("bonus_hit", 0)
	
	# 6. Flee Rate (Dodge)
	var flee: int = 100 + base_lv + total_agi + int(total_luk / 5.0) + attr.get("bonus_flee", 0)
	var perfect_dodge: float = 1.0 + (float(total_luk) * 0.1)
	
	# 7. Critical Rate
	var crit_rate: float = 1.0 + (float(total_luk) * 0.3) + float(attr.get("bonus_crit", 0))
	
	# 8. ASPD (Attack Speed) & Attacks/Sec
	var base_aspd: float = profile.get("base_aspd", 140.0)
	var aspd_buff: float = attr.get("aspd_buff_percent", 0.0)
	var aspd: float = 200.0 - (200.0 - base_aspd) * (1.0 - (total_agi * 4.0 + total_dex) / 1000.0) * (1.0 - aspd_buff / 100.0)
	aspd = clampf(aspd, 100.0, 195.0)
	var attacks_per_sec: float = 50.0 / maxf(1.0, 200.0 - aspd)
	var attack_delay: float = 1.0 / attacks_per_sec
	
	# 9. DEF (Hard & Soft)
	var hard_def: int = attr.get("armor_def", 0) + attr.get("shield_def", 0)
	var soft_def: int = int(total_vit * 0.8) + int(base_lv / 20.0)
	
	# 10. MDEF (Hard & Soft)
	var hard_mdef: int = attr.get("gear_mdef", 0)
	var soft_mdef: int = total_int + int(total_vit / 2.0)
	
	# 11. HP / SP Natural Regeneration per 6 seconds
	var hp_regen_per_tick: int = max(1, int(max_hp * 0.02) + int(total_vit / 5.0))
	var sp_regen_per_tick: int = max(1, int(max_sp * 0.02) + int(total_int / 6.0) + 1)
	
	# 12. Move Speed Factor
	var move_speed: float = 110.0 + (float(total_agi) * 0.4)
	
	# 13. Weight Limit
	var weight_limit: int = 2000 + (total_str * 30)
	
	return {
		"class_id": class_id,
		"base_level": base_lv,
		"job_level": job_lv,
		"total_str": total_str,
		"total_agi": total_agi,
		"total_vit": total_vit,
		"total_int": total_int,
		"total_dex": total_dex,
		"total_luk": total_luk,
		"max_hp": max_hp,
		"max_sp": max_sp,
		"min_atk": min_atk,
		"max_atk": max_atk,
		"avg_atk": avg_atk,
		"min_matk": min_matk,
		"max_matk": max_matk,
		"avg_matk": avg_matk,
		"hit": hit,
		"flee": flee,
		"perfect_dodge": perfect_dodge,
		"crit_rate": crit_rate,
		"aspd": aspd,
		"attacks_per_sec": attacks_per_sec,
		"attack_delay": attack_delay,
		"hard_def": hard_def,
		"soft_def": soft_def,
		"hard_mdef": hard_mdef,
		"soft_mdef": soft_mdef,
		"hp_regen": hp_regen_per_tick,
		"sp_regen": sp_regen_per_tick,
		"move_speed": move_speed,
		"weight_limit": weight_limit,
		"element": attr.get("element", SkillDatabase.Element.NEUTRAL)
	}

# Calculate elemental damage multiplier
static func get_elemental_multiplier(atk_elem: int, def_elem: int) -> float:
	if ELEMENT_TABLE.has(atk_elem):
		var sub = ELEMENT_TABLE[atk_elem]
		if sub.has(def_elem):
			return sub[def_elem]
	return 1.0

# Calculate physical combat damage
static func calculate_physical_damage(
	attacker: Dictionary,
	defender: Dictionary,
	skill_id: String = "",
	skill_level: int = 1,
	is_crit: bool = false
) -> Dictionary:
	var hit_chance: float = 1.0
	var is_miss: bool = false
	
	# Check for perfect dodge first
	var defender_pdodge: float = defender.get("perfect_dodge", 1.0)
	if randf() * 100.0 < defender_pdodge and not is_crit:
		return {"damage": 0, "is_miss": true, "is_crit": false, "is_perfect_dodge": true, "hits": 1}
	
	# Check standard Hit vs Flee if not a critical hit
	if not is_crit:
		var atk_hit = attacker.get("hit", 175)
		var def_flee = defender.get("flee", 100)
		# Classic RO Hit formula: 80 + (Hit - Flee), clamped 5% to 95%
		var rate = clampf(80.0 + (float(atk_hit) - float(def_flee)), 5.0, 95.0)
		hit_chance = rate / 100.0
		if randf() > hit_chance:
			is_miss = true
			return {"damage": 0, "is_miss": true, "is_crit": false, "is_perfect_dodge": false, "hits": 1}
	
	# Check for random crit proc if not explicitly given
	if not is_crit and skill_id == "":
		var crit_chance = attacker.get("crit_rate", 1.0)
		if randf() * 100.0 < crit_chance:
			is_crit = true
	
	# Calculate base raw attack roll
	var min_a = attacker.get("min_atk", 20)
	var max_a = attacker.get("max_atk", 30)
	var raw_atk = randi_range(min_a, max_a)
	
	var multiplier: float = 1.0
	var hits: int = 1
	var elem: int = SkillDatabase.Element.NEUTRAL
	
	if skill_id != "":
		var s_data = SkillDatabase.get_skill(skill_id)
		if not s_data.is_empty():
			multiplier = SkillDatabase.get_multiplier(skill_id, skill_level)
			elem = s_data.get("element", SkillDatabase.Element.NEUTRAL)
			var h_info = s_data.get("hits", 1)
			if typeof(h_info) == TYPE_ARRAY:
				var idx = clampi(skill_level - 1, 0, h_info.size() - 1)
				hits = h_info[idx]
			else:
				hits = int(h_info)
	
	var damage_before_def: float = float(raw_atk) * multiplier
	
	# Element matchup
	var def_elem: int = defender.get("element", SkillDatabase.Element.NEUTRAL)
	var elem_mult: float = get_elemental_multiplier(elem, def_elem)
	damage_before_def *= elem_mult
	
	# DEF Reduction:
	# Critical hits bypass Hard DEF and Soft DEF!
	var final_damage: int = 0
	if is_crit:
		# Crits deal 1.4x true damage ignoring DEF
		final_damage = int(ceil(damage_before_def * 1.4))
	else:
		var hard_def: float = float(defender.get("hard_def", 0))
		var soft_def: float = float(defender.get("soft_def", 0))
		# Hard DEF % reduction: (100 - HardDEF) / 100
		var hard_def_mod: float = maxf(0.05, (100.0 - hard_def) / 100.0)
		var reduced: float = (damage_before_def * hard_def_mod) - soft_def
		final_damage = int(maxf(1.0, reduced))
	
	return {
		"damage": final_damage,
		"is_miss": false,
		"is_crit": is_crit,
		"is_perfect_dodge": false,
		"hits": hits,
		"element": elem
	}

# Calculate magical combat damage
static func calculate_magic_damage(
	attacker: Dictionary,
	defender: Dictionary,
	skill_id: String,
	skill_level: int = 1
) -> Dictionary:
	var s_data = SkillDatabase.get_skill(skill_id)
	var elem: int = s_data.get("element", SkillDatabase.Element.NEUTRAL) if not s_data.is_empty() else SkillDatabase.Element.NEUTRAL
	var multiplier: float = SkillDatabase.get_multiplier(skill_id, skill_level)
	
	var hits: int = 1
	if not s_data.is_empty():
		var h_info = s_data.get("hits", 1)
		if typeof(h_info) == TYPE_ARRAY:
			var idx = clampi(skill_level - 1, 0, h_info.size() - 1)
			hits = h_info[idx]
		else:
			hits = int(h_info)
	
	var min_m = attacker.get("min_matk", 30)
	var max_m = attacker.get("max_matk", 45)
	var raw_matk = randi_range(min_m, max_m)
	
	var base_dmg = float(raw_matk) * multiplier
	
	# Elemental Multiplier
	var def_elem: int = defender.get("element", SkillDatabase.Element.NEUTRAL)
	var elem_mult = get_elemental_multiplier(elem, def_elem)
	base_dmg *= elem_mult
	
	# MDEF Reduction
	var hard_mdef: float = float(defender.get("hard_mdef", 0))
	var soft_mdef: float = float(defender.get("soft_mdef", 0))
	
	var hard_mod = maxf(0.05, (100.0 - hard_mdef) / 100.0)
	var reduced = (base_dmg * hard_mod) - soft_mdef
	var final_damage = int(maxf(1.0, reduced))
	
	return {
		"damage": final_damage,
		"is_miss": false,
		"is_crit": false,
		"hits": hits,
		"element": elem
	}

# Calculate heal output amount
static func calculate_heal_amount(healer: Dictionary, skill_level: int = 10) -> int:
	var base_lv = healer.get("base_level", 1)
	var int_stat = healer.get("total_int", 1)
	# RO Formula: floor((BaseLv + INT) / 8) * (SkillLv * 8 + 4)
	var factor = int(floor(float(base_lv + int_stat) / 8.0))
	var heal_val = factor * (skill_level * 10)
	return int(maxf(50.0, float(heal_val)))
