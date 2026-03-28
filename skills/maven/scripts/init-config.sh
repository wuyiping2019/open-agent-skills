#!/bin/bash
# 初始化或更新 Maven 配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
CONFIG_FILE="$CONFIG_DIR/config.json"
EXAMPLE_FILE="$CONFIG_DIR/config.example.json"

# 确保配置目录存在
mkdir -p "$CONFIG_DIR"

# 如果配置文件不存在，从示例复制或创建默认配置
if [[ ! -f "$CONFIG_FILE" ]]; then
    if [[ -f "$EXAMPLE_FILE" ]]; then
        cp "$EXAMPLE_FILE" "$CONFIG_FILE"
    else
        echo '{"mavenPath": ""}' > "$CONFIG_FILE"
    fi
fi

# 更新配置字段（纯 sed 实现）
update_config_field() {
    local key="$1"
    local value="$2"

    if [[ -z "$value" ]]; then
        return
    fi

    # 转义 Windows 路径中的反斜杠：\ -> \\\\（四个反斜杠字符）
    # 原因：sed 替换字符串中 \\ 表示输出一个 \，所以需要四个才能输出两个
    local escaped_value="${value//\\/\\\\\\\\}"

    # 使用 # 作为 sed 分隔符，避免路径中的 / 冲突
    # macOS 和 Linux sed 语法不同
    if [[ "$(uname)" == "Darwin" ]]; then
        if grep -q "\"$key\"" "$CONFIG_FILE" 2>/dev/null; then
            sed -i '' "s#\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"$key\": \"$escaped_value\"#" "$CONFIG_FILE"
        else
            # 添加新字段：在最后一个 } 前插入
            sed -i '' 's#}#, "'"$key"'": "'"$escaped_value"'"\n}#' "$CONFIG_FILE"
        fi
    else
        if grep -q "\"$key\"" "$CONFIG_FILE" 2>/dev/null; then
            sed -i "s#\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"$key\": \"$escaped_value\"#" "$CONFIG_FILE"
        else
            # 添加新字段：在最后一个 } 前插入
            sed -i 's#}#, "'"$key"'": "'"$escaped_value"'"\n}#' "$CONFIG_FILE"
        fi
    fi
}

# 处理传入的参数 key=value
for arg in "$@"; do
    if [[ "$arg" =~ ^([^=]+)=(.+)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        update_config_field "$key" "$value"
        echo "CONFIG_SET:$key=$value"
    fi
done

echo "CONFIG_FILE:$CONFIG_FILE"