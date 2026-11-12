## Base class for test suites. Extend it in res://tests/test_<thing>.gd and
## write `func test_<behaviour>():` methods (may `await`, e.g. physics frames).
extends Node

var runner  # set by run_tests.gd


func check(condition: bool, message: String) -> void:
	if not condition:
		runner.record_failure(message)


func check_eq(actual, expected, message: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [message, expected, actual])


func check_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	check(absf(actual - expected) <= tolerance, "%s (expected %s ±%s, got %s)" % [message, expected, tolerance, actual])
