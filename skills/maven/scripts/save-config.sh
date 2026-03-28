#!/bin/bash
# 保存 Maven 路径到配置文件

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

MVN_PATH="$1"

if [[ -z "$MVN_PATH" ]]; then
    echo "ERROR: 未提供 Maven 路径"
    exit 1
fi

# 先验证路径
if ! validate_maven "$MVN_PATH"; then
    echo "ERROR: Maven 路径无效: $MVN_PATH"
    exit 1
fi

# 使用 init-config.sh 保存配置
bash "$SCRIPT_DIR/init-config.sh" mavenPath="$MVN_PATH"

echo "MAVEN_CONFIG_SAVED:$MVN_PATH"

exit 0