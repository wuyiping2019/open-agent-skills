#!/bin/bash
# 列出远程和本地 skill

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_mirror

echo "远程 skill (镜像仓库):"
echo "-------------------"
remote_skills=$(list_remote_skills)
if [[ -n "$remote_skills" ]]; then
    echo "$remote_skills" | while read skill; do
        [[ -n "$skill" ]] && echo "  $skill"
    done
else
    echo "  (无)"
fi

echo ""
echo "本地 skill (当前项目):"
echo "-------------------"
local_skills=$(list_local_skills)
if [[ -n "$local_skills" ]]; then
    echo "$local_skills" | while read skill; do
        [[ -n "$skill" ]] && echo "  $skill"
    done
else
    echo "  (无)"
fi