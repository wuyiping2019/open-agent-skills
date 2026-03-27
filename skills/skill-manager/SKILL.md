---
name: skill-manager
description: |
  个人 Skill 仓库管理工具，用于在 Git 仓库和本地项目之间同步 skills。

  当用户执行以下操作时使用此 skill：
  - 执行 /skill-manager 命令（init、pull、push、list、status、diff）
  - 提到"同步 skill"、"拉取 skill"、"推送 skill"、"管理 skill"
  - 想要备份或恢复项目中的 skills

  注意：此 skill 也管理自身，但会自动排除自己参与同步操作。
---

# Skill Manager

个人 Skill 仓库管理工具，支持从 Git 仓库同步 skills 到本地项目。

## 命令

| 命令 | 说明 |
|------|------|
| `init` | 初始化镜像仓库（首次使用） |
| `pull [name]` | 拉取 skill 到当前项目 |
| `push [name]` | 推送 skill 到远程仓库 |
| `list` | 列出远程和本地所有 skill |
| `status` | 查看同步状态 |
| `diff <name>` | 查看指定 skill 的差异 |

## 工作原理

```
~/.skill-manager/repo/           ← 远程仓库的本地镜像
   ├── .git/
   └── skills/
       ├── skill-a/
       └── skill-b/

项目/.claude/skills/             ← 实际使用位置
   └── (通过 pull/push 同步)
```

镜像仓库是一个独立的 Git 工作目录，所有 Git 操作在这里进行，避免污染项目目录。

## 执行流程

### 1. 检查配置

```bash
export PROJECT_DIR="<当前项目路径>"
bash <skill-manager>/scripts/check.sh
```

解析输出中的配置状态，如果 `repoUrl:MISSING` 则询问用户。

### 2. 询问缺失配置

如果配置不完整，使用 AskUserQuestion 依次询问：

1. **repoUrl** - Skill 仓库地址（必填）
2. **repoBranch** - 分支名（默认 main）
3. **skillsPath** - Skills 目录路径（默认 skills）

### 3. 写入配置

```bash
bash <skill-manager>/scripts/init-config.sh repoUrl=xxx repoBranch=xxx skillsPath=xxx
```

### 4. 执行命令

```bash
export PROJECT_DIR="<当前项目路径>"
bash <skill-manager>/scripts/<command>.sh [args]
```

## 配置文件

配置存储在 `config/config.json`：

```json
{
  "repoUrl": "git@github.com:user/skills.git",
  "repoBranch": "main",
  "skillsPath": "skills"
}
```

## 仓库结构

```
your-skills/
├── skills/                     ← skillsPath 配置的目录
│   ├── skill-a/
│   │   ├── SKILL.md
│   │   └── scripts/
│   └── skill-b/
│       └── SKILL.md
└── README.md
```

## 特殊规则

- `skill-manager` 本身不参与同步操作（自动排除）
- 空仓库会自动初始化，无需手动创建目录
- SSH 连接失败时会提示用户配置免密登录