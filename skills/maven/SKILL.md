---
name: maven
description: |
  执行 Maven 构建命令，自动查找并验证 Maven 安装路径。

  **何时使用此 skill（必须触发）**：
  - 用户提到 Maven、mvn、pom.xml
  - 用户说"编译项目"、"打包"、"运行测试"、"构建"
  - 用户提到依赖问题、dependency、JAR/WAR
  - 用户请求 clean install 或任何 mvn 命令

  即使用户没有明确说"Maven"，只要是 Java 项目构建相关请求，就应该使用此 skill。

  支持跨平台（Windows/macOS/Linux），自动查找 IDEA 内置 Maven、包管理器安装、常见安装目录。

user-invocable: true
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# /maven — Maven 构建命令执行器

自动查找 Maven 并执行构建命令。

**参数**：`$ARGUMENTS`（如 `clean install` 或 `compile`）

---

## 执行流程

### 1. 查找并确定 Maven 路径

```bash
export PROJECT_DIR="<当前项目路径>"
bash <skill-dir>/scripts/find-maven.sh
```

解析输出：
- `MAVEN_COUNT:N` — 找到的路径数量
- `MAVEN_PATH:path` — 路径列表
- `MAVEN_SAVED:path` — 已保存的路径（优先）

**路径选择逻辑**：

| 找到数量 | 操作 |
|---------|------|
| 0 | AskUserQuestion 一次性提供：选项 1 "我还没有安装 Maven"（显示安装指引），选项 2 "我知道路径"（提示在 Other 输入）。用户可直接在 Other 输入路径，或选择安装指引 |
| 1 | AskUserQuestion 确认：显示路径来源和版本，选项为"使用此路径"或"输入其他路径" |
| 多个 | AskUserQuestion 选择：每个选项显示来源标签（IDEA/PATH/SAVED/PACKAGE），并增加"输入其他路径"选项 |

**找到 0 个路径时的 AskUserQuestion 格式**（仅此一次交互）：

```
Question: 未找到 Maven 安装。请在下方 'Other' 中输入 mvn.cmd 完整路径，或选择：
Options:
  1. "我还没有安装 Maven" — description: "获取 Maven 下载和安装指引"
  2. "我知道路径" — description: "在下方 Other 输入框中输入完整路径，如 C:/apache-maven-3.9.9/bin/mvn.cmd"
```

**找到 1 个或多个路径，用户选择"输入其他路径"时**：

使用 AskUserQuestion（不是纯文字提示）：

```
Question: 请在下方 'Other' 中输入 Maven 的完整路径（mvn.cmd 或 mvn）：
Options:
  1. "示例路径" — description: "Windows: C:/apache-maven-3.9.9/bin/mvn.cmd，macOS/Linux: /opt/maven/bin/mvn"
```

用户直接在 Other 输入框中输入路径即可。

**处理逻辑**：
- 用户在 Other 中直接输入路径 → 验证并使用
- 选择"我还没有安装 Maven" → 输出安装指引并结束
- 选择"我知道路径" → 等待用户在 Other 中输入

### 2. 验证路径

```bash
bash <skill-dir>/scripts/validate-maven.sh "<选定的路径>"
```

输出：
- `MAVEN_VALID:yes/no` — 是否有效
- `MAVEN_VERSION:...` — 版本（如 Apache Maven 3.9.9）
- `MAVEN_JAVA:...` — Java 版本

验证失败时，告知用户错误原因并重新询问路径。

### 3. 保存配置并验证

**每次确定新路径后都必须保存**，以便下次优先使用：

```bash
bash <skill-dir>/scripts/save-config.sh "<路径>"
```

此脚本会：
1. 验证路径有效性
2. 写入 `config/config.json` 的 `mavenPath` 字段
3. 输出 `MAVEN_CONFIG_SAVED:<路径>` 表示成功

### 4. 查找 pom.xml

在执行 Maven 命令前，需要确认项目位置：

```bash
export PROJECT_DIR="<当前工作目录>"
bash <skill-dir>/scripts/find-pom.sh
```

脚本从当前目录**向下搜索**子目录中的 pom.xml（不向上查找，工作空间边界）。

解析输出：
- `POM_COUNT:N` — 找到的 pom.xml 数量
- `POM_PATH:path` — pom.xml 路径列表
- `POM_ROOT:path` — 多模块项目根目录
- `POM_MODULES:root:module1,module2` — 多模块项目的子模块列表

**处理逻辑**：

| 场景 | 处理 |
|-----|-----|
| POM_COUNT=0 | 输出错误"当前工作空间不是 Maven 项目"，结束 |
| POM_COUNT=1 | 直接使用该 pom.xml 所在目录执行 |
| POM_COUNT>1 | AskUserQuestion：列出所有 pom.xml 的相对路径，让用户选择 |

**多个 pom.xml 时的 AskUserQuestion 格式**：

```
Question: 当前工作空间包含多个 Maven 项目，请选择要构建的项目：
Options:
  1. "module-a/pom.xml" — description: "相对路径"
  2. "module-b/pom.xml" — description: "相对路径"
  ...
```

### 5. 多模块项目处理

如果选中的 pom.xml 是多模块项目（有 `<modules>` 标签），需进一步选择：

```bash
# 从输出中提取模块列表
POM_MODULES=$(grep "POM_MODULES:" ...)
```

**AskUserQuestion 格式**：

```
Question: 这是一个多模块项目，请选择要构建的模块（默认会构建依赖模块 -am）：
Options:
  1. "全部构建" — description: "在根目录执行 mvn clean install"
  2. "module-name" — description: "仅构建此模块及其依赖"
  ...
```

选择单个模块后，执行命令自动添加 `-pl <module> -am` 参数。

### 6. 执行 Maven 命令

```bash
export PROJECT_DIR="<包含 pom.xml 的目录>"
bash <skill-dir>/scripts/exec-maven.sh "<Maven路径>" $ARGUMENTS
```

**重要**：`$ARGUMENTS` 不加引号，确保 `clean install -DskipTests` 等多参数正确传递为独立参数。

---

## Maven 查找优先级

脚本按此顺序查找：

1. **已保存配置** — `config/config.json` 中的 `mavenPath`
2. **PATH 环境变量** — `where mvn` / `which mvn`
3. **环境变量** — `MAVEN_HOME/bin/mvn` 或 `M2_HOME/bin/mvn`
4. **IDEA 内置** — JetBrains IDE 捆绑的 Maven（详见 `references/idea-maven-locations.md`）
5. **包管理器** — Scoop、Chocolatey、Homebrew、SDKMAN
6. **常见目录** — `C:/Program Files/apache-maven*`、`D:/maven*` 等

---

## 常用命令速查

**构建**：
- `clean install` — 完整构建
- `clean install -DskipTests` — 跳过测试构建
- `compile` — 仅编译
- `package` — 打包（不清理）

**测试**：
- `test` — 运行全部测试
- `test -Dtest=ClassName` — 单个测试类
- `test -Dtest=ClassName#method` — 单个方法

**依赖**：
- `dependency:tree` — 查看依赖树
- `dependency:analyze` — 分析未使用依赖

**多模块**：
- `-pl module -am` — 构建指定模块及其依赖
- `-pl module -amd` — 构建模块及依赖它的模块

---

## 错误处理

- **Maven 未找到** → AskUserQuestion：提供安装指引或输入路径选项
- **路径无效** → 显示验证错误，重新询问
- **无 pom.xml** → 输出错误"当前工作空间不是 Maven 项目"，结束
- **多个 pom.xml** → AskUserQuestion 让用户选择
- **执行失败** → 显示 Maven 输出的错误信息