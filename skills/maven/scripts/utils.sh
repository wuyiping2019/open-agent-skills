#!/bin/bash
# Maven 通用工具函数（纯 shell 实现）

# 配置文件路径（相对于 skill 目录）
get_skill_config_file() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local skill_dir="$(dirname "$script_dir")"
    echo "$skill_dir/config/config.json"
}

# 读取配置值（纯 shell）
get_config() {
    local key="$1"
    local default="$2"
    local config_file="$(get_skill_config_file)"
    local value=""

    if [[ -f "$config_file" ]]; then
        # 使用 grep 和 sed 提取值
        # 匹配 "key": "value" 格式，提取 value 部分
        value=$(grep "\"$key\"" "$config_file" 2>/dev/null | sed -n "s#.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*#\1#p" | head -1)
    fi

    # 返回值或默认值
    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# 写入配置值（纯 shell）
set_config() {
    local key="$1"
    local value="$2"
    local config_file="$(get_skill_config_file)"
    local config_dir="$(dirname "$config_file")"

    # 确保配置目录存在
    mkdir -p "$config_dir"

    # 如果配置文件不存在，创建默认配置
    if [[ ! -f "$config_file" ]]; then
        echo '{"mavenPath": ""}' > "$config_file"
    fi

    # 使用 # 作为 sed 分隔符，避免路径中的 / 冲突
    # macOS 和 Linux sed 语法不同
    if grep -q "\"$key\"" "$config_file" 2>/dev/null; then
        # 更新现有值
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s#\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"$key\": \"$value\"#" "$config_file"
        else
            sed -i "s#\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"$key\": \"$value\"#" "$config_file"
        fi
    else
        # 添加新键（在最后一个 } 之前插入）
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s#}#  \"$key\": \"$value\"\n}#" "$config_file"
        else
            sed -i "s#}#  \"$key\": \"$value\"\n}#" "$config_file"
        fi
    fi
}

# 验证 Maven 路径是否有效
validate_maven() {
    local mvn_path="$1"

    # 检查文件是否存在
    if [[ ! -f "$mvn_path" ]]; then
        return 1
    fi

    # 尝试执行 mvn -version
    local result
    result=$( "$mvn_path" -version 2>&1 )

    # 检查输出是否包含 Apache Maven
    if echo "$result" | grep -q "Apache Maven"; then
        return 0
    fi

    return 1
}

# 获取 Maven 版本信息
get_maven_version() {
    local mvn_path="$1"
    "$mvn_path" -version 2>&1 | head -1
}

# 获取操作系统类型
get_os_type() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "windows";;
        MINGW*)     echo "windows";;
        MSYS*)      echo "windows";;
        *)          echo "unknown";;
    esac
}

# 标记输出（用于 Claude 解析）
mark_output() {
    local type="$1"
    local data="$2"
    echo "MAVEN_$type:$data"
}