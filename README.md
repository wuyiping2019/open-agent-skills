# open-agent-skills

Claude Code 个人技能仓库，包含多个实用 skill。

## Skills

| Skill | Description | Link |
|-------|-------------|------|
| readme-writer | 为技能仓库生成 README.md。当用户要求生成、更新或编写 README，或提到"生成README"、"更新README"、"编写README"时使用。扫描 skills/ 目录下的所有 skill 并创建标准化 README。 | [SKILL.md](skills/readme-writer/SKILL.md) |
| skill-creator | Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy. | [SKILL.md](skills/skill-creator/SKILL.md) |
| skill-manager | 个人 Skill 仓库管理工具，用于在 Git 仓库和本地项目之间同步 skills。 当用户执行以下操作时使用此 skill： - 执行 /skill-manager 命令（init、pull、push、list、status、diff） - 提到"同步 skill"、"拉取 skill"、"推送 skill"、"管理 skill" - 想要备份或恢复项目中的 skills 注意：此 skill 也管理自身，但会自动排除自己参与同步操作。 | [SKILL.md](skills/skill-manager/SKILL.md) |
