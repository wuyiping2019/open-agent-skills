#!/bin/bash
# 推送本地 skill 到远程仓库

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_mirror

SKILLS_PATH=$(get_skills_path)
LOCAL_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
REMOTE_SKILLS_DIR="$MIRROR_DIR/$SKILLS_PATH"

if [[ ! -d "$LOCAL_SKILLS_DIR" ]]; then
    echo "错误: 本地 skills 目录不存在: $LOCAL_SKILLS_DIR" >&2
    exit 1
fi

# 参数：指定 skill 或全部
SKILL_NAME="$1"

cd "$MIRROR_DIR"
mkdir -p "$REMOTE_SKILLS_DIR"

if [[ -n "$SKILL_NAME" ]]; then
    # 推送指定 skill
    SKILL_DIR="$LOCAL_SKILLS_DIR/$SKILL_NAME"
    if [[ ! -d "$SKILL_DIR" ]]; then
        echo "错误: skill '$SKILL_NAME' 不存在于本地" >&2
        exit 1
    fi

    # 检查是否有 SKILL.md
    if [[ ! -f "$SKILL_DIR/SKILL.md" ]]; then
        echo "警告: skill '$SKILL_NAME' 缺少 SKILL.md 文件"
    fi

    cp -r "$SKILL_DIR" "$REMOTE_SKILLS_DIR/"
    git add "$SKILLS_PATH/$SKILL_NAME"
    git commit -m "Update skill: $SKILL_NAME"
    git push

    echo "✓ 已推送: $SKILL_NAME"
else
    # 推送所有 skill（排除 skill-manager）
    echo "正在推送所有 skill..."
    count=0
    has_changes=false

    for skill_dir in "$LOCAL_SKILLS_DIR"/*/; do
        if [[ -d "$skill_dir" ]]; then
            skill_name=$(basename "$skill_dir")
            # 排除 skill-manager
            if [[ "$skill_name" == "skill-manager" ]]; then
                continue
            fi
            cp -r "$skill_dir" "$REMOTE_SKILLS_DIR/"
            git add "$SKILLS_PATH/$skill_name"
            echo "  + $skill_name"
            ((count++)) || true
            has_changes=true
        fi
    done

    if [[ "$has_changes" == true ]]; then
        git commit -m "Update skills: $count skill(s)"
        git push
        echo ""
        echo "✓ 共推送 $count 个 skill"
    else
        echo "没有需要推送的 skill"
    fi
fi