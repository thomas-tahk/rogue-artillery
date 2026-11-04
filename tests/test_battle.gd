extends "res://tests/test_case.gd"

const BATTLE_SCENE := "res://src/scenes/battle.tscn"

var _ended := false
var _player_won := false


func _battle(seed_value: int, autoplay: bool) -> Battle:
	var battle: Battle = load(BATTLE_SCENE).instantiate()
	battle.battle_seed = seed_value
	battle.player_is_ai = autoplay
	add_child(battle)
	return battle


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _on_ended(player_won: bool) -> void:
	_ended = true
	_player_won = player_won


## Asserts only that a battle ends: who wins is not guaranteed, because both sides aim with random error.
func test_autoplay_battle_ends_within_40_turns():
	_ended = false
	var battle := _battle(7, true)
	battle.battle_ended.connect(_on_ended)
	Engine.time_scale = 8.0
	var frames := 0
	while not _ended and battle.turn_count <= 40 and frames < 20000:
		await get_tree().physics_frame
		frames += 1
	Engine.time_scale = 1.0
	check(_ended, "battle_ended emitted (turns=%d, frames=%d)" % [battle.turn_count, frames])
	check(battle.turn_count <= 40, "ended within 40 turns, got %d" % battle.turn_count)
	battle.queue_free()


func test_explosion_next_to_tank_damages_and_carves():
	var battle := _battle(11, false)
	await _frames(5)
	var blast: Vector2 = battle.enemy.global_position + Vector2(-28, 0)
	var expected := roundi(50.0 * (1.0 - 28.0 / 56.0))
	var ground := Vector2(blast.x, battle.terrain.surface_y(blast.x) + 8.0)
	check(battle.terrain.is_solid(ground), "ground solid before blast")
	battle.resolve_explosion(blast)
	check_eq(battle.enemy.hp, 100 - expected, "enemy hp lowered per formula")
	check_eq(battle.player.hp, 100, "far player untouched")
	check(not battle.terrain.is_solid(ground), "crater carved")
	battle.queue_free()


func test_direct_hit_deals_50():
	var battle := _battle(11, false)
	await _frames(5)
	battle.resolve_explosion(battle.enemy.global_position)
	check_eq(battle.enemy.hp, 50, "direct hit")
	battle.queue_free()


func test_tank_without_ground_falls_out_and_dies():
	var battle := _battle(13, false)
	await _frames(5)
	var pos: Vector2 = battle.enemy.global_position
	battle.terrain.destroy_circle(Vector2(pos.x, 640.0), 400.0)
	await _frames(240)
	check(battle.enemy.is_dead(), "tank fell below the world and died")
	battle.queue_free()


func test_restart_produces_different_terrain():
	var battle := _battle(21, false)
	await _frames(5)
	var before := _profile(battle.terrain)
	battle.restart()
	await _frames(5)
	check(before != _profile(battle.terrain), "terrain differs after restart")
	check_eq(battle.player.hp, 100, "fresh player hp")
	battle.queue_free()


func _profile(terrain: Terrain) -> Array[float]:
	var out: Array[float] = []
	for x in range(0, 1600, 80):
		out.append(terrain.surface_y(float(x)))
	return out


func _started(battle: Battle) -> void:
	var guard := 0
	while battle.turn_count == 0 and guard < 300:
		await get_tree().physics_frame
		guard += 1


func _key(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode as Key
	event.pressed = true
	return event


func _shells(battle: Battle) -> Array[Projectile]:
	var found: Array[Projectile] = []
	for child in battle.get_children():
		if child is Projectile:
			found.append(child)
	return found


func test_both_dead_counts_as_loss():
	_ended = false
	var battle := _battle(5, false)
	battle.battle_ended.connect(_on_ended)
	await _started(battle)
	battle.player.take_damage(100)
	battle.enemy.take_damage(100)
	await _frames(3)
	check(_ended, "battle ended")
	check(not _player_won, "both dead is a loss")
	battle.queue_free()


func test_battle_ended_emits_once_and_enemy_does_not_fire_after_over():
	var emitted := [0]
	var battle := _battle(5, true)  # autoplay: first turn is a THINK phase
	battle.battle_ended.connect(func(_won: bool) -> void: emitted[0] += 1)
	await _started(battle)
	battle._timer = 0.0
	battle.enemy.take_damage(100)
	await _frames(30)
	check_eq(emitted[0], 1, "battle_ended emitted once")
	check_eq(_shells(battle).size(), 0, "no shell fired once the battle was over")
	battle.queue_free()


func test_no_input_outside_aim_phase():
	var battle := _battle(5, true)  # THINK phase, input must be ignored
	await _started(battle)
	var aim_before := battle.player.aim_deg
	battle._unhandled_input(_key(KEY_SPACE))
	battle._unhandled_input(_key(KEY_UP))
	check_eq(_shells(battle).size(), 0, "space ignored while the AI thinks")
	check_eq(battle.player.aim_deg, aim_before, "aim keys ignored while the AI thinks")
	battle.queue_free()


func test_space_and_aim_ignored_while_shell_flies():
	var battle := _battle(5, false)
	await _started(battle)
	battle._unhandled_input(_key(KEY_SPACE))
	await _frames(2)
	var aim_before := battle.player.aim_deg
	battle._unhandled_input(_key(KEY_SPACE))
	battle._unhandled_input(_key(KEY_UP))
	check_eq(_shells(battle).size(), 1, "second space ignored while a shell flies")
	check_eq(battle.player.aim_deg, aim_before, "aim ignored while a shell flies")
	battle.queue_free()


func test_shell_does_not_land_in_shooters_own_box():
	var battle := _battle(5, false)
	await _started(battle)
	battle.player.adjust_aim(45.0)  # straight up: the shell stays over its own tank's box for a while
	battle._unhandled_input(_key(KEY_SPACE))
	await _frames(3)
	check_eq(_shells(battle).size(), 1, "shell still flying after its first frames")
	check_eq(battle.player.hp, 100, "shooter not hit by its own shell")
	battle.queue_free()


func test_restart_before_landing_leaves_new_battle_untouched():
	var battle := _battle(5, false)
	await _started(battle)
	battle._unhandled_input(_key(KEY_SPACE))
	var guard := 0
	while guard < 600 and _shells(battle).size() == 1 and not _near_ground(battle, _shells(battle)[0]):
		await get_tree().physics_frame
		guard += 1
	var old_generation: int = battle._generation
	battle.restart()
	await _started(battle)
	var cells: int = battle.terrain.get_used_cells().size()
	battle._on_shell_landed(battle.player.global_position, true, old_generation)
	await _frames(60)
	check_eq(battle.terrain.get_used_cells().size(), cells, "stale landing did not carve the new terrain")
	check_eq(battle.player.hp, 100, "stale landing did not hurt the new player")
	check_eq(battle.enemy.hp, 100, "stale landing did not hurt the new enemy")
	battle.queue_free()


func _near_ground(battle: Battle, shell: Projectile) -> bool:
	return shell.velocity.y > 0.0 and shell.position.y > battle.terrain.surface_y(shell.position.x) - 20.0
