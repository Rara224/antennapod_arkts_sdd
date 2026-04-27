# KAIZEN-Migration 完整架构设计

> 版本：v1.0
> 日期：2026-03-23
> 目标：将 Spec + Skills 扩展为六大组件闭环系统，覆盖 Memory、Multi-Agent、大小模型路由、Stage Gate

---

## 一、当前状态 vs 目标状态

```
当前：两个输出件
┌──────────┐     ┌──────────┐
│   Spec   │     │  Skills  │
│ (文档产物)│     │ (知识产物)│
└──────────┘     └──────────┘

目标：六大组件形成闭环系统
┌──────┐  ┌──────┐  ┌────────┐  ┌──────┐  ┌───────────┐  ┌────────────┐
│ Spec │  │Skills│  │Harness │  │Memory│  │Multi-Agent│  │Model Router│
│ 蓝图 │  │ 专家 │  │ 护栏   │  │ 记忆 │  │  劳力     │  │  梯队调度   │
└──────┘  └──────┘  └────────┘  └──────┘  └───────────┘  └────────────┘
```

---

## 二、四层架构总览

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        KAIZEN-Migration 完整架构                                 │
│                                                                                 │
│  ┌─── 控制层 (Control Plane) ──────────────────────────────────────────────┐    │
│  │                                                                         │    │
│  │  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                  │    │
│  │  │ Model Router │   │ Agent       │   │ Stage Gate  │                  │    │
│  │  │ 模型路由器    │   │ Orchestrator│   │ Controller  │                  │    │
│  │  │             │   │ Agent 编排器 │   │ 阶段门控器   │                  │    │
│  │  │ Opus ←→任务  │   │             │   │             │                  │    │
│  │  │ Sonnet←→任务 │   │ 分配/回收   │   │ Done Gate   │                  │    │
│  │  │ Haiku ←→任务 │   │ 并行/串行   │   │ 质量检查    │                  │    │
│  │  └──────┬──────┘   └──────┬──────┘   └──────┬──────┘                  │    │
│  │         │                 │                  │                          │    │
│  └─────────┼─────────────────┼──────────────────┼──────────────────────────┘    │
│            │                 │                  │                                │
│  ┌─── 知识层 (Knowledge Plane) ────────────────────────────────────────────┐    │
│  │         │                 │                  │                           │    │
│  │  ┌──────▼──────┐  ┌──────▼──────┐  ┌───────▼───────┐                  │    │
│  │  │   Skills    │  │   Memory    │  │    Harness    │                  │    │
│  │  │  (15 个)    │  │  (持久化)   │  │  (CLAUDE.md)  │                  │    │
│  │  │             │  │             │  │               │                  │    │
│  │  │ Hub(3个)    │  │ 踩坑清单    │  │ 语言约束层    │                  │    │
│  │  │ 生成(8个)   │  │ 概念映射    │  │ 平台约束层    │                  │    │
│  │  │ 分析(1个)   │  │ 自修复协议  │  │ 项目约束层    │                  │    │
│  │  │ 决策(1个)   │  │ UI映射经验  │  │               │                  │    │
│  │  │ 管线(1个)   │  │ API验证表   │  │ 踩坑→新规则   │                  │    │
│  │  │ 对齐(1个)   │  │ 架构决策    │  │               │                  │    │
│  │  └─────────────┘  └─────────────┘  └───────────────┘                  │    │
│  │         ↑                ↑↓                ↑                           │    │
│  │         │           沉淀/读取          踩坑沉淀                         │    │
│  └─────────┼────────────────┼─────────────────┼────────────────────────────┘    │
│            │                │                 │                                  │
│  ┌─── 执行层 (Execution Plane) ────────────────────────────────────────────┐    │
│  │                                                                         │    │
│  │  [阶段一]──→[阶段二]──→[阶段三]──→[阶段四]──→[阶段五]                    │    │
│  │   Spec      代码       修复       质量       测试                       │    │
│  │  Explore×4  Code×N    Fix Agent  Review×4   Test+Bug                   │    │
│  │  Plan Agent           路由修复    并行审查    Agent                      │    │
│  │     ↓          ↓          ↓          ↓          ↓                       │    │
│  │  Gate✓      Gate✓      Gate✓      Gate✓      Gate✓                     │    │
│  │                                                                         │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌─── 产出层 (Artifact Plane) ─────────────────────────────────────────────┐   │
│  │                                                                         │   │
│  │  Spec文档 → .ets代码 → 可运行版本 → 质量报告 → 生产版本 → 反哺知识层     │   │
│  │                                                                         │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 三、控制层详解（大脑）

控制层负责**决策**——用哪个模型、派哪个 Agent、是否放行到下一阶段。

### 3.1 Model Router（模型路由器）

根据任务复杂度自动选择 Opus / Sonnet / Haiku。

```
任务复杂度评估
       │
       ├─── SS7 标记为 Manual？──→ Opus（深度推理）
       │
       ├─── SS7 标记为 Semi-Auto？──→ Sonnet（常规生成）
       │
       └─── SS7 标记为 Auto？──→ Haiku（模式匹配）

动态升级：Sonnet 修复 2 轮未解决 → 自动升级为 Opus
动态降级：Opus 完成架构设计 → 降级 Sonnet 执行细节
```

| 模型 | 适用任务 | 五阶段分工 | 成本 |
|------|---------|-----------|------|
| **Opus** | 架构设计、复杂重写、Spec 生成、Manual 模块 | 阶段一 Spec + 阶段二 Manual(6 个) + 阶段三架构返工 + 阶段五大型重写 | 高 |
| **Sonnet** | 常规代码生成、修复、审查 | 阶段二 Semi-Auto(13 个) + 阶段三常规修复 + 阶段四逻辑审查 + 阶段五微调 | 中 |
| **Haiku** | 文本扫描、模式匹配、简单翻译 | 阶段一文件计数 + 阶段二 Auto(4 个) + 阶段四 grep 扫描 | 低 |

**成本效果**：混合策略（Opus 20% + Sonnet 65% + Haiku 15%）仅为全 Opus 的 **25-30%**，质量不降。

### 3.2 Agent Orchestrator（Agent 编排器）

按 DAG 依赖图自动分配 Agent，决定并行还是串行。

```
                      Agent Orchestrator
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         无依赖？        有依赖？        同层？
              │              │              │
              ▼              ▼              ▼
           并行           串行          可并行
         (4 Explore)   (P2→P3→P4)    (7 DAO 并行)
```

| 阶段 | Agent 编排策略 |
|------|--------------|
| 阶段一 | 4 个 Explore Agent **并行**扫描（数据/UI/工具/构建） |
| 阶段二 | Code Agent **按 DAG 串行**（P2→P3→P4→P5a→P5b→P5c），层内**并行**（7 DAO 并行） |
| 阶段三 | Fix Agent **单线程路由**（分析错误类型 → 分发到对应 Skill） |
| 阶段四 | 4 个 Review Agent **并行**审查（类型/资源/导入/SQL 四个维度） |
| 阶段五 | Test Agent + Bug Agent **协作**（Bug 接收 → 路由修复 → 回归验证） |

### 3.3 Stage Gate Controller（阶段门控器）

每个阶段结束时自动检查 Done Gate 清单，全部通过才放行。

| 阶段 | Done Gate 检查项 | 检查方式 |
|------|-----------------|---------|
| 阶段一 | SS1-SS12 章节完整 / SS7 全标记 / manifest 验证通过 / 分批计划就绪 | 脚本检查 + 人工审查 |
| 阶段二 | hvigor 编译通过 / 覆盖率 100% / Post-batch 验证 PASS / 目录与 Spec 一致 | `verify_target_build` + `check_coverage` |
| 阶段三 | 编译零错误 / 应用可启动 / 核心路径走通 / 踩坑已沉淀 | 编译 + 手动验证 |
| 阶段四 | 7 大规范域零违规 / 质量 ≥ 9.0 | grep 扫描 + Sonnet 审查 |
| 阶段五 | SS10 验收矩阵通过 / 截图对比无差异 / 7 路径走通 / 经验已沉淀 | 手动验证 + 沉淀检查 |

**失败处理**：
- 失败 → 回退到当前阶段修复
- 连续 3 次失败 → 升级为人工介入
- 跨阶段根因 → 回退到根因阶段修复

---

## 四、知识层详解（记忆）

### 4.1 三大知识组件的协作关系

```
Skills (教怎么做)        Memory (记住经验)       Harness (划红线)
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│  15 个 Skill │       │  5 类文件    │       │  CLAUDE.md   │
│  references/ │←─读取─│  持久化知识  │─沉淀─→│  三层约束    │
│  Hub 编排    │       │             │       │  自动加载    │
│  幻觉防线    │       │  跨会话     │       │  Done Gate   │
└──────┬───────┘       └──────┬───────┘       └──────┬───────┘
       │                      │                       │
       └──────────────────────┼───────────────────────┘
                              │
                    共同服务于五阶段流水线
```

**知识归属决策矩阵**：

| 知识类型 | 存入位置 | 理由 |
|---------|---------|------|
| 每次会话必须遵守的底线规则 | **Harness (CLAUDE.md)** | 自动加载，零遗漏 |
| 项目特有架构决策 | **Memory** | 项目级，不适用于其他项目 |
| 高频踩坑（Top-10） | **Harness + Memory** | Harness 确保自动加载，Memory 保留完整上下文 |
| 跨项目通用 ArkTS 规范 | **Skills (references/)** | 其他项目也需要 |
| 已验证 API 参考 | **Skills (verifier/references/)** | 跨项目通用 |

### 4.2 Memory 扩展设计（从 1 个文件 → 5 类文件）

| Memory 文件 | 内容 | 写入时机 | 读取时机 |
|------------|------|---------|---------|
| `project_migration_steps.md` | 六阶段方法论 + 踩坑清单 | 项目启动时创建 | 每次会话自动加载 |
| `platform_constraints.md` | **新增**。本项目发现的平台约束 | 阶段三每次踩坑时 | 阶段二代码生成前 |
| `architecture_decisions.md` | **新增**。架构决策记录 | 阶段二做决策时 | 阶段五修复时避免推翻已有决策 |
| `api_verification.md` | **新增**。已验证/不可用的 API | 阶段二/三验证后 | 阶段二代码生成时 |
| `ui_patterns.md` | **新增**。Android→ArkUI 视觉映射 | 阶段五 UI 对齐后 | 下个项目阶段二/五 |

### 4.3 Memory 生命周期

```
P1 阶段：创建 Memory 索引 + 方法论文件
   │
P2-P4：增长（新增踩坑、架构决策、API 验证）
   │
P5：稳定（完善验证结果、标注已解决/未解决）
   │
项目结束：归档
   ├─→ 通用知识 → 提炼到 Skills references/
   ├─→ 底线规则 → 合入 Harness CLAUDE.md
   └─→ 项目专属 → 保留在 Memory（下次参考）

下个项目：
   ├─ 加载 Skills（通用知识）
   ├─ 加载 Harness（底线规则）
   └─ 创建新 Memory（项目专属知识）
```

### 4.4 知识反哺闭环

```
阶段二/三 发现新踩坑
         │
         ▼
分析根因 → 归类（语言 / 平台 / 项目层）
         │
         ▼
    ┌────┴────┐
    ▼         ▼
 通用知识   项目专属
    │         │
    ├→ Skills references/ 更新
    ├→ Harness CLAUDE.md 新增规则
    └→ Memory 踩坑清单追加
```

---

## 五、执行层详解（手脚）

### 5.1 七类 Agent 设计

| Agent 类型 | 角色 | 使用模型 | 触发阶段 |
|-----------|------|---------|---------|
| **Explore Agent** | 代码分析师 | Haiku/Sonnet | 阶段一 |
| **Plan Agent** | 架构师 | Opus | 阶段一 |
| **Code Agent** | 开发工程师 | Sonnet(Semi) / Opus(Manual) | 阶段二 |
| **Fix Agent** | 修复工程师 | Sonnet / Opus(升级) | 阶段三 |
| **Review Agent** | 质量审计员 | Haiku(扫描) / Sonnet(审查) | 阶段四 |
| **Test Agent** | 测试工程师 | Sonnet | 阶段五 |
| **Bug Agent** | 问题路由器 | Sonnet | 阶段五 |

### 5.2 五阶段 Agent 编排图

**阶段一：并行扫描 + 并行审计**

```
用户指令
    │
    ├─→ Explore×4 (并行)          view-to-arkui (并行)
    │    ├─ 数据层 → SS5           ├─ scan → manifest.json
    │    ├─ UI 层 → SS4            ├─ deep_verify → 验证报告
    │    ├─ 工具层 → SS2           └─ build_feature_pack → batches/
    │    └─ 构建 → SS3
    │
    └─→ Plan Agent → 合并产出 Spec (SS1-SS12)
```

**阶段二：DAG 串行 + 层内并行**

```
P2 骨架 (scaffolder)
    │
    ▼
P3 适配层 (data-layer + system-capabilities + library-migration)  ← 可并行
    │
    ▼
P4 数据层 (data-layer: 7 DAO 并行)
    │
    ▼
P5a 导航+播放 (navigation + media-playback)  ← 可并行
    │
    ▼
P5b 状态+下载 (state-manager + download-manager)  ← 可并行
    │
    ▼
P5c 组件 (component-builder × N 并行 + pattern-library Hub + animation)

    全程: knowledge-verifier 辅助 + view-to-arkui 覆盖率检查
```

**阶段三：错误路由**

```
人工反馈 → Fix Agent → knowledge-verifier [入口路由]
                │
                ├─ ArkTS 语言错误 → verifier 直接修复（固定模式）
                ├─ UI 显示异常 → component-builder + navigation-builder
                ├─ 播放器异常 → media-playback
                ├─ 下载失败 → download-manager
                ├─ 数据库错误 → data-layer
                └─ 系统能力异常 → system-capabilities
```

**阶段四：多维度并行审查**

```
代码库 → 4 个 Review Agent 并行
         ├─ 类型安全 (any/as/对象字面量)      → Haiku 扫描
         ├─ 资源管理 (ResultSet/HTTP close)   → Haiku 扫描
         ├─ 导入规范 (@kit.* vs @ohos.*)      → Haiku 扫描
         └─ 逻辑正确性 (DAO/状态/导航)         → Sonnet 审查
                                │
                                ▼
                          质量审计报告
```

**阶段五：Bug 驱动 + 经验沉淀**

```
测试反馈 → Bug Agent → 分类路由
              │
              ├─ UI 视觉 → ui-alignment + component-builder
              ├─ 功能缺陷 → pattern-library [Hub] → 对应 Skill
              ├─ 交互体验 → animation-builder
              └─ 导航问题 → navigation-builder
                                │
                          修复 → 验证 → 沉淀
                                         │
                                    ┌────┴────┐
                                    ▼         ▼
                              Memory 更新   Skills 更新
                              Harness 更新
```

---

## 六、产出层详解（成果）

### 6.1 各阶段交付物

| 阶段 | 交付物 | 格式 | 驱动下游 |
|------|-------|------|---------|
| 阶段一 | migration-spec.md (SS1-SS12) | Markdown | 阶段二的生成范围和技术选型 |
| 阶段一 | manifest.json | JSON | 阶段二的 UI 组件清单 |
| 阶段一 | batches/*.md + .json | Markdown + JSON | 阶段二的分批执行计划 |
| 阶段二 | .ets 源文件 (98 个) | ArkTS | 阶段三的修复目标 |
| 阶段二 | migration-index.json | JSON | 覆盖率追踪 |
| 阶段二 | CLAUDE.md | Markdown | 阶段三-五的约束规则 |
| 阶段三 | 可编译可运行的代码 | ArkTS | 阶段四的审查目标 |
| 阶段三 | dev-pitfalls.md | Markdown | 踩坑沉淀 |
| 阶段四 | 质量审计报告 | Markdown | 确认代码基线质量 |
| 阶段五 | 生产版本 (v3) | 完整项目 | 最终交付 |
| 阶段五 | development-experience.md | Markdown | 反哺知识层 |

### 6.2 反哺路径

```
阶段五产出                    反哺到知识层
─────────                    ──────────
development-experience.md
  ├─ 22 条踩坑           ──→ Memory (platform_constraints.md)
  │                          Harness (CLAUDE.md Top-10)
  ├─ 16 个代码模式        ──→ Skills (references/ 新增模板)
  ├─ 14 组 UI 映射        ──→ Memory (ui_patterns.md)
  └─ 架构决策记录          ──→ Memory (architecture_decisions.md)
```

---

## 七、六大组件交互关系（一页总结）

```
                    ┌─────────────────┐
                    │  Model Router   │
                    │  (选模型)        │
                    └────────┬────────┘
                             │ 分配任务给对应模型
                             ▼
┌──────────┐  路由  ┌─────────────────┐  分配  ┌──────────────┐
│  Skills  │←──────│ Agent           │──────→│  五阶段      │
│ (教怎么做)│  触发  │ Orchestrator    │ Agent  │  流水线      │
└────┬─────┘       │ (编排 Agent)    │       └──────┬───────┘
     │             └─────────────────┘              │
     │                      ↑                       │
     │              Gate 检查结果                     │ 产出
     │                      │                       ▼
     │             ┌─────────────────┐      ┌──────────────┐
     │             │  Stage Gate     │←─────│  产出物      │
     │             │  Controller     │ 检查  │  (代码/文档)  │
     │             │  (质量门控)      │       └──────┬───────┘
     │             └─────────────────┘              │
     │                                              │ 踩坑沉淀
     ▼                                              ▼
┌──────────┐  约束  ┌─────────────────┐  反哺  ┌──────────────┐
│ Harness  │──────→│  代码生成过程    │←──────│  Memory      │
│(不能做什么)│ 自动   │                 │  注入  │  (记住经验)   │
└──────────┘ 加载   └─────────────────┘       └──────────────┘
```

**核心交互逻辑**：

| 交互 | 方向 | 说明 |
|------|------|------|
| Model Router → Agent | 下发 | 按任务复杂度选择模型，分配给 Agent |
| Agent Orchestrator → 五阶段 | 下发 | 按 DAG 依赖图分配 Agent 到各阶段 |
| Skills → Agent | 供给 | Agent 按需加载 Skill 的 references |
| Harness → 代码生成 | 约束 | CLAUDE.md 每次会话自动加载，划定边界 |
| Memory → 代码生成 | 注入 | 踩坑清单、API 验证表注入上下文 |
| 产出物 → Stage Gate | 检查 | 每阶段产出物必须通过 Done Gate |
| 产出物 → Memory | 反哺 | 新踩坑沉淀到 Memory |
| Memory → Skills | 提炼 | 通用知识提炼到 Skills references |
| Memory → Harness | 沉淀 | 底线规则合入 CLAUDE.md |

---

## 八、落地路线图

### Phase 1: Memory 扩展（1 周）

| 任务 | 产出 | 优先级 |
|------|------|-------|
| 从 1 个 Memory 文件扩展到 5 类 | 5 个 Memory 模板文件 | P0 |
| 建立"踩坑→Memory→Skills/Harness"沉淀 SOP | 沉淀流程文档 | P0 |
| 整理 AntennaPod 已有踩坑到新 Memory 结构 | 已有知识迁移完成 | P0 |

### Phase 2: Gate 自动化（2 周）

| 任务 | 产出 | 优先级 |
|------|------|-------|
| 阶段一 Gate：SS 章节完整性检查脚本 | gate_stage1.sh | P0 |
| 阶段二 Gate：覆盖率 + 编译检查脚本 | gate_stage2.sh | P0 |
| 阶段四 Gate：7 大规范域 grep 扫描脚本 | gate_stage4.sh | P0 |
| 阶段三/五 Gate：手动检查清单模板 | gate_checklist.md | P1 |

### Phase 3: Agent 编排（2 周）

| 任务 | 产出 | 优先级 |
|------|------|-------|
| 阶段二 DAG 并行框架（Team 模式） | Agent 编排配置 | P1 |
| 阶段一 4 Explore 并行模板 | explore_template.md | P1 |
| 阶段四 4 Review 并行模板 | review_template.md | P1 |

### Phase 4: Model 路由（1 周）

| 任务 | 产出 | 优先级 |
|------|------|-------|
| 基于 SS7 分类的模型选择规则 | model_routing_rules.md | P1 |
| 动态升级/降级规则 | 集成到 Agent Orchestrator | P2 |

### Phase 5: 反哺闭环（持续）

| 任务 | 产出 | 优先级 |
|------|------|-------|
| 每个项目结束后执行知识沉淀 SOP | 更新后的 Memory/Skills/Harness | 持续 |
| 每季度审查 Skills 成熟度 | skill-baseline.md 版本更新 | 持续 |

### 里程碑

```
当前 (v2)                  Phase 1-2          Phase 3-4          Phase 5
━━━━━━━━                  ━━━━━━━━           ━━━━━━━━           ━━━━━━━━
Spec + Skills             + Memory 扩展      + Agent 编排       + 反哺闭环
CLAUDE.md                 + Gate 自动化      + Model 路由       + 持续演进
手动 Agent                  半自动 Gate        半自动编排         飞轮效应
手动选模型                                     规则驱动选模型
1 个 Memory 文件           5 类 Memory        Team 模式         越用越强
```

---

## 九、一句话总结

> **控制层决策（选模型、派 Agent、卡门控）→ 知识层供给（Skills 教方法、Harness 划红线、Memory 提经验）→ 执行层干活（Multi-Agent 按 DAG 执行五阶段）→ 产出层交付并反哺知识层，形成越用越强的飞轮。**
