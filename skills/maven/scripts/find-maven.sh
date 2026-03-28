#!/bin/bash
# Maven 路径查找脚本
# 输出格式：MAVEN_FOUND:path  或 MAVEN_NOT_FOUND

# 注意：不使用 set -e，因为检查函数可能返回非零值表示未找到

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

OS_TYPE=$(get_os_type)
USER_HOME="$HOME"
USERNAME=$(whoami)

# 用于收集找到的路径
FOUND_PATHS=()

echo "MAVEN_SEARCH_START"

# 1. 检查已保存的配置
check_saved_config() {
    local saved_path=$(get_config "mavenPath" "")
    if [[ -n "$saved_path" ]]; then
        if validate_maven "$saved_path"; then
            mark_output "SAVED" "$saved_path"
            FOUND_PATHS+=("$saved_path")
        else
            mark_output "SAVED_INVALID" "$saved_path"
        fi
    fi
    # 不返回值，避免影响后续检查
}

# 2. 检查 PATH 环境变量
check_path_env() {
    local mvn_cmd=""
    if [[ "$OS_TYPE" == "windows" ]]; then
        mvn_cmd=$(where mvn 2>/dev/null | head -1 || echo "")
    else
        mvn_cmd=$(which mvn 2>/dev/null || echo "")
    fi

    if [[ -n "$mvn_cmd" ]]; then
        if validate_maven "$mvn_cmd"; then
            mark_output "PATH" "$mvn_cmd"
            FOUND_PATHS+=("$mvn_cmd")
        fi
    fi
}

# 3. 检查 MAVEN_HOME / M2_HOME
check_maven_home() {
    for env_var in MAVEN_HOME M2_HOME; do
        local home_path="${!env_var}"
        if [[ -n "$home_path" ]]; then
            local mvn_path=""
            if [[ "$OS_TYPE" == "windows" ]]; then
                mvn_path="$home_path/bin/mvn.cmd"
            else
                mvn_path="$home_path/bin/mvn"
            fi

            if [[ -f "$mvn_path" ]]; then
                if validate_maven "$mvn_path"; then
                    mark_output "ENV" "$mvn_path"
                    FOUND_PATHS+=("$mvn_path")
                fi
            fi
        fi
    done
}

# 4. 检查 IDEA 内置 Maven
check_idea_maven() {
    local idea_paths=()

    if [[ "$OS_TYPE" == "windows" ]]; then
        # Windows IDEA 路径 - 直接安装
        idea_paths=(
            "$LOCALAPPDATA/Programs/IntelliJ IDEA/plugins/maven/lib/maven3/bin/mvn.cmd"
            "$PROGRAMFILES/IntelliJ IDEA/plugins/maven/lib/maven3/bin/mvn.cmd"
            "$PROGRAMFILES/JetBrains/IntelliJ IDEA*/plugins/maven/lib/maven3/bin/mvn.cmd"
            "D:/servers/IntelliJ IDEA*/plugins/maven/lib/maven3/bin/mvn.cmd"
            "C:/Program Files/JetBrains/IntelliJ IDEA*/plugins/maven/lib/maven3/bin/mvn.cmd"
        )

        # JetBrains 配置目录（各种 IDEA 版本）
        for idea_version in "$LOCALAPPDATA/JetBrains/IntelliJIdea"* "$LOCALAPPDATA/JetBrains/idea"*; do
            if [[ -d "$idea_version" ]]; then
                # 直接 plugins 目录
                idea_paths+=("$idea_version/plugins/maven/lib/maven3/bin/mvn.cmd")
                # JetBrainsGateway 临时配置
                idea_paths+=("$idea_version/tmp/JetBrainsGateway/config/plugins/maven/lib/maven3/bin/mvn.cmd")
                # 其他可能的子目录
                for subdir in "$idea_version"/*; do
                    if [[ -d "$subdir" ]]; then
                        idea_paths+=("$subdir/plugins/maven/lib/maven3/bin/mvn.cmd")
                        idea_paths+=("$subdir/config/plugins/maven/lib/maven3/bin/mvn.cmd")
                    fi
                done
            fi
        done

        # Toolbox 安装
        for toolbox_path in "$LOCALAPPDATA/JetBrains/Toolbox/apps/IDEA"* "$LOCALAPPDATA/JetBrains/Toolbox/apps/idea"*; do
            if [[ -d "$toolbox_path" ]]; then
                idea_paths+=("$toolbox_path/plugins/maven/lib/maven3/bin/mvn.cmd")
            fi
        done

    elif [[ "$OS_TYPE" == "macos" ]]; then
        # macOS IDEA 路径
        idea_paths=(
            "/Applications/IntelliJ IDEA.app/Contents/plugins/maven/lib/maven3/bin/mvn"
            "/Applications/IntelliJ IDEA CE.app/Contents/plugins/maven/lib/maven3/bin/mvn"
            "$USER_HOME/Applications/IntelliJ IDEA.app/Contents/plugins/maven/lib/maven3/bin/mvn"
        )

        # JetBrains 配置目录
        for idea_version in "$USER_HOME/Library/Caches/JetBrains/IntelliJIdea"* "$USER_HOME/Library/Application Support/JetBrains/IntelliJIdea"*; do
            if [[ -d "$idea_version" ]]; then
                idea_paths+=("$idea_version/plugins/maven/lib/maven3/bin/mvn")
                idea_paths+=("$idea_version/tmp/JetBrainsGateway/config/plugins/maven/lib/maven3/bin/mvn")
            fi
        done

        # Toolbox 安装
        for toolbox_path in "$USER_HOME/Library/Caches/JetBrains/Toolbox/apps/IDEA"*; do
            if [[ -d "$toolbox_path" ]]; then
                idea_paths+=("$toolbox_path/plugins/maven/lib/maven3/bin/mvn")
            fi
        done

    else
        # Linux IDEA 路径
        idea_paths=(
            "/opt/idea/plugins/maven/lib/maven3/bin/mvn"
            "/opt/intellij-idea*/plugins/maven/lib/maven3/bin/mvn"
            "/usr/share/intellij-idea*/plugins/maven/lib/maven3/bin/mvn"
        )

        # JetBrains 配置目录
        for idea_version in "$USER_HOME/.cache/JetBrains/IntelliJIdea"* "$USER_HOME/.config/JetBrains/IntelliJIdea"* "$USER_HOME/.local/share/JetBrains/IntelliJIdea"*; do
            if [[ -d "$idea_version" ]]; then
                idea_paths+=("$idea_version/plugins/maven/lib/maven3/bin/mvn")
                idea_paths+=("$idea_version/tmp/JetBrainsGateway/config/plugins/maven/lib/maven3/bin/mvn")
            fi
        done

        # Toolbox 安装
        for toolbox_path in "$USER_HOME/.local/share/JetBrains/Toolbox/apps/IDEA"*; do
            if [[ -d "$toolbox_path" ]]; then
                idea_paths+=("$toolbox_path/plugins/maven/lib/maven3/bin/mvn")
            fi
        done
    fi

    for pattern in "${idea_paths[@]}"; do
        # 处理通配符
        for actual_path in $pattern; do
            if [[ -f "$actual_path" ]]; then
                if validate_maven "$actual_path"; then
                    mark_output "IDEA" "$actual_path"
                    FOUND_PATHS+=("$actual_path")
                fi
            fi
        done
    done
}

# 5. 检查包管理器安装
check_package_managers() {
    local pm_paths=()

    if [[ "$OS_TYPE" == "windows" ]]; then
        # Scoop
        pm_paths+=("$USER_HOME/scoop/apps/maven/current/bin/mvn.cmd")
        pm_paths+=("$USER_HOME/scoop/shims/mvn.cmd")

        # Chocolatey
        pm_paths+=("C:/ProgramData/chocolatey/bin/mvn.cmd")

    elif [[ "$OS_TYPE" == "macos" ]]; then
        # Homebrew
        pm_paths+=("/opt/homebrew/bin/mvn")
        pm_paths+=("/usr/local/bin/mvn")
        pm_paths+=("/usr/local Cellar/maven/*/bin/mvn")

    else
        # Linux
        pm_paths+=("/usr/bin/mvn")
        pm_paths+=("/usr/local/bin/mvn")

        # SDKMAN
        pm_paths+=("$USER_HOME/.sdkman/candidates/maven/current/bin/mvn")
    fi

    for pattern in "${pm_paths[@]}"; do
        for actual_path in $pattern; do
            if [[ -f "$actual_path" ]]; then
                if validate_maven "$actual_path"; then
                    mark_output "PACKAGE" "$actual_path"
                    FOUND_PATHS+=("$actual_path")
                fi
            fi
        done
    done
}

# 6. 检查常见安装目录
check_common_dirs() {
    local common_paths=()

    if [[ "$OS_TYPE" == "windows" ]]; then
        common_paths=(
            "C:/Program Files/apache-maven*/bin/mvn.cmd"
            "C:/Program Files/Maven*/bin/mvn.cmd"
            "C:/tools/maven*/bin/mvn.cmd"
            "C:/maven*/bin/mvn.cmd"
            "D:/apache-maven*/bin/mvn.cmd"
            "D:/maven*/bin/mvn.cmd"
            "D:/tools/maven*/bin/mvn.cmd"
            "$USER_HOME/apache-maven*/bin/mvn.cmd"
        )
    elif [[ "$OS_TYPE" == "macos" ]]; then
        common_paths=(
            "/opt/maven*/bin/mvn"
            "/usr/local/maven*/bin/mvn"
            "$USER_HOME/apache-maven*/bin/mvn"
            "$USER_HOME/maven*/bin/mvn"
        )
    else
        common_paths=(
            "/opt/maven*/bin/mvn"
            "/opt/apache-maven*/bin/mvn"
            "/usr/local/maven*/bin/mvn"
            "/usr/local/apache-maven*/bin/mvn"
            "$USER_HOME/apache-maven*/bin/mvn"
            "$USER_HOME/maven*/bin/mvn"
            "$USER_HOME/tools/maven*/bin/mvn"
        )
    fi

    for pattern in "${common_paths[@]}"; do
        for actual_path in $pattern; do
            if [[ -f "$actual_path" ]]; then
                if validate_maven "$actual_path"; then
                    mark_output "CUSTOM" "$actual_path"
                    FOUND_PATHS+=("$actual_path")
                fi
            fi
        done
    done
}

# 执行所有检查
check_saved_config
check_path_env
check_maven_home
check_idea_maven
check_package_managers
check_common_dirs

echo "MAVEN_SEARCH_END"

# 输出汇总
if [[ ${#FOUND_PATHS[@]} -gt 0 ]]; then
    echo "MAVEN_COUNT:${#FOUND_PATHS[@]}"
    for path in "${FOUND_PATHS[@]}"; do
        echo "MAVEN_PATH:$path"
    done
else
    echo "MAVEN_COUNT:0"
fi