#!/bin/bash
# 从当前目录向下搜索 pom.xml
# 不向上查找（工作空间边界）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
MAX_DEPTH=5  # 最大搜索深度，避免搜索整个磁盘

# 收集找到的 pom.xml
POM_FILES=()
POM_ROOTS=()  # 多模块项目根目录

echo "POM_SEARCH_START"
echo "PROJECT_DIR:$PROJECT_DIR"

# 递归搜索 pom.xml
search_pom_files() {
    local dir="$1"
    local depth="$2"

    if [[ $depth -gt $MAX_DEPTH ]]; then
        return
    fi

    # 检查当前目录是否有 pom.xml
    local pom_file="$dir/pom.xml"
    if [[ -f "$pom_file" ]]; then
        # 检查是否是多模块项目（有 <modules> 标签）
        if grep -q "<modules>" "$pom_file" 2>/dev/null; then
            POM_ROOTS+=("$dir")
        fi
        POM_FILES+=("$pom_file")
    fi

    # 搜索子目录（排除隐藏目录和常见的非源码目录）
    for subdir in "$dir"/*/; do
        # 跳过不存在或隐藏目录
        if [[ ! -d "$subdir" ]]; then
            continue
        fi
        local subdir_name=$(basename "$subdir")
        # 跳过隐藏目录和常见的排除目录
        case "$subdir_name" in
            .*|target|node_modules|.git|.idea|.claude|bin|build|dist|out)
                continue;;
        esac
        search_pom_files "$subdir" $((depth + 1))
    done
}

# 从项目目录开始搜索
search_pom_files "$PROJECT_DIR" 0

echo "POM_SEARCH_END"

# 收集多模块项目的子模块目录（用于过滤）
CHILD_DIRS=()
for root in "${POM_ROOTS[@]}"; do
    clean_root="${root//\/\//\/}"
    clean_root="${clean_root%/}"
    # 从 pom.xml 中提取模块名
    modules=$(grep '<module>' "$clean_root/pom.xml" 2>/dev/null | sed 's/[[:space:]]*<module>\([^<]*\)<\/module>[[:space:]]*/\1/')
    for mod in $modules; do
        CHILD_DIRS+=("$clean_root/$mod")
    done
done

# 过滤 pom.xml：如果 pom 所在目录是多模块项目的子模块，则跳过
FILTERED_POMS=()
for pom in "${POM_FILES[@]}"; do
    clean_path="${pom//\/\//\/}"
    pom_dir=$(dirname "$clean_path")
    # 检查是否是子模块目录
    is_child=0
    for child_dir in "${CHILD_DIRS[@]}"; do
        if [[ "$pom_dir" == "$child_dir" ]]; then
            is_child=1
            break
        fi
    done
    if [[ $is_child -eq 0 ]]; then
        FILTERED_POMS+=("$clean_path")
    fi
done

# 输出结果
echo "POM_COUNT:${#FILTERED_POMS[@]}"

for pom in "${FILTERED_POMS[@]}"; do
    echo "POM_PATH:$pom"
done

# 输出多模块项目根目录
for root in "${POM_ROOTS[@]}"; do
    # 清理路径中的双斜杠和尾部斜杠
    clean_root="${root//\/\//\/}"
    clean_root="${clean_root%/}"
    echo "POM_ROOT:$clean_root"
    # 从 pom.xml 中提取模块名（使用 sed，避免 grep -P 兼容性问题）
    modules=$(grep '<module>' "$clean_root/pom.xml" 2>/dev/null | sed 's/[[:space:]]*<module>\([^<]*\)<\/module>[[:space:]]*/\1/' | tr '\n' ',' | sed 's/,$//')
    if [[ -n "$modules" ]]; then
        echo "POM_MODULES:$clean_root:$modules"
    fi
done