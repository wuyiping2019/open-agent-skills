#!/bin/bash
# Generate README.md for skills repository
# Usage: bash generate.sh <project_root>

set -e

PROJECT_ROOT="${1:-.}"
SKILLS_DIR="$PROJECT_ROOT/skills"

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "Error: skills/ directory not found at $SKILLS_DIR"
    exit 1
fi

# Collect skill info
SKILLS_DATA=""

for skill_dir in "$SKILLS_DIR"/*/; do
    [[ -d "$skill_dir" ]] || continue

    skill_name=$(basename "$skill_dir")
    skill_md="$skill_dir/SKILL.md"

    # Skip if no SKILL.md
    if [[ ! -f "$skill_md" ]]; then
        echo "Warning: $skill_name has no SKILL.md, skipping"
        continue
    fi

    # Check if description: | (multiline format)
    if grep -q "^description: |$" "$skill_md"; then
        # Extract multiline description (indented lines after description: |)
        desc=$(sed -n '/^description: |$/,/^---$/p' "$skill_md" | grep "^  " | sed 's/^  //' | tr '\n' ' ' | sed 's/ $//')
    else
        # Single-line format
        desc=$(grep "^description:" "$skill_md" | head -1 | sed 's/^description: //')
    fi

    # Fallback to title if empty
    if [[ -z "$desc" ]]; then
        desc=$(grep "^# " "$skill_md" | head -1 | sed 's/^# //')
    fi

    # Escape for markdown table
    desc=$(echo "$desc" | sed 's/|/\\|/g')

    # Append to data
    if [[ -n "$SKILLS_DATA" ]]; then
        SKILLS_DATA="$SKILLS_DATA
"
    fi
    SKILLS_DATA="$SKILLS_DATA| $skill_name | $desc | [SKILL.md](skills/$skill_name/SKILL.md) |"
done

# Generate README.md
cat > "$PROJECT_ROOT/README.md" << 'HEADER'
# open-agent-skills

Claude Code 个人技能仓库，包含多个实用 skill。

## Skills

HEADER

if [[ -n "$SKILLS_DATA" ]]; then
    cat >> "$PROJECT_ROOT/README.md" << 'TABLE_HEADER'
| Skill | Description | Link |
|-------|-------------|------|
TABLE_HEADER
    echo "$SKILLS_DATA" >> "$PROJECT_ROOT/README.md"
else
    echo "(No skills found)" >> "$PROJECT_ROOT/README.md"
fi

echo "Generated README.md at $PROJECT_ROOT/README.md"