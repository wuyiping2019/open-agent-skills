#!/bin/bash
# 从任意仓库加载 skill 到项目空间
# Usage: bash load.sh <repo_url>|<repo_name> <skill_name> [--temp]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# 临时仓库目录
TEMP_REPO_DIR="$HOME/.skill-manager/temp-repos"

# 参数解析
REPO_SOURCE="$1"
SKILL_NAME="$2"
IS_TEMP="$3"

if [[ -z "$REPO_SOURCE" ]]; then
    echo "ERROR: 未指定仓库来源"
    echo "USAGE: load <repo_url|repo_name> <skill_name> [--temp]"
    exit 1
fi

if [[ -z "$SKILL_NAME" ]]; then
    echo "ERROR: 未指定 skill 名称"
    echo "USAGE: load <repo_url|repo_name> <skill_name> [--temp]"
    exit 1
fi

echo "LOAD_START"
echo "REPO_SOURCE:$REPO_SOURCE"
echo "SKILL_NAME:$SKILL_NAME"

# 设置代理
setup_proxy

# 解析仓库来源（URL 或名称）
resolve_repo_url() {
    local source="$1"

    # 如果是完整 URL，直接返回
    if [[ "$source" =~ ^https?:// || "$source" =~ ^git@ ]]; then
        echo "$source"
        return 0
    fi

    # 如果是 GitHub 简写（owner/repo），补全为完整 URL
    if [[ "$source" =~ ^[^/]+/[^/]+$ ]]; then
        echo "https://github.com/$source"
        return 0
    fi

    # 从内置索引查找
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

# 检查是否是主仓库
is_main_repo() {
    local url="$1"
    local main_url=$(get_config "repoUrl" "")

    if [[ -n "$main_url" ]]; then
        # 规范化 URL 比较
        local norm_url="${url%.git}"
        local norm_main="${main_url%.git}"
        if [[ "$norm_url" == "$norm_main" ]]; then
            return 0
        fi
    fi
    return 1
}

# 确定仓库目录
get_repo_dir() {
    local url="$1"

    if is_main_repo "$url"; then
        # 主仓库使用镜像目录
        echo "$MIRROR_DIR"
    else
        # 其他仓库使用临时目录
        local repo_name=$(echo "$url" | sed 's/.*github.com[/:]//' | sed 's/\.git$//' | tr '/' '_')
        echo "$TEMP_REPO_DIR/$repo_name"
    fi
}

# 克隆或更新仓库
clone_or_update_repo() {
    local url="$1"
    local repo_dir="$2"

    if [[ -d "$repo_dir/.git" ]]; then
        echo "UPDATE_REPO:$repo_dir"
        cd "$repo_dir"
        git pull --quiet 2>/dev/null || true
    else
        echo "CLONE_REPO:$url"
        mkdir -p "$repo_dir"
        git clone --depth 1 "$url" "$repo_dir" 2>&1 || {
            echo "ERROR: 克隆仓库失败: $url"
            exit 1
        }
    fi
}

# 查找 skill 目录
find_skill_dir() {
    local repo_dir="$1"
    local skill_name="$2"

    # 尝试常见路径
    local paths=(
        "skills/$skill_name"
        ".claude/skills/$skill_name"
        "$skill_name"
    )

    for path in "${paths[@]}"; do
        if [[ -d "$repo_dir/$path" ]]; then
            echo "$repo_dir/$path"
            return 0
        fi
    done

    # 遍历查找
    for dir in "$repo_dir"/*/; do
        if [[ -d "$dir" ]]; then
            local name=$(basename "$dir")
            if [[ "$name" == "$skill_name" ]]; then
                echo "$dir"
                return 0
            fi
            # 检查 skills 子目录
            if [[ -d "$dir/skills/$skill_name" ]]; then
                echo "$dir/skills/$skill_name"
                return 0
            fi
        fi
    done

    return 1
}

# 解析仓库 URL
REPO_URL=$(resolve_repo_url "$REPO_SOURCE") || {
    echo "ERROR: 无法解析仓库来源"
    echo "LOAD_END"
    exit 1
}

echo "REPO_URL:$REPO_URL"

# 如果是主仓库，确保镜像已初始化
if is_main_repo "$REPO_URL"; then
    if [[ ! -d "$MIRROR_DIR/.git" ]]; then
        echo "ERROR: 主仓库镜像未初始化"
        echo "请先执行: /skill-manager init"
        echo "LOAD_END"
        exit 1
    fi
    cd "$MIRROR_DIR"
    git pull --quiet 2>/dev/null || true
    REPO_DIR="$MIRROR_DIR"
else
    # 临时仓库
    REPO_DIR=$(get_repo_dir "$REPO_URL")
    clone_or_update_repo "$REPO_URL" "$REPO_DIR"
fi

echo "REPO_DIR:$REPO_DIR"

# 查找 skill
SKILL_DIR=$(find_skill_dir "$REPO_DIR" "$SKILL_NAME") || {
    echo "ERROR: skill '$SKILL_NAME' 不存在于仓库中"
    echo "提示: 请检查 skill 名称是否正确"
    echo "LOAD_END"
    exit 1
}

echo "SKILL_DIR:$SKILL_DIR"

# 复制到项目空间
LOCAL_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
mkdir -p "$LOCAL_SKILLS_DIR"

# 检查是否已存在
if [[ -d "$LOCAL_SKILLS_DIR/$SKILL_NAME" ]]; then
    echo "WARN: skill '$SKILL_NAME' 已存在于项目空间"
    echo "提示: 使用 '/skill-manager status' 查看状态"
fi

# 复制 skill（排除 config 目录中的本地配置）
cp -r "$SKILL_DIR" "$LOCAL_SKILLS_DIR/"

# 清理可能存在的本地配置
if [[ -d "$LOCAL_SKILLS_DIR/$SKILL_NAME/config" ]]; then
    # 保留 config.example.json，删除 config.json
    rm -f "$LOCAL_SKILLS_DIR/$SKILL_NAME/config/config.json" 2>/dev/null || true
    rm -f "$LOCAL_SKILLS_DIR/$SKILL_NAME/config/config.local.json" 2>/dev/null || true
fi

echo "LOAD_SUCCESS:$SKILL_NAME"

# 如果是临时仓库且没有 --temp 标记，提示用户是否添加为常用仓库
if ! is_main_repo "$REPO_URL" && [[ "$IS_TEMP" != "--temp" ]]; then
    echo "TEMP_REPO:$REPO_URL"
    echo "提示: 此 skill 来自临时仓库"
fi

echo "LOAD_END"