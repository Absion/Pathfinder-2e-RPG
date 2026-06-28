import re

db_file_path = r"c:\Users\Absion\Documents\Game Development\Projects\pathfinder-2rpg\scripts\database\pf_database.gd"

with open(db_file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _actions_cache
if "var _actions_cache: Dictionary = {}" not in content:
    content = content.replace("var _conditions_cache: Dictionary = {}", "var _conditions_cache: Dictionary = {}\nvar _actions_cache: Dictionary = {}")

# 2. Add get_action_data method
get_action_data_method = """
func get_action_data(action_id: StringName) -> Dictionary:
	if _actions_cache.has(action_id):
		return _actions_cache[action_id]
	db.query("SELECT * FROM actions WHERE id = '" + str(action_id) + "';")
	var result = db.query_result
	if result.is_empty():
		return {}
	_actions_cache[action_id] = result[0]
	return result[0]
"""

if "func get_action_data" not in content:
    content = content + "\n" + get_action_data_method

with open(db_file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Added get_action_data to pf_database.gd")
