import re
import os
import sys

def find_container_conflicts(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    issues = []
    pos = 0
    
    while pos < len(content):
        # Find Container( or AnimatedContainer(
        m = re.search(r'\b(Animated)?Container\s*\(', content[pos:])
        if not m:
            break
        
        start = pos + m.start()
        container_start = start
        # Get line number
        line_no = content[:start].count('\n') + 1
        
        # Now find the matching closing paren
        i = start + m.end() - 1  # position of opening '('
        depth = 1
        i += 1
        
        direct_color = False
        inside_box_decoration = False
        has_decoration = False
        deco_depth = None
        box_deco_depth = None
        
        while i < len(content) and depth > 0:
            ch = content[i]
            
            if ch == '(':
                depth += 1
                # Check if BoxDecoration just started
                preceding = content[max(0, i-30):i]
                if re.search(r'BoxDecoration\s*$', preceding.strip()):
                    box_deco_depth = depth
            elif ch == ')':
                if box_deco_depth is not None and depth == box_deco_depth:
                    box_deco_depth = None
                depth -= 1
            
            # Check for 'decoration:' at depth 1 (direct param of Container)
            if depth == 1:
                snippet = content[i:i+20]
                if re.match(r'decoration\s*:', snippet):
                    has_decoration = True
                # Check for 'color:' at depth 1 that is NOT inside BoxDecoration
                if re.match(r'color\s*:', snippet) and box_deco_depth is None:
                    direct_color = True
            
            i += 1
        
        if direct_color and has_decoration:
            issues.append((filepath, line_no))
        
        pos = container_start + 1
    
    return issues

results = []
for root, dirs, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            try:
                issues = find_container_conflicts(path)
                results.extend(issues)
            except Exception as e:
                pass

for path, line in results:
    print(f"{path}:{line}")
