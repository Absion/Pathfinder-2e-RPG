# test_attachments.gd
class_name TestAttachments
extends GdUnitTestSuite

var db: PFDatabase
var attacker: PFActor

func before() -> void:
	# Ensure the database is initialized
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()
	else:
		db = PFDatabase.get_instance()

func before_test() -> void:
	attacker = PFPlayerCharacter.new("Attacker", [], 1, 50, 0, 0, 0)

func test_attaching_scope_to_crossbow() -> void:
	# Create a crossbow weapon
	var crossbow = PFWeapon.new("Crossbow", [&"crossbow"], 1, 0, PFEquipmentConstants.WeaponType.RANGED)
	
	# Create a scope attachment
	var scope = PFAttachment.new("Scope", [&"attachment"], 1, 0)
	scope.valid_hosts = ["crossbow", "firearm"] as Array[String]
	scope.granted_traits = [&"deadly_d6", &"fatal_aim_d10"] as Array[StringName]
	
	var inv = attacker.get("inventory") as PFInventory
	inv.add_item(crossbow)
	inv.add_item(scope)
	
	# Ensure crossbow doesn't have deadly_d6
	assert_bool(crossbow.has_trait(&"deadly_d6")).is_false()
	
	# Attach scope
	var attach_action = PFActionInteractAttach.new(scope, crossbow)
	assert_bool(await attach_action.execute(attacker)).is_true()
	
	# Verify attachment
	assert_object(crossbow.attachment).is_equal(scope)
	assert_object(scope.host_item).is_equal(crossbow)
	
	# Verify traits added
	assert_bool(crossbow.has_trait(&"deadly_d6")).is_true()
	assert_bool(crossbow.has_trait(&"fatal_aim_d10")).is_true()
	
	# Verify item removed from main inventory pool
	assert_bool(inv.items.has(scope)).is_false()

func test_attaching_bayonet_weapon() -> void:
	# Create a crossbow weapon
	var crossbow = PFWeapon.new("Crossbow", [&"crossbow"], 1, 0, PFEquipmentConstants.WeaponType.RANGED)
	
	# Create a bayonet attachment with a granted weapon
	var bayonet_weapon = PFWeapon.new("Bayonet Attack", [&"agile", &"finesse"], 1, 0, PFEquipmentConstants.WeaponType.MELEE)
	var bayonet = PFAttachment.new("Bayonet", [&"attachment"], 1, 0)
	bayonet.valid_hosts = ["crossbow", "firearm"] as Array[String]
	bayonet.granted_weapon = bayonet_weapon
	
	var inv = attacker.get("inventory") as PFInventory
	inv.add_item(crossbow)
	inv.add_item(bayonet)
	
	var attach_action = PFActionInteractAttach.new(bayonet, crossbow)
	assert_bool(await attach_action.execute(attacker)).is_true()
	
	# Ensure bayonet attack exists
	assert_object(crossbow.attachment.granted_weapon).is_not_null()
	assert_str(crossbow.attachment.granted_weapon.entity_name).is_equal("Bayonet Attack")
	
func test_db_fetching_attachment() -> void:
	var bayonet = db.get_attachment("bayonet")
	assert_object(bayonet).is_not_null()
	assert_str(bayonet.entity_name).is_equal("Bayonet")
	
	# Should have granted weapon because we seeded it
	assert_object(bayonet.granted_weapon).is_not_null()
	assert_str(bayonet.granted_weapon.entity_name).is_equal("Bayonet Attack")
	assert_bool(bayonet.granted_weapon.has_trait(&"agile")).is_true()
