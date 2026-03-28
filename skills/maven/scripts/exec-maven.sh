#!/bin/bash
# 执行 Maven 命令

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

MVN_PATH="$1"
shift
MVN_ARGS="$*"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

if [[ -z "$MVN_PATH" ]]; then
    echo "ERROR: 未提供 Maven 路径"
    exit 1
fi

if [[ -z "$MVN_ARGS" ]]; then
    echo "ERROR: 未提供 Maven 命令参数"
    exit 1
fi

# 验证路径
if ! validate_maven "$MVN_PATH"; then
    echo "ERROR: Maven 路径无效: $MVN_PATH"
    exit 1
fi

# 查找 pom.xml
POM_RESULT=$(bash "$SCRIPT_DIR/find-pom.sh")
POM_COUNT=$(echo "$POM_RESULT" | grep "POM_COUNT:" | sed 's/POM_COUNT://')

if [[ "$POM_COUNT" -eq 0 ]]; then
    echo "ERROR: 当前工作空间不是 Maven 项目（未找到 pom.xml）"
    echo "PROJECT_DIR: $PROJECT_DIR"
    exit 1
fi

# 获取 pom.xml 路径列表
POM_PATHS=$(echo "$POM_RESULT" | grep "POM_PATH:" | sed 's/POM_PATH://')

# 如果有多个 pom.xml，需要用户选择
if [[ "$POM_COUNT" -gt 1 ]]; then
    echo "POM_MULTIPLE:$POM_COUNT"
    for path in $POM_PATHS; do
        # 计算相对路径
        rel_path="${path#$PROJECT_DIR/}"
        echo "POM_OPTION:$rel_path|$path"
    done
    exit 0  # 返回 0 表示需要用户选择，Claude 会处理
fi

# 单个 pom.xml，获取项目根目录
POM_DIR=$(dirname "$POM_PATHS")

echo "MAVEN_EXEC_START"
echo "MAVEN_PATH: $MVN_PATH"
echo "MAVEN_ARGS: $MVN_ARGS"
echo "PROJECT_DIR: $POM_DIR"
echo "---"

# 执行 Maven 命令
cd "$POM_DIR" || exit 1
"$MVN_PATH" "$MVN_ARGS"

echo "---"
echo "MAVEN_EXEC_END"