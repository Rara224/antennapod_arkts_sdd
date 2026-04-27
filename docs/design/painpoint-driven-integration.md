# KAIZEN-Migration v2：痛点驱动技术集成方案

> 版本：v1.0（APPROVED）
> 日期：2026-03-23
> 来源：/office-hours 产出，经 Spec Review（14 issues found, 14 fixed, 8.5/10）
> 状态：已批准，Phase 1 可启动

---

## 一、问题陈述

KAIZEN-Migration v1（Spec + Skills + Harness）已在 AntennaPod 项目验证（98 文件 / 质量 9.5/10），但实际使用中暴露了 **7 个痛点**。领导需要看到：把 Memory、Multi-Agent、Model Router、Stage Gate 等技术集成进来后，这 7 个痛点分别怎么解决。

**核心原则**：每个技术投入都必须有明确的痛点对应，不做多余的事。

---

## 二、7 个痛点 → 7 个技术解法

### 痛点 1: 知识丢失 → Memory 5 类文件

**现象**：每次新会话 LLM 忘记上次的踩坑和决策，重复犯错。

**技术解法**：将 Memory 从 1 个文件扩展为 5 类文件，每次会话自动加载。

| Memory 文件 | 解决什么 | 写入时机 | 读取时机 |
|------------|---------|---------|---------|
| `project_migration_steps.md` | 方法论+踩坑清单遗忘 | 项目启动 | 每次会话 |
| `platform_constraints.md` | 平台约束重复踩坑 | 阶段三每次踩坑 | 阶段二代码生成前 |
| `architecture_decisions.md` | 架构决策被推翻 | 阶段二做决策时 | 阶段五修复时 |
| `api_verification.md` | API/symbol 重复验证 | 阶段二/三验证后 | 阶段二代码生成时 |
| `ui_patterns.md` | UI 映射经验丢失 | 阶段五对齐后 | 下个项目阶段二/五 |

**写入机制**：
- `platform_constraints.md`：LLM 在阶段三每次修复踩坑后追加，人工审查
- `architecture_decisions.md`：人工在阶段二做关键决策时记录
- `api_verification.md`：LLM 在阶段二/三验证 API 后追加
- `ui_patterns.md`：人工在阶段五 UI 对齐完成后总结
- **淘汰规则**：项目结束时，通用知识提炼到 Skills references/，项目专属保留在 Memory，过时条目标注 `[STALE]`

**验证标准**：同一个踩坑在新会话中复发率从"偶尔"降到 **0%**。度量方式：下个项目统计同类错误数。

---

### 痛点 2: 编译反馈慢 → Stage Gate Controller + ArkTS Linter

**现象**：生成代码后要手动编译、复制错误、贴回 LLM，往返多轮。平均 1.7 轮修复。

**技术解法（两层）**：

**第一层：ArkTS 轻量 Linter（秒级反馈）**
```
生成代码 → [Linter 扫描 any/as/对象字面量] → 立即修复 → 再生成
```
实现：文本扫描规则，不需要完整编译链。捕获 3 类最常见的 ArkTS 严格模式违规。

**第二层：hvigorw CLI 编译验证（分钟级反馈，条件性）**
```
Linter 通过 → [hvigorw --mode module] → 编译错误 → 自动修复
```
实现：每个 batch 完成后自动调用 `verify_target_build`（android-view-to-arkui 已内置）。

> **条件性**：hvigorw CLI 的 macOS 可用性待确认（OQ-1）。如果不可用，痛点 #2 仍可通过 Linter 解决 60% 的编译错误（3 类 ArkTS 违规），剩余 40% 依赖人工编译反馈。

**验证标准**：平均修复迭代从 1.7 轮降到 **≤1.2 轮**。度量方式：统计每个 bug 的修复轮数。

---

### 痛点 3: Agent 编排繁琐 → Multi-Agent DAG 编排

**现象**：每次手动启动多个 Agent，手动协调并行/串行。

**技术解法**：Agent Orchestrator 基于 DAG 依赖图自动编排。

```
阶段一: Explore×4 并行（无依赖）
阶段二: Code Agent 按 DAG 串行（P2→P3→P4→P5），层内并行（7 DAO 并行）
阶段三: Fix Agent 单线程（按错误类型路由）
阶段四: Review×4 并行（4 个审查维度）
阶段五: Test+Bug Agent 协作
```

**实现方式**：使用 Claude Code Team 模式。Orchestrator 读取 Spec SS7 的模块列表和依赖关系，自动生成 Task DAG 并分配给 Agent。

> **条件性**：Team 模式稳定性待确认（OQ-2）。如果不稳定，退回手动编排 + 检查清单脚本，效率提升从 3-4x 降为 ~2x。

**验证标准**：阶段二代码生成中，DAO 批量生成和组件并行效率提升 **3-4x**。度量方式：对比手动 vs 自动编排的耗时。

---

### 痛点 4: UI 对齐耗时 → ui-alignment Skill 升级 + 截图对比

**现象**：~40% 的 v1 后时间花在视觉调整上，反复截图对比。

**技术解法（三层）**：

**第一层：UI 组件映射模板库**
将 AntennaPod 实战中验证的 14 组 Android→ArkUI 映射固化为 ui-alignment Skill 的 references，新项目直接复用。

**第二层：截图对比工具**
使用 gstack `/browse` 的 `screenshot` + `diff` 命令，自动生成 Android 原版 vs ArkTS 实现的视觉差异报告。Android 参考截图预先从真机/模拟器截取，存储在 `docs/screenshots/android/` 目录。

**第三层：已验证 sys.symbol 清单**
从 Memory `api_verification.md` 加载 22 个可用 + 5 个不可用的 symbol 名称，代码生成时直接引用。

> 注：痛点 #4 和 #6 共享同一个底层方案（api_verification.md），但解决的问题不同：#4 是 UI 对齐效率，#6 是 symbol 名称编译失败。

**验证标准**：UI 对齐时间占比从 ~40% 降到 **≤25%**。度量方式：统计阶段五时间占比。

---

### 痛点 5: 多级功能缺失 → view-to-arkui 覆盖率追踪

**现象**：一次性迁移遗漏子组件（Adapter/Dialog/菜单），每轮测试都发现新缺失。

**技术解法**：android-view-to-arkui 的覆盖率追踪机制。

```
Step 1:   scan_android_ui    → manifest.json（完整 UI 清单）
Step 1.5: deep_verify        → 继承链交叉验证（确保无遗漏）
Step 2:   build_feature_pack → 分批计划
每批完成后:
  Step 5:   check_coverage   → 覆盖率报告（exit 0 才继续）
  Step 5.5: Post-batch 验证  → include/Adapter/Dialog/菜单逐项检查
```

**验证标准**：migration-index.json 覆盖率达到 **100%** 才允许进入阶段三。度量方式：check_coverage exit code。

---

### 痛点 6: 图标不一比一 → Memory api_verification.md

**现象**：sys.symbol 名称猜测导致编译失败，需要逐个验证。

**技术解法**：维护已验证 API 参考数据库。

| 当前 | 目标 |
|------|------|
| 22 个已验证 sys.symbol 分散在 development-experience.md | 整合到 Memory `api_verification.md`，代码生成时自动注入 |
| 每次猜测→编译→失败→替换 | 直接从已验证清单选取，新名称验证后追加 |

**持续维护**：每次项目发现新的可用/不可用 symbol → 更新 api_verification.md → 提炼到 Skills references → 下个项目自动可用。

**验证标准**：symbol 名称编译失败从 5+ 次降到 **0 次**。

---

### 痛点 7: 三方库处理 → library-migration Skill L2→L3

**现象**：遇到三方库依赖不确定用什么替代，决策链长。

**技术解法**：升级 library-migration Skill 的 5 层查找策略。

```
Layer 1: ohpm 包搜索（最低成本）
Layer 2: HarmonyOS @kit.* 原生 API（零依赖）
Layer 3: NAPI 桥接 C/C++ 库（FFmpeg 等）
Layer 4: WebView + JS 库（降级方案）
Layer 5: 自研或功能降级（兜底）
```

**初始交付范围**（控制 scope，先做 5 个速查）：
- 图片加载替代方案速查
- 网络请求替代方案速查
- JSON 解析替代方案速查
- 日期处理替代方案速查
- 加密替代方案速查

映射表扩展（43 组→60+ 组）推迟到后续版本。

**验证标准**：三方库替代方案查找时间从"需要调研"降到"查表即得"（<5 分钟）。

---

## 三、技术 × 痛点映射总表

| 技术组件 | 解决的痛点 | 复杂度 | 预期效果 | 验证方法 | 未达标回退方案 |
|---------|-----------|-------|---------|---------|-------------|
| **Memory 5 类文件** | #1 知识丢失, #6 图标 | 低（1 人周） | 踩坑复发率 0% | 下个项目统计同类错误数 | 回退到手动粘贴踩坑清单 |
| **ArkTS Linter** | #2 编译反馈 | 中（2 人周） | 修复迭代 1.7→1.2 | 统计修复轮数 | 回退到人工编译反馈 |
| **hvigorw CLI** | #2 编译反馈 | 中（条件性） | 编译错误秒级发现 | 对比反馈延迟 | 若不可用，仍用人工编译 |
| **Multi-Agent DAG** | #3 Agent 编排 | 中（条件性） | 效率 3-4x | 对比编排耗时 | 用手动编排+检查清单脚本 |
| **ui-alignment 升级** | #4 UI 对齐 | 低（1 人周） | 时间占比 40%→25% | 统计阶段五时间占比 | 回退到手动截图对比 |
| **view-to-arkui 覆盖率** | #5 功能缺失 | 已有（集成） | 覆盖率 100% 门控 | exit code | 已内置，无需回退 |
| **library-migration L3** | #7 三方库 | 低（1 人周） | 查表即得 | 查找时间 <5 分钟 | 推迟到后续版本 |

---

## 四、分阶段实施计划

```
Phase 1 (第 1 周): Memory 5 类文件  ← 最低成本最高收益，无依赖
    │
    ├──→ platform_constraints.md (踩坑清单)
    ├──→ architecture_decisions.md (决策记录)
    ├──→ api_verification.md (已验证 API/symbol)
    ├──→ ui_patterns.md (UI 映射经验)
    └──→ 更新 project_migration_steps.md

Phase 2 (第 2-3 周): Linter + library-migration  ← 可并行，无依赖
    ├──→ ArkTS Linter (any/as/对象字面量扫描规则)
    └──→ library-migration 5 个速查场景

Phase 3 (第 4-5 周): Multi-Agent DAG  ← 依赖 OQ-2 确认
    └──→ Team 模式编排 or 手动编排+脚本

Phase 4 (第 6 周): ui-alignment 升级 + 截图对比  ← 依赖 Phase 1 (Memory)
    ├──→ 14 组映射模板固化到 references
    └──→ gstack browse 截图对比工作流

Phase 5 (持续): hvigorw CLI 评估  ← 依赖 OQ-1
    └──→ 确认可用性后集成到 Stage Gate
```

**依赖关系图**：
```
Phase 1 (Memory) ───→ Phase 4 (ui-alignment，需读取 Memory)
Phase 2 (Linter) ───→ 独立，可并行
Phase 3 (Agent)  ───→ 依赖 OQ-2 验证结果
Phase 5 (CLI)    ───→ 依赖 OQ-1 验证结果
```

---

## 五、待确认问题 (Open Questions)

| 编号 | 问题 | 如果答案是"不可用" | 影响 |
|------|------|------------------|------|
| OQ-1 | hvigorw CLI 能否在 macOS 命令行调用？ | Linter 兜底 60% 编译错误 | 痛点 #2 部分解决 |
| OQ-2 | Claude Code Team 模式是否稳定？Agent 并行上限？ | 手动编排+脚本，效率 ~2x | 痛点 #3 降级解决 |
| OQ-3 | Memory 5 类文件总 token 量？ | 预估 3K-5K tokens，控制单文件 ≤200 行 | 不影响 |
| OQ-4 | Android 参考截图来源？ | 预先从真机截取存 `docs/screenshots/android/` | 需一次性投入 |

---

## 六、成功标准

- [ ] 7 个痛点每个都有对应的技术解法和验证标准
- [ ] 领导能看到"技术投入→痛点消除"的直接映射
- [ ] 每个方案都有"未达标回退方案"，不存在单点风险
- [ ] 分阶段实施计划清晰，Phase 1 可在 1 周内启动
- [ ] 方案可在下一个迁移项目中验证

---

## 七、下一步行动

**立即启动**：Phase 1 Memory 5 类文件扩展（1 人周，最低成本最高收益）

**同步启动**：OQ-1（hvigorw CLI macOS 可用性）和 OQ-2（Team 模式稳定性）的可行性验证

**然后**：带着 AntennaPod 的实证数据 + 这份痛点→解法映射表，找领导对齐完整方案

---

## 附录：实战观察

- **Spec 前期投入看似慢但省了大量返工** — 阶段一 3 个 Spec 遗漏级联了 6+ 个下游问题，如果在阶段一拦截可省 15-20% 返工
- **UI 对齐比代码翻译难得多** — 代码翻译是结构化的，视觉对齐是主观判断，这是阶段五消耗 ~40% 时间的根本原因
- **多级小功能持续补漏** — 迁移不是一次性事件，每轮测试都发现新缺失。方法论需要内置"持续补漏"机制（view-to-arkui 覆盖率追踪解决的就是这个问题）
