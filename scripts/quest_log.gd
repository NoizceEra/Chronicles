# quest_log.gd
# Chronicles of Midgard - Per-player quest tracking component.
# Attach as a child of the player node. Call setup() with a starting level reference.
# world.gd / enemy.gd integration: call report_kill() and report_item_collected()
# from enemy die() and pickup _on_body_entered() hooks respectively.
class_name QuestLog
extends Node

signal quest_accepted(quest_id: String, quest_data: Dictionary)
signal quest_progress_updated(quest_id: String, objective_idx: int, current: int, required: int)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_abandoned(quest_id: String)

# ── State ────────────────────────────────────────────────────────────────────
# active_quests: { quest_id -> { "data": quest_def_dict, "progress": [int, ...] } }
var active_quests: Dictionary = {}
# completed_quests: list of quest ids that have been finished
var completed_quests: Array = []
# player level ref — set via setup(), used for accept validation
var _player_level: int = 1

# ── Lifecycle ────────────────────────────────────────────────────────────────

func setup(player_level: int) -> void:
	_player_level = player_level

# Called from player.gd when the player levels up so availability can be rechecked.
func notify_level_change(new_level: int) -> void:
	_player_level = new_level

# ── Accept / Abandon ─────────────────────────────────────────────────────────

func accept_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id):
		push_warning("QuestLog: quest '%s' is already active." % quest_id)
		return false
	if quest_id in completed_quests:
		push_warning("QuestLog: quest '%s' already completed." % quest_id)
		return false

	var quest_data: Dictionary = QuestDatabase.get_quest(quest_id)
	if quest_data.is_empty():
		push_error("QuestLog: unknown quest id '%s'." % quest_id)
		return false

	if _player_level < quest_data.get("min_level", 1):
		push_warning("QuestLog: player level %d too low for quest '%s' (min %d)." % [
			_player_level, quest_id, quest_data.get("min_level", 1)])
		return false

	# Verify prerequisites
	for prereq in quest_data.get("prerequisites", []):
		if not (prereq in completed_quests):
			push_warning("QuestLog: prerequisite '%s' not met for quest '%s'." % [prereq, quest_id])
			return false

	# Build zero-progress array (one counter per objective)
	var objectives: Array = quest_data.get("objectives", [])
	var progress: Array = []
	for _i in objectives.size():
		progress.append(0)

	active_quests[quest_id] = {"data": quest_data, "progress": progress}
	emit_signal("quest_accepted", quest_id, quest_data)
	return true

func abandon_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		active_quests.erase(quest_id)
		emit_signal("quest_abandoned", quest_id)

# ── Progress reporting ────────────────────────────────────────────────────────

# Call from enemy.gd die() or an enemy-death signal handler.
func report_kill(enemy_type: String) -> void:
	_tick_objectives(QuestDatabase.OBJ_KILL, enemy_type, 1)

# Call from pickup.gd / inventory when an item is picked up.
func report_item_collected(item_id: String, qty: int = 1) -> void:
	_tick_objectives(QuestDatabase.OBJ_COLLECT, item_id, qty)
	_tick_objectives(QuestDatabase.OBJ_DELIVER, item_id, qty)

# Call from world.gd trigger zones (Area2D body_entered connecting to this method).
func report_reach(location_tag: String) -> void:
	_tick_objectives(QuestDatabase.OBJ_REACH, location_tag, 1)

# ── Internal tick ─────────────────────────────────────────────────────────────

func _tick_objectives(obj_type: String, target: String, amount: int) -> void:
	# Iterate over all active quests; check each objective
	for quest_id in active_quests.keys():
		var entry: Dictionary = active_quests[quest_id]
		var quest_data: Dictionary = entry["data"]
		var progress: Array = entry["progress"]
		var objectives: Array = quest_data.get("objectives", [])
		var all_complete := true

		for i in objectives.size():
			var obj: Dictionary = objectives[i]
			if obj.get("type", "") != obj_type:
				# Not the matching type; check if this objective is already done for completion test
				if progress[i] < obj.get("count", 1):
					all_complete = false
				continue

			if obj.get("target", "") != target:
				if progress[i] < obj.get("count", 1):
					all_complete = false
				continue

			var required: int = obj.get("count", 1)
			if progress[i] < required:
				progress[i] = mini(progress[i] + amount, required)
				emit_signal("quest_progress_updated", quest_id, i, progress[i], required)

			if progress[i] < required:
				all_complete = false

		if all_complete:
			_complete_quest(quest_id)
			# Break since the dict may have changed (quest removed); re-entry on next call is safe.
			break

func _complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var entry: Dictionary = active_quests[quest_id]
	var rewards: Dictionary = entry["data"].get("rewards", {})
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	emit_signal("quest_completed", quest_id, rewards)

# ── Query helpers ─────────────────────────────────────────────────────────────

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

# Returns current progress for a specific objective index (0-based).
func get_objective_progress(quest_id: String, objective_idx: int) -> int:
	if not active_quests.has(quest_id):
		return 0
	var progress: Array = active_quests[quest_id].get("progress", [])
	if objective_idx >= progress.size():
		return 0
	return progress[objective_idx]

# Returns a summary array of {objective, current, required} dicts for HUD display.
func get_active_objectives(quest_id: String) -> Array:
	if not active_quests.has(quest_id):
		return []
	var entry: Dictionary = active_quests[quest_id]
	var objectives: Array = entry["data"].get("objectives", [])
	var progress: Array = entry["progress"]
	var result: Array = []
	for i in objectives.size():
		result.append({
			"objective": objectives[i],
			"current": progress[i] if i < progress.size() else 0,
			"required": objectives[i].get("count", 1),
		})
	return result

# Returns quests from the database this NPC can give that the player hasn't accepted or finished.
func get_available_from_npc(npc_id: String) -> Array:
	var npc_data: Dictionary = NPCDatabase.get_npc(npc_id)
	var npc_quest_ids: Array = npc_data.get("quest_ids", [])
	var result: Array = []
	for q_id in npc_quest_ids:
		if is_quest_active(q_id) or is_quest_completed(q_id):
			continue
		var q_data: Dictionary = QuestDatabase.get_quest(q_id)
		if q_data.is_empty():
			continue
		if _player_level < q_data.get("min_level", 1):
			continue
		var prereqs_met := true
		for prereq in q_data.get("prerequisites", []):
			if not is_quest_completed(prereq):
				prereqs_met = false
				break
		if prereqs_met:
			result.append(q_data)
	return result

# Serialise to a dict for save/load integration.
func to_save_dict() -> Dictionary:
	var active_serialised: Dictionary = {}
	for q_id in active_quests:
		active_serialised[q_id] = active_quests[q_id]["progress"].duplicate()
	return {
		"active": active_serialised,
		"completed": completed_quests.duplicate(),
	}

# Restore from a save dict produced by to_save_dict().
func from_save_dict(save: Dictionary) -> void:
	completed_quests = save.get("completed", []).duplicate()
	active_quests.clear()
	var active_saved: Dictionary = save.get("active", {})
	for q_id in active_saved:
		var q_data: Dictionary = QuestDatabase.get_quest(q_id)
		if q_data.is_empty():
			continue
		active_quests[q_id] = {
			"data": q_data,
			"progress": active_saved[q_id].duplicate(),
		}
