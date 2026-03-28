#!/bin/bash
# 验证 Maven 路径并获取版本信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

MVN_PATH="$1"

if [[ -z "$MVN_PATH" ]]; then
    echo "ERROR: 未提供 Maven 路径"
    exit 1
fi

echo "MAVEN_VALIDATE_START"

# 验证路径
if validate_maven "$MVN_PATH"; then
    echo "MAVEN_VALID:yes"
    echo "MAVEN_PATH:$MVN_PATH"

    # 获取版本信息
    VERSION=$(get_maven_version "$MVN_PATH")
    echo "MAVEN_VERSION:$VERSION"

    # 获取 Java 信息
    JAVA_INFO=$( "$MVN_PATH" -version 2>&1 | grep -E "Java version|java version" | head -1 || echo "")
    echo "MAVEN_JAVA:$JAVA_INFO"

    echo "MAVEN_VALIDATE_END"
    exit 0
else
    echo "MAVEN_VALID:no"
    echo "MAVEN_PATH:$MVN_PATH"
    echo "MAVEN_ERROR:路径无效或 Maven 无法执行"
    echo "MAVEN_VALIDATE_END"
    exit 1
fi