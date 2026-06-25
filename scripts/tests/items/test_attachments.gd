# test_attachments.gd
class_name TestAttachments
extends GutTest

var db: PFDatabase
var attacker: PFActor

func before_all() -> void:
	# Ensure the database is initialized
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()
	else:
		db = PFDatabase.get_instance()

func before_each() -> void:
	attacker = PFPlayerCharacter.new("Attacker", [], 1, 50, 0, 0, 0)

func test_attaching_scope_to_crossbow() -> void:
	# Create a crossbow weapon
	var crossbow = PFWeapon.new("Crossbow", [&"crossbow"], 1, 0, PFEquipmentConstants.WeaponType.RANGED)
	
	# Create a scope attachment
	var scope = PFAttachment.new("Scope", [&"attachment"], 1, 0)
	scope.valid_hosts = ["crossbow", "firearm"] as Array[String]
	scope.granted_traits = [&"deadly_d6", &"fatal_aim_d10"] as Array[StringName]
	
	var inv = attacker.get(&"inventory") as PFInventory
	inv.add_item(crossbow)
	inv.add_item(scope)
	
	# Ensure crossbow doesn't have deadly_d6
	assert_false(crossbow.has_trait(&"deadly_d6"))
	
	# Attach scope
	var attach_action = PFActionInteractAttach.new(scope, crossbow)
	assert_true(await attach_action.execute(attacker))
	
	# Verify attachment
	assert_eq(crossbow.attachment, scope)
	assert_eq(scope.host_item, crossbow)
	
	# Verify traits added
	assert_true(crossbow.has_trait(&"deadly_d6"))
	assert_true(crossbow.has_trait(&"fatal_aim_d10"))
	
	# Verify item removed from main inventory pool
	assert_false(inv.items.has(scope))

func test_attaching_bayonet_weapon() -> void:
	# Create a crossbow weapon
	var crossbow = PFWeapon.new("Crossbow", [&"crossbow"], 1, 0, PFEquipmentConstants.WeaponType.RANGED)
	
	# Create a bayonet attachment with a granted weapon
	var bayonet_weapon = PFWeapon.new("Bayonet Attack", [&"agile", &"finesse"], 1, 0, PFEquipmentConstants.WeaponType.MELEE)
	var bayonet = PFAttachment.new("Bayonet", [&"attachment"], 1, 0)
	bayonet.valid_hosts = ["crossbow", "firearm"] as Array[String]
	bayonet.granted_weapon = bayonet_weapon
	
	var inv = attacker.get(&"inventory") as PFInventory
	inv.add_item(crossbow)
	inv.add_item(bayonet)
	
	var attach_action = PFActionInteractAttach.new(bayonet, crossbow)
	assert_true(await attach_action.execute(attacker))
	
	# Ensure bayonet attack exists
	assert_not_null(crossbow.attachment.granted_weapon)
	assert_eq(crossbow.attachment.granted_weapon.entity_name, "Bayonet Attack")
	
func test_db_fetching_attachment() -> void:
	var bayonet = db.get_attachment("bayonet")
	assert_not_null(bayonet)
	assert_eq(bayonet.entity_name, "Bayonet")
	
	# Should have granted weapon because we seeded it
	assert_not_null(bayonet.granted_weapon)
	assert_eq(bayonet.granted_weapon.entity_name, "Bayonet Attack")
	assert_true(bayonet.granted_weapon.has_trait(&"agile"))
