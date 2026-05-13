#!/bin/bash
# Find dart files that have Container with both 'color:' and 'decoration:' as direct params
cd /Users/brayan/restaurant_kiosko
find lib -name "*.dart" | while read file; do
  python3 - "$file" <<'EOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()

i = 0
while i < len(lines):
    line = lines[i]
    if re.search(r'\b(Animated)?Container\s*\(', line):
        # Gather the block
        block_start = i
        block = ''
        depth = 0
        j = i
        while j < len(lines) and j < i + 40:
            block += lines[j]
            depth += lines[j].count('(') + lines[j].count('{')
            depth -= lines[j].count(')') + lines[j].count('}')
            j += 1
            if depth <= 0:
                break
        
        # Find color: and decoration: as direct params (not inside BoxDecoration)
        # Split by BoxDecoration( to exclude inside
        # Simple approach: look for lines with 'color:' not preceded by BoxDecoration
        block_lines = block.split('\n')
        has_direct_color = False
        has_decoration = False
        for bl in block_lines:
            stripped = bl.strip()
            if re.match(r'color\s*:', stripped) and 'BoxDecoration' not in stripped:
                has_direct_color = True
            if re.match(r'decoration\s*:', stripped):
                has_decoration = True
        
        if has_direct_color and has_decoration:
            print(f"{path}:{block_start+1}: Container with color+decoration conflict")
    i += 1
EOF
done
