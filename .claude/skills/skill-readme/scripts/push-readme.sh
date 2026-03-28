#!/bin/bash
# 为远程技能仓库生成 README.md 并推送
# Usage: bash push-readme.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$HOME/.skill-share/repo"

if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "ERROR: 远程仓库镜像不存在: $REPO_DIR"
    echo "请先运行 /share-skill init 初始化"
    exit 1
fi

cd "$REPO_DIR"

# 拉取最新
echo "正在拉取最新代码..."
git pull --quiet 2>/dev/null || true

# 生成 README
echo "正在生成 README.md..."
bash "$SCRIPT_DIR/generate.sh" "$REPO_DIR"

# 检查是否有变化
if git diff --quiet README.md 2>/dev/null; then
    echo "README.md 无变化，跳过提交"
    exit 0
fi

# 提交并推送
echo "正在提交并推送..."
git add README.md
git commit -m "Update README.md"
git push

echo ""
echo "README_SUCCESS: 已更新远程仓库的 README.md"