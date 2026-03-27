#!/bin/bash
# 拉取 skill 到本地项目

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_mirror

# 更新镜像仓库
echo "正在更新镜像仓库..."
cd "$MIRROR_DIR"
git pull --quiet

SKILLS_PATH=$(get_skills_path)
LOCAL_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
REMOTE_SKILLS_DIR="$MIRROR_DIR/$SKILLS_PATH"

# 参数：指定 skill 或全部
SKILL_NAME="$1"

if [[ -n "$SKILL_NAME" ]]; then
    # 拉取指定 skill
    SKILL_DIR="$REMOTE_SKILLS_DIR/$SKILL_NAME"
    if [[ ! -d "$SKILL_DIR" ]]; then
        echo "错误: skill '$SKILL_NAME' 不存在于远程仓库" >&2
        exit 1
    fi

    mkdir -p "$LOCAL_SKILLS_DIR"
    cp -r "$SKILL_DIR" "$LOCAL_SKILLS_DIR/"
    echo "✓ 已拉取: $SKILL_NAME"
else
    # 拉取所有 skill（排除 skill-manager）
    if [[ ! -d "$REMOTE_SKILLS_DIR" ]]; then
        echo "错误: 远程 skills 目录不存在: $REMOTE_SKILLS_DIR" >&2
        exit 1
    fi

    mkdir -p "$LOCAL_SKILLS_DIR"

    echo "正在拉取所有 skill..."
    count=0
    for skill_dir in "$REMOTE_SKILLS_DIR"/*/; do
        if [[ -d "$skill_dir" ]]; then
            skill_name=$(basename "$skill_dir")
            # 排除 skill-manager
            if [[ "$skill_name" == "skill-manager" ]]; then
                continue
            fi
            cp -r "$skill_dir" "$LOCAL_SKILLS_DIR/"
            echo "  ✓ $skill_name"
            ((count++)) || true
        fi
    done

    echo ""
    echo "✓ 共拉取 $count 个 skill"
fi