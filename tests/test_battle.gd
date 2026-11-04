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
