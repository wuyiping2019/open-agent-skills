#!/bin/bash
# 查看本地与远程 skill 的差异

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_mirror

# 更新镜像仓库
cd "$MIRROR_DIR"
git pull --quiet 2>/dev/null || true

SKILLS_PATH=$(get_skills_path)
LOCAL_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
REMOTE_SKILLS_DIR="$MIRROR_DIR/$SKILLS_PATH"

# 获取 skill 列表
remote_skills=$(list_remote_skills)
local_skills=$(list_local_skills)

# 合并并去重
all_skills=$(echo -e "$remote_skills\n$local_skills" | sort -u)

echo "Skill 同步状态:"
echo "==============="
echo ""
echo "符号说明:"
echo "  [仅远程]  - 远程有，本地无（可 pull）"
echo "  [仅本地]  - 本地有，远程无（可 push）"
echo "  [有差异]  - 两边都有，但内容不同"
echo "  [已同步]  - 两边一致"
echo ""

for skill in $all_skills; do
    [[ -z "$skill" ]] && continue

    remote_dir="$REMOTE_SKILLS_DIR/$skill"
    local_dir="$LOCAL_SKILLS_DIR/$skill"

    if [[ ! -d "$remote_dir" && -d "$local_dir" ]]; then
        echo "  [仅本地]  $skill"
    elif [[ -d "$remote_dir" && ! -d "$local_dir" ]]; then
        echo "  [仅远程]  $skill"
    elif [[ -d "$remote_dir" && -d "$local_dir" ]]; then
        # 比较差异
        diff_output=$(diff -rq "$remote_dir" "$local_dir" 2>/dev/null || true)
        if [[ -z "$diff_output" ]]; then
            echo "  [已同步]  $skill"
        else
            echo "  [有差异]  $skill"
        fi
    fi
done