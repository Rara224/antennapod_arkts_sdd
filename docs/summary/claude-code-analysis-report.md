# AntennaPod Android→ArkTS 迁移：Claude Code 全流程分析报告

> 生成日期：2026-03-21
> 分析范围：17 个 Claude Code 会话 + 8 次 git 提交（2026-03-14 ~ 2026-03-20）
> 目标：识别五阶段开发流程中的问题分布、根因及优化方向

---

## 一、执行摘要

| 维度 | 数据 |
|------|------|
| 项目 | AntennaPod 开源播客客户端，Android Java (36 Gradle 模块) → HarmonyOS ArkTS (单 entry 模块) |
| 开发周期 | 6 个日历日（2026-03-14 ~ 2026-03-20），17 个 Claude Code 会话 |
| 产出 | 96 个 `.ets` 文件，~6,300+ 行新增代码，8 次 git 提交（v1 ~ v3） |
| 代码质量 | 9.5/10 — 零 `any` 类型违规、零 SQL 注入、全部 ResultSet/HTTP 实例正确释放 |
| 踩坑记录 | 22 条（含根因、解决方案、预防规则） |
| 风险项 | 6 个 Manual 级风险项全部成功迁移 |

**核心发现**：

1. **阶段二（代码生成）和阶段三（多轮修复）集中了 86% 的问题**（19/22 条）
2. **阶段一 Spec 的 3 个遗漏级联产生了 6+ 个下游问题**，其中下载 API 方案变更 3 次是最昂贵的返工项
3. **阶段四质量把控有效**，CLAUDE.md 规则体系成功预防了质量问题
4. **阶段五 UI 对齐消耗了 v1 后 ~40% 的开发时间**，属于跨平台迁移的固有挑战
5. **预计通过 5 项流程优化 + 5 项技术引入，可减少 40-55% 的返工量**

---

## 二、项目概况

### 2.1 源与目标对比

| 维度 | Android (源) | ArkTS (目标) |
|------|-------------|-------------|
| 语言 | Java 100% | ArkTS (严格模式) |
| 架构 | MVVM + RxJava3 + EventBus | MVVM + async/await + 自建 EventBus |
| 模块 | 36 个 Gradle 模块 | 1 个 entry 模块 |
| 组件 | 12 Activity, 71 Fragment, 46 Adapter | 1 @Entry Page, 28 @Component, 14 ViewModel |
| 数据库 | SQLite (PodDBAdapter 单例) | relationalStore (PodDatabase 单例, 7 DAO) |
| 播放器 | ExoPlayer / Media3 | AVPlayer |
| 网络 | OkHttp / Retrofit | http from @kit.NetworkKit + request.agent |
| 构建 | Gradle 8.11.0 | hvigor |

### 2.2 提交时间线

| 提交 | 日期 | 描述 | 变更文件 | 增/删行 |
|------|------|------|---------|---------|
| v1 | 03-18 11:22 | 初始完整迁移 | 109 | (基线) |
| v2 (文档) | 03-18 16:33 | 文档+下载重写+修复 | 6 | +1771/-186 |
| v2 (UI) | 03-18 16:50 | 大规模 UI 重构 | 109 | +2948/-1001 |
| v2 | 03-19 19:33 | Feed 详情/设置/队列打磨 | 26 | +2948/-1001 |
| v2.1 | 03-19 20:57 | 收件箱/播放历史/统计 | 8 | +738/-187 |
| v2.3 | 03-19 22:42 | AddFeed 重写/首页优化 | 12 | +511/-220 |
| v (未命名) | 03-20 11:59 | AddFeed 大幅重写 (495行) | 8 | +495/- |
| v3 | 03-20 20:17 | 最终打磨+新 SVG 图标 | 9 | +126/-77 |

### 2.3 文件分布

| 目录 | 文件数 | 职责 |
|------|-------|------|
| models/ | 7 | 数据模型 (Feed, FeedItem, FeedMedia 等) |
| database/ | 8 | PodDatabase + 7 DAO |
| network/ | 5 | HttpClient, DownloadManager, FeedUpdateService, PodcastSearcher |
| parser/ + namespace/ | 8 | RSS/Atom/OPML 解析器 + 5 命名空间处理器 |
| playback/ | 3 | PlaybackController, BackgroundPlaybackManager, SleepTimer |
| pages/ | 1 | Index.ets (唯一 @Entry) |
| components/ | ~28 | UI 组件（8 个子目录） |
| viewmodels/ | 14 | 视图逻辑层 |
| datasource/ | 2 | LazyForEach 数据源 |
| helpers/ | 7 | 工具类、Preferences、权限 |
| common/ | 4 | GlobalState, AppRouter, EventBus, Constants |
| workers/ | 2 | 后台任务调度 |

### 2.4 热点文件（修改最频繁的文件）

这些文件代表了开发中的**反复返工区域**：

| 文件 | 提交次数 | 当前行数 | 返工原因 |
|------|---------|---------|---------|
| `pages/Index.ets` | 8 | ~356 | Tab 栏方案变更、MiniPlayer 添加、路由映射扩展 |
| `database/FeedItemDao.ets` | 6 | ~405 | JOIN 查询列别名迭代、为不同视图添加查询方法 |
| `components/queue/QueueComponent.ets` | 5 | ~372 | 滑动操作、拖拽排序替代方案、空状态 |
| `components/home/HomeComponent.ets` | 5 | ~738 | 最大组件，v1→v2 完全重新设计 |
| `components/common/MoreComponent.ets` | 5 | ~86 | 溢出菜单样式反复调整 |
| `viewmodels/HomeViewModel.ets` | 4 | ~62 | 随 HomeComponent UI 变更同步调整数据加载逻辑 |
| `playback/PlaybackController.ets` | 4 | ~664 | fd:// 协议修复、倍速映射、位置保存定时器 |
| `network/FeedUpdateService.ets` | 4 | ~271 | Feed 刷新逻辑、HTTP 头处理 |

---

## 三、五阶段问题分布分析

### 3.0 问题总览

```
阶段一(Spec生成)  ███░░░░░░░░░░░░░░░░  3 条  (14%)  — 低返工成本，但级联影响大
阶段二(代码生成)  ██████████░░░░░░░░░ 10 条  (45%)  — 高返工成本，结构性重写
阶段三(多轮修复)  █████████░░░░░░░░░░  9 条  (41%)  — 中高返工成本，平均 1.7 轮迭代
阶段四(质量保证)  ░░░░░░░░░░░░░░░░░░░  0 条  ( 0%)  — CLAUDE.md 规则有效
阶段五(测试反馈)  UI 对齐迭代          ~40% v1 后时间  — 跨平台固有挑战
```

### 3.1 阶段一：Spec 生成（3 个问题）

阶段一用 2 个 Claude Code 会话完成了完整的迁移 Spec（migration-spec.md, SS1-SS11），正确识别了模块结构、组件计数和技术栈映射。但存在 3 个**平台约束遗漏**：

| # | 问题 | 下游影响 |
|---|------|---------|
| 1 | Spec 遗漏 `request.agent` 作为推荐下载 API | 下载方案经历 3 次变更（最昂贵的返工项） |
| 2 | 高估 `http.requestInStream()` 可靠性 | 方案中途废弃，浪费 1 个 Session |
| 3 | 未覆盖鸿蒙平台特有约束（fd:// 协议、5MB 限制、mkdir 非递归等） | 5+ 个阶段二/三的问题 |

**关键洞察**：这 3 个 Spec 级遗漏**级联产生了 6+ 个下游问题**。下载 API 返工（3 次方案变更，DownloadManager.ets 278 行 diff）是整个项目中单项成本最高的返工。

**根因**：Spec 生成阶段缺乏"鸿蒙平台约束清单"，导致 LLM 基于 Android 经验做出的技术选型在鸿蒙平台上不适用。

### 3.2 阶段二：代码生成（10 个问题）

LLM 生成的代码在编译或运行时暴露的问题，按子类别分为三组：

#### A. ArkTS 语言约束（3 条）

| # | 问题 | 踩坑编号 | 说明 |
|---|------|---------|------|
| 1 | `any` 类型被完全禁止 | #15 | LLM 生成合法 TypeScript 但违反 ArkTS 严格模式 |
| 2 | `as` 类型断言被禁止 | #14 | 需用 `instanceof` 替代 |
| 3 | 对象字面量不能做类型声明 | #13 | 回调参数必须用独立 `class` 定义 |

**原因**：ArkTS 严格模式与标准 TypeScript 的差异。LLM 的训练数据以 TypeScript 为主，对 ArkTS 特有限制的认知不足。

#### B. API 命名不确定（2 条）

| # | 问题 | 踩坑编号 | 说明 |
|---|------|---------|------|
| 4 | `sys.symbol` 名称猜测（5+ 个不存在） | #10 | LLM 基于 SF Symbols/Material Icons 推断，但鸿蒙有独立子集 |
| 5 | `ShowActionMenuSuccessResponse` 命名错误 | #17 | 正确名称是 `ActionMenuSuccessResponse` |

**原因**：鸿蒙 API 命名约定与 Android/iOS 不同，LLM 推断逻辑不适用。

#### C. 平台语义差异（5 条）

| # | 问题 | 踩坑编号 | 说明 |
|---|------|---------|------|
| 6 | AVPlayer 状态机不能跳过步骤 | #2 | 必须严格按 Idle→Initialized→Prepared→Playing |
| 7 | 后台播放三要素配置不完整 | P14 | module.json5 + startContinuousTask + AVSession 缺一不可 |
| 8 | Tabs 在 Navigation 内部导致 Tab 栏被覆盖 | #8 | 必须自定义 Tab 栏放在 Navigation 外部 |
| 9 | NavDestination 参数在 aboutToAppear 获取为 undefined | #16 | 必须在 onReady 回调中获取 |
| 10 | PlaybackSpeed 是离散枚举（仅 6 个值） | #3 | 不能设置任意倍速，需 snapToValidSpeed() 映射 |

**原因**：LLM 基于 Android/iOS 的经验类比鸿蒙 API 行为，但底层实现差异导致类比失效。

### 3.3 阶段三：多轮修复（9 个问题）

人工编译/测试发现后，经过多轮迭代修复的问题：

| # | 问题 | 迭代次数 | 最终方案 |
|---|------|---------|---------|
| 1 | 下载 API 方案变更 | **3 次** | http.request → requestInStream → request.agent |
| 2 | 目录创建不支持递归 | 2 次 | `mkdirSync(path, true)` |
| 3 | fd:// 协议发现 | 2 次 | `fileIo.openSync` → `fd://` + 文件描述符 |
| 4 | AppStorage 时序问题 | 2 次 | `GlobalState.initAppStorage()` 统一注册所有 key |
| 5 | ForEach key 缺少变化字段 | 2 次 | key 包含 playState/title 等可变字段 |
| 6 | Emoji vs SymbolGlyph 大小不一致 | 2 次 | 统一使用 SymbolGlyph |
| 7 | HTTP 响应头 Object 类型处理 | 1 次 | JSON.stringify → 解析桥接 |
| 8 | RSS URL 中 `&amp;` 实体编码 | 1 次 | 正则替换 |
| 9 | INSERT OR REPLACE 改变自增 ID | 1 次 | ON CONFLICT DO UPDATE |

**关键数据**：平均每个问题 **1.7 次迭代**。问题 #1（下载 API）3 次迭代是最昂贵的，涉及 DownloadManager.ets 的完全重写。

### 3.4 阶段四：代码质量保证（0 个严重问题）

最终代码库的质量扫描结果：

| 指标 | 结果 | 验证方式 |
|------|------|---------|
| `any` 类型使用 | **0 违规** | 全 .ets 文件 grep 扫描 |
| `as` 类型断言 | **0 违规** | 全 .ets 文件 grep 扫描 |
| SQL 注入（字符串拼接） | **0 违规** | 全部使用 `?` 占位符 |
| ResultSet 泄漏 | **0 违规** | 全部在 try/finally 中 close() |
| HTTP 实例泄漏 | **0 违规** | 全部在 try/finally 中 destroy() |
| 废弃 `@ohos.*` 导入 | **0 违规** | 全部使用 `@kit.*` 统一导入 |
| setTimeout 滥用 | **0 严重** | 仅用于 UI debounce（合理场景） |

**结论**：CLAUDE.md 中定义的 20+ 条编码规则**有效预防了质量问题的引入**。这是整个五阶段流程中表现最好的环节。

### 3.5 阶段五：测试反馈与 UI 对齐

| 版本过渡 | 重点 | 变更文件 | 关键变更 |
|---------|------|---------|---------|
| v1 → v2 | 结构+UI 大改 | 49 文件 | Feed 详情重设计、设置页拆分为列表+详情、自定义 Tab 栏、SymbolGlyph 迁移 |
| v2 → v2.1 | 组件打磨 | 16 文件 | AllEpisodes/Downloads 组件增强、Feed 设置视觉对齐 |
| v2.1 → v2.3 | 功能补全 | 14 文件 | 收件箱、播放历史、统计图表 |
| v2.3 → v3 | 最终打磨+新功能 | 27 文件 | AddFeed 重写 (495行)、UI 一致性修正、PodcastSearcher |

**关键数据**：阶段五消耗了 v1 后约 **40% 的开发时间**。最大单项返工是 AddFeedComponent.ets（495 行变更），实质上是完全重写。

**原因**：Android Material Design 组件与 HarmonyOS ArkUI 不存在 1:1 映射，需要**视觉比对+迭代调整**：

| Android 组件 | ArkTS 映射 | 对齐难度 |
|-------------|-----------|---------|
| BottomNavigationView | 自定义 Row（**不是** Tabs！） | 高 — 需架构变更 |
| BottomSheet | Panel / NavDestination | 中 |
| RecyclerView + DiffUtil | List + LazyForEach + key 生成器 | 中 |
| ViewPager2 | Swiper | 低 |
| CardView | Column + borderRadius + shadow | 低 |

---

## 四、根因分析

### RC1: LLM 鸿蒙知识缺口（影响 8 个问题，严重性：高）

LLM 对 Android、TypeScript 和通用编程模式有强大的知识储备，但对**鸿蒙特有 API 行为**的认知不足：

- **fd:// 协议**：不知道 AVPlayer 本地播放必须用文件描述符
- **5MB http 限制**：不知道 `http.request()` ARRAY_BUFFER 模式有体积上限
- **requestInStream 不可靠**：训练数据可能显示 API 可用，但真机行为不同
- **ArkTS 严格模式**：生成合法 TypeScript 但违反 ArkTS 特有规则
- **sys.symbol 命名**：基于 SF Symbols 或 Material Icons 猜测，但鸿蒙有独立子集
- **PlaybackSpeed 枚举**：假设连续值（如 ExoPlayer），但鸿蒙仅支持 6 个离散值

**证据**：22 条踩坑中有 8 条直接源于 LLM 对鸿蒙 API 行为的认知偏差。

### RC2: Spec 平台约束深度不足（影响 3+6 个问题，严重性：高）

迁移 Spec（migration-spec.md, SS1-SS11）成功识别了模块结构和技术映射，但缺乏对鸿蒙平台特有约束的**深度分析**：

- 正确将 AVPlayer 标记为"Manual/红色风险"，但**未指定 fd:// 要求**
- 正确映射 OkHttp → http from @kit.NetworkKit，但**未指定下载体积限制**
- **缺少"鸿蒙已知约束"章节**

### RC3: 缺乏编译验证环（影响阶段二全部问题，严重性：高）

当前工作流：

```
代码生成(阶段二) → 人工编译 → 发现错误 → 反馈 LLM → 修复 → 再编译 → ...
```

阶段二和阶段三之间**没有自动化编译反馈**。每个编译错误都需要人工往返，错误发现延迟高。本项目约有 10 个编译级错误本可以更早发现。

### RC4: UI 对齐需要视觉迭代（影响 ~40% 的 v1 后开发时间，严重性：中）

Android Material Design 组件与 ArkUI 不存在 1:1 等价物。映射需要**视觉判断**，无法完全自动化。Tab 栏架构决策（Tabs 在 Navigation 内部 vs 外部）单独引发了 Index.ets 的结构性重写。

### RC5: API 命名不确定性（影响 2 个问题，严重性：中）

鸿蒙 API 命名约定与 Android/iOS 不同：
- `showActionMenu()` → 类型名**不是** `ShowActionMenuSuccessResponse`，而是 `ActionMenuSuccessResponse`
- `sys.symbol.tray_arrow_down` **不存在**，替代为 `envelope`
- LLM 的推断逻辑在鸿蒙命名体系下失效

---

## 五、优化建议

### 5.1 流程优化（5 条）

#### 优化 1：阶段一 Spec 增加「鸿蒙平台约束清单」

在 Spec 模板中新增 **SS12: 鸿蒙平台约束** 章节，必须覆盖：

- [ ] 文件访问：媒体播放器的 fd:// vs file:// 协议选择
- [ ] HTTP 下载：各 API 的体积限制（http.request ≤5MB, request.agent 无限制）
- [ ] UI 架构：Tab 栏相对于 Navigation 的放置位置
- [ ] 存储：沙箱路径限制、mkdir 递归参数
- [ ] 后台：后台执行的三要素（module.json5 + ContinuousTask + AVSession）
- [ ] 状态管理：AppStorage 初始化时序要求
- [ ] ArkTS 严格模式：禁止语言特性清单

**预期效果**：减少阶段二约 50% 的错误（消除 10 个代码生成问题中的 5 个）。

#### 优化 2：构建「已验证 API 参考数据库」

将分散在文档中的已验证信息结构化为**可查询的参考数据库**：

| 类别 | 当前数量 | 来源 |
|------|---------|------|
| 已验证 sys.symbol 名称 | 22 个 | development-experience.md |
| 已验证 API 类型名 | 5+ 个 | dev-pitfalls.md |
| 已验证 kit 导入路径 | 10+ 个 | CLAUDE.md |
| API 行为备注 | 10+ 条 | dev-pitfalls.md |

**形式**：整合为 skills 的 reference 文件，在代码生成前自动注入 LLM 上下文。

**预期效果**：将阶段二 API 命名错误降至接近零。

#### 优化 3：引入编译反馈环

重构阶段二→三的工作流，缩短编译错误发现周期：

```
当前：生成代码 → [人工编译] → [人工反馈] → 修复         (延迟: 分钟级)
优化：生成代码 → [自动语法检查] → 立即修复 → [人工编译]  (延迟: 秒级)
```

实现方式：
- 在 skills 中内嵌 ArkTS 严格模式检查规则（any、as、对象字面量）
- 维护"编译时错误模式库"，LLM 在输出前自检
- 探索 `hvigorw` CLI 集成（需评估可行性）

**预期效果**：将阶段三平均迭代次数从 1.7 降至约 1.2。

#### 优化 4：建立 UI 组件映射模板库

为阶段五（UI 对齐）创建**形式化的映射库**：

- 每个 Android UI 模式提供对应的 ArkTS 等价代码模板
- 包含架构决策（如"Tab 栏必须在 Navigation 外部"）作为硬规则
- 本项目已产出 16 个可复用代码模式模板（development-experience.md Part 3），应整合进 skills 系统

**预期效果**：减少阶段五约 30% 的 UI 迭代工作量。

#### 优化 5：阶段门控踩坑注入

在每个阶段开始前，将相关踩坑注入 LLM 上下文：

| 阶段 | 注入内容 |
|------|---------|
| 阶段一（Spec 生成） | 鸿蒙平台约束清单 + 上一项目的 RC1-RC5 根因 |
| 阶段二（代码生成） | 全部 22 条踩坑 + ArkTS 严格模式规则 |
| 阶段三（多轮修复） | 自修复协议（memory 中的内循环修复流程） |
| 阶段五（测试反馈） | UI 组件映射表 + 已验证 sys.symbol 清单 |

当前 CLAUDE.md 自动加载已覆盖部分规则，但 development-experience.md 和 dev-pitfalls.md 中的踩坑**未自动加载**。

**预期效果**：防止已知问题在后续项目中复发。

### 5.2 技术建议（3 条）

#### 技术建议 1：将 Top-10 踩坑合并入 CLAUDE.md

当前编码规则在 CLAUDE.md（自动加载），但 22 条踩坑在独立文档（不自动加载）。将影响最大的 10 条踩坑**直接写入 CLAUDE.md** 的"已知踩坑"章节，确保每次会话自动加载。

优先合并清单：
1. fd:// 协议（AVPlayer 本地播放）
2. request.agent（大文件下载）
3. Tabs 在 Navigation 外部（Tab 栏架构）
4. onReady 获取参数（NavDestination 生命周期）
5. mkdirSync(path, true)（递归目录创建）
6. ON CONFLICT DO UPDATE（保持自增 ID 稳定）
7. PlaybackSpeed 离散枚举
8. 后台播放三要素
9. sys.symbol 已验证清单
10. Object → JSON.stringify 类型桥接

#### 技术建议 2：推进 Skills 成熟度

skill-baseline.md 已定义 5 个 Skill 类别（SYN-01、REP-01、MIG-01、DT-01、DFX-01），当前状态：

| Skill ID | 当前成熟度 | 目标成熟度 | 行动项 |
|---------|-----------|-----------|--------|
| MIG-01 | L2 | L3 | 整合全部 22 条踩坑 + 平台约束清单 |
| DT-01 | L1 | L2 | 定义 smoke test 检查清单（7 条核心用户路径） |
| DFX-01 | L1 | L2 | 统一 hilog 分类 + 错误码映射 |

#### 技术建议 3：新增专项 Skill

development-experience.md 已建议 3 个新 Skill（已部分实现）：

| Skill | 优先级 | 覆盖范围 |
|-------|-------|---------|
| `arkts-media-playback` | P0 | AVPlayer 生命周期、fd:// 协议、后台播放三要素 |
| `arkts-download-manager` | P0 | request.agent 模式、文件移动管线 |
| `arkts-ui-alignment` | P1 | Android→ArkTS UI 组件映射表 |

---

## 六、可引入的新技术/工具

### 6.1 DevEco Studio CLI 集成

`hvigorw` 命令行构建工具可集成到开发流程中：
- 在每批代码生成后触发 `hvigorw --mode module -p module=entry` 编译验证
- 实现"生成即验证"，将编译错误发现从阶段三前移到阶段二

### 6.2 ArkTS 轻量 Linter

构建自定义 lint 规则集，在编译前捕获最常见的 3 类 ArkTS 严格模式违规：
- `any` / `unknown` 类型使用
- `as` 类型断言
- 对象字面量类型声明

可实现为轻量文本扫描器，不需要完整编译链。

### 6.3 回归测试矩阵

定义结构化测试矩阵，覆盖 7 条核心用户路径：

| # | 用户路径 | 涉及组件 | 验证点 |
|---|---------|---------|-------|
| 1 | 订阅 Feed | AddFeed → OnlineFeedView → FeedDao | RSS URL 解析 → 保存 → 显示 |
| 2 | 浏览剧集 | FeedDetail → EpisodeDetail | 列表 → 详情 → 播放 |
| 3 | 下载剧集 | DownloadManager → DownloadsComponent | 进度 → 完成 → 离线播放 |
| 4 | 队列管理 | QueueComponent → QueueDao | 添加 → 排序 → 自动播放 |
| 5 | 搜索播客 | SearchComponent → PodcastSearcher | 在线搜索 → 预览 → 订阅 |
| 6 | 设置偏好 | SettingsComponent → UserPreferences | 修改 → 持久化 → 重启验证 |
| 7 | 后台播放 | PlaybackController → BackgroundPlaybackManager | 播放 → 切后台 → 通知栏控制 |

### 6.4 OPML/快照回归

维护 OPML 测试固件验证数据层完整性：
- 解析器正确性（RSS 2.0、Atom、5 个命名空间处理器）
- 数据库往返完整性（导入 → 存储 → 查询 → 验证）
- Feed 更新流（HTTP 获取 → 解析差异 → 合并）

### 6.5 基于截图对比的 UI 回归

引入截图对比工具辅助阶段五 UI 对齐：
- Android 原版截图作为基准
- ArkTS 实现截图作为比对目标
- 可视化差异辅助人工判断

---

## 七、结论

### 7.1 量化改进潜力

| 优化措施 | 可预防的问题 | 预估时间节省 |
|---------|------------|------------|
| 增强 Spec 平台约束清单 | 3 个 Spec 遗漏 + 5 个级联问题 | 15-20% |
| 已验证 API 参考数据库 | 2 个命名错误 | 5% |
| 编译反馈环 | 10 个编译错误更快发现 | 10-15% |
| UI 组件映射模板 | ~30% 的 UI 返工 | 10-15% |
| 踩坑门控注入 | 已知问题复发预防 | 未来项目受益 |
| **合计** | | **40-55% 返工量减少** |

### 7.2 成熟度评估

本项目展示了成熟的迁移方法论：
- 六阶段流水线 + Done Gate 验收门（来自 project_migration_steps.md）
- 完整的踩坑沉淀（22 条，含根因+方案+预防规则）
- Skills 基线追踪（5 类别，L0-L4 成熟度）
- 16 个可复用代码模式模板

**主要成熟度缺口**：从"文档化知识"到"自动化执行"的转化——踩坑已记录在文档中，但尚未系统性地**注入 LLM 上下文**或通过**自动化工具**验证。

### 7.3 建议优先行动

| 优先级 | 行动项 | 工作量 | 预期效果 |
|-------|--------|-------|---------|
| P0 | 合并 Top-10 踩坑到 CLAUDE.md | 半天 | 每次会话自动加载关键约束 |
| P0 | 创建鸿蒙平台约束清单模板 | 1 天 | 阶段一 Spec 质量提升 |
| P1 | 结构化已验证 API 参考数据库 | 1 天 | 消除 API 命名猜测错误 |
| P1 | 推进 MIG-01 Skill 从 L2 到 L3 | 2-3 天 | 迁移执行标准化 |
| P2 | 评估 hvigorw CLI 编译反馈集成 | 需评估 | 阶段二→三加速 |
| P2 | 定义 7 条核心路径回归测试矩阵 | 1 天 | 阶段五测试覆盖可追踪 |

---

## 附录

### A. 22 条踩坑按阶段分布

| 踩坑编号 | 标题 | 主要影响阶段 |
|---------|------|------------|
| #1 | fd:// 协议 (AVPlayer) | 阶段二→三 |
| #2 | AVPlayer 状态机顺序 | 阶段二 |
| #3 | PlaybackSpeed 离散枚举 | 阶段二 |
| #4 | http.request() 5MB 限制 | 阶段一→三 |
| #5 | requestInStream 不可靠 | 阶段一→三 |
| #6 | request.agent 目录创建 | 阶段三 |
| #7 | URL &amp; 实体编码 | 阶段三 |
| #8 | Tab 栏 Navigation 位置 | 阶段二→五 |
| #9 | Emoji vs SymbolGlyph | 阶段三→五 |
| #10 | sys.symbol 名称验证 | 阶段二 |
| #11 | AppStorage 时序 | 阶段三 |
| #12 | ForEach key 变化字段 | 阶段三 |
| #13 | 对象字面量类型声明 | 阶段二 |
| #14 | as 类型断言禁止 | 阶段二 |
| #15 | any 类型禁止 | 阶段二 |
| #16 | NavDestination onReady | 阶段二 |
| #17 | ActionMenuSuccessResponse | 阶段二 |
| #18 | INSERT OR REPLACE 自增 ID | 阶段三 |
| #19 | ResultSet 必须 close() | 阶段二→四 |
| #20 | Preferences 序列化 | 阶段三 |
| #21 | http 实例必须 destroy() | 阶段二→四 |
| #22 | 响应头 Object 类型处理 | 阶段三 |

### B. 数据来源

| 文件 | 描述 |
|------|------|
| `docs/development-experience.md` | 主数据源：22 条踩坑、7 阶段开发时间线、16 个代码模式模板 |
| `docs/dev-pitfalls.md` | 踩坑精选：10 条含解决代码 |
| `CLAUDE.md` | 项目编码规则（自动加载，质量保证基石） |
| `docs/skill-baseline.md` | Skills 成熟度追踪（5 类别，L0-L4） |
| `docs/migration-spec.md` | 迁移 Spec（SS1-SS11） |
| Git 历史 | 8 次提交的完整 diff 和变更统计 |
| 代码扫描 | 全 96 个 .ets 文件的规则合规性检查 |
