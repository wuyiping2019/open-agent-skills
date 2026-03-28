---
name: readme-writer
description: 为技能仓库生成 README.md。当用户要求生成、更新或编写 README，或提到"生成README"、"更新README"、"编写README"时使用。扫描 skills/ 目录下的所有 skill 并创建标准化 README。
---

# README Writer

扫描技能仓库并生成 README.md。

## 快速开始

```bash
cd <readme-writer目录>
bash scripts/generate.sh <项目根目录>
```

脚本将 README.md 输出到项目根目录。

## 脚本说明

`scripts/generate.sh` 执行以下操作：

1. 扫描 `skills/` 目录下的所有 skill 文件夹
2. 读取每个 `SKILL.md` 的 frontmatter（name、description）
3. 生成 README.md，包含：
   - 项目标题和描述
   - Skills 表格（名称、描述、链接）
   - 使用说明

## README 模板

生成的结构：

```markdown
# open-agent-skills

Claude Code 个人技能仓库。

## Skills

| Skill | Description | Link |
|-------|-------------|------|
| skill-name | 描述内容 | [SKILL.md](skills/skill-name/SKILL.md) |

## Usage

如何安装和使用 skill。
```

## 注意事项

- 脚本从 frontmatter 提取 description 字段
- 若 skill 缺少 frontmatter，跳过并警告
- README 纯脚本生成，快速稳定