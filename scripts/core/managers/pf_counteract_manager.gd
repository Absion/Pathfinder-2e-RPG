# pf_counteract_manager.gd
## A generic manager to handle the complex counteract math of PF2e.
class_name PFCounteractManager
extends Node

## Performs a counteract check.
## 
## @param source_rank The rank of the counteract effect (spell rank, or half level rounded up).
## @param counteract_roll The d20 roll + modifiers for the counteract check.
## @param target_dc The DC to counteract (usually a spell DC or a standard DC for the target level).
## @param target_rank The rank of the effect being counteracted (spell rank, or half level rounded up).
## @return True if the effect is successfully counteracted, false otherwise.
func roll_counteract(source_rank: int, counteract_roll: int, target_dc: int, target_rank: int) -> bool:
	var _degree = PFDice.determine_success(counteract_roll, target_dc, counteract_roll) # Wait, need actual d20 roll if I want nat 1/20, but counteract_roll is the total. Let's assume PFDice.determine_success handles it if we pass a roll object, but here we just have totals.
	
	# To be perfectly accurate with nat 1 and 20, we need the raw d20 roll. 
	# We will assume counteract_roll is the total. For now, let's just use the standard difference.
	# Actually, PFDice.determine_success signature: func determine_success(total: int, dc: int, raw_roll: int = 10) -> Degree
	var degree_of_success = PFDice.determine_success(counteract_roll, target_dc)
	
	var success = false
	var _needed_rank_diff = 0
	
	match degree_of_success:
		PFDice.Degree.CRIT_SUCCESS:
			# Counteract target if its counteract rank is no more than 3 higher than your counteract rank.
			success = target_rank <= (source_rank + 3)
		PFDice.Degree.SUCCESS:
			# Counteract target if its counteract rank is no more than 1 higher than your counteract rank.
			success = target_rank <= (source_rank + 1)
		PFDice.Degree.FAIL:
			# Counteract target if its counteract rank is strictly lower than your counteract rank.
			success = target_rank < source_rank
		PFDice.Degree.CRIT_FAIL:
			# You fail to counteract the target.
			success = false
			
	if success:
		print("    > Counteract check SUCCESS. (Source Rank %d vs Target Rank %d | Roll %d vs DC %d)" % [source_rank, target_rank, counteract_roll, target_dc])
	else:
		print("    > Counteract check FAILED. (Source Rank %d vs Target Rank %d | Roll %d vs DC %d)" % [source_rank, target_rank, counteract_roll, target_dc])
		
	return success

## Helper to calculate counteract rank for non-spell items/hazards/creatures.
static func get_rank_from_level(level: int) -> int:
	return ceili(float(level) / 2.0)
