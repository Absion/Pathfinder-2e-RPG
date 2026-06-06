# pf_movement_component.gd
## Manages an actor's speeds and movement capabilities.
class_name PFMovementComponent
extends Node

# --- MOVEMENT ---
var speed_land: int
var speed_fly: int
var speed_swim: int
var speed_climb: int 
var speed_burrow: int 

func initialize(p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0, p_speed_climb: int = 0, p_speed_burrow: int = 0) -> void:
	speed_land = p_speed_land
	speed_fly = p_speed_fly
	speed_swim = p_speed_swim
	speed_climb = p_speed_climb
	speed_burrow = p_speed_burrow

func get_speed() -> int:
	return speed_land
