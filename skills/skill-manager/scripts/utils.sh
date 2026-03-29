#!/bin/bash
# 通用工具函数

set -e

# 镜像仓库路径
MIRROR_DIR="$HOME/.skill-manager/repo"

# 配置默认值
DEFAULT_REPO_BRANCH="main"
DEFAULT_SKILLS_PATH="skills"

# 配置文件路径
CONFIG_FILE="$PROJECT_DIR/.claude/skills/skill-manager/config/config.json"

# 读取配置
get_config() {
    local key="$1"
    local default="$2"
    local value=""

    # 从 skill-manager/config/config.json 读取
    if [[ -f "$CONFIG_FILE" ]]; then
        value=$(cat "$CONFIG_FILE" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" 2>/dev/null | head -1 | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//')
    fi

    # 返回值或默认值
    echo "${value:-$default}"
}

# 获取仓库 URL（必填）
get_repo_url() {
    local url=$(get_config "repoUrl" "")
    if [[ -z "$url" ]]; then
        echo "========================================" >&2
        echo "错误: 未配置 skill 仓库地址" >&2
        echo "========================================" >&2
        echo "" >&2
        echo "请运行配置初始化脚本:" >&2
        echo "" >&2
        echo "  bash scripts/init-config.sh repoUrl=git@github.com:your-username/skills.git" >&2
        echo "" >&2
        echo "或手动编辑配置文件:" >&2
        echo "  .claude/skills/skill-manager/config/config.json" >&2
        echo "========================================" >&2
        exit 1
    fi
    echo "$url"
}

# 获取分支名（可选，默认 main）
get_repo_branch() {
    get_config "repoBranch" "$DEFAULT_REPO_BRANCH"
}

# 获取 skills 路径（可选，默认 skills）
get_skills_path() {
    get_config "skillsPath" "$DEFAULT_SKILLS_PATH"
}

# 检查镜像仓库是否存在
check_mirror() {
    if [[ ! -d "$MIRROR_DIR/.git" ]]; then
        echo "错误: 镜像仓库不存在" >&2
        echo "请先执行: /skill-manager init" >&2
        exit 1
    fi
}

# 列出镜像仓库中的 skills（排除 skill-manager）
list_remote_skills() {
    local skills_path=$(get_skills_path)
    local skills_dir="$MIRROR_DIR/$skills_path"

    if [[ -d "$skills_dir" ]]; then
        find "$skills_dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort | grep -v "^skill-manager$"
    fi
}

# 列出本地项目的 skills（排除 skill-manager）
list_local_skills() {
    local skills_dir="$PROJECT_DIR/.claude/skills"

    if [[ -d "$skills_dir" ]]; then
        find "$skills_dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort | grep -v "^skill-manager$"
    fi
}

# 显示当前配置
show_config() {
    echo "当前配置:"
    echo "  仓库地址: $(get_repo_url)"
    echo "  分支: $(get_repo_branch)"
    echo "  Skills 路径: $(get_skills_path)"
    echo "  镜像目录: $MIRROR_DIR"
}

# 设置代理环境变量
setup_proxy() {
    local proxy=$(get_config "proxy" "")
    if [[ -n "$proxy" ]]; then
        export HTTP_PROXY="$proxy"
        export HTTPS_PROXY="$proxy"
        export http_proxy="$proxy"
        export https_proxy="$proxy"
        echo "PROXY_SET:$proxy"
    fi
}