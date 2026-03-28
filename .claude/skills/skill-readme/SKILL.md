---
name: skill-readme
description: |
  为技能仓库生成 README.md。当用户要求生成、更新或编写 README，或提到"生成README"、"更新README"、"编写README"时使用。扫描 skills/ 目录下的所有 skill 并创建标准化 README。

  支持本地项目和远程仓库。
---

# Skill README

扫描技能仓库并生成 README.md。

## 命令

| 命令 | 说明 |
|------|------|
| `generate` | 为本地项目生成 README.md |
| `push` | 为远程仓库生成 README.md 并推送 |

---

## generate — 本地生成

```bash
bash <skill-readme>/scripts/generate.sh <项目根目录>
```

输出 `README.md` 到项目根目录。

---

## push — 远程仓库生成并推送

```bash
bash <skill-readme>/scripts/push-readme.sh
```

此脚本会：
1. 拉取远程仓库最新代码（`~/.skill-share/repo`）
2. 扫描 `skills/` 目录生成 README.md
3. 提交并推送到远程仓库

成功输出 `README_SUCCESS`。

---

## README 模板

生成的结构：

```markdown
# open-agent-skills

Claude Code 个人技能仓库。

## Skills

| Skill | Description | Link |
|-------|-------------|------|
| skill-name | 描述内容 | [SKILL.md](skills/skill-name/SKILL.md) |
```

---

## 注意事项

- 脚本从 frontmatter 提取 description 字段
- 若 skill 缺少 frontmatter，跳过并警告
- README 纯脚本生成，快速稳定