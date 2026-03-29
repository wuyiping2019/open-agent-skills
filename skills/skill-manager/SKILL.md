---
name: skill-manager
description: |
  项目空间 Skill 管理工具，用于在 Git 仓库和本地项目空间之间同步 skills。

  **务必在以下场景使用此 skill**：
  - 用户执行 /skill-manager 命令（init、pull、push、list、status、diff、search、load、browse）
  - 用户提到"同步 skill"、"拉取 skill"、"安装 skill"、"加载 skill"、"管理 skill"
  - 用户想要将远程仓库的 skill 同步到当前项目
  - 用户搜索全网可用的 skill（"搜索 skill"、"查找 skill"、"有没有 xxx skill"）
  - 用户从任意网络仓库加载 skill（"从 GitHub 加载"、"从某个仓库安装")
  - 多步骤 skill 管理任务（搜索 → 选择 → 加载）

  此 skill 管理项目空间目录 .claude/skills/，所有加载的 skill 从这里供 Claude Code 使用。
---

# Skill Manager

项目空间 Skill 管理工具，在 Git 仓库和本地项目空间之间同步 skills。

## 概念

**项目空间**：指项目目录下的 `.claude/skills/` 目录，Claude Code 从这里加载 skill 供本地使用。

skill-manager 帮助你：
- 从远程 Git 仓库拉取 skill 到项目空间
- 将项目空间中的 skill 推送到远程仓库
- 管理项目空间中的 skill 列表和同步状态

## 命令

| 命令 | 说明 |
|------|------|
| `init` | 初始化镜像仓库（首次使用） |
| `pull [name]` | 从主仓库拉取 skill 到项目空间 |
| `push [name]` | 推送项目空间中的 skill 到主仓库 |
| `list` | 列出主仓库和本地所有 skill |
| `status` | 查看同步状态 |
| `diff <name>` | 查看指定 skill 的差异 |
| `search <keyword>` | 搜索全网 skill（主仓库 + 索引 + GitHub） |
| `load <repo> <skill>` | 从任意仓库加载 skill 到项目空间 |
| `browse <repo>` | 浏览远程仓库中的可用 skills |

---

## 扩展功能

### search — 全网搜索

```bash
export PROJECT_DIR="<当前项目路径>"
bash <skill-manager>/scripts/search.sh <keyword>
```

搜索范围：
1. **本地主仓库** — 已配置的主仓库镜像
2. **内置索引** — `references/repos-index.json` 中的常用仓库
3. **GitHub** — 动态搜索 GitHub 上的 skill 仓库

输出格式：
- `SEARCH_RESULT:local:<name>` — 主仓库中的 skill
- `SEARCH_RESULT:index:<name>|<url>` — 索引仓库中的 skill
- `SEARCH_RESULT:github:<full_name>|<url>` — GitHub 搜索结果

---

### load — 从任意仓库加载

```bash
export PROJECT_DIR="<当前项目路径>"
bash <skill-manager>/scripts/load.sh <repo> <skill_name>
```

参数：
- `<repo>` — 仓库来源，支持多种格式：
  - 完整 URL：`https://github.com/user/skills.git`
  - GitHub 简写：`user/skills`
  - 索引名称：`anthropic-skills`
- `<skill_name>` — 要加载的 skill 名称

加载逻辑：
- 主仓库 → 使用镜像目录（已初始化）
- 其他仓库 → 临时克隆到 `~/.skill-manager/temp-repos/`

输出：
- `LOAD_SUCCESS:<name>` — 加载成功
- `TEMP_REPO:<url>` — 来自临时仓库（非主仓库）

---

### browse — 浏览远程仓库

```bash
export PROJECT_DIR="<当前项目路径>"
bash <skill-manager>/scripts/list-remote-skills.sh <repo>
```

列出远程仓库中所有可用的 skills，帮助用户选择要加载的内容。

输出：
- `REMOTE_SKILL:<name>|<description>` — 每个 skill 的名称和描述

## 工作原理

```
~/.skill-manager/repo/           ← 远程仓库的本地镜像
   ├── .git/
   └── skills/
       ├── skill-a/
       └── skill-b/

项目/.claude/skills/             ← 项目空间（skill-manager 操作这里）
   └── (通过 pull/push 同步)
```

镜像仓库是一个独立的 Git 工作目录，所有 Git 操作在这里进行，避免污染项目目录。

---

## 执行流程

**所有脚本调用前需设置环境变量**：
```bash
export PROJECT_DIR="<当前项目路径>"
```

**脚本清单**：

| 脚本 | 用途 |
|------|------|
| `check.sh` | 检查配置状态 |
| `init.sh` | 初始化镜像仓库 |
| `init-config.sh` | 写入配置 |
| `list.sh` | 列出所有 skills |
| `status.sh` | 查看同步状态 |
| `diff.sh` | 查看差异 |
| `pull.sh` | 从主仓库拉取 |
| `push.sh` | 推送到主仓库 |
| `search.sh` | 全网搜索 |
| `list-remote-skills.sh` | 浏览远程仓库 |
| `load.sh` | 加载 skill |
| `update-config.sh` | 更新单个配置字段 |
| `utils.sh` | 工具函数（内部） |

### 基本流程

1. **检查配置** → 解析 `check.sh` 输出，`repoUrl:MISSING` 则询问用户
2. **询问缺失配置** → 使用 AskUserQuestion 依次询问 repoUrl（必填）、repoBranch（默认 main）、skillsPath（默认 skills）
3. **写入配置** → `init-config.sh repoUrl=xxx repoBranch=xxx skillsPath=xxx proxy=xxx`
4. **执行命令** → `bash scripts/<command>.sh [args]`

### 搜索加载流程（多步骤）

当用户要"搜索/查找 skill"或"加载某个仓库的 skill"：

1. **搜索** → `search.sh <keyword>` → 解析 `SEARCH_RESULT:*` 输出
2. **展示结果** → AskUserQuestion 让用户选择感兴趣的仓库
3. **浏览仓库** → `list-remote-skills.sh <repo>` → 解析 `REMOTE_SKILL:*` 输出
4. **展示 skills** → AskUserQuestion 让用户选择要加载的 skill
5. **加载** → `load.sh <repo> <skill_name>` → 解析 `LOAD_SUCCESS:*` 输出

**关键输出格式**：
- `SEARCH_RESULT:local:<name>` — 主仓库中的 skill
- `SEARCH_RESULT:index:<name>|<url>` — 索引仓库
- `SEARCH_RESULT:github:<full_name>|<url>` — GitHub 搜索
- `REMOTE_SKILL:<name>|<desc>` — 仓库中的 skill
- `LOAD_SUCCESS:<name>` — 加载成功
- `ERROR:*` — 错误，需提示用户
- `WARN:*` — 警告，继续执行但提醒用户

---

## 使用示例

**示例 1：从 Anthropic 官方仓库加载 PDF 处理 skill**

```
用户: 我需要一个处理 PDF 文件的 skill

流程:
1. search.sh pdf → 找到多个仓库
2. 用户选择 anthropic-skills
3. list-remote-skills.sh anthropic-skills → 列出 17 个 skills
4. 用户选择 pdf
5. load.sh anthropic-skills pdf → 加载成功
```

**示例 2：同步主仓库的所有 skills**

```
用户: 把我配置的主仓库里的 skill 都拉下来

流程:
1. check.sh → 确认配置完整
2. pull.sh → 拉取所有 skills（无参数）
```

---

## 配置文件

配置文件位于 `config/` 目录：

| 文件 | 说明 | 是否推送 |
|------|------|----------|
| `config.example.json` | 配置模板（无敏感信息） | ✓ 推送 |
| `config.json` | 本地配置（可能含敏感信息） | ✗ 不推送 |

**配置模板** (`config.example.json`)：
```json
{
  "repoUrl": "",
  "repoBranch": "main",
  "skillsPath": "skills",
  "proxy": ""
}
```

**本地配置** (`config.json`) - 首次使用时自动生成：
```json
{
  "repoUrl": "git@github.com:user/skills.git",
  "repoBranch": "main",
  "skillsPath": "skills",
  "proxy": "http://127.0.0.1:7890"
}
```

**配置字段**：

| 字段 | 说明 | 必填 |
|------|------|------|
| `repoUrl` | 主仓库地址 | 是 |
| `repoBranch` | 分支名（默认 main） | 否 |
| `skillsPath` | Skills 目录路径（默认 skills） | 否 |
| `proxy` | HTTP/HTTPS 代理地址 | 否 |

**代理配置**：如果网络需要代理才能访问 GitHub，设置 `proxy` 字段。常用格式：
- Clash: `http://127.0.0.1:7890`
- Shadowsocks: `http://127.0.0.1:1080`
- V2RayN: `http://127.0.0.1:10809`

---

## 目录结构

```
your-project/                    ← 项目目录
├── .claude/skills/              ← 项目空间（skill-manager 操作这里）
│   ├── skill-manager/           ← 此 skill 本身
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   └── config/
│   ├── skill-a/
│   │   └── SKILL.md
│   └── skill-b/
│       └── SKILL.md
└── ...

远程仓库/
├── skills/                      ← 远程 skill 存储
│   ├── skill-a/
│   └── skill-b/
└── README.md
```

---

## 特殊规则

- `skill-manager` 本身不参与同步操作（自动排除）
- 空仓库会自动初始化，无需手动创建目录
- SSH 连接失败时会提示用户配置免密登录