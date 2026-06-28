import os
import re

test_dir = r"c:\Users\Absion\Documents\Game Development\Projects\pathfinder-2rpg\test"

for root, _, files in os.walk(test_dir):
    for file in files:
        if file.endswith(".gd"):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Use regex to find `something.execute(` and prepend `await` if it doesn't already have it
            # Match optional whitespace, maybe an assignment like `var success = ` or `assert_bool(`
            # The easiest way is to find `.execute(` that does not have `await ` before it.
            
            # Simple approach: replace any instance of `foo.execute(` with `await foo.execute(`
            # But wait, we need to make sure we don't double await.
            # And wait, `assert_bool(await foo.execute(..))` is valid in GDScript 4!
            
            # Regex to match `word.execute(`
            # We want to insert `await ` right before `word`
            # Pattern: ([a-zA-Z0-9_]+)\.execute\(
            # We replace with: await \1.execute(
            # Exclude if preceded by `await `
            
            new_content = re.sub(r'(?<!await )([a-zA-Z0-9_]+)\.execute\(', r'await \1.execute(', content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
