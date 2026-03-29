#!/bin/bash
# 搜索 skill（支持本地仓库索引和 GitHub 搜索）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

SEARCH_TERM="$1"

if [[ -z "$SEARCH_TERM" ]]; then
    echo "ERROR: 未提供搜索关键词"
    echo "USAGE: search <keyword>"
    exit 1
fi

echo "SEARCH_START"
echo "SEARCH_TERM:$SEARCH_TERM"

# 设置代理
setup_proxy

# 1. 搜索本地主仓库
search_local_repo() {
    if [[ -d "$MIRROR_DIR/.git" ]]; then
        local skills_path=$(get_skills_path)
        local skills_dir="$MIRROR_DIR/$skills_path"
        if [[ -d "$skills_dir" ]]; then
            for skill_dir in "$skills_dir"/*/; do
                if [[ -d "$skill_dir" ]]; then
                    local name=$(basename "$skill_dir")
                    if [[ "$name" == "skill-manager" ]]; then
                        continue
                    fi
                    local skill_md="$skill_dir/SKILL.md"
                    if [[ -f "$skill_md" ]]; then
                        # 检查名称或描述是否匹配
                        if grep -qi "$SEARCH_TERM" "$skill_md" 2>/dev/null || echo "$name" | grep -qi "$SEARCH_TERM"; then
                            echo "SEARCH_RESULT:local:$name"
                        fi
                    fi
                fi
            done
        fi
    fi
}

# 2. 搜索内置仓库索引
search_index() {
    local index_file="$(dirname "$SCRIPT_DIR")/references/repos-index.json"
    if [[ -f "$index_file" ]]; then
        # 简单搜索：匹配名称或描述
        grep -i "$SEARCH_TERM" "$index_file" 2>/dev/null | grep '"name"' | while read line; do
            local name=$(echo "$line" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            local url=$(grep -A5 "\"name\"[[:space:]]*:[[:space:]]*\"$name\"" "$index_file" | grep '"url"' | sed 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            echo "SEARCH_RESULT:index:$name|$url"
        done
    fi
}

# 3. 搜索 GitHub（如果可用）
search_github() {
    if command -v curl &>/dev/null; then
        echo "SEARCH_GITHUB_START"
        local api_url="https://api.github.com/search/repositories?q=claude-code-skill+$SEARCH_TERM&per_page=5"
        local result=$(curl -s "$api_url" 2>/dev/null || echo '{"items":[]}')

        echo "$result" | grep -o '"full_name"[^,]*' | head -5 | while read line; do
            local full_name=$(echo "$line" | sed 's/.*"full_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [[ -n "$full_name" ]]; then
                echo "SEARCH_RESULT:github:$full_name|https://github.com/$full_name"
            fi
        done
        echo "SEARCH_GITHUB_END"
    fi
}

echo "搜索主仓库..."
search_local_repo

echo "搜索仓库索引..."
search_index

echo "搜索 GitHub..."
search_github

echo "SEARCH_END"