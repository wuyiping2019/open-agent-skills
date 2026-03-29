#!/bin/bash
# 列出远程仓库中可用的 skills
# Usage: bash list-remote-skills.sh <repo_url|repo_name>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

TEMP_REPO_DIR="$HOME/.skill-manager/temp-repos"

REPO_SOURCE="$1"

if [[ -z "$REPO_SOURCE" ]]; then
    echo "ERROR: 未指定仓库"
    echo "USAGE: list-remote-skills <repo_url|repo_name>"
    exit 1
fi

echo "REMOTE_SKILLS_START"
echo "REPO_SOURCE:$REPO_SOURCE"

# 设置代理
setup_proxy

# 解析仓库 URL（同 load.sh）
resolve_repo_url() {
    local source="$1"

    if [[ "$source" =~ ^https?:// || "$source" =~ ^git@ ]]; then
        echo "$source"
        return 0
    fi

    if [[ "$source" =~ ^[^/]+/[^/]+$ ]]; then
        echo "https://github.com/$source"
        return 0
    fi

    local index_file="$(dirname "$SCRIPT_DIR")/references/repos-index.json"
    if [[ -f "$index_file" ]]; then
        local url=$(grep -A5 "\"name\"[[:space:]]*:[[:space:]]*\"$source\"" "$index_file" | grep '"url"' | sed 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [[ -n "$url" ]]; then
            echo "$url"
            return 0
        fi
    fi

    echo "ERROR: 无法解析仓库来源: $source" >&2
    return 1
}

REPO_URL=$(resolve_repo_url "$REPO_SOURCE") || {
    echo "ERROR: 无法解析仓库来源"
    echo "REMOTE_SKILLS_END"
    exit 1
}

echo "REPO_URL:$REPO_URL"

# 确定仓库目录
if [[ "$REPO_URL" == "$(get_config 'repoUrl' '')" ]]; then
    REPO_DIR="$MIRROR_DIR"
    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "ERROR: 主仓库镜像未初始化"
        echo "REMOTE_SKILLS_END"
        exit 1
    fi
    cd "$REPO_DIR" && git pull --quiet 2>/dev/null || true
else
    repo_name=$(echo "$REPO_URL" | sed 's/.*github.com[/:]//' | sed 's/\.git$//' | tr '/' '_')
    REPO_DIR="$TEMP_REPO_DIR/$repo_name"

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "CLONE_REPO:$REPO_URL"
        mkdir -p "$REPO_DIR"
        git clone --depth 1 "$REPO_URL" "$REPO_DIR" 2>&1 || {
            echo "ERROR: 克隆仓库失败"
            echo "REMOTE_SKILLS_END"
            exit 1
        }
    else
        cd "$REPO_DIR" && git pull --quiet 2>/dev/null || true
    fi
fi

echo "REPO_DIR:$REPO_DIR"

# 搜索 skills 目录
find_skills_dirs() {
    local repo_dir="$1"

    # 尝试常见路径
    local search_dirs=(
        "$repo_dir/skills"
        "$repo_dir/.claude/skills"
    )

    for search_dir in "${search_dirs[@]}"; do
        if [[ -d "$search_dir" ]]; then
            for skill_dir in "$search_dir"/*/; do
                if [[ -d "$skill_dir" ]]; then
                    local name=$(basename "$skill_dir")
                    local skill_md="$skill_dir/SKILL.md"
                    if [[ -f "$skill_md" ]]; then
                        # 提取 description
                        local desc=$(grep -A1 "^description:" "$skill_md" 2>/dev/null | head -2 | sed 's/description:[[:space:]]*//' | sed 's/^[[:space:]]*//' | tr '\n' ' ' | sed 's/  / /g' | cut -c1-60)
                        if [[ -z "$desc" ]]; then
                            desc=$(grep "^# " "$skill_md" | head -1 | sed 's/^# //')
                        fi
                        echo "REMOTE_SKILL:$name|$desc"
                    fi
                fi
            done
            return 0
        fi
    done

    # 遍历查找
    for dir in "$repo_dir"/*/; do
        if [[ -d "$dir/skills" ]]; then
            for skill_dir in "$dir/skills"/*/; do
                if [[ -d "$skill_dir" ]]; then
                    local name=$(basename "$skill_dir")
                    local skill_md="$skill_dir/SKILL.md"
                    if [[ -f "$skill_md" ]]; then
                        local desc=$(grep -A1 "^description:" "$skill_md" 2>/dev/null | head -2 | sed 's/description:[[:space:]]*//' | sed 's/^[[:space:]]*//' | tr '\n' ' ' | sed 's/  / /g' | cut -c1-60)
                        echo "REMOTE_SKILL:$name|$desc"
                    fi
                fi
            done
        fi
    done
}

echo "列出可用 skills..."
find_skills_dirs "$REPO_DIR"

echo "REMOTE_SKILLS_END"