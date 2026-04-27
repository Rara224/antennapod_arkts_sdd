# 五阶段执行流程：输入/输出/Skills 使用梳理

> 日期：2026-03-21（更新：纳入 android-view-to-arkui Skill）
> Skills 目录：`/Users/chenjiamin/.claude/skills/` + `.opencode/skills/`（共 15 个 Skill）
> 基于 AntennaPod 项目实战数据

---

## 一、五阶段总览流程

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  Android 源码                                                                │
│      │                                                                       │
│      ▼                                                                       │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐   │
│  │ 阶段一   │    │ 阶段二   │    │ 阶段三   │    │ 阶段四   │    │ 阶段五   │   │
│  │ Spec 生成│───→│ 代码生成 │───→│ 多轮修复 │───→│ 质量保证 │───→│ 测试优化 │   │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘   │
│       │              │              │              │              │          │
│       ▼              ▼              ▼              ▼              ▼          │
│  migration-spec  .ets 源文件    可编译版本      审计报告       生产版本      │
│  (SS1-SS11)     (98 文件)      (0 编译错误)    (0 违规)       (v3)          │
│                                                                              │
│  Harness: CLAUDE.md ─────── 全阶段自动加载 ──────────────────────────────→   │
│  Memory:  project_migration_steps.md ──── 全阶段知识注入 ───────────────→   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、15 个 Skills 清单

### A. arkts-* 系列（14 个，ArkTS 代码生成与验证）

| # | Skill 名称 | 目录 | 类型 | 一句话描述 |
|---|-----------|------|------|-----------|
| 1 | `arkts-spec-generator` | `skills/arkts-spec-generator/` | 分析类 | Android 源码扫描 → SS1-SS11 迁移 Spec |
| 2 | `arkts-project-scaffolder` | `skills/arkts-project-scaffolder/` | Hub | 从零搭建项目骨架、配置文件、目录结构 |
| 3 | `arkts-knowledge-verifier` | `skills/arkts-knowledge-verifier/` | Hub | ArkTS 知识验证、API 兼容性检查、Skill 路由 |
| 4 | `arkts-component-builder` | `skills/arkts-component-builder/` | 生成类 | 声明式 UI 组件、布局、ForEach/LazyForEach |
| 5 | `arkts-navigation-builder` | `skills/arkts-navigation-builder/` | 生成类 | Navigation + NavPathStack 路由、Tab 导航 |
| 6 | `arkts-state-manager` | `skills/arkts-state-manager/` | 生成类 | @State/@StorageLink/AppStorage 状态管理 |
| 7 | `arkts-data-layer` | `skills/arkts-data-layer/` | 生成类 | 数据模型、网络请求、DAO、DataSource |
| 8 | `arkts-media-playback` | `skills/arkts-media-playback/` | 生成类 | AVPlayer 播放、后台播放、进度保存 |
| 9 | `arkts-download-manager` | `skills/arkts-download-manager/` | 生成类 | request.agent 大文件下载、队列管理 |
| 10 | `arkts-animation-builder` | `skills/arkts-animation-builder/` | 生成类 | animateTo/transition/手势动画 |
| 11 | `arkts-system-capabilities` | `skills/arkts-system-capabilities/` | 生成类 | 权限申请、文件操作、后台任务、媒体库 |
| 12 | `arkts-library-migration` | `skills/arkts-library-migration/` | 决策类 | Android 三方库 → 鸿蒙替代方案查找 |
| 13 | `arkts-pattern-library` | `skills/arkts-pattern-library/` | Hub | 完整业务功能模式（搜索、列表详情、下拉刷新等） |
| 14 | `arkts-ui-alignment` | `skills/arkts-ui-alignment/` | 对齐类 | Android Material → ArkUI 视觉映射 |

### B. android-view-to-arkui（1 个，UI 迁移管线）

| # | Skill 名称 | 目录 | 类型 | 一句话描述 |
|---|-----------|------|------|-----------|
| 15 | `android-view-to-arkui` | `.opencode/skills/android-view-to-arkui/` | **迁移管线** | Android View/XML UI 的结构化分批迁移管线（审计→分批→迁移→覆盖率→构建验证） |

#### android-view-to-arkui 详细说明

**定位**：这是唯一一个**面向 Android 源码侧**的 UI 迁移 Skill。其他 arkts-* Skills 都面向目标侧（生成 ArkTS 代码），而 `android-view-to-arkui` 专注于**源码审计 + 分批规划 + 覆盖率追踪 + 构建验证**的完整管线。

**核心能力**：

| 步骤 | 脚本 | 输入 | 输出 |
|------|------|------|------|
| Step 1: 审计源码 | `scan_android_ui.ps1` | Android 项目根目录 | `manifest.json`（页面/布局/Adapter/Dialog 清单） |
| Step 1.5: 深度验证 | `deep_verify.ps1` | 源码 + manifest.json | `manifest-verify-report.json`（继承链交叉验证） |
| Step 2: 分批规划 | `build_feature_pack.ps1` | manifest + 页面名 | `batches/{name}.md` + `.json` + `migration-index.json` |
| Step 3: 读取映射 | 手动 | - | 参考 `android-to-arkui-mapping.md` |
| Step 4: 逐批迁移 | 手动/AI | 批次文件 + Android 源码 | 对应的 .ets 文件 |
| Step 5: 覆盖率检查 | `check_coverage.ps1` | batch.json + migration-index | 覆盖率报告（exit code 0=完整） |
| Step 5.5: 后批验证 | 手动 | 源码重读 | 验证报告（include 布局/Adapter/Dialog/菜单/导航是否遗漏） |
| Step 6: 构建验证 | `verify_target_build.ps1` | 目标项目根目录 | 编译结果（hvigorw 构建） |

**Android View → ArkUI 映射表**（内置于 `references/android-to-arkui-mapping.md`）：

| Android | ArkUI | 分类 |
|---------|-------|------|
| Activity | 路由页面或应用壳 | 页面 |
| Fragment | @Component 或路由页面 | 页面 |
| DialogFragment / Dialog | dialog 或 sheet 组件 | 页面 |
| LinearLayout (vertical) | Column | 布局 |
| LinearLayout (horizontal) | Row | 布局 |
| FrameLayout | Stack | 布局 |
| ConstraintLayout | 拆分为更小的 ArkUI 组件 | 布局 |
| ScrollView | Scroll | 布局 |
| RecyclerView | List/Grid + ForEach/LazyForEach | 控件 |
| Adapter + ViewHolder | 列表项 @Component + 回调 | 控件 |
| TextView | Text | 控件 |
| ImageView | Image | 控件 |
| Button | Button | 控件 |
| Toolbar | 页面头部组件 | 控件 |
| menu XML | 头部操作按钮 | 控件 |
| dp | vp | 资源 |
| sp | fp | 资源 |

**与其他 Skills 的差异**：

| 维度 | `android-view-to-arkui` | `arkts-component-builder` | `arkts-ui-alignment` |
|------|------------------------|--------------------------|---------------------|
| 视角 | **源码侧**（从 Android 看过来） | **目标侧**（在 ArkTS 中构建） | **对比侧**（Android vs ArkTS 视觉对齐） |
| 关注点 | 发现什么需要迁移 + 分批计划 | 怎么写 ArkUI 组件 | 迁移后视觉是否一致 |
| 产出 | manifest.json + 批次计划 + 覆盖率 | .ets 组件代码 | UI 调整建议 |
| 阶段 | **阶段一→二（桥接）** | 阶段二（代码生成） | 阶段五（测试优化） |

**不适用场景**：Jetpack Compose 源码、非 UI 业务逻辑迁移、自定义 Canvas 绘制、独立组件设计。

---

## 三、各阶段详细卡片

### 阶段一：Spec 生成

```
┌─────────────────────────────────────────────────────────┐
│  阶段一：Spec 生成                                        │
│  目标：将 Android 源码转化为结构化迁移蓝图                   │
├─────────────────────────────────────────────────────────┤
│  输入                          │  输出                    │
│  ─────                         │  ─────                   │
│  • Android 项目源码路径          │  • migration-spec.md     │
│  • build.gradle / settings.gradle│   (SS1-SS11, 11 章节)   │
│  • AndroidManifest.xml          │  • 模块合并策略           │
│  • Memory 中的概念映射表(43组)    │  • 技术栈替换表(43组)    │
│  • Memory 中的踩坑清单(20条)     │  • 迁移分类矩阵          │
│                                 │    (Auto/Semi/Manual/Skip)│
│                                 │  • 风险评估报告           │
│                                 │  • manifest.json         │
│                                 │    (UI 组件清单, 由       │
│                                 │     android-view-to-arkui │
│                                 │     审计产出)             │
│                                 │  • 分批迁移计划           │
│                                 │    (batches/*.md + .json) │
└─────────────────────────────────────────────────────────┘
```

#### 使用的 Skills

| Skill | 作用 | 调用方式 | 关键 references |
|-------|------|---------|----------------|
| **`arkts-spec-generator`** | **主力 Skill**。驱动 4 个 Explore Agent 并行扫描 Android 源码，产出 SS1-SS11 规格文档 | 直接调用（用户说"分析 Android 项目"/"生成迁移方案"时触发） | `scanning-guide.md` — 扫描策略和 Agent 分工<br>`migration-verification.md` — 验证清单 |
| **`android-view-to-arkui`** | **UI 审计 Skill（新增）**。对 Android 源码执行结构化 UI 审计，产出 manifest.json（页面/布局/Adapter/Dialog 完整清单），并通过 deep_verify 做继承链交叉验证确保无遗漏。然后按功能分批，生成分批迁移计划 | 与 spec-generator **并行调用**。spec-generator 产出架构级 Spec，android-view-to-arkui 产出 UI 组件级清单 | `android-to-arkui-mapping.md` — View→ArkUI 映射表<br>`unsupported-patterns.md` — 不支持模式升级表<br>`prompt-templates.md` — 批次任务模板 |
| **`arkts-library-migration`** | **辅助 Skill**。负责 SS3 技术栈替换表中的三方库映射（OkHttp→http、RxJava→async/await、Glide→Image 等） | 被 spec-generator 组合调用 | `library-mapping-table.md` — 已验证映射表<br>`download-api-decision.md` — 下载 API 选型决策树 |
| **`arkts-knowledge-verifier`** | **辅助 Skill**。验证 Spec 中的技术选型是否符合当前 API 版本，检查 @ohos→@kit 导入迁移 | 被 spec-generator 组合调用 | `api12-baseline.md` — API 12 基线<br>`arkts-vs-typescript.md` — ArkTS 差异矩阵 |

#### Skills 编排方式

```
用户指令："分析这个 Android 项目"
         │
         ▼
  ┌──────────────────────────────────── 并行 ────────────────────────────────┐
  │                                                                          │
  │  arkts-spec-generator [架构级 Spec]      android-view-to-arkui [UI 审计] │
  │         │                                         │                      │
  │         ├─→ 4 个 Explore Agent 并行                ├─→ Step 1: scan_android_ui.ps1
  │         │   ├─ Agent 1: 数据层 → SS5               │   → manifest.json (页面/布局清单)
  │         │   ├─ Agent 2: UI 层 → SS4                │
  │         │   ├─ Agent 3: 工具层 → SS2               ├─→ Step 1.5: deep_verify.ps1
  │         │   └─ Agent 4: 构建配置 → SS3             │   → manifest-verify-report.json
  │         │                                          │     (继承链交叉验证, 确保无遗漏)
  │         ├─→ arkts-library-migration                │
  │         │   └─ 生成 SS3 技术栈替换表                ├─→ Step 2: build_feature_pack.ps1
  │         │                                          │   → batches/{name}.md + .json
  │         └─→ arkts-knowledge-verifier               │     (功能分批计划)
  │             └─ 验证技术选型是否可行                  │
  │                                                    └─→ migration-index.json
  │                                                          (覆盖率追踪基线)
  └──────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    合并产出：Spec (SS1-SS11) + UI manifest + 分批计划
```

**两个 Skill 的互补关系**：

| 维度 | `arkts-spec-generator` | `android-view-to-arkui` |
|------|----------------------|------------------------|
| 粒度 | 模块级（36 模块→单 entry） | 组件级（每个 Activity/Fragment/Adapter/Dialog） |
| 覆盖 | 全栈（数据层+UI+网络+播放器） | 仅 UI 层（View/XML 布局） |
| 产出 | 架构蓝图 (migration-spec.md) | 执行清单 (manifest.json + batches/) |
| 验证 | 人工审查 | 脚本化验证 (deep_verify + check_coverage) |

#### Done Gate（阶段质量门）

- [ ] SS1-SS11 全部 11 章节存在
- [ ] SS7 每个模块有 Auto/Semi-Auto/Manual/Skip 分类
- [ ] SS3 技术栈替换表覆盖所有依赖项
- [ ] **manifest.json 深度验证通过**（deep_verify verdict = COMPLETE）
- [ ] **分批计划已生成**（至少第一批 batch 文件就绪）
- [ ] 人工审查通过

---

### 阶段二：代码生成

```
┌─────────────────────────────────────────────────────────┐
│  阶段二：代码生成                                         │
│  目标：基于 Spec 生成符合鸿蒙规范的 ArkTS 代码              │
├─────────────────────────────────────────────────────────┤
│  输入                          │  输出                    │
│  ─────                         │  ─────                   │
│  • migration-spec.md (SS1-SS11)│  • 完整 .ets 源文件       │
│  • manifest.json (UI 清单)     │    (AntennaPod: 98 文件)  │
│  • batches/*.md (分批计划)      │  • 目录结构 (MVVM 分层)   │
│  • 用户自然语言指令              │  • 配置文件              │
│  • Android 源码（参考对照）      │    (module.json5 等)      │
│  • CLAUDE.md (Harness 规则)     │  • CLAUDE.md (初始规则集)  │
│  • Memory 踩坑清单              │  • GlobalState / EventBus │
│                                 │  • migration-index.json   │
│                                 │    (覆盖率追踪, 由        │
│                                 │     android-view-to-arkui │
│                                 │     持续更新)             │
└─────────────────────────────────────────────────────────┘
```

#### 使用的 Skills

| Skill | 作用 | 调用时机 | 关键 references |
|-------|------|---------|----------------|
| **`android-view-to-arkui`** | **分批驱动器（新增）**。按阶段一产出的 batch 计划逐批执行迁移，每批完成后运行 check_coverage + post-batch 验证确保无遗漏，最后运行 verify_target_build 验证编译 | **贯穿整个阶段二**。每个 batch 是一轮迭代：读取 batch → 参考映射表 → 生成 .ets → 覆盖率检查 → 构建验证 | `android-to-arkui-mapping.md` — View→ArkUI 映射<br>`prompt-templates.md` — 批次任务模板<br>`unsupported-patterns.md` — 不支持模式 |
| **`arkts-project-scaffolder`** | **P2 骨架**。生成项目目录结构、module.json5、app.json5、EntryAbility、GlobalState、AppRouter | 最先调用，搭建项目骨架 | `single-module-template.md` — 单模块模板<br>`config-reference.md` — 配置速查<br>`audio-app-scaffold.md` — 音频应用骨架 |
| **`arkts-data-layer`** | **P3 适配层 + P4 数据层**。生成 HttpClient、数据模型(class)、PodDatabase 单例、7 个 DAO、DataSource | 骨架之后，UI 之前 | `model-patterns.md` — 模型定义模式<br>`network-service.md` — HTTP 封装<br>`rdbstore-dao-patterns.md` — DAO 模式<br>`datasource-patterns.md` — IDataSource 实现<br>`feed-update-service.md` — Feed 更新服务 |
| **`arkts-navigation-builder`** | **P5a 导航骨架**。生成 Index.ets 主页(Navigation+NavPathStack)、AppRouter 路由表、NavDestination 注册 | 数据层之后 | `nav-patterns.md` — 导航模式<br>`tab-navigation.md` — Tab 导航<br>`advanced-nav-patterns.md` — 高级导航 |
| **`arkts-state-manager`** | **P5b 状态管理**。设计 GlobalState AppStorage key 注册、@StorageLink 绑定、ViewModel 模式 | 导航之后 | (内置于 SKILL.md) |
| **`arkts-component-builder`** | **P5c 组件填充**。生成 28 个 UI 组件（首页、队列、订阅、播放器、设置等） | 状态管理之后 | `layout-patterns.md` — 布局模式<br>`common-components.md` — 通用组件<br>`media-app-components.md` — 媒体应用组件<br>`component-lifecycle-patterns.md` — 组件生命周期 |
| **`arkts-media-playback`** | **P5a 播放引擎**。生成 PlaybackController(AVPlayer 状态机)、BackgroundPlaybackManager、SleepTimer | 与导航并行 | `avplayer-lifecycle.md` — AVPlayer 生命周期<br>`playback-patterns.md` — 播放模式<br>`background-playback.md` — 后台播放三要素 |
| **`arkts-download-manager`** | **P5b 下载管理**。生成 DownloadManager(request.agent)、FeedUpdateService | 与播放引擎并行 | `request-agent-patterns.md` — request.agent 模式<br>`file-pipeline.md` — 文件管线 |
| **`arkts-system-capabilities`** | **P3 适配层**。生成 PermissionHelper、FileUtils、后台任务配置 | 与数据层并行 | `permission-helper.md` — 权限申请<br>`file-utils.md` — 文件操作<br>`background-tasks.md` — 后台任务<br>`avplayer-guide.md` — AVPlayer 指南 |
| **`arkts-animation-builder`** | **P5c 动效**。为组件添加转场动画、点击反馈、列表项出现动画 | 组件填充阶段 | `explicit-animation.md` — 显式动画<br>`transition-patterns.md` — 转场<br>`media-app-animations.md` — 媒体应用动效 |
| **`arkts-pattern-library`** | **P5c 业务模式**。提供搜索、列表详情、下拉刷新等完整业务模式参考 | Hub 编排，按需路由 | `list-detail-pattern.md` — 列表详情<br>`search-pattern.md` — 搜索<br>`media-app-pattern.md` — 媒体应用模式 |
| **`arkts-knowledge-verifier`** | **全程辅助**。验证生成代码是否符合 ArkTS 规范、API 是否存在 | 任何不确定时调用 | `verification-index.md` — 验证索引<br>`skill-routing-guide.md` — Skill 路由指南 |
| **`arkts-library-migration`** | **P3 适配层**。为 Spec 中标记的三方库依赖找到鸿蒙替代方案 | 适配层阶段 | `ohpm-search-guide.md` — ohpm 搜索<br>`library-mapping-table.md` — 映射表 |

#### Skills 编排方式（六阶段流水线）

```
P2 骨架 ─────────────────────────────────────────────────────────→
│ project-scaffolder
│
▼
P3 适配层 ──────────────────────────────────────────────────────→
│ data-layer (HttpClient, FileUtils)
│ system-capabilities (权限, 文件操作)
│ library-migration (三方库替代)
│
▼
P4 数据层 ──────────────────────────────────────────────────────→
│ data-layer (Models, PodDatabase, 7 DAOs, DataSource)
│
▼
P5a 导航 + 播放 ──────────── 可并行 ─────────────────────────→
│ navigation-builder (Index.ets, AppRouter, NavDestination)
│ media-playback (PlaybackController, BackgroundPlayback)
│
▼
P5b 状态 + 下载 ──────────── 可并行 ─────────────────────────→
│ state-manager (GlobalState, @StorageLink, ViewModel)
│ download-manager (DownloadManager, FeedUpdateService)
│
▼
P5c 组件 ─────────────────────────────────────────────────────→
│ component-builder (28 个 UI 组件)
│ pattern-library [Hub 编排] → 按业务场景路由到专项 Skill
│ animation-builder (转场/交互动效)
│
▼
knowledge-verifier ──────── 全程辅助 ─────────────────────────→
  (API 验证, 知识查询, Skill 路由)

android-view-to-arkui ───── 贯穿阶段二 ──────────────────────→
  每个 batch 完成后:
  ├─ Step 5: check_coverage.ps1 → 覆盖率检查 (exit 0 才继续)
  ├─ Step 5.5: Post-batch 验证 (include/Adapter/Dialog/菜单遗漏检查)
  └─ Step 6: verify_target_build.ps1 → hvigorw 编译验证
```

#### Done Gate

- [ ] `hvigor build` 编译通过（或仅剩已知的非阻塞警告）
- [ ] 目录结构与 Spec SS2 一致
- [ ] 每个 Spec SS7 标记的模块都有对应 .ets 文件
- [ ] **migration-index.json 覆盖率 100%**（android-view-to-arkui 的 check_coverage 通过）
- [ ] **Post-batch 验证全部 PASS**（include 布局/Adapter/Dialog/菜单/导航目标无遗漏）
- [ ] CLAUDE.md 规则集已建立

---

### 阶段三：多轮修复

```
┌─────────────────────────────────────────────────────────┐
│  阶段三：多轮修复                                         │
│  目标：修复所有编译错误和运行时异常                           │
├─────────────────────────────────────────────────────────┤
│  输入                          │  输出                    │
│  ─────                         │  ─────                   │
│  • 编译错误信息                  │  • 可编译、可运行的代码    │
│  • 运行时崩溃日志                │  • 更新后的 CLAUDE.md     │
│  • UI 显示异常截图               │    (新增踩坑规则)         │
│  • DevEco Studio 报错信息        │  • dev-pitfalls.md       │
│  • Memory 自修复协议             │    (踩坑沉淀)            │
│  • CLAUDE.md 错误模式库          │  • 更新后的 Spec          │
│                                 │    (方案变更回溯)         │
└─────────────────────────────────────────────────────────┘
```

#### 使用的 Skills

| Skill | 作用 | 调用时机 | 关键 references |
|-------|------|---------|----------------|
| **`arkts-knowledge-verifier`** | **主力 Skill**。验证修复方案是否正确，查找 API 的正确用法，识别 ArkTS vs TypeScript 差异导致的错误 | 每次修复前先验证 | `arkts-vs-typescript.md` — 差异矩阵（定位语言约束错误）<br>`api12-baseline.md` — API 基线<br>`migration-patterns.md` — 迁移模式 |
| **`arkts-component-builder`** | UI 类修复（布局错乱、组件不显示、ForEach 不刷新等） | UI 相关错误时 | `component-lifecycle-patterns.md` — 生命周期<br>`layout-patterns.md` — 布局模式 |
| **`arkts-media-playback`** | 播放器类修复（AVPlayer 状态异常、fd:// 协议、后台播放失败） | 播放器相关错误时 | `avplayer-lifecycle.md` — 状态机顺序<br>`background-playback.md` — 三要素检查 |
| **`arkts-download-manager`** | 下载类修复（5MB 限制、文件移动失败、进度不回调） | 下载相关错误时 | `request-agent-patterns.md` — 正确的下载模式<br>`file-pipeline.md` — 文件管线排错 |
| **`arkts-data-layer`** | 数据层修复（ResultSet 泄漏、SQL 错误、JOIN 列别名） | 数据库相关错误时 | `rdbstore-dao-patterns.md` — DAO 排错<br>`advanced-dao-patterns.md` — 高级查询修复 |
| **`arkts-navigation-builder`** | 导航类修复（参数传递 undefined、Tab 栏被覆盖） | 导航相关错误时 | `nav-patterns.md` — onReady 参数接收<br>`tab-navigation.md` — Tab 栏正确位置 |
| **`arkts-system-capabilities`** | 系统 API 修复（权限申请失败、文件路径错误） | 系统能力相关错误时 | `permission-helper.md` — 权限排错<br>`file-utils.md` — 沙箱路径 |

#### Skills 编排方式（按错误类型路由）

```
人工反馈（编译错误/运行时异常/UI 异常）
         │
         ▼
  arkts-knowledge-verifier [入口路由]
         │
         ├─ ArkTS 语言错误 (any/as/对象字面量)
         │   └─→ knowledge-verifier 直接修复（固定模式）
         │
         ├─ UI 显示异常
         │   └─→ component-builder + navigation-builder
         │
         ├─ 播放器异常
         │   └─→ media-playback（状态机/fd://）
         │
         ├─ 下载失败
         │   └─→ download-manager（API 选型/文件管线）
         │
         ├─ 数据库错误
         │   └─→ data-layer（ResultSet/SQL/DAO）
         │
         └─ 系统能力异常
             └─→ system-capabilities（权限/文件/后台）
```

#### 自修复协议（来自 Memory）

| 错误类型 | 检查路径 | 对应 Skill |
|---------|---------|-----------|
| 编译错误 | 检查类型/import/@Component struct | knowledge-verifier |
| 运行时 undefined | 检查 GlobalState.init() 初始化时序 | state-manager |
| 数据库错误 | 检查 ResultSet.close() + SQL 语法 | data-layer |
| 网络错误 | 检查权限声明 + http.destroy() | system-capabilities |
| 播放器无反应 | 检查 AVPlayer 状态机顺序 | media-playback |
| UI 不刷新 | 检查 ForEach key + @State/@StorageLink | component-builder |

#### Done Gate

- [ ] 编译零错误
- [ ] 应用可启动运行
- [ ] 核心功能路径可走通
- [ ] 新发现的踩坑已沉淀到 dev-pitfalls.md / CLAUDE.md

---

### 阶段四：代码质量保证

```
┌─────────────────────────────────────────────────────────┐
│  阶段四：代码质量保证                                      │
│  目标：确保代码库符合全部质量标准                             │
├─────────────────────────────────────────────────────────┤
│  输入                          │  输出                    │
│  ─────                         │  ─────                   │
│  • 可编译可运行的代码库          │  • 质量审计报告           │
│  • CLAUDE.md 规则集             │    (全通过 / 违规清单)    │
│  • 7 大规范域检查清单            │  • 修复后的代码           │
│    (导入/类型/组件/数据库/       │  • 更新后的 CLAUDE.md     │
│     播放器/XML/网络)            │                          │
│  • Memory 项目特有检查项         │                          │
└─────────────────────────────────────────────────────────┘
```

#### 使用的 Skills

| Skill | 作用 | 调用方式 | 关键 references |
|-------|------|---------|----------------|
| **`arkts-knowledge-verifier`** | **主力 Skill**。执行 7 大规范域的合规性检查，验证 API 用法、导入路径、类型安全 | 直接调用，逐项检查 | `verification-index.md` — 完整验证索引<br>`arkts-vs-typescript.md` — 差异矩阵<br>`api12-baseline.md` — API 基线 |
| **`arkts-data-layer`** | 数据层审查：SQL 注入检查、ResultSet 泄漏检查、DAO 模式合规 | 数据层专项审查时 | `rdbstore-dao-patterns.md` — DAO 模式对照 |
| **`arkts-component-builder`** | 组件审查：ForEach key 完整性、@Component struct 规范、build() 根容器 | 组件层专项审查时 | `component-lifecycle-patterns.md` — 规范对照 |

#### Skills 编排方式（多维度并行审查）

```
代码库
  │
  ├─→ knowledge-verifier: 类型安全审查 (any/as/对象字面量)
  │
  ├─→ knowledge-verifier: 导入规范审查 (@kit.* vs @ohos.*)
  │
  ├─→ data-layer: 数据层审查 (SQL 占位符 / ResultSet close / DAO 模式)
  │
  ├─→ component-builder: 组件审查 (ForEach key / struct / 根容器)
  │
  └─→ CLAUDE.md: 全局规则对照
         │
         ▼
    质量审计报告
```

#### 检查清单（CLAUDE.md 7 大规范域）

| # | 规范域 | 检查项 | AntennaPod 结果 |
|---|-------|-------|----------------|
| 1 | 导入规范 | 全部使用 @kit.* 统一导入 | 0 违规 |
| 2 | 类型安全 | 无 any/as/对象字面量类型 | 0 违规 |
| 3 | 组件规范 | @Component struct + 单根容器 + ForEach key | 0 违规 |
| 4 | 数据库规范 | SQL 占位符 + ResultSet close + ON CONFLICT | 0 违规 |
| 5 | 播放器规范 | 状态机顺序 + fd:// + backgroundModes | 0 违规 |
| 6 | XML 规范 | XmlPullParser Pull 模式 + 命名空间 | 0 违规 |
| 7 | 网络规范 | http.destroy() + 权限声明 | 0 违规 |

#### Done Gate

- [ ] 7 大规范域全部通过
- [ ] 零 `any` 类型
- [ ] 零 SQL 拼接
- [ ] 零 ResultSet/HTTP 资源泄漏

---

### 阶段五：测试反馈与优化

```
┌─────────────────────────────────────────────────────────┐
│  阶段五：测试反馈与优化                                    │
│  目标：修复功能缺陷、优化 UI 对齐、提升体验                  │
├─────────────────────────────────────────────────────────┤
│  输入                          │  输出                    │
│  ─────                         │  ─────                   │
│  • 测试同学的 Bug 报告           │  • 生产就绪版本 (v3)      │
│  • Android 原版截图（对照）      │  • 更新后的代码库          │
│  • UI 走查结果                  │  • development-experience │
│  • 功能验收清单 (SS10)           │    .md (经验沉淀)         │
│  • 已验证 sys.symbol 清单       │  • 更新后的 Skills        │
│  • Memory 中的 UI 映射经验       │    (新增模式模板)         │
└─────────────────────────────────────────────────────────┘
```

#### 使用的 Skills

| Skill | 作用 | 调用时机 | 关键 references |
|-------|------|---------|----------------|
| **`arkts-ui-alignment`** | **主力 Skill**。Android Material Design → ArkUI 视觉映射，处理 UI 对齐差异 | 每次 UI 类反馈时 | (内置映射表) |
| **`arkts-component-builder`** | **主力 Skill**。修改/重写 UI 组件代码，调整布局和样式 | 每次组件修改时 | `common-components.md` — 组件模板<br>`responsive-design.md` — 响应式<br>`media-app-components.md` — 媒体组件 |
| **`arkts-pattern-library`** | **Hub 编排**。当修复涉及完整业务功能（如 AddFeed 重写）时，提供完整模式参考 | 大型功能重写时 | `search-pattern.md` — 搜索模式<br>`list-detail-pattern.md` — 列表详情<br>`media-app-pattern.md` — 媒体应用 |
| **`arkts-animation-builder`** | 为修复后的组件添加/优化动画效果 | UI 打磨阶段 | `explicit-animation.md` — 动画<br>`media-app-animations.md` — 媒体动效 |
| **`arkts-navigation-builder`** | 导航相关的 UI 问题修复（页面切换、Tab 状态、返回行为） | 导航类反馈时 | `tab-navigation.md` — Tab 导航 |
| **`arkts-knowledge-verifier`** | 验证修复后的代码是否引入新问题 | 修复后验证 | `verification-index.md` — 验证索引 |
| **`arkts-data-layer`** | 数据展示相关修复（列表数据不完整、排序错误等） | 数据展示问题时 | `datasource-patterns.md` — 数据源 |

#### Skills 编排方式（Bug 反馈驱动）

```
测试反馈
  │
  ├─ UI 视觉差异 ──→ arkts-ui-alignment + component-builder
  │
  ├─ 功能缺陷 ──→ pattern-library [Hub] → 路由到对应 Skill
  │                  ├─ 搜索功能 → data-layer + component-builder
  │                  ├─ 播放功能 → media-playback
  │                  └─ 下载功能 → download-manager
  │
  ├─ 交互体验 ──→ animation-builder + component-builder
  │
  └─ 导航问题 ──→ navigation-builder
```

#### Done Gate

- [ ] SS10 验收矩阵全量通过
- [ ] Android 原版截图对比无明显差异
- [ ] 7 条核心用户路径全部可走通
- [ ] 经验沉淀到 development-experience.md

---

## 四、Skills 全景矩阵

### 15 个 Skill × 5 个阶段的调用关系

| Skill | 阶段一 Spec | 阶段二 代码 | 阶段三 修复 | 阶段四 质量 | 阶段五 测试 |
|-------|:----------:|:----------:|:----------:|:----------:|:----------:|
| `arkts-spec-generator` | **主力** | - | - | - | - |
| **`android-view-to-arkui`** | **UI 审计+分批** | **分批驱动+覆盖率+构建验证** | - | - | - |
| `arkts-project-scaffolder` | - | **P2 骨架** | - | - | - |
| `arkts-knowledge-verifier` | 辅助 | 全程辅助 | **入口路由** | **主力** | 辅助 |
| `arkts-component-builder` | - | **P5c 组件** | UI 修复 | 组件审查 | **主力** |
| `arkts-navigation-builder` | - | **P5a 导航** | 导航修复 | - | 导航修复 |
| `arkts-state-manager` | - | **P5b 状态** | 状态修复 | - | - |
| `arkts-data-layer` | - | **P3+P4 数据** | 数据修复 | 数据审查 | 数据修复 |
| `arkts-media-playback` | - | **P5a 播放** | 播放修复 | - | - |
| `arkts-download-manager` | - | **P5b 下载** | 下载修复 | - | - |
| `arkts-animation-builder` | - | P5c 动效 | - | - | 动效优化 |
| `arkts-system-capabilities` | - | **P3 适配** | 系统修复 | - | - |
| `arkts-library-migration` | **辅助** | P3 适配 | - | - | - |
| `arkts-pattern-library` | - | **P5c Hub** | - | - | Hub 编排 |
| `arkts-ui-alignment` | - | - | - | - | **主力** |

### android-view-to-arkui 的独特价值

```
┌──────────────────────────────────────────────────────────────────────┐
│  android-view-to-arkui 横跨阶段一→阶段二，是两个阶段的桥梁 Skill      │
│                                                                      │
│  阶段一 (审计+规划)                    阶段二 (执行+验证)              │
│  ─────────────────                     ─────────────────              │
│  Step 1:  scan_android_ui.ps1          Step 4:  逐批迁移              │
│           → manifest.json                       (读 batch → 生成 .ets)│
│  Step 1.5: deep_verify.ps1             Step 5:  check_coverage.ps1   │
│           → 继承链交叉验证                       → 覆盖率检查          │
│  Step 2:  build_feature_pack.ps1       Step 5.5: Post-batch 验证     │
│           → batches/{name}.md + .json            → 遗漏检查           │
│           → migration-index.json       Step 6:  verify_target_build  │
│  Step 3:  读取映射参考文件                        → hvigorw 编译验证   │
│                                                                      │
│  解决的核心问题：                                                      │
│  1. 防止"一次性全量迁移"导致的遗漏（分批 + 覆盖率追踪）                  │
│  2. 防止 Adapter/ViewHolder/Dialog/菜单 被静默丢弃（Post-batch 验证）  │
│  3. 提供 View→ArkUI 精确映射（android-to-arkui-mapping.md）           │
│  4. 内置构建验证闭环（verify_target_build 调用 hvigorw）               │
└──────────────────────────────────────────────────────────────────────┘
```

### Skill 使用频率分布

```
阶段一 █████                        4 个 Skill (spec-generator + view-to-arkui + 2 辅助)
阶段二 ██████████████████████████████ 13 个 Skill (全部参与, view-to-arkui 贯穿)
阶段三 ████████████████             7 个 Skill (按错误类型路由)
阶段四 ██████                       3 个 Skill (verifier + 2 审查)
阶段五 ██████████████               7 个 Skill (UI 对齐 + 功能修复)
```

---

## 五、阶段间流转关系

### 上一阶段的输出 → 下一阶段的输入

```
阶段一 输出                    阶段二 如何使用
─────────                     ─────────────
migration-spec.md         →   SS2 决定目录结构
                              SS3 决定技术选型
                              SS4 决定组件映射
                              SS5 决定数据库设计
                              SS7 决定生成优先级 + 模型选择(Opus/Sonnet)
                              SS9 决定 module.json5 配置

manifest.json             →   UI 组件完整清单，确保无遗漏
  (android-view-to-arkui)      (Activity/Fragment/Adapter/Dialog/菜单全覆盖)

batches/{name}.md+.json   →   逐批迁移的执行单元
  (android-view-to-arkui)      每批包含：入口页面 + 直接依赖 + 完成标准

migration-index.json      →   覆盖率追踪基线
  (android-view-to-arkui)      每完成一批更新，确保最终 100% 覆盖

阶段二 输出                    阶段三 如何使用
─────────                     ─────────────
.ets 源文件 (98 个)       →   编译检查目标
CLAUDE.md                 →   错误模式库（语言约束修复模板）
GlobalState/EventBus      →   运行时检查的初始化时序参考

阶段三 输出                    阶段四 如何使用
─────────                     ─────────────
可编译代码库              →   质量扫描目标
更新后的 CLAUDE.md        →   7 大规范域检查清单
dev-pitfalls.md           →   项目特有的检查项补充

阶段四 输出                    阶段五 如何使用
─────────                     ─────────────
质量审计报告 (全通过)     →   确认代码基线质量达标
修复后的代码              →   测试验证的目标版本

阶段五 输出                    下个项目
─────────                     ─────────
生产版本 (v3)             →   参考实现
development-experience.md →   Memory 沉淀 → 新项目的踩坑注入
更新后的 Skills           →   新项目直接复用升级后的 Skills
```

### 关键流转依赖

| 依赖关系 | 说明 | 如果缺失的后果 |
|---------|------|-------------|
| Spec → 代码生成 | Spec 驱动生成的范围、顺序和技术选型 | 盲写，遗漏模块，架构不一致 |
| **manifest.json → 代码生成** | **android-view-to-arkui 的 UI 清单确保组件级无遗漏** | **Adapter/Dialog/菜单被静默丢弃，阶段五大量补漏** |
| **batches → 代码生成** | **分批计划控制迁移节奏，每批有覆盖率检查** | **一次性全量迁移容易遗漏子组件，返工成本高** |
| CLAUDE.md → 全阶段 | Harness 约束贯穿全流程 | 阶段四质量从 0 违规退化到 10+ 违规 |
| Memory → 阶段二/三 | 踩坑知识注入避免重复犯错 | 平均修复迭代从 1.7 轮上升到 3+ 轮 |
| 阶段三踩坑 → CLAUDE.md | 新发现的问题沉淀为规则 | 同类错误在后续会话中复发 |
| 阶段五经验 → Skills | UI 映射模板/代码模式沉淀 | 下个项目重复 ~40% 的 UI 对齐工作 |

---

## 六、附录：Skill 目录结构参考

每个 Skill 的标准目录结构：

```
skills/arkts-xxx/
├── SKILL.md              # 主文件（决策树 + 代码模板 + 约束规则，<500 行）
├── evals.json            # 2-3 个测试用例（用于评估 Skill 效果）
└── references/           # 详细参考文件（按需加载）
    ├── xxx-patterns.md   # 代码模式模板
    ├── xxx-guide.md      # 使用指南
    └── xxx-advanced.md   # 高级场景
```

**三级渐进加载机制**：
1. **Level 1** — Skill description（~100 词，触发条件判断）
2. **Level 2** — SKILL.md body（~500 行，决策树+核心模板）
3. **Level 3** — references/（按需加载，详细参考）
