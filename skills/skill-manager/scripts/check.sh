#!/bin/bash
# 配置检查脚本（非交互式）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

CONFIG_FILE="$PROJECT_DIR/.claude/skills/skill-manager/config/config.json"

# 输出标记
echo "CHECK_START"

# 1. 检查配置文件是否存在
check_files() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "FILE:CONFIG:EXISTS:$CONFIG_FILE"
    else
        echo "FILE:CONFIG:MISSING:$CONFIG_FILE"
    fi
}

# 2. 检查 JSON 格式
check_json() {
    local file="$1"

    if [[ -f "$file" ]]; then
        if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            echo "JSON:VALID"
        elif python -c "import json; json.load(open('$file'))" 2>/dev/null; then
            echo "JSON:VALID"
        else
            echo "JSON:INVALID"
        fi
    fi
}

# 3. 检查配置值
check_values() {
    local repo_url=$(get_config "repoUrl" "")
    local branch=$(get_config "repoBranch" "")
    local path=$(get_config "skillsPath" "")

    if [[ -n "$repo_url" ]]; then
        echo "VALUE:repoUrl:SET:$repo_url"
    else
        echo "VALUE:repoUrl:MISSING"
    fi

    if [[ -n "$branch" ]]; then
        echo "VALUE:repoBranch:SET:$branch"
    else
        echo "VALUE:repoBranch:DEFAULT:main"
    fi

    if [[ -n "$path" ]]; then
        echo "VALUE:skillsPath:SET:$path"
    else
        echo "VALUE:skillsPath:DEFAULT:skills"
    fi
}

# 4. 测试 SSH 连接
test_ssh() {
    local repo_url="$1"

    if [[ -z "$repo_url" ]]; then
        return
    fi

    # 提取 host
    local host=""
    if [[ "$repo_url" =~ ^git@([^:]+): ]]; then
        host="${BASH_REMATCH[1]}"
    elif [[ "$repo_url" =~ ^https?:// ]]; then
        echo "SSH:HTTPS"
        return
    fi

    if [[ -n "$host" ]]; then
        if ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@$host 2>&1 | grep -q "successfully authenticated"; then
            echo "SSH:OK:$host"
        else
            echo "SSH:FAIL:$host"
        fi
    fi
}

# 执行检查
check_files
check_json "$CONFIG_FILE"
check_values

repo_url=$(get_config "repoUrl" "")
test_ssh "$repo_url"

echo "CHECK_END"

# 返回状态码
if [[ -z "$repo_url" ]]; then
    exit 1
fi
exit 0