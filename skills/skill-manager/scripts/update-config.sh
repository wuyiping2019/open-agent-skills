#!/bin/bash
# 更新配置文件中的单个字段

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
CONFIG_FILE="$CONFIG_DIR/config.json"

# 用法检查
if [[ $# -lt 2 ]]; then
    echo "用法: update-config.sh <字段名> <值>"
    echo ""
    echo "可用字段:"
    echo "  repoUrl      - Skill 仓库地址"
    echo "  repoBranch   - 分支名 (默认: main)"
    echo "  skillsPath   - Skills 目录路径 (默认: skills)"
    echo ""
    echo "示例:"
    echo "  update-config.sh repoUrl git@github.com:user/skills.git"
    echo "  update-config.sh repoBranch master"
    exit 1
fi

KEY="$1"
VALUE="$2"

# 检查配置文件是否存在
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "错误: 配置文件不存在"
    echo "请先运行: init-config.sh"
    exit 1
fi

# 验证字段名
VALID_KEYS="repoUrl repoBranch skillsPath"
if ! echo "$VALID_KEYS" | grep -qw "$KEY"; then
    echo "错误: 无效的字段名 '$KEY'"
    echo "可用字段: $VALID_KEYS"
    exit 1
fi

# 更新配置
if command -v python3 &> /dev/null; then
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
config['$KEY'] = '$VALUE'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
"
elif command -v python &> /dev/null; then
    python -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
config['$KEY'] = '$VALUE'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
"
else
    sed -i "s/\"$KEY\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"$KEY\": \"$VALUE\"/" "$CONFIG_FILE"
fi

echo "✓ 已更新 $KEY = $VALUE"
echo ""
echo "当前配置:"
cat "$CONFIG_FILE"