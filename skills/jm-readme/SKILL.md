---
name: jm-readme
description: |
  为 Java Maven 模块生成结构化 README 文档。触发场景：用户说"生成文档"、"写 README"、"文档化这个模块"、"更新文档"、"/readme"；或用户想了解模块结构、想为新模块添加文档、想更新现有文档、想检查文档标题格式。支持单模块、批量生成（--all）、根目录（--root）、验证（--validate）四种模式。当用户提到 Maven 模块的文档相关工作时，优先使用此 skill。
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
---

# /readme — Java 模块文档生成器

**参数**：`$ARGUMENTS`

| 参数 | 说明 |
|------|------|
| `--all` | 并发生成所有叶子模块文档 |
| `--root` | 仅生成项目根 README.md |
| `--validate` | 验证所有文档标题格式 |
| `模块路径` | 指定单个模块，如 `auth/auth-core` |
| 留空 | 使用当前目录 |

---

## 工作流程

### 步骤 1：识别模式

```bash
# 判断是否为根目录
test -f pom.xml && ! grep -q "<parent>" pom.xml && echo "ROOT"

# 判断是否为父模块
grep -q "<packaging>pom</packaging>" pom.xml && echo "PARENT"
```

### 步骤 2：清理旧文档

| 模式 | 清理范围 |
|------|----------|
| 根目录 | 仅 `README.md` |
| 父模块 | 仅 `README.md` |
| 普通模块 | `README.md` + `docs/` 目录 |

### 步骤 3：分析模块

| 分析项 | 来源 | 用途 |
|--------|------|------|
| 基本信息 | pom.xml | 名称、版本、依赖 |
| 包结构 | src/main/java | 核心类识别 |
| 自动配置 | *AutoConfiguration.java | Spring Boot 集成 |
| 数据模型 | Entity/*.sql/*.lua | 表结构、缓存 Key |

### 步骤 4：生成文档

| 模块类型 | 判断条件 | 生成文档 |
|----------|----------|----------|
| **core** | 无 Spring 依赖 | README + concepts + data |
| **impl** | 依赖 core，有 Repository | README + flow + spring-boot + data + test |
| **web** | 依赖 spring-boot-starter-web | README + spring-boot + test |
| **parent** | packaging=pom | 仅 README |
| **root** | 项目根目录 | 仅 README |

---

## 标题验证

验证已生成文档的标题格式是否符合 Writerside 兼容规则。

### 验证命令

```bash
# 验证所有文档
/readme --validate

# 验证指定模块
bash .claude/skills/readme/scripts/validate-headings.sh auth/auth-sk
```

### 验证规则

| 标题级别 | 格式要求 | 示例 |
|----------|----------|------|
| 一级 | 模块名，不加编号，全文唯一 | `# auth-core` |
| 二级 | 数字 + 点 + 空格 | `## 1. 快速开始` |
| 三级 | 两段数字，无末尾点 | `### 1.1 依赖` |
| 四级 | 三段数字，无末尾点 | `#### 1.1.1 说明` |

### 为什么三级标题不加末尾点？

Writerside 根据标题生成元素 ID。如果二级是 `## 3. 场景`，三级是 `### 3.1. 场景`，规范化后 ID 可能冲突。去掉末尾点后：
- 二级 `## 3. 场景` → ID `3`
- 三级 `### 3.1 场景` → ID `3-1`

### 验证错误示例

```
✗ 行 70: 二级标题缺少序号
    标题: ## 快速开始
    正确格式: ## 1. 快速开始

✗ 行 74: 三级标题缺少序号或格式错误
    标题: ### 1.1. 依赖
    正确格式: ### 1.1 依赖（两段数字，无末尾点）
```

---

## 模板

详细模板见 `references/templates.md`，包含：
- README.md（普通模块 / 根目录 / 父模块）
- docs/concepts.md
- docs/flow.md
- docs/spring-boot.md
- docs/data.md
- docs/test.md

---

## 注意事项

1. **信息来源**：所有内容必须来自实际代码，不臆造
2. **代码位置**：流程文档需标注 `类名.java:行号`
3. **标题编号**：二级及以下使用层级编号，确保全局唯一