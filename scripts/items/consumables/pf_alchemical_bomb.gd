# pf_alchemical_bomb.gd
## Represents an alchemical bomb (a martial ranged weapon with splash damage that is consumed when thrown).
class_name PFAlchemicalBomb
extends PFWeapon

var splash_damage: int = 1

func _init(p_id: String = "alchemists_fire", p_name: String = "Alchemist's Fire", p_traits: Array[StringName] = [&"alchemical", &"bomb", &"consumable", &"splash", &"fire", &"thrown"], p_level: int = 1, p_price_gp: float = 3.0, p_damage_type: int = PFCombatConstants.DamageType.FIRE):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.WeaponType.RANGED, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.BOMB, 1, 8, p_damage_type, PFEquipmentConstants.ItemMaterial.STANDARD, 0, 0, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0, 0, 0, 1, PFEquipmentConstants.AmmunitionType.NONE)
	
	id = p_id
	splash_damage = 1

	
	# Ensure required traits are present
	if not traits.has(&"thrown"):
		traits.append(&"thrown")
	if not traits.has(&"splash"):
		traits.append(&"splash")
	if not traits.has(&"consumable"):
		traits.append(&"consumable")
	if not traits.has(&"alchemical"):
		traits.append(&"alchemical")
	if not traits.has(&"bomb"):
		traits.append(&"bomb")
