# KAIZEN-Migration: AI 驱动的 Android→ArkTS 代码翻译工程方法论

> 版本：v2.1
> 日期：2026-03-21
> 基于：AntennaPod 项目实战数据（17 会话 / 98 文件 / 22 踩坑 / 质量 9.5/10）

---

## Part 1: 体系总览

### 方法论命名

**KAIZEN-Migration**

> **K**nowledge-Augmented, **I**terative, **Z**ero-defect, **E**ngineering-constrained, **N**-agent Migration
> 知识增强 · 迭代优化 · 零缺陷追求 · 工程约束 · 多智能体协作

### 一句话定义

**以 Spec 为蓝图、Skills 为专家、Harness 为护栏、Memory 为记忆、Multi-Agent 为劳力、大小模型为梯队，实现 Android 代码到 HarmonyOS ArkTS 的高质量、可复现、持续演进的一比一翻译。**

### 核心理念

传统跨平台迁移有两个极端：

| 极端 | 做法 | 问题 |
|------|------|------|
| **纯手工迁移** | 工程师逐行改写 | 速度慢、人力贵、经验不可复用 |
| **纯 LLM 生成** | 丢给 AI 一把梭 | 幻觉频发、平台约束无感知、质量不可控 |

KAIZEN-Migration 的理念是 **"约束 AI 的创造力，放大 AI 的生产力"**：

| # | 理念 | 实证 |
|---|------|------|
| 1 | **约束优先于生成** — 先建立完整的工程约束框架（Harness），再让 AI 在约束内生成代码 | CLAUDE.md 的 20+ 条规则使阶段四质量问题**归零** |
| 2 | **知识沉淀优先于知识重发现** — 22 条踩坑、43 组概念映射、16 个代码模式模板，全部持久化 | 避免每次会话从零学习。Memory 使踩坑复发率 **0%** |
| 3 | **分阶段门控优先于事后修复** — 五阶段各有质量门（Done Gate），问题在最早的阶段拦截 | 阶段一 3 个 Spec 遗漏级联了 6+ 个下游问题，证明"左移"的价值 |
| 4 | **专家分工优先于通才包揽** — 14 个 Skills 覆盖不同领域，大小模型各司其职 | Manual 模块用 Opus（100% 成功率），Semi-Auto 模块用 Sonnet（更经济） |

### 差异化对比

| 维度 | 纯手工迁移 | 纯 LLM 生成 | 通用 AI 翻译工具 | **KAIZEN-Migration** |
|------|-----------|------------|-------------------|---------------------|
| 速度 | 慢（人月级） | 快但返工多 | 中等 | **快且返工少**（6 天 / 98 文件） |
| 质量 | 依赖个人经验 | 不可控（幻觉） | 中等 | **9.5/10**（零 any / 零注入 / 零泄漏） |
| 知识复用 | 口头传承 | 无 | 有限 | **系统化**（Memory + Skills + Harness） |
| 平台适配 | 手动试错 | AI 猜测 | 通用规则 | **领域专精**（22 条鸿蒙踩坑 + 43 组映射） |
| 可复现性 | 不可复现 | 不可复现 | 部分 | **高度可复现**（Spec 驱动 + 门控验收） |
| 规模化 | 线性增长 | 无保证 | 有限 | **可扩展**（Multi-Agent 并行 + Skill 编排） |

---

## Part 2: 五阶段关键技术矩阵

### 总览架构图

```
阶段一             阶段二            阶段三           阶段四           阶段五
Spec 生成     →   代码生成      →   多轮修复     →   质量保证     →   测试优化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Opus]            [Sonnet+Opus]    [Sonnet+Opus]   [Haiku+Sonnet]  [Opus+Sonnet]
[Explore×4]       [Code Agent]     [Fix Agent]     [Review×4]      [Test+Bug Agent]
[spec-generator]  [14 Skills]      [Memory]        [Harness]       [ui-alignment]
[Memory 读取]      [Harness 约束]   [自修复协议]     [CLAUDE.md]     [截图对比]
       ↓                ↓               ↓               ↓               ↓
   migration-spec    .ets 源文件     可编译版本       审计报告        生产版本
   (SS1-SS12)       (98 文件)       (0 编译错误)     (0 违规)        (v3 发布)
```

### 五阶段技术矩阵汇总

| 技术 | 阶段一 Spec | 阶段二 代码 | 阶段三 修复 | 阶段四 质量 | 阶段五 测试 |
|------|:----------:|:----------:|:----------:|:----------:|:----------:|
| **Spec** | 产出核心蓝图 | 驱动生成范围 | 回溯更新 | 验收基准 | 验收矩阵 |
| **Skills** | spec-generator | 14 个按域路由 | verifier + analyzer | verifier | ui-alignment |
| **Harness** | SS7 分类模板 | CLAUDE.md 约束 | 错误模式库 | 7 大规范域 | UI 架构规则 |
| **Memory** | 映射表+踩坑 | 踩坑注入 | 自修复协议 | 检查清单 | symbol 清单 |
| **Multi-Agent** | Explore×4 并行 | Code 按序+层内并行 | Fix 路由 | Review×4 并行 | Test+Bug 协作 |
| **大小模型** | Opus+Haiku | Sonnet+Opus | Sonnet+Opus | Haiku+Sonnet | Opus+Sonnet |

---

### 阶段一：Spec 生成（Android 分析 → 迁移蓝图）

| 维度 | 内容 |
|------|------|
| **目标** | 将 Android 源码转化为结构化迁移规格文档（SS1-SS12） |
| **产出** | `migration-spec.md`，含组件清单、模块合并策略、概念映射表、风险分级、平台约束清单 |
| **输入** | Android 项目源码路径 |

#### 六大技术在本阶段的具体应用

| 技术 | 具体应用 | 为什么用 |
|------|---------|---------|
| **Spec Engineering** | SS1-SS12 结构化模板，强制覆盖 12 个维度 | AntennaPod 证明 Spec 的 3 个遗漏级联了 6+ 个下游问题 |
| **Skills** | `arkts-spec-generator` 驱动并行扫描 Agent | 36 个 Gradle 模块的人工分析需数天，自动化压缩到 2 个会话 |
| **Memory** | 读取概念映射表（43 组）和踩坑清单（20 条），注入 Spec 生成上下文 | 避免 LLM 重新发现已知约束（fd:// 协议、5MB 限制） |
| **Multi-Agent** | 4 个 Explore Agent 并行：数据层 / UI 层 / 工具层 / 构建配置 | 并行比串行快 3-4x |
| **大小模型** | **Opus** 做 Spec 生成（深度架构理解）；**Haiku** 做文件计数和依赖图提取 | Spec 质量决定下游全部阶段，需最强模型 |
| **Harness** | Spec 模板本身即 Harness — SS7 强制每个模块标记 Auto/Semi-Auto/Manual/Skip | 防止 LLM 跳过风险评估 |

#### 本阶段竞争力

> **SS12「鸿蒙平台约束清单」是 KAIZEN-Migration 独有的**。通用 AI 翻译工具不会主动检查目标平台特有约束（fd:// 协议、request.agent 选型、Tab 栏架构等）。这个清单来自 22 条实战踩坑的沉淀，是**纯知识壁垒**。

---

### 阶段二：代码生成（Spec → ArkTS 代码）

| 维度 | 内容 |
|------|------|
| **目标** | 基于 Spec + 自然语言描述，生成符合鸿蒙规范的 ArkTS 代码 |
| **产出** | 完整 .ets 源文件（AntennaPod 项目：98 文件，~6,300+ 行） |
| **输入** | migration-spec.md + 用户自然语言指令 + Android 源码参考 |

#### 六大技术在本阶段的具体应用

| 技术 | 具体应用 | 为什么用 |
|------|---------|---------|
| **Skills** | 14 个 Skills 按任务类型自动路由：`component-builder` 生成 UI、`data-layer` 生成 DAO、`navigation-builder` 生成路由、`media-playback` 生成播放器 | Hub-and-Spoke 编排确保每个代码域由最专业的 Skill 处理 |
| **Harness** | CLAUDE.md 20+ 条规则每次会话自动加载：禁 any/as/对象字面量、强制 ResultSet close()、强制 SQL 占位符、强制 fd:// 等 | **阶段四 0 个质量问题的根本原因**。Harness 将防线前移到"生成时约束" |
| **Memory** | 22 条踩坑自动注入上下文（AVPlayer 状态机、后台播放三要素、Panel 三态等） | LLM 鸿蒙训练数据不足（RC1 根因），Memory 补偿知识缺口 |
| **Multi-Agent** | Code Agent 按六阶段流水线生成：骨架→适配层→数据层→导航→状态→组件。同层内可并行（如 7 DAO 并行） | 保证依赖顺序正确，最大化并行度 |
| **大小模型** | **Sonnet** 做 Semi-Auto 模块（DAO、Component、ViewModel）；**Opus** 做 Manual 模块（RSS 解析器 SAX→Pull、AVPlayer 状态机、EventBus 自建） | Manual 模块（6 个）是最大风险点需 Opus；Semi-Auto（13 个）用 Sonnet 更经济 |
| **Spec** | SS4 组件映射、SS5 数据层、SS7 迁移分类直接驱动生成范围和顺序 | 无 Spec 驱动的代码生成是"盲写" |

#### 本阶段竞争力

> **14 个 Skills 的三级渐进加载机制**（description 100 词 → SKILL.md 500 行 → references 按需加载）既保证知识完整性，又避免上下文窗口溢出。这是通用 AI 编码工具不具备的**结构化领域知识注入能力**。

---

### 阶段三：多轮修复（人工检测 → 迭代修正）

| 维度 | 内容 |
|------|------|
| **目标** | 人工编译/运行发现问题后，多轮迭代修复所有编译错误和运行时异常 |
| **产出** | 可编译、可运行的代码版本 |
| **输入** | 编译错误信息、运行时崩溃日志、UI 截图 |

#### 六大技术在本阶段的具体应用

| 技术 | 具体应用 | 为什么用 |
|------|---------|---------|
| **Memory** | 自修复协议（查表驱动）：编译错误→检查类型/import、运行时 undefined→检查初始化时序、数据库错误→检查 ResultSet.close()、播放器无反应→检查状态机 | 修复经验系统化，平均迭代 1.7 轮 |
| **Harness** | 错误模式库：ArkTS 3 类常见违规（any/as/对象字面量）有固定修复模式 | 语言约束错误直接套模板，无需推理 |
| **Skills** | `arkts-knowledge-verifier` 验证修复方案是否符合平台规范 | 避免"修了一个坑又挖了新坑" |
| **Multi-Agent** | Fix Agent 路由：语言约束→套模板；平台语义→查 Memory；架构级→升级 Opus | 跨阶段错误需智能路由到正确修复层 |
| **大小模型** | **Sonnet** 处理常规编译错误；**Opus** 处理架构级返工（如 Tab 栏方案变更涉及 Index.ets 结构重写） | 常规错误不值得 Opus 成本，架构返工需全局视角 |
| **Spec** | 方案变更时回溯更新 Spec（如下载 API 从 http.request 更新为 request.agent） | 保持 Spec 作为 Single Source of Truth |

#### 本阶段竞争力

> **自修复协议 + 重试上限机制**。通用 LLM 修复是"盲试"，KAIZEN-Migration 是"查表驱动" — 6 种错误类型各有固定检查路径。重试上限（≤3 次）防止死循环，超限自动升级人工介入。

---

### 阶段四：代码质量保证

| 维度 | 内容 |
|------|------|
| **目标** | 确保代码库符合全部质量标准，零违规 |
| **产出** | 质量审计报告（全通过） |
| **输入** | 完整代码库 |

#### 六大技术在本阶段的具体应用

| 技术 | 具体应用 | 为什么用 |
|------|---------|---------|
| **Harness** | CLAUDE.md 7 大规范域（导入、类型、组件、数据库、播放器、XML、网络）自动化检查 | AntennaPod 阶段四 **0 个问题**，证明 Harness 有效 |
| **大小模型** | **Haiku** 执行模式匹配扫描（grep any/as/@ohos/SQL 拼接）；**Sonnet** 审查逻辑正确性 | Haiku 做文本模式匹配极其高效且低成本 |
| **Multi-Agent** | 4 个 Review Agent 并行：安全性 / 资源管理 / 类型安全 / 导入规范 | 并行扫描比串行审查快 4x |
| **Memory** | 质量检查清单从 Memory 加载，含项目特有检查项（如 GlobalState key 完整性） | 项目特有质量要求不在通用 linter 覆盖范围 |
| **Skills** | `arkts-knowledge-verifier` 验证 API 用法是否符合最新平台规范 | 防止使用已废弃 API 或不存在的 sys.symbol |
| **Spec** | 回溯 SS10 验收矩阵定义的验收标准 | 确保代码符合迁移规格 |

#### 本阶段竞争力

> 阶段四是整个流程中表现最好的环节（0 问题）。核心是 **Harness 先行** — 不是代码写完再检查，而是**生成时就约束**。CLAUDE.md 每次会话自动加载，等同于给 LLM 装了"编译期约束器"。

---

### 阶段五：测试反馈与持续优化

| 维度 | 内容 |
|------|------|
| **目标** | 基于测试同学反馈，修复功能缺陷、优化 UI 对齐 |
| **产出** | 生产就绪版本 |
| **输入** | 测试报告、Bug 单、Android 原版截图 |

#### 六大技术在本阶段的具体应用

| 技术 | 具体应用 | 为什么用 |
|------|---------|---------|
| **Skills** | `arkts-ui-alignment` 提供 Android→ArkTS UI 映射表（14 组）；`arkts-component-builder` 生成修复后组件代码 | 阶段五消耗 ~40% v1 后时间，映射模板库可减少约 30% 迭代 |
| **Memory** | 已验证 sys.symbol 名称清单（22 可用 + 5 不可用）、颜色/间距系统规范 | 避免重复验证已知 symbol 名称 |
| **Multi-Agent** | Test Agent 管理回归测试矩阵（7 路径 x 5 验证项）；Bug Agent 接收反馈路由到对应 Skill | 系统化回归替代临时验证 |
| **大小模型** | **Opus** 处理大型组件重写（如 AddFeedComponent 495 行重写）；**Sonnet** 处理样式微调 | 大型重写需 Opus 理解完整业务逻辑 |
| **Harness** | UI 验证规则：Tab 栏在 Navigation 外部、ForEach key 含变化字段、@StorageLink key 预注册 | 防止 UI 修复引入已知架构问题 |
| **Spec** | 回溯 SS10 验收矩阵，确保修复不偏离迁移目标 | 防止过度优化偏离原版 |

#### 本阶段竞争力

> **Android→ArkTS UI 组件映射表**是纯经验产物，需真机验证。14 组映射来自实战验证，其中"Tab 栏必须在 Navigation 外部"一条就避免了 Index.ets 的结构性重写。

---

## Part 3: 六大技术支柱详解

### 支柱 1: Spec Engineering（规格工程）

#### 定义

Spec 是 Android 项目的结构化分析文档，采用 SS1-SS12 的 12 章节格式，是整个迁移流水线的**单一事实源（Single Source of Truth）**。

#### 为什么用

AntennaPod 证明：Spec 的 3 个遗漏级联产生了 6+ 个下游问题。其中下载 API 方案变更 3 次是最昂贵的返工项（DownloadManager.ets 278 行 diff）。结构化 Spec 通过强制覆盖消除遗漏。

#### Spec 结构（SS1-SS12）

| 章节 | 名称 | 内容 | 驱动下游 |
|------|------|------|---------|
| SS1 | 项目概览 | 应用名、语言、架构、组件计数 | 全部 |
| SS2 | 模块合并策略 | N 个 Android 模块 → 单 entry 映射表 | P2 骨架 |
| SS3 | 技术栈替换表 | 43 个依赖项 → 替代方案 | P3 适配层 |
| SS4 | UI 组件映射 | Activity→Page、Fragment→Component | P5 UI 层 |
| SS5 | 数据层设计 | 表结构、DAO 接口、Preferences key | P4 数据层 |
| SS6 | 导航图 | 路由名、参数类型、页面跳转关系 | P5a 导航 |
| SS7 | 迁移分类 | Auto/Semi-Auto/Manual/Skip + 模块清单 | 全部 |
| SS8 | 风险矩阵 | 红/黄/绿风险分级 + 缓解方案 | P3, P5a |
| SS9 | 配置清单 | module.json5 权限、backgroundModes | P2 骨架 |
| SS10 | 验收矩阵 | V1 功能 14 项 + V2 功能 10 项 | P6, 阶段五 |
| SS11 | 时间估算 | 每阶段预估工作量 | 项目管理 |
| **SS12** | **鸿蒙平台约束** | fd://、5MB 限制、Tab 架构、ArkTS 严格模式等 | **阶段二全部** |

#### Spec 驱动关系图

```
SS1 项目概览 ─────→ 确定迁移范围
SS2 模块合并 ─────→ 目录结构 (P2)
SS3 技术栈替换 ───→ 适配层选型 (P3)
SS5 数据层设计 ───→ 建表 + DAO (P4)
SS7 迁移分类 ─────→ 生成优先级排序 + 模型选择 (Opus vs Sonnet)
SS12 平台约束 ────→ 代码生成约束 (阶段二) + Harness 规则来源
SS10 验收矩阵 ───→ 测试验收 (阶段四-五)
```

#### Spec 质量保证机制

| 机制 | 实现方式 |
|------|---------|
| 结构完整性检查 | Done Gate：SS1-SS12 全部 12 章节必须存在 |
| 分类准确性检查 | SS7 每个模块必须标记分类，不允许"待定" |
| 平台约束覆盖检查 | SS12 必须覆盖 7 类约束（文件/HTTP/UI/存储/后台/状态/语言） |
| 人工审查 | Spec 生成后必须经人工审查才进入阶段二 |
| 回溯更新 | 阶段三发现的方案变更必须反映回 Spec |

---

### 支柱 2: Skills System（专业化 Skill 编排）

#### 定义

14 个代码生成类 Skills + 6 个分析类 Skills，每个 Skill 是一个领域专家，封装了特定代码域的生成规则、决策树、代码模板和常见错误纠正。

#### 为什么用

单一 LLM 上下文无法同时承载所有领域知识。Skills 实现**按需加载**的知识注入。三级渐进加载（100 词 description → 500 行 SKILL.md → references 按需）在知识完整性和上下文效率之间取得平衡。

#### 14 个代码生成 Skills 分工矩阵

| Skill | 职责域 | 阶段一 | 阶段二 | 阶段三 | 阶段四 | 阶段五 |
|-------|--------|:------:|:------:|:------:|:------:|:------:|
| `arkts-spec-generator` | Spec 生成 | **主力** | - | - | - | - |
| `arkts-project-scaffolder` | 项目骨架 | - | P2 | - | - | - |
| `arkts-knowledge-verifier` | 知识验证 | 辅助 | 辅助 | 辅助 | **主力** | 辅助 |
| `arkts-component-builder` | UI 组件 | - | P5c | 修复 | - | **主力** |
| `arkts-state-manager` | 状态管理 | - | P5b | 修复 | - | - |
| `arkts-navigation-builder` | 页面导航 | - | P5a | 修复 | - | - |
| `arkts-data-layer` | 数据层 | - | P3+P4 | 修复 | - | - |
| `arkts-media-playback` | 媒体播放 | - | P5a | 修复 | - | - |
| `arkts-download-manager` | 文件下载 | - | P5b | 修复 | - | - |
| `arkts-system-capabilities` | 系统 API | - | P3 | 修复 | - | - |
| `arkts-pattern-library` | 业务模式 | - | P5c | - | - | 辅助 |
| `arkts-animation-builder` | 动画效果 | - | P5c | - | - | 辅助 |
| `arkts-library-migration` | 三方库替换 | 辅助 | P3 | - | - | - |
| `arkts-ui-alignment` | UI 对齐 | - | - | - | - | **主力** |

#### Hub-and-Spoke 编排

三个 Hub Skill 负责跨 Skill 编排：

```
                 ┌─── knowledge-verifier ───┐  (兜底路由)
                 │                          │
    ┌────────────┤                          ├────────────┐
    │            │                          │            │
project-       pattern-library          各专项 Skill
scaffolder     (业务功能入口)             (单技术点入口)
(从零建项目)        │
                    ├── component-builder
                    ├── state-manager
                    ├── navigation-builder
                    ├── data-layer
                    └── animation-builder
```

**路由规则**：
- "做个商品列表页" → `pattern-library`（业务功能）
- "从零搭建新闻 App" → `project-scaffolder`（项目级）
- "ArkTS 能用 any 吗" → `knowledge-verifier`（知识验证）
- "写个 Text 组件" → `component-builder`（单技术点）

#### Skill 成熟度管理（L0-L4）

| 等级 | 定义 | 升级条件 |
|------|------|---------|
| L0 | 只有问题识别，无 Skill 方案 | 形成 Skill 草案 |
| L1 | 有草案，触发条件初步明确 | 在 1 个项目中落地验证 |
| L2 | 可落地使用，但覆盖面不足 | 覆盖该领域 80%+ 常见场景 |
| L3 | 团队默认做法，可支撑版本交付 | 通过 3+ 个项目验证 |
| L4 | 已标准化，可复用到其他项目 | 有完整文档 + 验收标准 + 版本历史 |

---

### 支柱 3: Harness Engineering（工程约束框架）

#### 定义

Harness 是一套多层约束规则体系，以 `CLAUDE.md` 为核心载体，在 LLM 生成代码时**自动加载**，将质量防线从"事后检查"前移到"生成时约束"。

#### 为什么用

AntennaPod 阶段四 **0 个质量问题**，而阶段二有 10 个问题。差异在于：阶段四的检查规则（CLAUDE.md）每次会话自动加载。Harness 的价值 = **预防成本远低于修复成本**。

#### Harness 三层结构

**第一层：语言约束层（ArkTS 严格模式规则）**

| 规则 | 违规后果 | 修复模式 |
|------|---------|---------|
| 禁止 `any`/`unknown` | 编译错误 arkts-no-any-unknown | 使用具体类型或 `Object` |
| 禁止 `as` 类型断言 | 编译错误 arkts-no-ts-like-as | 使用 `instanceof` 检查 |
| 禁止对象字面量类型 | 编译错误 arkts-no-obj-literals-as-types | 定义独立 `class` |
| 禁止 `eval()` / 动态 `import()` | 编译错误 | 静态引用 |
| `@Component` 必须是 `struct` | 编译错误 | `struct` 替代 `class` |
| `build()` 唯一根容器 | 编译错误 | 包一层 Column/Row/Stack |

**第二层：平台约束层（鸿蒙 API 行为约束）**

| 约束 | 来源踩坑 | 违反后果 |
|------|---------|---------|
| AVPlayer 必须 fd:// 协议 | #1 | 播放器进入 error 状态 |
| AVPlayer 状态机不能跳过 | #2 | 操作静默失败 |
| http.createHttp() 必须 destroy() | #21 | 内存泄漏/句柄耗尽 |
| ResultSet 必须 close() | #19 | 数据库锁错误 |
| NavDestination 参数在 onReady 获取 | #16 | 参数为 undefined |
| AppStorage.setOrCreate 先于 @StorageLink | #11 | UI 不刷新 |
| ForEach key 含变化字段 | #12 | 列表不刷新 |
| 使用 @kit.* 统一导入 | 平台规范 | 使用废弃 API |

**第三层：项目约束层（架构决策、模式规范）**

| 约束 | 原理 |
|------|------|
| 单 entry 模块，MVVM 分层 | 36 模块合并策略 |
| 单例数据库 PodDatabase.getInstance() | 避免多连接 |
| SQL 参数用 ? 占位符 | 防注入 |
| INSERT 用 ON CONFLICT DO UPDATE | 保持 id 稳定 |
| Tab 栏在 Navigation 外部 | 避免子页面覆盖 |
| 统一使用 SymbolGlyph | 图标大小一致 |

#### Harness 的持续沉淀机制

```
阶段二/三发现新问题
       │
       ▼
分析根因 → 归类（语言 / 平台 / 项目层）
       │
       ▼
编写预防规则 → 加入 CLAUDE.md 对应规范域
       │
       ▼
同步到 Skills（相关 Skill 的 references 更新）
       │
       ▼
同步到 Memory（踩坑清单追加）
```

#### Harness 与 Skills 的协作关系

```
Harness (CLAUDE.md)              Skills (SKILL.md + references/)
━━━━━━━━━━━━━━━━━━━              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
定义"不能做什么"                  教会"怎么做"
每次会话自动加载                   按需加载（Hub 路由触发）
20+ 条底线规则                    14 个领域的详细模板
通用于所有任务                    特定于某类任务
持续从踩坑沉淀新规则               持续从实战沉淀新模板

       ↕ 协作 ↕
Harness 约束 LLM 的输出边界
Skills 在边界内引导正确方向
→ 共同产出：符合规范的高质量代码
```

---

### 支柱 4: Memory System（知识持久化与演进）

#### 定义

Memory 是 Claude Code 的跨会话持久化知识系统，存储在 `~/.claude/projects/*/memory/` 目录下。每次新会话自动加载 Memory，使 LLM 具备"长期记忆"。

#### 为什么用

AntennaPod 跨 17 个会话完成，每个会话之间 LLM 上下文完全重置。没有 Memory，每个会话都需要重新"教"LLM 已知的踩坑和架构决策。Memory 将知识从"会话级"提升到"项目级"。

#### Memory 类型分类

| 类型 | 内容特征 | 生命周期 | 示例 |
|------|---------|---------|------|
| **User** | 用户偏好、工作习惯 | 永久 | 开发风格偏好 |
| **Project** | 项目迁移方法论、踩坑清单 | 项目周期 | `project_migration_steps.md` |
| **Feedback** | 阶段三/五的修复经验 | 项目周期 | 自修复协议、UI 对齐经验 |
| **Reference** | 跨项目通用平台知识 | 持久 | API 基线规则、迁移模式 |

#### 知识归属决策矩阵

| 知识类型 | 存入位置 | 理由 |
|---------|---------|------|
| 每次会话必须遵守的底线规则 | **CLAUDE.md** | 自动加载，零遗漏 |
| 项目特有架构决策（36→1 模块合并） | **Memory** | 项目级，不适用于其他项目 |
| 高频踩坑（Top-10） | **CLAUDE.md** + **Memory** | 高频踩坑放 CLAUDE.md 确保自动加载 |
| 跨项目通用 ArkTS 规范 | **Skills** (references/) | 其他项目也需要 |
| 迁移方法论 | **Memory** + **Skills** | Memory 快速参考，Skills 详细指南 |
| 已验证 API 参考 | **Skills** (verifier/references/) | 跨项目通用 |

#### Memory 生命周期

```
P1 阶段：创建 Memory 索引 + 方法论文件
P2-P4：增长（新增踩坑条目、架构决策）
P5：稳定（完善验证结果、标注已解决/未解决）
项目结束：归档 → 提炼通用知识 → 迁移到 Skills references
下个项目：加载 Skills（通用） + 创建新 Memory（项目专属）
```

#### 跨项目复用路径

```
项目 A Memory（项目专属知识）
       │
       ▼ 提炼通用部分
Skills references/（跨项目通用知识）
       │
       ▼ 新项目自动加载
项目 B 的 Skills 上下文
```

**实例**：AntennaPod 的概念映射表（43 组）提炼自前一个项目（Gallery），通过 Memory 传递到当前项目。

---

### 支柱 5: Multi-Agent 协作

#### 定义

使用多个 Claude Code Agent 实例并行或串行协作完成复杂任务。每个 Agent 有明确角色、职责和信息边界。

#### 7 类 Agent 设计

| Agent 类型 | 角色 | 触发时机 | 输出 |
|-----------|------|---------|------|
| **Explore Agent** | 代码分析师 | 阶段一源码扫描 | 模块清单、依赖图 |
| **Plan Agent** | 架构师 | 阶段一 Spec、阶段二方案设计 | Spec 文档、技术方案 |
| **Code Agent** | 开发工程师 | 阶段二代码生成 | .ets 源文件 |
| **Fix Agent** | 修复工程师 | 阶段三多轮修复 | 修复 diff、根因分析 |
| **Review Agent** | 质量审计员 | 阶段四质量扫描 | 审计报告 |
| **Test Agent** | 测试工程师 | 阶段五回归管理 | 测试矩阵、验证结果 |
| **Bug Agent** | 问题路由器 | 阶段五接收反馈 | Bug 分析 + 路由到 Skill |

#### 五阶段 Agent 编排策略

**阶段一：4 个 Explore Agent 并行扫描**

```
         ┌─── Explore Agent 1 (数据层) ───→ Entity/DAO 清单
         │
源码 ───├─── Explore Agent 2 (UI 层) ────→ Activity/Fragment 清单
         │
         ├─── Explore Agent 3 (工具层) ──→ Helper/Service 清单
         │
         └─── Explore Agent 4 (构建) ────→ 依赖/权限清单
                                              │
                           Plan Agent ←───────┘
                               │
                          Spec 文档 (SS1-SS12)
```

**阶段二：Code Agent 按层串行 + 层内并行**

```
Code Agent (骨架) → Code Agent (适配层) → Code Agent×7 (DAO 并行)
                                              │
                                    Code Agent (导航骨架)
                                              │
                                    Code Agent (状态管理)
                                              │
                                    Code Agent×N (组件并行)
```

**阶段三：Fix Agent 路由决策**

```
人工反馈 → Fix Agent → 判断根因
                │
                ├─ 语言约束错误 → 套用修复模板
                ├─ 平台语义差异 → 查询 Memory 踩坑
                └─ 架构级问题 → 升级 Opus → 结构性重写
```

**阶段四：Review Agent 多维度并行**

```
         ┌─── Review (安全性) ─────→
代码库 ──├─── Review (资源管理) ───→ 审计报告
         ├─── Review (类型安全) ───→
         └─── Review (导入规范) ───→
```

**阶段五：Test + Bug Agent 协作**

```
测试反馈 → Bug Agent → 分析路由 → Code Agent (修复) → Test Agent (回归)
```

#### 并行 vs 串行决策

| 场景 | 策略 | 理由 |
|------|------|------|
| 源码扫描 4 维度 | **并行** | 无依赖 |
| 7 个 DAO 生成 | **并行** | 无依赖 |
| 骨架→适配层→数据层 | **串行** | 上层依赖下层 |
| 质量扫描 4 维度 | **并行** | 无依赖 |
| Bug 修复→回归验证 | **串行** | 验证依赖修复 |

---

### 支柱 6: 大小模型协作

#### 定义

根据任务复杂度、推理深度和成本敏感度，在 Opus、Sonnet、Haiku 三个模型之间动态选择。

#### 能力边界对比

| 维度 | Opus | Sonnet | Haiku |
|------|------|--------|-------|
| 推理深度 | 最强（复杂架构） | 中等（常规逻辑） | 轻量（模式匹配） |
| 代码生成质量 | 最高 | 高（常规足够） | 中等（简单可用） |
| 速度 | 较慢 | 较快 | 最快 |
| 成本 | 高 | 中 | 低 |
| 适用任务 | 架构设计、复杂重写、Spec | 常规代码生成、修复 | 文本扫描、模式匹配 |

#### 五阶段分工表

| 阶段 | Opus 任务 | Sonnet 任务 | Haiku 任务 |
|------|----------|------------|-----------|
| **阶段一** | Spec 架构设计、风险评估、SS12 平台约束 | - | 文件计数、依赖图提取 |
| **阶段二** | 6 个 Manual 模块（RSS 解析器、AVPlayer 状态机、EventBus、后台播放、拖拽替代、workScheduler） | 13 个 Semi-Auto 模块（DAO、Component、ViewModel、Preferences、网络层） | 4 个 Auto 模块（常量、模型字段、SQL DDL、资源引用） |
| **阶段三** | 架构级返工（Tab 栏变更、下载 API 3 次变更） | 常规编译错误修复 | - |
| **阶段四** | - | 逻辑正确性审查 | 模式匹配扫描（any/as/@ohos） |
| **阶段五** | 大型组件重写（495+ 行） | UI 微调（间距/颜色/字体） | - |

#### 动态升级/降级规则

```
任务复杂度评估
       │
       ▼
 ┌─── Manual 级？───→ Opus
 │
 ├─── Semi-Auto 级？──→ Sonnet
 │
 └─── Auto 级？───────→ Haiku

动态升级：Sonnet 修复 2 轮未解决 → 升级 Opus
动态降级：Opus 完成架构设计 → 降级 Sonnet 执行细节
交叉验证：Haiku 扫描发现复杂问题 → 路由 Sonnet/Opus
```

#### 成本优化效果

| 策略 | Token 分布 | 相对成本 |
|------|-----------|---------|
| 全部 Opus | 100% Opus | **3-4x** |
| 全部 Sonnet | 100% Sonnet | 1.5x |
| **混合策略** | Opus 20% + Sonnet 65% + Haiku 15% | **1x（基准）** |

混合策略在**质量不降的前提下，成本仅为全 Opus 的 25-30%**。

---

## Part 4: 竞争力分析

### 与纯手工迁移的对比

| 维度 | 纯手工迁移 | KAIZEN-Migration | 优势 |
|------|-----------|-----------------|------|
| 速度 | AntennaPod 级预估 2-3 人月 | 6 天（17 AI 会话） | **10-15x** |
| 质量一致性 | 依赖个人经验 | CLAUDE.md 约束 + 阶段四 0 违规 | **标准化** |
| 知识传承 | 口头传承 | Memory + Skills 持久化 | **可复制** |
| 平台踩坑 | 逐一试错 | 22 条踩坑即时注入 | **左移 80%** |
| 架构决策 | 个人判断 | Spec SS7 + SS12 | **系统化** |

### 与通用 AI 代码翻译工具的对比

| 维度 | 通用 AI 翻译 | KAIZEN-Migration | 差异化来源 |
|------|------------|-----------------|-----------|
| 平台知识 | 通用 LLM 知识 | 14 个 ArkTS 专项 Skills + 22 条踩坑 | **领域知识壁垒** |
| 约束框架 | 无或简单 prompt | CLAUDE.md 三层 Harness | **Harness Engineering** |
| 跨会话记忆 | 无 | Memory 系统 | **知识持久化** |
| 质量门控 | 无 | 五阶段 Done Gate + 自修复协议 | **流程工程** |
| 多 Agent | 单 Agent | 7 类 Agent 按阶段编排 | **任务分解能力** |
| 可复现性 | 每次不同 | Spec 驱动 + Harness 约束 | **工程确定性** |
| 成本优化 | 单一模型 | Opus/Sonnet/Haiku 三梯队 | **成本效率** |

### 四大核心壁垒

#### 壁垒 1：领域知识沉淀（深度壁垒）

| 知识类型 | 数量 | 积累方式 | 复制难度 |
|---------|------|---------|---------|
| 鸿蒙平台踩坑 | 22 条 | 实战验证 | 高（需真机） |
| Android→ArkTS 概念映射 | 43 组 | 实战验证 | 高（需双平台经验） |
| 已验证 sys.symbol 名称 | 27 个 | 编译验证 | 中 |
| 可复用代码模式 | 16 个 | 实战提炼 | 高 |

#### 壁垒 2：工程约束框架（宽度壁垒）

CLAUDE.md + Skills + Memory 三位一体：
- CLAUDE.md 说"不能做什么"（约束边界）
- Skills 说"应该怎么做"（引导方向）
- Memory 说"之前遇到过什么"（经验传承）

**三者缺一不可**：只有 CLAUDE.md 则知道不能犯错但不知道正确做法；只有 Skills 则有模板但无边界；只有 Memory 则有经验但无结构。

#### 壁垒 3：分阶段质量门控（流程壁垒）

五阶段 Done Gate 确保问题在最早阶段拦截。AntennaPod 量化证明：阶段一 3 个遗漏级联 6+ 个下游问题，如果在阶段一拦截，可节省 15-20% 返工量。

#### 壁垒 4：可复用可迭代的方法论（时间壁垒）

- v1 来自 Gallery 项目（简单应用）
- v2 来自 AntennaPod（复杂播客应用，新增 P3 适配层 + 播客踩坑 P11-P20）
- 每次迁移都沉淀新知识，方法论越来越成熟

---

## Part 5: 量化指标体系

### 每阶段 KPI

| 阶段 | KPI | AntennaPod 实际值 | 下个项目目标 |
|------|-----|------------------|------------|
| **阶段一** | Spec 覆盖率（SS1-SS12） | 11/12（缺 SS12） | 12/12 |
| **阶段一** | 迁移分类准确率 | 100%（6 Manual 全部验证） | >= 95% |
| **阶段一** | Spec 遗漏致下游问题数 | 3 个（级联 6+） | <= 1 |
| **阶段二** | 编译通过率（首次生成） | ~60%（10 个编译错误） | >= 80% |
| **阶段二** | 平台约束命中率 | ~50% | >= 85% |
| **阶段二** | Manual 模块成功率 | 100%（6/6） | 100% |
| **阶段三** | 平均修复迭代次数 | 1.7 轮 | <= 1.2 |
| **阶段三** | 最大单项迭代次数 | 3 轮 | <= 2 |
| **阶段三** | 架构级返工次数 | 2 次 | <= 1 |
| **阶段四** | 质量违规数 | 0 | 0 |
| **阶段四** | 资源泄漏（ResultSet/HTTP） | 0 | 0 |
| **阶段五** | UI 对齐时间占比 | ~40% v1 后时间 | <= 25% |
| **阶段五** | 组件完全重写次数 | 1 次 | 0 |

### 质量指标

| 指标 | AntennaPod 值 | 评级 |
|------|-------------|------|
| 代码质量分 | 9.5/10 | 优秀 |
| 类型安全率（无 any/as） | 100% | 满分 |
| 资源管理率（ResultSet/HTTP 正确释放） | 100% | 满分 |
| SQL 注入安全率 | 100% | 满分 |
| 导入规范率（@kit.*） | 100% | 满分 |
| 踩坑复发率 | 0% | 满分 |

### 效率指标

| 指标 | AntennaPod 值 |
|------|-------------|
| 总开发时间 | 6 天 |
| Claude Code 会话数 | 17 个 |
| .ets 文件产出 | 98 个 |
| 新增代码行 | 6,300+ 行 |
| 文件/会话 | 5.8 个 |
| 代码行/会话 | ~370 行 |

### 成熟度指标

| 指标 | 当前值 | 目标 |
|------|-------|------|
| Skills 平均成熟度 | L2 | L3 |
| Memory 踩坑覆盖率 | 91% | 100% |
| Harness 规则数 | ~15 条 | 20+ |
| Spec 模板完整度 | 11/12 | 12/12 |
| 代码模式库规模 | 16 个 | 25+ |
| 概念映射完整度 | 43 组 | 50+ |

---

## Part 6: 未来演进路线图

### 短期（1-2 个月）

| 优先级 | 行动项 | 预期效果 | 工作量 |
|-------|--------|---------|-------|
| P0 | 合并 Top-10 踩坑到 CLAUDE.md | 每次会话自动加载关键约束 | 0.5 天 |
| P0 | 完善 SS12 鸿蒙平台约束模板 | Spec 遗漏从 3 个降至 <=1 | 1 天 |
| P0 | `arkts-media-playback` / `arkts-download-manager` 推进到 L2 | 播放/下载高风险域完整 Skill 覆盖 | 2 天 |
| P1 | 结构化已验证 API 参考数据库 | 消除 API 命名猜测错误 | 1 天 |
| P1 | 定义 7 条核心路径 Smoke Test 清单 | 阶段五回归标准化 | 1 天 |
| P1 | 建立 Memory 归档→Skills 迁移流程 | 踩坑→通用知识传递 | 1 天 |

### 中期（3-6 个月）

| 优先级 | 行动项 | 预期效果 |
|-------|--------|---------|
| P0 | 接入 hvigorw CLI 实现"生成即编译"反馈环 | 阶段三迭代从 1.7 降至 ~1.2 |
| P0 | 实现 Opus/Sonnet/Haiku 自动路由 | 成本降低 30-40%，质量不降 |
| P1 | 构建 ArkTS 轻量 Linter（any/as/对象字面量） | 编译前捕获 3 类最常见违规 |
| P1 | 实现 Multi-Agent 并行框架（Team 模式） | DAO 批量/组件并行效率提升 3-4x |
| P1 | 建立 UI 截图对比回归体系 | 阶段五效率提升 30% |
| P2 | 全部 Skills 推进到 L3 | 方法论可交付给其他团队 |
| P2 | 建立 DFX 体系（hilog + 错误码 + 性能基线） | 问题定位效率提升 |

### 长期（6-12 个月）

| 优先级 | 行动项 | 预期效果 |
|-------|--------|---------|
| P0 | KAIZEN-Migration 产品化：CLI 工具 + Web 界面 | 非 AI 专家也能执行迁移 |
| P0 | 支持更多源平台：iOS Swift→ArkTS、Flutter→ArkTS | 方法论从单源扩展到多源 |
| P1 | 建立 Benchmark 项目集（5+ 个不同类型应用） | 量化不同应用类型的迁移效率 |
| P1 | 全部 Skills 推进到 L4 | 标准化，跨项目复用 |
| P2 | 引入 RAG 系统：向量化全部 Skills + Memory + 踩坑 | 语义检索智能知识注入 |
| P2 | 建立迁移质量认证体系 | 标准化质量认证 |

### 演进里程碑

```
当前 (v2)                  短期                 中期                 长期
━━━━━━━━                  ━━━━                 ━━━━                 ━━━━
17 会话/98 文件            CLAUDE.md 增强       生成即编译反馈环     产品化 CLI
9.5/10 质量               SS12 完善            模型自动路由         多源平台支持
14 Skills (L2)            +2 新 Skill          全 Skills L3         全 Skills L4
22 条踩坑                  Top-10 合入 Harness  轻量 Linter          RAG 知识系统
手动模型选择                模型选择指南          自动模型选择         自适应策略
单项目验证                  2 项目验证            5+ Benchmark        行业标准
```

---

## 附录：关键术语表

| 术语 | 定义 |
|------|------|
| **Spec** | 迁移规格文档，SS1-SS12 格式的结构化分析报告 |
| **Skill** | Claude Code 的领域专家插件，封装生成规则和代码模板 |
| **Harness** | 工程约束框架，以 CLAUDE.md 为核心载体，生成时自动约束 LLM 输出 |
| **Memory** | 跨会话持久化知识，存储在项目级 Memory 文件中 |
| **Done Gate** | 阶段质量门控，必须通过才能进入下一阶段 |
| **Hub Skill** | 具备跨 Skill 编排能力的入口 Skill |
| **Manual 级** | 需要人工设计方案后再翻译的高风险模块 |
| **Semi-Auto 级** | 有明确映射关系，可半自动翻译的模块 |
| **自修复协议** | 阶段三的查表驱动修复策略 |
| **三级渐进加载** | Skill 的 description→SKILL.md→references 知识加载机制 |
| **左移** | 将问题拦截从下游阶段前移到上游阶段 |
| **KAIZEN** | Knowledge-Augmented, Iterative, Zero-defect, Engineering-constrained, N-agent |
