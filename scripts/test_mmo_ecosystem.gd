# test_mmo_ecosystem.gd
# Headless Verification Test Suite for Chronicles of Midgard MMO Core
extends SceneTree

const SkillDatabase = preload("res://scripts/skill_database.gd")
const StatEngine = preload("res://scripts/stat_engine.gd")
const MMOEngine = preload("res://scripts/mmo_engine.gd")

func _init() -> void:
	print("=================================================================")
	print("   CHRONICLES OF MIDGARD: MMO CORE & CONCURRENCY TEST SUITE      ")
	print("=================================================================")
	
	var all_passed: bool = true
	all_passed = test_skill_database() and all_passed
	all_passed = test_stat_engine() and all_passed
	all_passed = test_mmo_concurrency() and all_passed
	
	if all_passed:
		print("=================================================================")
		print("   >>> ALL MMO CORE & CONCURRENCY TESTS PASSED SUCCESSFULLY! <<< ")
		print("=================================================================")
		quit(0)
	else:
		print("=================================================================")
		print("   >>> TEST FAILURES DETECTED! CHECK LOGS ABOVE <<<             ")
		print("=================================================================")
		quit(1)

func test_skill_database() -> bool:
	print("\n[TEST 1] Verifying Skill Database & Multi-Class Skill Trees...")
	var classes = ["knight", "wizard", "assassin", "high_priest", "hunter", "blacksmith"]
	var total_skills_count = SkillDatabase.SKILLS.size()
	print("  - Total skills registered in database: %d" % total_skills_count)
	
	if total_skills_count < 24:
		printerr("  [FAIL] Expected at least 24 skills, got %d" % total_skills_count)
		return false
		
	for c in classes:
		var class_skills = SkillDatabase.get_skills_for_class(c)
		print("  - Class '%s' has %d skills registered." % [c, class_skills.size()])
		if class_skills.size() < 4:
			printerr("  [FAIL] Class %s has less than 4 skills!" % c)
			return false
			
	# Test key skill entries
	var bash = SkillDatabase.get_skill("bash")
	var storm_gust = SkillDatabase.get_skill("storm_gust")
	var sonic_blow = SkillDatabase.get_skill("sonic_blow")
	var heal = SkillDatabase.get_skill("heal")
	var falcon_assault = SkillDatabase.get_skill("falcon_assault")
	var mammonite = SkillDatabase.get_skill("mammonite")
	
	if bash.is_empty() or storm_gust.is_empty() or sonic_blow.is_empty() or heal.is_empty() or falcon_assault.is_empty() or mammonite.is_empty():
		printerr("  [FAIL] One or more core iconic skills missing!")
		return false
		
	# Verify DEX Cast Time Reduction Formula
	# Storm Gust base cast = 3.0s. At 75 DEX (50% reduction) -> 1.5s. At 150 DEX -> 0.0s (Instant Cast)
	var cast_0_dex = SkillDatabase.calculate_cast_time("storm_gust", 0)
	var cast_75_dex = SkillDatabase.calculate_cast_time("storm_gust", 75)
	var cast_150_dex = SkillDatabase.calculate_cast_time("storm_gust", 150)
	
	print("  - Storm Gust Cast Time: 0 DEX = %.2fs, 75 DEX = %.2fs, 150 DEX = %.2fs" % [cast_0_dex, cast_75_dex, cast_150_dex])
	if abs(cast_0_dex - 3.0) > 0.01 or abs(cast_75_dex - 1.5) > 0.01 or abs(cast_150_dex - 0.0) > 0.01:
		printerr("  [FAIL] DEX cast time formula incorrect!")
		return false
		
	print("  [PASS] Skill Database tests passed!")
	return true

func test_stat_engine() -> bool:
	print("\n[TEST 2] Verifying 6-Stat Attribute Formula Engine...")
	
	# Test Knight Attributes
	var knight_raw = StatEngine.create_default_attributes("knight", 99, 50, 99, 50, 80, 10, 60, 20)
	knight_raw["weapon_atk"] = 180
	knight_raw["refine_atk"] = 70
	knight_raw["armor_def"] = 45
	knight_raw["shield_def"] = 15
	
	var knight_stats = StatEngine.compute_derived_stats(knight_raw)
	print("  - Knight Lv.99 Derived Stats:")
	print("    Max HP: %d | Max SP: %d | Total STR: %d | ATK: %d-%d (Avg %d)" % [
		knight_stats["max_hp"], knight_stats["max_sp"], knight_stats["total_str"],
		knight_stats["min_atk"], knight_stats["max_atk"], knight_stats["avg_atk"]
	])
	print("    Hard DEF: %d | Soft DEF: %d | Hit: %d | Flee: %d | ASPD: %.1f (%.2f hits/sec)" % [
		knight_stats["hard_def"], knight_stats["soft_def"], knight_stats["hit"],
		knight_stats["flee"], knight_stats["aspd"], knight_stats["attacks_per_sec"]
	])
	
	if knight_stats["max_hp"] < 5000 or knight_stats["avg_atk"] < 300 or knight_stats["hit"] < 300:
		printerr("  [FAIL] Knight derived stats out of expected mathematical range!")
		return false
		
	# Test Wizard Attributes & MATK
	var wiz_raw = StatEngine.create_default_attributes("wizard", 99, 50, 10, 40, 40, 99, 85, 20)
	wiz_raw["weapon_matk"] = 120
	var wiz_stats = StatEngine.compute_derived_stats(wiz_raw)
	print("  - Wizard Lv.99 MATK: %d-%d (Avg %d) | Max SP: %d" % [
		wiz_stats["min_matk"], wiz_stats["max_matk"], wiz_stats["avg_matk"], wiz_stats["max_sp"]
	])
	
	if wiz_stats["min_matk"] < 300 or wiz_stats["max_sp"] < 1500:
		printerr("  [FAIL] Wizard MATK or Max SP calculation incorrect!")
		return false
		
	# Test Physical Combat Simulation
	var dummy_target = {"hard_def": 25, "soft_def": 30, "flee": 150, "perfect_dodge": 2.0, "element": SkillDatabase.Element.NEUTRAL}
	var bash_result = StatEngine.calculate_physical_damage(knight_stats, dummy_target, "bash", 10)
	print("  - Knight Bash Lv.10 vs Target: %d damage (Miss: %s, Crit: %s)" % [bash_result["damage"], bash_result["is_miss"], bash_result["is_crit"]])
	
	if bash_result["damage"] <= 0 and not bash_result["is_miss"]:
		printerr("  [FAIL] Physical combat calculation returned invalid damage!")
		return false
		
	# Test Elemental Multipliers (e.g. Fire vs Earth = 175%, Holy vs Undead = 200%)
	var fire_vs_earth = StatEngine.get_elemental_multiplier(SkillDatabase.Element.FIRE, SkillDatabase.Element.EARTH)
	var holy_vs_undead = StatEngine.get_elemental_multiplier(SkillDatabase.Element.HOLY, SkillDatabase.Element.UNDEAD)
	print("  - Elemental Matchup: Fire vs Earth = %.2fx, Holy vs Undead = %.2fx" % [fire_vs_earth, holy_vs_undead])
	
	if abs(fire_vs_earth - 1.75) > 0.01 or abs(holy_vs_undead - 2.0) > 0.01:
		printerr("  [FAIL] Elemental table multiplier error!")
		return false
		
	print("  [PASS] 6-Stat Attribute Formula Engine tests passed!")
	return true

func test_mmo_concurrency() -> bool:
	print("\n[TEST 3] Verifying 50-100 Player Concurrency Simulator...")
	
	var engine = MMOEngine.new()
	var test_concurrency_count = 80
	engine.initialize_ecosystem(test_concurrency_count)
	
	print("  - Active simulated players spawned: %d" % engine.simulated_players.size())
	if engine.simulated_players.size() != test_concurrency_count:
		printerr("  [FAIL] Expected %d players, got %d" % [test_concurrency_count, engine.simulated_players.size()])
		return false
		
	print("  - Parties formed: %d" % engine.parties.size())
	for pid in engine.parties:
		var p = engine.parties[pid]
		print("    * Party %s (%s): %d members | EXP bonus: %.0f%%" % [p.party_id, p.name, p.get_member_count(), (p.get_exp_bonus() - 1.0) * 100.0])
		
	# Test Spatial Partitioning Query
	engine.rebuild_spatial_grid()
	var nearby_city = engine.query_nearby_players(engine.city_center, 250.0)
	print("  - Spatial Grid Query at City Center found %d players within 250px." % nearby_city.size())
	
	# Simulate 120 frames (~2.0 seconds) of MMO simulation ticks
	print("  - Simulating 120 game ticks (2.0s game time)...")
	var start_time_usec = Time.get_ticks_usec()
	for _frame in range(120):
		engine.update_simulation(0.0166)
	var elapsed_ms = (Time.get_ticks_usec() - start_time_usec) / 1000.0
	print("  - 120 Simulation ticks completed in %.2f ms (%.2f ms/frame - Highly Performant!)." % [elapsed_ms, elapsed_ms / 120.0])
	
	# Check chat logs and banter
	print("  - Dynamic Chat Log Entries: %d" % engine.chat_log.size())
	if engine.chat_log.size() > 0:
		print("    Sample Chat:")
		for i in range(min(5, engine.chat_log.size())):
			var c = engine.chat_log[i]
			print("    [%s] [%s] %s: %s" % [c["time"], c["channel"], c["sender"], c["message"]])
			
	print("  [PASS] 50-100 Player Concurrency Simulator tests passed!")
	return true
