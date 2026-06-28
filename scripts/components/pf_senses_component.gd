# pf_senses_component.gd
## Tracks what the actor can perceive through various senses.
class_name PFSensesComponent
extends Node

# --- BIOMETRICS & SENSES ---
var vision: PFBiographyConstants.Vision = PFBiographyConstants.Vision.NORMAL
var senses: Array[PFSense] = []

func initialize() -> void:
	# Default Senses
	senses.append_array([
		PFSense.new(PFBiographyConstants.SenseType.VISION, PFBiographyConstants.SenseAcuity.PRECISE),
		PFSense.new(PFBiographyConstants.SenseType.TOUCH, PFBiographyConstants.SenseAcuity.PRECISE),
		PFSense.new(PFBiographyConstants.SenseType.HEARING, PFBiographyConstants.SenseAcuity.IMPRECISE),
		PFSense.new(PFBiographyConstants.SenseType.SCENT, PFBiographyConstants.SenseAcuity.VAGUE),
		PFSense.new(PFBiographyConstants.SenseType.TASTE, PFBiographyConstants.SenseAcuity.VAGUE)
	])

# Safely adds a new sense or upgrades an existing one
func grant_sense(sense_type: PFBiographyConstants.SenseType, acuity: PFBiographyConstants.SenseAcuity, range_ft: int = 0) -> void:
	# Check if the actor already has this sense
	for s in senses:
		if s.type == sense_type:
			var upgraded = false
			# Upgrade Acuity if the new one is better (Precise < Imprecise < Vague mathematically in the enum)
			if acuity < s.acuity: 
				s.acuity = acuity
				upgraded = true
			# Upgrade Range if the new one is longer (or if the new one is unlimited [0])
			if range_ft == 0 or (s.range_ft != 0 and range_ft > s.range_ft):
				s.range_ft = range_ft
				upgraded = true
				
			if upgraded:
				print("    > %s's %s upgraded to: %s" % [get_parent().entity_name if get_parent() and "entity_name" in get_parent() else "Entity", PFBiographyConstants.SenseType.keys()[sense_type], s.get_sense_string()])
			return

	# If they don't have it, add it completely fresh
	var new_sense = PFSense.new(sense_type, acuity, range_ft)
	senses.append(new_sense)
	print("    > %s gained a new sense: %s" % [get_parent().entity_name if get_parent() and "entity_name" in get_parent() else "Entity", new_sense.get_sense_string()])
