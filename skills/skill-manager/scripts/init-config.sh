#!/bin/bash
# 初始化配置文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
CONFIG_FILE="$CONFIG_DIR/config.json"
EXAMPLE_FILE="$CONFIG_DIR/config.example.json"

# 确保配置目录存在
mkdir -p "$CONFIG_DIR"

# 如果配置文件不存在，从示例复制
if [[ ! -f "$CONFIG_FILE" ]]; then
    if [[ -f "$EXAMPLE_FILE" ]]; then
        cp "$EXAMPLE_FILE" "$CONFIG_FILE"
        echo "已创建配置文件: $CONFIG_FILE"
    else
        # 创建默认配置
        cat > "$CONFIG_FILE" << 'EOF'
{
  "repoUrl": "",
  "repoBranch": "main",
  "skillsPath": "skills"
}
EOF
        echo "已创建默认配置文件: $CONFIG_FILE"
    fi
fi

# 解析参数并更新配置
# 用法: init-config.sh repoUrl=xxx repoBranch=xxx skillsPath=xxx
update_config_field() {
    local key="$1"
    local value="$2"

    if [[ -z "$value" ]]; then
        return
    fi

    # 使用 sed 替换 JSON 字段
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
import sys
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
config['$key'] = '$value'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
"
    elif command -v python &> /dev/null; then
        python -c "
import json
import sys
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
config['$key'] = '$value'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
"
    else
        # 使用 sed 简单替换（不支持复杂 JSON）
        sed -i "s/\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/" "$CONFIG_FILE"
    fi
}

# 处理传入的参数
for arg in "$@"; do
    if [[ "$arg" =~ ^([^=]+)=(.+)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        update_config_field "$key" "$value"
        echo "已设置 $key = $value"
    fi
done

echo ""
echo "当前配置:"
cat "$CONFIG_FILE"