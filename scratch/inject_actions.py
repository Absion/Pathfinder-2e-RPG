import re
import sys

db_file_path = r"c:\Users\Absion\Documents\Game Development\Projects\pathfinder-2rpg\scripts\database\pf_database.gd"

with open(db_file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add the CREATE TABLE IF NOT EXISTS actions block
create_actions_table = """
	db.query("CREATE TABLE IF NOT EXISTS actions (
		id TEXT PRIMARY KEY,
		name TEXT,
		cost TEXT,
		traits TEXT,
		requirements TEXT,
		trigger TEXT,
		description TEXT,
		script_path TEXT
	);")
"""

if "CREATE TABLE IF NOT EXISTS actions" not in content:
    # Insert it after the conditions table
    content = content.replace('db.query("CREATE TABLE IF NOT EXISTS conditions (', create_actions_table + '\n\tdb.query("CREATE TABLE IF NOT EXISTS conditions (')

# 2. Add the insert statements for basic actions
seed_actions = """
	# Seed Basic Actions
	db.query("INSERT OR IGNORE INTO actions (id, name, cost, traits, requirements, trigger, description, script_path) VALUES 
		('aid', 'Aid', 'reaction', '[]', '', 'An ally is about to use an action.', 'You try to help your ally with a task.', ''),
		('avert_gaze', 'Avert Gaze', '1', '[]', '', '', 'You avert your gaze from a danger.', ''),
		('burrow', 'Burrow', '1', '[\"move\"]', 'You have a burrow Speed.', '', 'You dig your way through dirt.', ''),
		('cast_a_spell', 'Cast a Spell', 'varies', '[]', '', '', 'You cast a spell you have prepared or in your repertoire.', ''),
		('crawl', 'Crawl', '1', '[\"move\"]', 'You are prone and your Speed is at least 10 feet.', '', 'You move 5 feet by crawling.', ''),
		('delay', 'Delay', 'free', '[]', 'Your turn begins and you haven''t acted yet.', '', 'You wait to take your turn.', ''),
		('drop_prone', 'Drop Prone', '1', '[\"move\"]', '', '', 'You fall prone.', ''),
		('escape', 'Escape', '1', '[\"attack\"]', 'You are grabbed, immobilized, or restrained.', '', 'You attempt to escape.', ''),
		('fly', 'Fly', '1', '[\"move\"]', 'You have a fly Speed.', '', 'You move through the air.', ''),
		('grab_an_edge', 'Grab an Edge', 'reaction', '[\"manipulate\"]', 'You fall or slip.', '', 'You attempt to catch an edge to stop falling.', ''),
		('interact', 'Interact', '1', '[\"manipulate\"]', '', '', 'You use your hand or hands to manipulate an object or the terrain.', ''),
		('leap', 'Leap', '1', '[\"move\"]', '', '', 'You take a careful, short jump.', ''),
		('point_out', 'Point Out', '1', '[\"auditory\",\"manipulate\",\"visual\"]', '', '', 'You indicate an unseen creature to your allies.', ''),
		('ready', 'Ready', '2', '[\"concentrate\"]', '', '', 'You prepare an action to use as a reaction.', ''),
		('release', 'Release', 'free', '[\"manipulate\"]', '', '', 'You release something you are holding.', ''),
		('seek', 'Seek', '1', '[\"concentrate\",\"secret\"]', '', '', 'You scan an area for unseen creatures or objects.', ''),
		('sense_motive', 'Sense Motive', '1', '[\"concentrate\",\"secret\"]', '', '', 'You try to tell whether a creature''s behavior is abnormal.', ''),
		('stand', 'Stand', '1', '[\"move\"]', '', '', 'You stand up from prone.', ''),
		('step', 'Step', '1', '[\"move\"]', '', '', 'You carefully move 5 feet.', ''),
		('stride', 'Stride', '1', '[\"move\"]', '', '', 'You move up to your Speed.', ''),
		('strike', 'Strike', '1', '[\"attack\"]', '', '', 'You attack with a weapon or unarmed attack.', ''),
		('take_cover', 'Take Cover', '1', '[]', '', '', 'You press yourself against a wall or duck behind an obstacle.', '')
	;")
"""

if "# Seed Basic Actions" not in content:
    # Insert it before "# Seed Conditions"
    content = content.replace('\t# Seed Conditions', seed_actions + '\n\t# Seed Conditions')

with open(db_file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Database script updated successfully.")
