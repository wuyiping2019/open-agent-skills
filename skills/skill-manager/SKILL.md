# Skill Manager

个人 Skill 仓库管理工具，支持从 Git 仓库同步 skills 到本地项目。

## 快速开始

直接运行命令，系统会自动检查并引导配置：

```
/skill-manager init
```

如果配置不完整，会依次询问：
1. Git 仓库地址（必填）
2. 分支名（默认 main，可选 master）
3. Skills 目录路径（默认 skills）

## 配置参数

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| repoUrl | 是 | - | Skill 仓库地址（支持 SSH 或 HTTPS） |
| repoBranch | 否 | main | 分支名 |
| skillsPath | 否 | skills | 仓库中 skill 存放的目录路径 |

### 配置文件位置

配置存储在 skill 内部：`config/config.json`

```
skill-manager/
├── config/
│   ├── config.json          ← 实际配置（用户填写）
│   └── config.example.json  ← 配置示例（保留）
└── scripts/
    ├── init-config.sh       ← 初始化配置
    ├── update-config.sh     ← 更新单个配置项
    └── ...
```

### 配置管理脚本

**初始化配置：**
```bash
bash scripts/init-config.sh repoUrl=git@github.com:user/skills.git repoBranch=main
```

**更新单个配置项：**
```bash
bash scripts/update-config.sh repoUrl git@github.com:user/new-skills.git
bash scripts/update-config.sh repoBranch master
bash scripts/update-config.sh skillsPath .
```

## 命令

| 命令 | 说明 |
|------|------|
| `init` | 初始化镜像仓库 |
| `pull [name]` | 拉取 skill 到当前项目（全部或指定） |
| `push [name]` | 推送 skill 到远程仓库（全部或指定） |
| `list` | 列出远程和本地所有 skill |
| `status` | 查看本地与远程的同步状态 |
| `diff <name>` | 查看指定 skill 的详细差异 |

## 工作原理

```
~/.skill-manager/repo/           ← 远程仓库的本地镜像（Git 操作在这里）
   ├── .git/
   └── skills/
       ├── skill-a/
       └── skill-b/

项目/.claude/skills/             ← 实际使用位置（纯文件复制）
   └── (通过 pull/push 同步)
```

**注意：** `skill-manager` 本身不参与同步操作（push/pull/list/status/diff 会自动排除它）。

## 使用示例

```
/skill-manager init              # 初始化
/skill-manager pull              # 拉取所有 skill
/skill-manager pull my-skill     # 拉取指定 skill
/skill-manager push my-skill     # 推送 skill
/skill-manager status            # 查看同步状态
```

## 执行步骤

### 步骤 1：运行 check.sh 检查配置

```bash
cd <skill-manager目录>
export PROJECT_DIR="<当前项目路径>"
bash scripts/check.sh
```

### 步骤 2：解析 check.sh 输出

输出格式（在 `CHECK_START` 和 `CHECK_END` 之间）：

```
CHECK_START
VALUE:repoUrl:SET:<url>|MISSING
VALUE:repoBranch:SET:<value>|DEFAULT:main
VALUE:skillsPath:SET:<value>|DEFAULT:skills
SSH:OK|FAIL|HTTPS:<host>
CHECK_END
```

关键字段解析：
- `VALUE:repoUrl:MISSING` → 需要询问用户仓库地址
- `VALUE:repoUrl:SET:<url>` → 已配置
- `VALUE:repoBranch:DEFAULT:main` → 未配置，使用默认值
- `SSH:FAIL:<host>` → SSH 免密未配置，提示用户

### 步骤 3：询问缺失配置（使用 AskUserQuestion）

**3.1 询问 repoUrl（必填）**

```
问题: 请输入你的 Skill 仓库地址（Git SSH 或 HTTPS URL）
选项:
  - git@github.com:wuyiping2019/agent-skills.git（常用地址）
  - 其他（用户自定义输入）
```

**3.2 询问 repoBranch**

```
问题: 请选择仓库分支名
选项:
  - main（默认主分支）
  - master（旧版默认分支）
```

**3.3 询问 skillsPath**

```
问题: 请输入仓库中 skill 存放的目录路径
选项:
  - skills（默认路径）
  - .（仓库根目录即为 skills 目录）
```

### 步骤 4：使用脚本写入配置

收到用户输入后，调用脚本写入配置：

```bash
bash scripts/init-config.sh repoUrl=<用户输入> repoBranch=<用户选择> skillsPath=<用户输入>
```

**注意：** 脚本会自动创建 `config/config.json`，如果文件已存在会更新对应字段。

### 步骤 5：执行对应命令

```bash
cd <skill-manager目录>
export PROJECT_DIR="<当前项目路径>"

# init
bash scripts/init.sh

# pull
bash scripts/pull.sh [name]

# push
bash scripts/push.sh [name]

# list
bash scripts/list.sh

# status
bash scripts/status.sh

# diff
bash scripts/diff.sh <name>
```

## 仓库结构要求

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

## 触发条件

- 用户执行 `/skill-manager` 命令
- 用户提到 "同步 skill"、"拉取 skill"、"推送 skill"、"管理 skill"