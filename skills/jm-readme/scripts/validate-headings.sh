#!/bin/bash
# 验证 Markdown 文档标题规则
# 用法: bash 4-validate-headings.sh [目录路径]
#   无参数：验证项目所有 README.md 和 docs/*.md 文件
#   有参数：验证指定目录下的文档

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 查找项目根目录
find_project_root() {
    local dir="$(pwd)"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/pom.xml" ]] && ! grep -q "<parent>" "$dir/pom.xml" 2>/dev/null; then
            echo "$dir"
            return
        fi
        dir="$(dirname "$dir")"
    done
    echo "$(pwd)"
}

PROJECT_ROOT=$(find_project_root)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 错误计数
ERROR_COUNT=0
WARNING_COUNT=0

# 验证单个文件
validate_file() {
    local file="$1"
    local errors=0
    local warnings=0
    local h1_count=0
    local prev_level=0
    local prev_number=""
    local line_num=0
    local in_code_block=0

    echo -e "\n${YELLOW}检查: $file${NC}"

    # 读取文件并逐行分析
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))

        # 检测代码块开始/结束（```）
        if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then
            in_code_block=$((1 - in_code_block))
            continue
        fi

        # 跳过代码块内的内容
        if [[ $in_code_block -eq 1 ]]; then
            continue
        fi

        # 提取标题（以 # 开头，后跟空格）
        if [[ "$line" =~ ^(#+)[[:space:]]+(.*) ]]; then
            local hashes="${BASH_REMATCH[1]}"
            local title="${BASH_REMATCH[2]}"
            local level=${#hashes}

            # 提取序号
            local number=""

            case $level in
                2)
                    # 二级标题：匹配 "数字." 格式
                    if [[ "$title" =~ ^([0-9]+)\.[[:space:]] ]]; then
                        number="${BASH_REMATCH[1]}"
                    fi

                    if [[ -z "$number" ]]; then
                        echo -e "  ${RED}✗ 行 $line_num: 二级标题缺少序号${NC}"
                        echo "    标题: $title"
                        echo "    正确格式: ## 1. 标题名"
                        errors=$((errors + 1))
                    fi
                    prev_level=$level
                    prev_number="$number"
                    ;;

                3)
                    # 三级标题：匹配 "数字.数字 " 格式
                    if [[ "$title" =~ ^([0-9]+\.[0-9]+)[[:space:]] ]]; then
                        number="${BASH_REMATCH[1]}"
                    fi

                    if [[ -z "$number" ]]; then
                        echo -e "  ${RED}✗ 行 $line_num: 三级标题缺少序号或格式错误${NC}"
                        echo "    标题: $title"
                        echo "    正确格式: ### 1.1 标题名（两段数字，无末尾点）"
                        errors=$((errors + 1))
                    fi

                    # 检查层次关系
                    if [[ -n "$prev_number" && "$prev_level" -eq 2 ]]; then
                        local parent_num=$(echo "$number" | cut -d'.' -f1)
                        if [[ "$parent_num" != "$prev_number" ]]; then
                            echo -e "  ${YELLOW}⚠ 行 $line_num: 三级标题序号与上级不匹配${NC}"
                            echo "    标题: $title"
                            echo "    当前序号: $number"
                            echo "    上级序号: $prev_number"
                            echo "    建议: 使用 ### $prev_number.1 或类似序号"
                            warnings=$((warnings + 1))
                        fi
                    fi
                    prev_level=$level
                    prev_number="$number"
                    ;;

                4)
                    # 四级标题：匹配 "数字.数字.数字 " 格式
                    if [[ "$title" =~ ^([0-9]+\.[0-9]+\.[0-9]+)[[:space:]] ]]; then
                        number="${BASH_REMATCH[1]}"
                    fi

                    if [[ -z "$number" ]]; then
                        echo -e "  ${RED}✗ 行 $line_num: 四级标题缺少序号或格式错误${NC}"
                        echo "    标题: $title"
                        echo "    正确格式: #### 1.1.1 标题名（三段数字）"
                        errors=$((errors + 1))
                    fi
                    prev_level=$level
                    prev_number="$number"
                    ;;

                1)
                    # 一级标题：只能有一个
                    h1_count=$((h1_count + 1))
                    if [[ $h1_count -gt 1 ]]; then
                        echo -e "  ${RED}✗ 行 $line_num: 一级标题重复（全文只能有一个）${NC}"
                        echo "    标题: $title"
                        errors=$((errors + 1))
                    fi
                    ;;
            esac
        fi
    done < "$file"

    # 检查一级标题
    if [[ $h1_count -eq 0 ]]; then
        echo -e "  ${RED}✗ 缺少一级标题${NC}"
        errors=$((errors + 1))
    fi

    # 输出结果
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        echo -e "  ${GREEN}✓ 标题格式正确${NC}"
    else
        if [[ $errors -gt 0 ]]; then
            echo -e "  ${RED}发现 $errors 个错误${NC}"
        fi
        if [[ $warnings -gt 0 ]]; then
            echo -e "  ${YELLOW}发现 $warnings 个警告${NC}"
        fi
    fi

    ERROR_COUNT=$((ERROR_COUNT + errors))
    WARNING_COUNT=$((WARNING_COUNT + warnings))

    return $errors
}

# 主函数
main() {
    echo "============================================================"
    echo "验证 Markdown 文档标题规则"
    echo "============================================================"
    echo ""

    local files=()

    if [[ -n "$1" ]]; then
        # 验证指定目录
        local target_dir="$1"
        if [[ -f "$target_dir" ]]; then
            files+=("$target_dir")
        elif [[ -d "$target_dir" ]]; then
            # 收集 README.md
            if [[ -f "$target_dir/README.md" ]]; then
                files+=("$target_dir/README.md")
            fi
            # 收集 docs/*.md
            while IFS= read -r -d '' file; do
                files+=("$file")
            done < <(find "$target_dir/docs" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null | sort -z)
        else
            echo -e "${RED}错误: 路径不存在 - $target_dir${NC}"
            exit 1
        fi
    else
        # 验证项目所有文档
        # 根目录 README.md
        if [[ -f "$PROJECT_ROOT/README.md" ]]; then
            files+=("$PROJECT_ROOT/README.md")
        fi
        # 根目录 docs/*.md
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$PROJECT_ROOT/docs" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null | sort -z)

        # 各模块的 README.md 和 docs/*.md
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$PROJECT_ROOT" -path "*/Writerside" -prune -o \( -name "README.md" -o -path "*/docs/*.md" \) -type f -print0 2>/dev/null | sort -z)
    fi

    echo "待检查文件数: ${#files[@]}"

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}未找到需要检查的文件${NC}"
        exit 0
    fi

    local failed_files=()

    for file in "${files[@]}"; do
        if ! validate_file "$file"; then
            failed_files+=("$file")
        fi
    done

    echo ""
    echo "============================================================"
    echo "验证结果"
    echo "============================================================"
    echo -e "检查文件: ${#files[@]} 个"
    echo -e "错误总数: $ERROR_COUNT"
    echo -e "警告总数: $WARNING_COUNT"

    if [[ ${#failed_files[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}以下文件需要修复:${NC}"
        for f in "${failed_files[@]}"; do
            echo "  - $f"
        done
        echo ""
        echo "修复建议:"
        echo "  1. 一级标题: # 模块名（不加编号，全文唯一）"
        echo "  2. 二级标题: ## 1. 标题名（数字 + 点 + 空格）"
        echo "  3. 三级标题: ### 1.1 标题名（数字.数字 + 空格，无末尾点）"
        echo "  4. 四级标题: #### 1.1.1 标题名（数字.数字.数字 + 空格）"
        exit 1
    else
        echo -e "${GREEN}所有文件标题格式正确${NC}"
        exit 0
    fi
}

main "$@"