#!/bin/bash
# 初始化镜像仓库

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

MIRROR_DIR="$HOME/.skill-manager/repo"

# 检查是否已存在
if [[ -d "$MIRROR_DIR/.git" ]]; then
    echo "镜像仓库已存在: $MIRROR_DIR"
    echo "正在更新..."
    cd "$MIRROR_DIR"
    git pull
    echo ""
    show_config
    echo ""
    echo "✓ 镜像仓库已更新"
    exit 0
fi

# 获取配置并显示
REPO_URL=$(get_repo_url)
REPO_BRANCH=$(get_repo_branch)
SKILLS_PATH=$(get_skills_path)

echo "========================================"
echo "初始化 Skill Manager 镜像仓库"
echo "========================================"
echo ""
show_config
echo ""
echo "========================================"

# 创建目录
mkdir -p "$(dirname "$MIRROR_DIR")"

# 尝试克隆仓库，处理空仓库情况
echo ""
echo "正在克隆仓库..."
if git clone -b "$REPO_BRANCH" "$REPO_URL" "$MIRROR_DIR" 2>&1; then
    echo ""
    echo "✓ 镜像仓库初始化完成"
else
    # 空仓库，手动初始化
    echo ""
    echo "远程仓库为空或不存在分支 '$REPO_BRANCH'，正在手动初始化..."
    mkdir -p "$MIRROR_DIR"
    cd "$MIRROR_DIR"
    git init
    git remote add origin "$REPO_URL"
    mkdir -p "$SKILLS_PATH"
    echo ""
    echo "✓ 已初始化空仓库"
    echo ""
    echo "提示: 使用 push 命令推送本地 skill 到远程仓库"
fi

echo ""
echo "可用的 skill:"
list_remote_skills | while read skill; do
    [[ -n "$skill" ]] && echo "  - $skill"
done

if [[ -z "$(list_remote_skills)" ]]; then
    echo "  (仓库中暂无 skill)"
    echo ""
    echo "提示: 使用 /skill-manager push 推送本地 skill"
fi