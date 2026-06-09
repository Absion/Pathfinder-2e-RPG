# pf_time_manager.gd
## A global manager responsible for tracking the passage of time across the game state.
## In Pathfinder 2e, time passes differently depending on the mode of play (Encounter, Exploration, Downtime).
class_name PFTimeManager
extends Node

signal time_advanced(seconds: int)
signal day_passed()
signal rested_for_night()

const SECONDS_PER_ROUND = 6
const SECONDS_PER_MINUTE = 60
const SECONDS_PER_HOUR = 3600
const SECONDS_PER_DAY = 86400

var current_day: int = 1
var current_time_seconds: int = 0

static var _instance: PFTimeManager

func _ready() -> void:
	_instance = self

static func get_instance() -> PFTimeManager:
	return _instance

## Advances time by a specific number of seconds (e.g. 6 seconds for one combat round).
func advance_seconds(amount: int) -> void:
	if amount <= 0: return
	
	current_time_seconds += amount
	time_advanced.emit(amount)
	_check_day_rollover()

## Advances time by a specific number of minutes. Used for Exploration mode activities like Treat Wounds (10 min).
func advance_minutes(amount: int) -> void:
	advance_seconds(amount * SECONDS_PER_MINUTE)

## Advances time by a specific number of hours.
func advance_hours(amount: int) -> void:
	advance_seconds(amount * SECONDS_PER_HOUR)

## Advances the game by one or more days. Used in Downtime mode for Retraining or Crafting.
func advance_days(amount: int) -> void:
	if amount <= 0: return
	
	current_day += amount
	for i in range(amount):
		day_passed.emit()
		print("--- A new day has dawned! Day %d ---" % current_day)

## Simulates the party taking an 8-hour rest.
func rest_for_night() -> void:
	print("The party rests for 8 hours...")
	advance_hours(8)
	rested_for_night.emit()

func _check_day_rollover() -> void:
	if current_time_seconds >= SECONDS_PER_DAY:
		var days_passed = current_time_seconds / SECONDS_PER_DAY
		current_time_seconds = current_time_seconds % SECONDS_PER_DAY
		advance_days(days_passed)
