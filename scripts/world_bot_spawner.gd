# world_bot_spawner.gd
# Chronicles of Midgard - Small decorative bot-crowd helper.
# Call spawn_bots() once from world.gd _ready() on the server.
# Default count is intentionally 10-20 (NOT 65-100 — see ROADMAP.md).
class_name WorldBotSpawner
extends Node

const DEFAULT_BOT_COUNT: int = 14  # Comfortable default; adjust via spawn_bots(count:) param.

# Optional: connect to this signal to display floating chat bubbles in the HUD.
signal bot_chat(bot_name: String, bot_position: Vector2, message: String)

# Bot scene preloaded here. Because bot_player.gd is pure-code (no .tscn),
# we instantiate CharacterBody2D and set the script directly.
const BotPlayerScript = preload("res://scripts/bot_player.gd")

# ── Main entry point ──────────────────────────────────────────────────────────
# parent       : the Node2D that will own the spawned bots (typically the world root).
# count        : number of bots to create (clamped 1-20).
# spawn_points : world-space positions used as initial placement; bots are distributed
#                across them round-robin. If empty, bots are placed at Vector2.ZERO.
# town_bounds  : Rect2 the bots treat as the safe "town" region for idle/chat behaviour.
# field_bounds : Rect2 the bots roam to for cosmetic grinding.
# is_authority : pass true only on the server; false on client mirrors (no AI tick).
func spawn_bots(
	parent: Node,
	count: int = DEFAULT_BOT_COUNT,
	spawn_points: Array = [],
	town_bounds: Rect2 = Rect2(-256.0, -256.0, 512.0, 512.0),
	field_bounds: Rect2 = Rect2(256.0, -512.0, 1024.0, 1024.0),
	is_authority: bool = true
) -> Array:
	count = clampi(count, 1, 20)

	var spawned: Array = []

	for i in count:
		var bot := CharacterBody2D.new()
		bot.set_script(BotPlayerScript)

		# Position: cycle through provided spawn_points; fall back to (0,0) with jitter.
		var base_pos: Vector2
		if spawn_points.size() > 0:
			base_pos = spawn_points[i % spawn_points.size()]
		else:
			base_pos = Vector2.ZERO
		# Small scatter so bots don't stack on the exact same pixel.
		bot.global_position = base_pos + Vector2(randf_range(-32.0, 32.0), randf_range(-32.0, 32.0))

		# Add to tree before calling setup so _ready fires first.
		parent.add_child(bot)

		# setup() configures authority and movement bounds.
		bot.setup(is_authority, town_bounds, field_bounds)

		# Relay chat signals upward so the HUD/world can display speech bubbles.
		bot.chat_said.connect(func(bot_name: String, message: String):
			emit_signal("bot_chat", bot_name, bot.global_position, message)
		)

		spawned.append(bot)

	return spawned

# ── Convenience: despawn all bots spawned under a parent ─────────────────────
func despawn_bots(parent: Node) -> void:
	for child in parent.get_children():
		if child is BotPlayer:
			child.queue_free()

# ── Convenience: update authority flag (e.g. after a server transfer) ─────────
func set_authority_on_all(parent: Node, is_authority: bool) -> void:
	for child in parent.get_children():
		if child is BotPlayer:
			child._is_authority = is_authority
