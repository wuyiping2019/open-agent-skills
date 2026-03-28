# 文档模板

## 1. README.md（普通模块）

```markdown
# {模块名}

{一句话描述}

## 1. 快速开始

### 1.1 依赖

\`\`\`xml
<dependency>
    <groupId>{groupId}</groupId>
    <artifactId>{artifactId}</artifactId>
    <version>{version}</version>
</dependency>
\`\`\`

### 1.2 使用示例

\`\`\`java
// 最简使用代码
\`\`\`

## 2. 核心概念

{2-3 句说明模块解决什么问题}

## 3. 文档索引

- [核心概念](docs/concepts.md) - 设计理念和核心概念
- [处理流程](docs/flow.md) - 详细处理流程
- [Spring Boot 集成](docs/spring-boot.md) - 自动配置和集成指南
- [数据模型](docs/data.md) - 数据库表结构和配置说明
```

---

## 2. README.md（根目录）

```markdown
# {项目名}

{一句话描述}

## 1. 模块架构

{模块结构说明}

## 2. 快速开始

\`\`\`bash
mvn clean install
\`\`\`

## 3. 文档

{各模块文档链接}
```

---

## 3. README.md（父模块）

```markdown
# {模块名}

{一句话描述}

## 1. 子模块

| 模块 | 说明 | 依赖 |
|------|------|------|
| [{子模块名}]({子模块路径}/README.md) | {说明} | {依赖} |

## 2. 快速开始

\`\`\`xml
<dependency>
    <groupId>{groupId}</groupId>
    <artifactId>{artifactId}</artifactId>
</dependency>
\`\`\`
```

---

## 4. docs/concepts.md

```markdown
# {模块名} 核心概念

## 1. 设计理念

{为什么这样设计}

## 2. 核心概念

### 2.1 {概念名}

**定义**：{是什么}

**作用**：{解决什么问题}

### 2.2 {概念名}

**定义**：{是什么}

**作用**：{解决什么问题}
```

---

## 5. docs/flow.md

```markdown
# {模块名} 处理流程

## 1. 流程图

\`\`\`mermaid
flowchart TD
    A[入口] --> B{判断} --> C[处理]
\`\`\`

## 2. 详细步骤

### 2.1 {步骤名称}

**条件**：{触发条件}

**处理**：{逻辑}

**数据**：读 {来源} → 写 {目标}

**代码**：`XxxService.java:行号`

### 2.2 {步骤名称}

**条件**：{触发条件}

**处理**：{逻辑}

**数据**：读 {来源} → 写 {目标}

**代码**：`XxxService.java:行号`
```

---

## 6. docs/spring-boot.md

```markdown
# {模块名} Spring Boot 集成

## 1. 自动配置

| Bean | 条件 | 默认实现 |
|------|------|----------|
| {接口} | {条件} | {实现类} |

## 2. 配置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| {key} | {default} | {desc} |

## 3. 快速集成

### 3.1 添加依赖

\`\`\`xml
<dependency>
    <groupId>{groupId}</groupId>
    <artifactId>{artifactId}</artifactId>
</dependency>
\`\`\`

### 3.2 配置 application.yml

\`\`\`yaml
{配置内容}
\`\`\`

### 3.3 使用示例

\`\`\`java
{代码示例}
\`\`\`
```

---

## 7. docs/data.md

```markdown
# {模块名} 数据模型

## 1. 数据库表

### 1.1 {表名}

| 字段 | 类型 | 说明 |
|------|------|------|
| {field} | {type} | {desc} |

\`\`\`sql
CREATE TABLE {表名} (
    {建表语句}
);
\`\`\`

## 2. Redis Key

| Key | TTL | 用途 |
|-----|-----|------|
| {pattern} | {ttl} | {desc} |

## 3. 实体类

### 3.1 {实体名}

| 字段 | 类型 | 说明 |
|------|------|------|
| {field} | {type} | {desc} |
```

---

## 8. docs/test.md

```markdown
# {模块名} 测试场景

## 1. 单元测试

### 1.1 测试类结构

\`\`\`
src/test/java/
└── com/hmsk/xxx/
    ├── XxxServiceTest.java
    └── XxxRepositoryTest.java
\`\`\`

### 1.2 测试场景

| 场景 | 测试方法 | 预期结果 |
|------|----------|----------|
| {场景} | {方法} | {结果} |

## 2. 集成测试

### 2.1 测试配置

\`\`\`yaml
# application-test.yml
\`\`\`

### 2.2 测试场景

| 场景 | 测试类 | 说明 |
|------|--------|------|
| {场景} | {类名} | {说明} |
```