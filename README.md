# open-agent-skills

Claude Code 个人技能仓库，包含多个实用 skill。

## Skills

| Skill | Description | Link |
|-------|-------------|------|
| jm-readme | 为 Java Maven 模块生成结构化 README 文档。触发场景：用户说"生成文档"、"写 README"、"文档化这个模块"、"更新文档"、"/readme"；或用户想了解模块结构、想为新模块添加文档、想更新现有文档、想检查文档标题格式。支持单模块、批量生成（--all）、根目录（--root）、验证（--validate）四种模式。当用户提到 Maven 模块的文档相关工作时，优先使用此 skill。 - Read - Write - Edit - Glob - Grep - Bash - Agent | [SKILL.md](skills/jm-readme/SKILL.md) |
| maven | 执行 Maven 构建命令，自动查找并验证 Maven 安装路径。 **何时使用此 skill（必须触发）**： - 用户提到 Maven、mvn、pom.xml - 用户说"编译项目"、"打包"、"运行测试"、"构建" - 用户提到依赖问题、dependency、JAR/WAR - 用户请求 clean install 或任何 mvn 命令 即使用户没有明确说"Maven"，只要是 Java 项目构建相关请求，就应该使用此 skill。 支持跨平台（Windows/macOS/Linux），自动查找 IDEA 内置 Maven、包管理器安装、常见安装目录。 - Bash - Read - AskUserQuestion | [SKILL.md](skills/maven/SKILL.md) |
| skill-creator | Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy. | [SKILL.md](skills/skill-creator/SKILL.md) |
| skill-manager | 个人 Skill 仓库管理工具，用于在 Git 仓库和本地项目之间同步 skills。 当用户执行以下操作时使用此 skill： - 执行 /skill-manager 命令（init、pull、push、list、status、diff） - 提到"同步 skill"、"拉取 skill"、"推送 skill"、"管理 skill" - 想要备份或恢复项目中的 skills 注意：此 skill 也管理自身，但会自动排除自己参与同步操作。 | [SKILL.md](skills/skill-manager/SKILL.md) |
