#!/bin/bash
# 查看指定 skill 的详细差异

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_mirror

SKILL_NAME="$1"

if [[ -z "$SKILL_NAME" ]]; then
    echo "用法: skill-manager diff <skill-name>" >&2
    exit 1
fi

# 排除 skill-manager
if [[ "$SKILL_NAME" == "skill-manager" ]]; then
    echo "提示: skill-manager 是管理工具本身，不参与同步操作" >&2
    exit 0
fi

SKILLS_PATH=$(get_skills_path)
LOCAL_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
REMOTE_SKILLS_DIR="$MIRROR_DIR/$SKILLS_PATH"

remote_dir="$REMOTE_SKILLS_DIR/$SKILL_NAME"
local_dir="$LOCAL_SKILLS_DIR/$SKILL_NAME"

if [[ ! -d "$remote_dir" && ! -d "$local_dir" ]]; then
    echo "错误: skill '$SKILL_NAME' 既不在本地也不在远程" >&2
    exit 1
fi

if [[ ! -d "$remote_dir" ]]; then
    echo "skill '$SKILL_NAME' 仅存在于本地:"
    echo ""
    find "$local_dir" -type f | while read f; do
        echo "  ${f#$local_dir/}"
    done
    exit 0
fi

if [[ ! -d "$local_dir" ]]; then
    echo "skill '$SKILL_NAME' 仅存在于远程:"
    echo ""
    find "$remote_dir" -type f | while read f; do
        echo "  ${f#$remote_dir/}"
    done
    exit 0
fi

echo "skill '$SKILL_NAME' 差异对比:"
echo "远程: $remote_dir"
echo "本地: $local_dir"
echo ""

# 使用 diff 或 git diff
if command -v git &> /dev/null; then
    # 使用 git diff --no-index 获得彩色输出
    git diff --no-index --stat "$remote_dir" "$local_dir" 2>/dev/null || echo "(无差异)"
else
    diff -rq "$remote_dir" "$local_dir" || echo "(无差异)"
fi