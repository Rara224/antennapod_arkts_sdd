
# AntennaPod Android→ArkTS 全流程开发经验总结

> 生成日期：2026-03-18
> 项目：AntennaPod 开源播客客户端
> 迁移范围：Android Java (36 模块) → HarmonyOS ArkTS (单 entry 模块)
> 会话数：17 个 Claude Code 会话（2026-03-14 ~ 2026-03-18）
> 最终产出：96 个 .ets 文件，覆盖完整播客功能

---

## Part 1: 全流程开发历程

### 概览时间线

| 阶段 | 时间 | Sessions | 主要工作 | 关键决策 |
|------|------|----------|----------|----------|
| P1 分析 | Mar 14 | 2 | 36 模块→单 entry 规划, migration-spec.md | 模块合并策略, 6 个 Manual 风险项识别 |
| P2 脚手架 | Mar 15-16 | 3 | 目录结构, CLAUDE.md, module.json5, GlobalState | 单页架构(Index @Entry), 自建 EventBus |
| P3 平台适配 | Mar 16 | 3 | HttpClient, FileUtils, EventBus(33事件) | JSON.stringify 提取响应头(避免 any) |
| P4 数据层 | Mar 16-17 | 4 | 9 模型, PodDatabase, 7 DAOs | SQL 直接移植, JOIN 列别名策略 |
| P5a 播放 | Mar 17 | 3 | PlaybackController(641行), BackgroundPlaybackManager, SleepTimer | fd:// 协议, 三要素后台播放 |
| P5b 下载 | Mar 17 | 2 | DownloadManager(request.agent), FeedUpdateService | 5MB 限制发现, agent API 迁移 |
| P5c UI | Mar 17-18 | 4 | 28 组件, 自定义 Tab 栏, Android UI 对齐 | Tab 栏移出 Navigation, SymbolGlyph 统一 |

---

### P1: 分析阶段（Mar 14, 2 Sessions）

**做了什么**：
- 完整扫描 AntennaPod Android 源码（36 个 Gradle 模块）
- 识别组件计数：12 Activity, 71 Fragment, 46 Adapter, 7 数据库表, 20+ 事件
- 生成 `migration-spec.md`（SS1-SS11, 11 个规格段落）
- 制定模块合并策略：36 模块 → 单 entry，3 个 Skip（Cast, SSL, Widget）

**什么顺利**：
- 模块依赖关系清晰，合并策略一次确定
- 技术栈替换表（43 个依赖项→32 个替代方案+11 Skip）快速完成
- 风险分级准确：3 个红色（AVPlayer、MediaSession、SAX Parser）后来全部验证

**什么需要迭代**：
- 初版 Spec 遗漏了 `request.agent` 作为下载 API 的推荐，后在 P5b 修正
- 对 `http.requestInStream()` 可靠性估计过高，实际不可用

**经验教训**：
> 分析阶段投入 2 个 Session 看似"慢"，但为后续 15 个 Session 节省了大量返工。特别是模块合并策略和风险识别，如果跳过直接编码，数据层和播放器的坑会在后期集中爆发。

---

### P2: 脚手架阶段（Mar 15-16, 3 Sessions）

**做了什么**：
- 创建 15 个目录结构（models/, database/, network/, parser/, playback/ 等）
- 编写 `CLAUDE.md`（约 150 行，20+ 条编码规范）
- 配置 `module.json5`（权限、backgroundModes、extensionAbilities）
- 实现 `GlobalState.ets`（AppStorage 初始化 25+ key）
- 实现 `EventBus.ets`（33 个事件常量 + 发布/订阅/取消订阅）
- 定义 `AppRouter.ets`（19 个路由名 + 8 个参数类）

**什么顺利**：
- 单页 `@Entry` 架构（Index.ets）一次确定，后续无需变更
- `CLAUDE.md` 极大提升了后续 Session 的代码一致性
- `GlobalState.initAppStorage()` 确保了所有 `@StorageLink` key 的时序正确

**什么需要迭代**：
- `EventBus` 最初只有 10 个事件，随功能开发逐步扩展到 33 个
- `AppStorage` key 初始只有 8 个，最终扩展到 25+ 个

**经验教训**：
> `CLAUDE.md` 是跨 Session 一致性的基石。每条规则都来自实际踩坑（如 `any` 禁止、`as` 断言禁止）。建议在 P2 就建立，而非等到出问题再补。

---

### P3: 平台适配层（Mar 16, 3 Sessions）

**做了什么**：
- `HttpClient.ets`：封装 `http.createHttp()` 的 GET/POST，统一 destroy() 管理
- `FileUtils.ets`：文件读写、删除、目录创建、存在性检查
- `StringUtils.ets`：HTML 标签清理、时间格式化
- `EventData.ets`：33 个事件对应的数据类
- `Constants.ets`：数据库表名、播放状态常量、下载错误码

**什么顺利**：
- `@kit.NetworkKit` 的 `http` API 与 OkHttp 概念对齐度高
- `@kit.CoreFileKit` 的 `fileIo` API 覆盖了 commons-io 的核心功能
- ArkTS 的 `async/await` 完美替代 RxJava 的 `subscribeOn/observeOn`

**什么需要迭代**：
- `http.request()` 的响应头类型是 `Object`，需要用 `JSON.stringify()` 再解析才能类型安全地提取（避免 `any`）
- `fileIo.mkdir()` 不支持递归创建 → 改用 `fileIo.mkdirSync(path, true)`

**经验教训**：
> 平台适配层（HttpClient, FileUtils）应该先写、先测、先稳定。上层所有模块都依赖这一层，如果这里有隐藏 bug，会在数据层和下载层集中暴露。

---

### P4: 数据层（Mar 16-17, 4 Sessions）

**做了什么**：
- 9 个数据模型：Feed(36列), FeedItem(17列), FeedMedia(13列), Chapter, FeedPreferences, FeedFunding, DownloadResult, PodcastSearchResult, TranscriptEntry
- `PodDatabase.ets`：单例 + 7 表创建（含索引）
- 7 个 DAO：FeedDao, FeedItemDao, FeedMediaDao, ChapterDao, QueueDao, FavoritesDao, DownloadLogDao
- SQL 直接从 Android `PodDBAdapter` 移植，保持列名一致

**什么顺利**：
- `relationalStore` 的 SQL API 与 Android SQLite 几乎一致
- 7 表 DDL 一次创建成功，无需调试
- DAO 方法签名保持与 Android 一致，降低上层迁移成本

**什么需要迭代**：
- JOIN 查询的列别名必须与 DAO 解析逻辑对齐（如 `fm.id AS media_id`）
- `INSERT OR REPLACE` 会改变自增 id → 改用 `INSERT ... ON CONFLICT DO UPDATE`
- `ResultSet` 必须在 `finally` 中 `close()`，否则数据库锁
- 对象字面量不能做类型声明 → 每个回调参数都需要独立 class

**经验教训**：
> SQL 可以直接移植，但 DAO 的 ResultSet 解析需要特别注意列别名。建议为每个 JOIN 查询单独写解析方法（如 `parseItemWithMedia`），避免列名混淆。

---

### P5a: 播放引擎（Mar 17, 3 Sessions）

**做了什么**：
- `PlaybackController.ets`（641 行）：单例播放控制器
  - 播放/暂停/停止/快进/快退/seek/倍速/队列自动切歌
  - AVPlayer 状态机：Idle → Initialized → Prepared → Playing/Paused
  - 位置保存定时器（5秒间隔）
  - fd:// 本地文件播放 + 流式 URL 播放
- `BackgroundPlaybackManager.ets`（154 行）：后台播放三要素
  1. `backgroundTaskManager.startBackgroundRunning()` — 长时任务
  2. `avSession.createAVSession()` — 媒体会话
  3. `wantAgent` — 通知栏点击返回
- `SleepTimer.ets`（91 行）：定时暂停

**什么顺利**：
- AVPlayer 基础播放（play/pause/seek）API 简洁
- `avSession` 的媒体控制命令（play/pause/seek/next/previous）与 Android MediaSession 概念一致
- `SleepTimer` 用 `setInterval` 实现比 Android 的 `CountDownTimer` 更简洁

**什么需要迭代**：
- AVPlayer 不支持 `file://` 协议 → 必须用 `fd://` + 文件描述符
- `media.PlaybackSpeed` 是枚举（只有 6 个值：0.75x~2.0x），不能设置任意倍速 → 需要 `snapToValidSpeed()` 映射
- fd 生命周期管理：打开太早会占用资源，关闭太早会中断播放 → 在 `stopInternal()` 统一关闭
- 后台播放需要 3 处配置协同：module.json5 `backgroundModes`、权限 `KEEP_BACKGROUND_RUNNING`、代码 `startBackgroundRunning()`

**经验教训**：
> AVPlayer 是整个项目风险最高的组件。状态机必须严格按顺序，不能跳过步骤。建议单独测试 AVPlayer 生命周期后再集成到 PlaybackController。后台播放的三要素缺一不可，忘记任何一个都会导致后台被杀。

---

### P5b: 下载管理（Mar 17, 2 Sessions）

**做了什么**：
- `DownloadManager.ets`（296 行）：基于 `request.agent` 的下载管理器
  - 下载/取消/删除/进度追踪
  - 文件移动管线：cacheDir → downloads 目录
  - MIME 类型→扩展名映射
  - URL 中 `&amp;` 解码
- `FeedUpdateService.ets`：Feed 刷新服务
- `FeedUpdateWorker.ets` + `FeedUpdateWorkAbility.ets`：后台定时刷新

**什么顺利**：
- `request.agent` API 的设计比 `http.request()` 更适合大文件下载
- 进度回调 `task.on('progress')` 稳定可靠
- workScheduler 配置简单（module.json5 + WorkSchedulerExtensionAbility）

**什么需要迭代**：
- `http.request()` 有 ~5MB 大小限制（错误码 2300023）→ 必须用 `request.agent`
- `http.requestInStream()` 的 `dataEnd` 事件不可靠，实际设备上卡住 → 完全弃用
- `request.agent` 下载到 `cacheDir`，不是 `filesDir` → 需要 `moveFileSync` 后处理
- `moveFileSync` 要求目标目录已存在 → 先 `mkdirSync(dir, true)`

**经验教训**：
> 下载是"看似简单实际复杂"的典型。从 `http.request()` 到 `requestInStream` 到 `request.agent`，经历了 3 次方案变更。建议直接从 `request.agent` 开始，不要尝试 http API 下载大文件。

---

### P5c: UI 组件层（Mar 17-18, 4 Sessions）

**做了什么**：
- 28 个 UI 组件，涵盖 6 大功能区：
  - **首页**：HomeComponent, HomeConfigureDialog, SectionHeader
  - **队列**：QueueComponent
  - **收件箱**：InboxComponent
  - **订阅**：SubscriptionComponent, FeedGridItem
  - **播放**：FullPlayerComponent, VideoPlayerComponent, PlaybackHistoryComponent
  - **剧集**：EpisodeDetailComponent, AllEpisodesComponent, DownloadsComponent, EpisodeListItem
  - **Feed**：FeedDetailComponent, FeedInfoComponent, FeedSettingsComponent
  - **搜索/发现**：SearchComponent, AddFeedComponent, OnlineFeedViewComponent
  - **通用**：MoreComponent, SettingsComponent, StatisticsComponent, HalfCircleChart
  - **弹窗**：SortDialog, CustomizeNavigationDialog
  - **导入**：OpmlImportComponent
- 6 个 ViewModel：HomeViewModel, QueueViewModel, FeedDetailViewModel, AllEpisodesViewModel, SearchViewModel, StatisticsViewModel 等
- 2 个 DataSource：FeedItemDataSource, FeedDataSource

**什么顺利**：
- ArkUI 声明式语法与 Android XML 布局概念对齐度高
- `@StorageLink` 实现全局状态驱动 UI 刷新非常优雅
- `Navigation` + `NavPathStack` 的路由管理简洁

**什么需要迭代**：
- `Tabs` 在 `Navigation` 内部时，NavDestination 覆盖 Tab 栏 → 改为自定义 Tab 栏放在 Navigation 外部
- Unicode emoji 在 Tab 栏中大小不一致 → 统一使用 `SymbolGlyph`
- 多个 `sys.symbol` 名称不存在（如 `tray_arrow_down`, `dot_3_horizontal`）→ 需要逐个验证
- `promptAction.ShowActionMenuSuccessResponse` 命名错误 → 正确名称是 `ActionMenuSuccessResponse`
- `aboutToAppear` 中不能获取 NavDestination 参数 → 必须在 `onReady` 中获取
- `ForEach` key 生成器必须包含会变化的字段，否则列表不刷新

**经验教训**：
> UI 层的坑主要集中在"系统行为与预期不符"。建议每个 UI 组件先实现最简版本验证基本功能，再逐步完善样式。特别是 Tab 栏方案需要早期确定，因为它影响整个 App 的页面架构。

---

## Part 2: 技术踩坑百科（22 条，7 大类）

### AVPlayer（3 条）

#### 1. 本地文件播放必须使用 `fd://` 协议

**问题**：`file:// + 绝对路径` 设置 `avPlayer.url`，AVPlayer 直接进入 error 状态。

**根因**：HarmonyOS AVPlayer 不支持 `file://` 协议，本地文件必须通过文件描述符播放。

**解决方案**：
```typescript
import { fileIo } from '@kit.CoreFileKit';

const file = fileIo.openSync(localPath, fileIo.OpenMode.READ_ONLY);
avPlayer.url = 'fd://' + file.fd.toString();

// 播放结束/停止时在 stopInternal() 中统一关闭
fileIo.closeSync(file.fd);
```

**预防规则**：任何本地音视频播放都使用 fd:// 协议，永远不要尝试 file://。

---

#### 2. AVPlayer 状态机必须严格按顺序

**问题**：在 Initialized 状态直接调用 `play()` 无效，或在未 Prepared 时调用 `seek()` 静默失败。

**根因**：AVPlayer 状态机是严格的：`Idle → Initialized → Prepared → Playing/Paused`，不能跳过任何步骤。

**解决方案**：
```typescript
// 设置 URL 后等待 'initialized' 回调
player.on('stateChange', (state: string) => {
  if (state === 'initialized') {
    player.prepare();           // 不能跳过
  } else if (state === 'prepared') {
    player.setSpeed(speed);     // 必须在 prepared 后
    player.seek(savedPosition); // 必须在 prepared 后
    player.play();
  }
});
player.url = sourceUrl; // 触发 Idle → Initialized
```

**预防规则**：所有 AVPlayer 操作（seek/play/setSpeed）必须在对应状态回调中执行，不能"凭感觉"调用。

---

#### 3. PlaybackSpeed 是离散枚举，不能设置任意倍速

**问题**：`avPlayer.setSpeed(1.3)` 不生效或报错。

**根因**：`media.PlaybackSpeed` 只有 6 个有效值：`0.75x, 1.0x, 1.25x, 1.5x, 1.75x, 2.0x`。

**解决方案**：
```typescript
private snapToValidSpeed(speed: number): number {
  const validSpeeds: number[] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  let closest = validSpeeds[0];
  let minDiff = Math.abs(speed - closest);
  for (let i = 1; i < validSpeeds.length; i++) {
    const diff = Math.abs(speed - validSpeeds[i]);
    if (diff < minDiff) { minDiff = diff; closest = validSpeeds[i]; }
  }
  return closest;
}

private mapToPlaybackSpeed(speed: number): media.PlaybackSpeed {
  if (speed <= 0.75) return media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
  else if (speed <= 1.0) return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  // ... 其他映射
}
```

**预防规则**：UI 上的倍速选择器只展示这 6 个有效值，不要提供自由输入。

---

### 下载（4 条）

#### 4. `http.request()` 下载大文件有 ~5MB 限制

**问题**：`http.createHttp().request()` + `expectDataType: ARRAY_BUFFER` 下载播客音频，报错 `CURLcode 23, error 2300023`。

**根因**：`http.request()` 的 ARRAY_BUFFER 模式将整个响应加载到内存，有约 5MB 的大小限制。

**解决方案**：使用 `request.agent` API：
```typescript
import { request } from '@kit.BasicServicesKit';

const config: request.agent.Config = {
  action: request.agent.Action.DOWNLOAD,
  url: downloadUrl,
  overwrite: true,
  saveas: './' + fileName, // 相对于 cacheDir
  mode: request.agent.Mode.FOREGROUND,
  gauge: true              // 启用进度回调
};
const task = await request.agent.create(context, config);
```

**预防规则**：任何超过 1MB 的文件下载都使用 `request.agent`，不要使用 `http.request()`。

---

#### 5. `http.requestInStream()` 不可靠

**问题**：`httpRequest.requestInStream()` 返回的 Promise 在收到**响应头**后即 resolve，`dataEnd` 事件在实际设备上不触发，导致下载卡住。

**根因**：`requestInStream` 的事件机制在当前版本不稳定。

**解决方案**：完全弃用 `requestInStream`，直接使用 `request.agent` API。

**预防规则**：不要使用 `requestInStream` 下载文件，它只适合小数据量的流式读取（如 SSE）。

---

#### 6. `request.agent` 下载到 cacheDir，文件移动需递归创建目录

**问题**：`request.agent` 下载完成后文件在 `cacheDir`。`moveFileSync` 到 `filesDir/downloads/` 时报 `13900002`（ENOENT）。

**根因**：`fileIo.mkdir()` 默认不递归创建，目标目录不存在。

**解决方案**：
```typescript
try {
  fileIo.mkdirSync(downloadDir, true);  // 递归创建
  fileIo.moveFileSync(cachePath, destPath);
} catch (moveErr) {
  // 降级：直接使用 cache 路径
  finalPath = cachePath;
}
```

**预防规则**：创建目录统一使用 `mkdirSync(path, true)`，移动文件前先确保目标目录存在。

---

#### 7. URL 中 `&amp;` 需要解码

**问题**：RSS XML 中的下载 URL 包含 `&amp;` 实体编码，直接用于 HTTP 请求返回 400 错误。

**根因**：XML 解析器输出的 URL 保留了 HTML 实体编码。

**解决方案**：
```typescript
const cleanUrl = downloadUrl.replace(/&amp;/g, '&');
```

**预防规则**：所有从 XML/RSS 解析出的 URL 在使用前都要做实体解码。

---

### UI（5 条）

#### 8. Tab 栏在子页面中的可见性问题

**问题**：`Navigation` 包裹 `Tabs` 时，NavDestination 子页面覆盖整个 Navigation 区域，Tab 栏随之隐藏。

**根因**：Tabs 在 Navigation 内部，NavDestination 会覆盖包括 Tabs 在内的整个区域。

**解决方案**：将 Tab 栏放在 Navigation 外部：
```typescript
Column() {
  Navigation() { /* 内容区 */ }
    .layoutWeight(1)
  // MiniPlayer — 始终在 Tab 栏上方
  if (isPlayerVisible && !isFullPlayerVisible) { MiniPlayerArea() }
  // 自定义 Tab 栏 — 始终在最底部
  if (!isFullPlayerVisible) { CustomTabBar() }
}
```

**预防规则**：Tab 栏使用自定义 Row 实现，放在 Navigation 外部。不要使用 `Tabs` 包裹在 Navigation 内部。

---

#### 9. Emoji vs SymbolGlyph 大小不一致

**问题**：Unicode emoji（📋📥📡）与普通 Unicode 字符（⌂）渲染大小差异巨大。

**根因**：emoji 按平台图片渲染，大小不受 `fontSize` 精确控制。

**解决方案**：统一使用 `SymbolGlyph` + 系统 Symbol 资源：
```typescript
SymbolGlyph($r('sys.symbol.house'))
  .fontSize(22)
  .fontColor([Color.Black])
```

**预防规则**：所有图标统一使用 `SymbolGlyph`，不要混用 emoji 和 SymbolGlyph。

---

#### 10. `sys.symbol` 名称验证清单

**问题**：部分 SF Symbol 名称在 HarmonyOS 中不存在，编译报 `Unknown resource name`。

**已验证可用（22 个）**：
```
house, list_bullet, envelope, square_grid_2x2, line_3_horizontal,
play_fill, pause_fill, arrow_down, checkmark, plus, trash,
magnifyingglass, chevron_right, chevron_left, lock, clock, gearshape,
arrow_left, arrow_right, speaker_wave_2_fill, play_circle_fill,
pause_circle_fill, square_and_pencil
```

**已验证不存在**：
- `forward_fill` → 替代：Text('\u25B6\u25B6')
- `backward_fill` → 替代：Text('\u25C0\u25C0')
- `tray_arrow_down` → 替代：`envelope`
- `dot_3_horizontal` / `ellipsis` → 替代：`line_3_horizontal`
- `chart_bar` → 替代：`square_grid_2x2`

**预防规则**：只从已验证列表中选取 symbol 名称，不要猜测。新名称需先编译验证。

---

#### 11. AppStorage 时序：`setOrCreate` 必须在 `@StorageLink` 声明前执行

**问题**：`@StorageLink('someKey')` 在组件创建时找不到对应的 AppStorage key，UI 不刷新。

**根因**：`@StorageLink` 在组件实例化时绑定 AppStorage，如果此时 key 尚未通过 `setOrCreate` 注册，绑定失败。

**解决方案**：在 `GlobalState.initAppStorage()` 中统一注册所有 key，确保在任何组件创建前执行：
```typescript
// GlobalState.ets — 在 EntryAbility.onCreate 时调用
static initAppStorage(): void {
  AppStorage.setOrCreate<boolean>('isPlaying', false);
  AppStorage.setOrCreate<string>('currentEpisodeTitle', '');
  // ... 所有 25+ key
}
```

**预防规则**：新增任何 `@StorageLink` key 时，必须同时在 `GlobalState.initAppStorage()` 中添加 `setOrCreate`。

---

#### 12. ForEach key 生成器必须包含会变化的字段

**问题**：`ForEach` 列表更新数据后，UI 不刷新或刷新异常。

**根因**：如果 key 只用 `id`，当同一条目的属性变化（如 isPlayed 状态改变）时，ArkUI 认为该条目未变化，跳过重渲染。

**解决方案**：
```typescript
ForEach(this.items, (item: FeedItem) => {
  EpisodeListItem({ item: item })
}, (item: FeedItem) => item.id.toString() + '_' + item.playState.toString())
```

**预防规则**：ForEach 的 key 生成器必须包含所有会影响 UI 显示的字段。

---

### ArkTS 语言（3 条）

#### 13. 对象字面量不能做类型声明

**问题**：编译报错 `Object literals cannot be used as type declarations (arkts-no-obj-literals-as-types)`。

**触发代码**：
```typescript
// 错误
httpRequest.on('dataReceiveProgress', (data: { receiveSize: number, totalSize: number }) => {});
```

**解决方案**：必须定义独立的 class：
```typescript
class DownloadReceiveProgress {
  receiveSize: number = 0;
  totalSize: number = 0;
}
httpRequest.on('dataReceiveProgress', (data: DownloadReceiveProgress) => {});
```

**预防规则**：所有回调参数类型都使用 class 定义，不使用对象字面量类型。

---

#### 14. `as` 类型断言被禁止

**问题**：编译报错 `Type assertion expressions are not allowed (arkts-no-ts-like-as)`。

**根因**：ArkTS 严格模式禁止 TypeScript 的 `as` 断言。

**解决方案**：使用 `instanceof` 检查：
```typescript
// 错误
const item = data as FeedItem;

// 正确
if (data instanceof FeedItem) {
  const item: FeedItem = data;
}
```

**预防规则**：所有类型窄化使用 `instanceof`，不使用 `as`。

---

#### 15. `any` 类型被完全禁止

**问题**：编译报错 `Use explicit types instead of "any", "unknown" (arkts-no-any-unknown)`。

**根因**：ArkTS 严格模式禁止所有 `any` 和 `unknown` 类型。

**解决方案**：使用具体类型或 `Object`：
```typescript
// 错误
let data: any = response.result;

// 正确
let data: string = response.result.toString();
```

**预防规则**：所有变量必须有明确类型标注，用 `Object` 替代 `any`/`unknown`。

---

### 导航（2 条）

#### 16. NavDestination 参数必须在 `onReady` 中获取

**问题**：在 `aboutToAppear()` 中通过 `NavPathStack` 获取参数，得到 `undefined`。

**根因**：`aboutToAppear` 在组件实例化时调用，此时 NavDestination 上下文尚未就绪。

**解决方案**：
```typescript
NavDestination() {
  // UI 内容
}
.onReady((ctx: NavDestinationContext) => {
  const param = ctx.pathInfo.param;
  if (param instanceof EpisodeDetailParam) {
    this.episodeId = param.episodeId;
    this.loadData();
  }
})
```

**预防规则**：所有 NavDestination 参数获取放在 `onReady` 回调中。

---

#### 17. `ActionMenuSuccessResponse` 命名陷阱

**问题**：使用 `promptAction.ShowActionMenuSuccessResponse`，编译报 "does not exist"。

**根因**：正确的类型名是 `ActionMenuSuccessResponse`，没有 `Show` 前缀。

**解决方案**：
```typescript
promptAction.showActionMenu({ ... })
  .then((result: promptAction.ActionMenuSuccessResponse) => { ... });
```

**预防规则**：API 名称不确定时查阅官方文档，不要根据方法名推断类型名。

---

### 数据库（3 条）

#### 18. `INSERT OR REPLACE` 会改变自增 id

**问题**：使用 `INSERT OR REPLACE` 更新已有记录时，自增 id 被重新分配，关联关系断裂。

**根因**：`INSERT OR REPLACE` 实际执行的是 DELETE + INSERT，会触发新的 AUTOINCREMENT。

**解决方案**：使用 `INSERT ... ON CONFLICT DO UPDATE`：
```sql
INSERT INTO Feeds (id, title, download_url)
VALUES (?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  title = excluded.title,
  download_url = excluded.download_url
```

**预防规则**：需要保持 id 稳定时，使用 `ON CONFLICT DO UPDATE`，不使用 `OR REPLACE`。

---

#### 19. ResultSet 必须 close()

**问题**：查询后未关闭 ResultSet，后续查询报数据库锁错误。

**根因**：`relationalStore` 的 ResultSet 持有数据库连接，不关闭会导致连接泄漏。

**解决方案**：使用 `try/finally` 确保关闭：
```typescript
const resultSet = await store.querySql(sql, params);
try {
  // 处理数据
  while (resultSet.goToNextRow()) { ... }
} finally {
  resultSet.close(); // 必须关闭
}
```

**预防规则**：所有 DAO 方法的 ResultSet 使用 `try/finally` 模式。

---

#### 20. Preferences 序列化只支持基础类型

**问题**：`preferences.putSync()` 不支持存储对象或数组。

**根因**：`@kit.ArkData` 的 Preferences 只支持 string, number, boolean, string[] 类型。

**解决方案**：复杂数据用 JSON 序列化：
```typescript
// 存储
preferences.putSync('feedOrder', JSON.stringify(orderArray));

// 读取
const orderStr = preferences.getSync('feedOrder', '[]') as string;
const orderArray: number[] = JSON.parse(orderStr) as number[];
```

**预防规则**：Preferences 存储复杂数据统一用 JSON.stringify/parse，并明确类型。

---

### 网络（2 条）

#### 21. http 实例用完必须 destroy()

**问题**：频繁创建 `http.createHttp()` 而不 destroy，出现内存泄漏和句柄耗尽。

**根因**：每个 `http.createHttp()` 实例持有底层 CURL 句柄。

**解决方案**：使用 `try/finally`：
```typescript
const httpRequest = http.createHttp();
try {
  const response = await httpRequest.request(url, options);
  return response.result.toString();
} finally {
  httpRequest.destroy(); // 必须销毁
}
```

**预防规则**：封装 HttpClient 工具类，确保每次请求后 destroy。

---

#### 22. 响应头提取需要 JSON.stringify workaround

**问题**：`response.header` 类型是 `Object`，不能直接用点语法或索引访问属性（会引入 `any`）。

**根因**：ArkTS 严格模式下 `Object` 不能通过 `[]` 访问属性。

**解决方案**：序列化后重新解析：
```typescript
const headerStr = JSON.stringify(response.header);
const headerJson = JSON.parse(headerStr);
// 此时可以安全地访问具体字段
```

**预防规则**：系统 API 返回 `Object` 类型时，用 JSON.stringify → JSON.parse 桥接。

---

## Part 3: 现有 11 个 Skills 优化建议

### 3.1 arkts-knowledge-verifier

**建议新增内容**：

| 内容 | 说明 |
|------|------|
| 已验证 sys.symbol 名称清单 (22个) | 避免使用不存在的 symbol 名称 |
| kit 统一导入路径表 | `@kit.NetworkKit`, `@kit.ArkData`, `@kit.MediaKit` 等完整映射 |
| API 命名纠错表 | `ShowActionMenuSuccessResponse` → `ActionMenuSuccessResponse` 等 |
| ArkTS 严格模式禁止项速查 | `any`, `as`, 对象字面量类型、`eval()`、动态 `import()` |

**参考文件**：`docs/dev-pitfalls.md` #6 (sys.symbol), #4 (对象字面量), #5 (API 命名)

---

### 3.2 arkts-component-builder

**建议新增内容**：

| 模式 | 代码模板 | 参考文件 |
|------|---------|---------|
| MiniPlayer 模式 | 底部浮动播放条 + 进度条 + 封面 + 播放/暂停按钮 | `Index.ets:152-226` |
| 自定义 Tab 栏模式 | 药丸指示器 + SymbolGlyph 图标 + layoutWeight 等分 | `Index.ets:229-241` |
| EventBus 订阅生命周期模式 | `aboutToAppear` 订阅, `aboutToDisappear` 取消 | `HomeComponent.ets` |
| ViewModel 数据加载模式 | `@State` 驱动 + async 加载 + EventBus 刷新 | `HomeViewModel.ets` |
| 封面图 + fallback 模式 | Image(url) + 文字首字母占位符 | `Index.ets:162-183` |
| 空状态组件模式 | EmptyStateView 通用占位 | `EmptyStateView.ets` |

---

### 3.3 arkts-data-layer

**建议新增内容**：

| 模式 | 代码模板 | 参考文件 |
|------|---------|---------|
| 多表 JOIN DAO 模式 | LEFT JOIN + 列别名 + 分表解析方法 | `FeedItemDao.ets:13-32` |
| request.agent 下载队列管理 | Config 模板 + Progress 回调 + 文件移动管线 | `DownloadManager.ets:70-117` |
| FeedUpdateService 模式 | HTTP 获取 → XML 解析 → DB 合并 → EventBus 通知 | `FeedUpdateService.ets` |
| ResultSet 安全模式 | try/finally close() 模式 | `FeedItemDao.ets:24-31` |
| 批量操作模式 | `executeSql` + `?` 占位符数组 | `PodDatabase.ets` |

---

### 3.4 arkts-navigation-builder

**建议新增内容**：

| 模式 | 代码模板 | 参考文件 |
|------|---------|---------|
| 路由参数类定义模式 | class XxxParam { fieldName: type = default } | `AppRouter.ets:29-60` |
| routerMap @Builder 模式 | if-else 链匹配 RouteName → 组件 | `Index.ets:49-81` |
| FullPlayer 隐藏 Tab 模式 | `@StorageLink('isFullPlayerVisible')` 控制 Tab 栏 | `Index.ets:229` |
| onReady 参数接收模式 | `NavDestination.onReady((ctx) => ctx.pathInfo.param)` | `EpisodeDetailComponent.ets` |
| 路由常量集中管理 | `RouteName` 静态类 (19个路由) | `AppRouter.ets:4-24` |

---

### 3.5 arkts-state-manager

**建议新增内容**：

| 模式 | 代码模板 | 参考文件 |
|------|---------|---------|
| GlobalState 完整 key 注册表 (25+) | 播放器状态 8 key, UI 状态 3 key, 偏好设置 8 key 等 | `GlobalState.ets:53-88` |
| 双层持久化模式 | Preferences 持久化 + `syncToAppStorage()` 驱动 UI | `UserPreferences.ets` |
| PlaybackController→AppStorage 绑定 | 播放器内部状态实时同步到 AppStorage | `PlaybackController.ets:134-143` |
| EventBus + @State 联动模式 | EventBus 通知 → ViewModel 更新 @State → UI 自动刷新 | `QueueViewModel.ets` |
| @Provide/@Consume NavPathStack | Index @Provide → 子组件 @Consume | `Index.ets:29` |

---

### 3.6 arkts-system-capabilities

**建议新增内容**：

| 模式 | 代码模板 | 参考文件 |
|------|---------|---------|
| AVPlayer 完整生命周期文档 | Idle→Initialized→Prepared→Playing/Paused→Stopped→Released | `PlaybackController.ets:296-354` |
| 后台播放三要素模式 | WantAgent + startBackgroundRunning + AVSession | `BackgroundPlaybackManager.ets:32-89` |
| workScheduler module.json5 配置 | extensionAbilities type:"workScheduler" | `module.json5:76-81` |
| fd:// 本地文件播放模式 | fileIo.openSync → fd:// → 统一关闭 | `PlaybackController.ets:110-121` |
| 权限配置三件套 | INTERNET + GET_NETWORK_INFO + KEEP_BACKGROUND_RUNNING | `module.json5:14-38` |

---

### 3.7 arkts-pattern-library

**建议新增内容**：

| 模式 | 说明 | 参考文件 |
|------|------|---------|
| 播放器 UI 模式 | MiniPlayer + FullPlayer 双态播放器 | `Index.ets`, `FullPlayerComponent.ets` |
| 下载管理 UI 模式 | 进度环 + 取消按钮 + 完成状态 | `EpisodeDetailComponent.ets` |
| Feed 列表 + 详情页模式 | 网格订阅列表 → Feed 详情 → 剧集详情 | `SubscriptionComponent.ets`, `FeedDetailComponent.ets` |
| 设计对齐工作流 | Android 截图 → 组件拆解 → ArkUI 实现 | 全 UI 组件 |

---

### 3.8 arkts-project-scaffolder

**建议新增内容**：

| 内容 | 说明 | 参考文件 |
|------|------|---------|
| 完整文件清单模板 (96 文件) | 包含 models/database/network/parser/playback/pages/components/viewmodels/datasource/helpers/workers/common 全目录 | `entry/src/main/ets/` |
| 层依赖规则 | pages→components→viewmodels→database+network, common←所有层 | `CLAUDE.md` |
| module.json5 音频应用模板 | 含 audioPlayback backgroundMode + 3 权限 + workScheduler | `module.json5` |
| GlobalState 初始化清单 | 25+ AppStorage key 的注册模板 | `GlobalState.ets` |

---

### 3.9 arkts-library-migration

**建议新增内容**：

| 决策节点 | 结论 | 参考文件 |
|---------|------|---------|
| 大文件下载 API 选型 | http.request() ≤5MB, request.agent 无限制 → 统一用 agent | `DownloadManager.ets` |
| requestInStream 可靠性 | 不可靠，弃用 | `dev-pitfalls.md #9` |
| RxJava 复杂度评估 | AntennaPod 仅用简单模式，async/await 可完全替代 | `migration-spec.md SS3` |
| EventBus 自建 vs 三方 | 自建 Map<string, Function[]> 足够（< 100 行代码） | `EventBus.ets` |

---

### 3.10 arkts-animation-builder

**建议新增内容**：

| 模式 | 说明 | 参考文件 |
|------|------|---------|
| 下载进度环动画 | Progress(type: Ring) + 动态 value 绑定 | `EpisodeDetailComponent.ets` |
| 播放按钮状态切换 | SymbolGlyph play_fill ↔ pause_fill + 透明度过渡 | `Index.ets:202` |
| MiniPlayer 出现/消失 | if 条件控制 + transition 动画 | `Index.ets:153` |
| 半圆统计图表 | Canvas 自定义绘制 + 动画填充 | `HalfCircleChart.ets` |

---

### 3.11 arkts-spec-generator

**建议新增内容**：

| 内容 | 说明 | 参考文件 |
|------|------|---------|
| 扩展概念映射表（含实际代码引用） | Activity→@Entry Page, Fragment→@Component, Adapter→LazyForEach 等 + 真实代码行号 | `migration-spec.md SS2-SS3` |
| RSS 命名空间迁移模式 | SAX Push → XmlPullParser Pull，8 个 Namespace Handler 保持结构 | `parser/FeedParser.ets`, `parser/namespace/` |
| 风险分级验证结果 | 3 个红色风险全部验证（AVPlayer/MediaSession/SAX 全部成功迁移） | 本文档 Part 1 |

---

## Part 4: 新 Skill 提案（3 个）

### 4.1 arkts-media-playback（高优先级）

**触发关键词**：AVPlayer、音视频播放、后台播放、媒体会话、播客播放、音乐播放器

**核心内容**：

| 模块 | 内容 |
|------|------|
| AVPlayer 状态机图 | Idle → Initialized → Prepared → Playing ↔ Paused → Stopped → Released |
| fd:// 本地播放 | `fileIo.openSync` → `fd://` + fd → `stopInternal()` 统一关闭 |
| Speed 枚举映射 | 6 个有效值 + `snapToValidSpeed()` + `mapToPlaybackSpeed()` |
| 位置保存定时器 | `setInterval` 5秒 → `feedMediaDao.setPosition()` |
| PlaybackCallbacks 接口 | play/pause/seek/fastForward/rewind/next/previous 7 个回调 |
| 队列自动切歌 | `onCompleted` → `getNextQueueItem()` → `playEpisode()` 或 `stop()` |
| 后台播放三要素 | WantAgent + startBackgroundRunning(AUDIO_PLAYBACK) + AVSession |
| SleepTimer 模式 | setInterval tick → EventBus publish → onTimerExpired callback |

**参考实现**：
- `PlaybackController.ets` (641 行) — 播放控制核心
- `BackgroundPlaybackManager.ets` (154 行) — 后台播放
- `SleepTimer.ets` (91 行) — 定时暂停

**module.json5 必须配置**：
```json5
{
  "abilities": [{
    "backgroundModes": ["audioPlayback"]
  }],
  "requestPermissions": [{
    "name": "ohos.permission.KEEP_BACKGROUND_RUNNING"
  }]
}
```

---

### 4.2 arkts-download-manager（高优先级）

**触发关键词**：文件下载、进度追踪、下载队列管理、request.agent、大文件下载

**核心内容**：

| 模块 | 内容 |
|------|------|
| request.agent.Config 模板 | action/url/saveas/mode/gauge 5 个必填字段 |
| Progress 回调模式 | `progress.sizes[0]`=已接收, `progress.sizes[1]`=总量 |
| 文件移动管线 | verify stat → mkdirSync(true) → moveFileSync → updateDB → EventBus |
| 取消/删除模式 | `task.stop()` 取消 + `fileIo.unlinkSync()` 删除 + DB 清除 |
| MIME→扩展名映射 | mp3/m4a/ogg/opus/aac/mp4 + URL 扩展名 fallback |
| URL 清洗 | `&amp;` → `&` 解码 |
| 下载去重 | `activeDownloads: Set<number>` 防止重复下载 |
| 下载日志 | DownloadResult 记录 + DownloadLogDao 持久化 |

**参考实现**：
- `DownloadManager.ets` (296 行) — 下载管理核心
- `FileUtils.ets` (100 行) — 文件操作工具

**API 选型决策树**：
```
文件大小 ≤ 5MB → http.request() + ARRAY_BUFFER 可用
文件大小 > 5MB → 必须用 request.agent
需要进度回调   → 必须用 request.agent (gauge: true)
需要后台下载   → request.agent + Mode.BACKGROUND
```

---

### 4.3 arkts-ui-alignment（中优先级）

**触发关键词**：匹配 Android UI 设计、视觉一致性、Material Design 迁移、UI 对齐

**核心内容**：

| 模块 | 内容 |
|------|------|
| Android→ArkTS 布局映射 | BottomNavigationView→自定义 Row, BottomSheet→NavDestination, DrawerLayout→SideBarContainer, ViewPager2→Swiper |
| Material 3 药丸 Tab 指示器 | Column + borderRadius(14) + backgroundColor 条件切换 |
| 封面图 + fallback 模式 | Image(url) 成功→显示图片, 失败→Text(首字母) + 灰色背景 |
| SymbolGlyph 图标体系 | 22 个已验证名称 + fontSize/fontColor 统一规范 |
| 颜色系统迁移 | Material primaryColor→`#007DFF`, surface→`#FAFAFA`, onSurface→`#182431` |
| 间距系统 | margin/padding 采用 4dp 基数（4/8/12/16/20/24） |

**Android UI 元素→ArkTS 组件映射表**：

| Android 元素 | ArkTS 组件 | 备注 |
|-------------|-----------|------|
| `BottomNavigationView` | 自定义 `Row` + `tabBarItem` @Builder | 不用 `Tabs`（见踩坑 #8） |
| `BottomSheetDialogFragment` | `NavDestination` (全屏) 或 `Sheet` | 视需求选择 |
| `DrawerLayout` | `SideBarContainer` | 侧边栏 |
| `RecyclerView` | `List` + `LazyForEach` | 虚拟列表 |
| `ViewPager2` | `Swiper` | 翻页 |
| `CoordinatorLayout` | `Stack` + 自定义手势 | 需手动实现 |
| `CardView` | `Column` + `borderRadius` + `shadow` | 卡片 |
| `FloatingActionButton` | `Button` + 绝对定位 | FAB |
| `ProgressBar` (Linear) | `Progress({ type: ProgressType.Linear })` | 进度条 |
| `ProgressBar` (Circular) | `Progress({ type: ProgressType.Ring })` | 进度环 |
| `Toolbar` / `ActionBar` | `NavDestination` 标题栏 | 自动 |
| `AlertDialog` | `AlertDialog.show()` | 弹窗 |
| `PopupMenu` | `Menu` + `MenuItem` | 菜单 |
| `Snackbar` | `promptAction.showToast()` | 轻提示 |

---

## Part 5: 可复用资产清单

### 5.1 代码模式模板（16 个）

| # | 模式名 | 核心代码 | 参考文件 |
|---|--------|---------|---------|
| 1 | **Singleton 单例** | `private static instance`, `static getInstance()` | `PodDatabase.ets`, `PlaybackController.ets`, `EventBus.ets` |
| 2 | **EventBus 发布/订阅** | `Map<string, Function[]>`, subscribe/publish/unsubscribe | `EventBus.ets` |
| 3 | **Database 单例初始化** | `relationalStore.getRdbStore()` + `createTables()` | `PodDatabase.ets` |
| 4 | **DAO JOIN 查询** | LEFT JOIN + 列别名 + try/finally close ResultSet | `FeedItemDao.ets:13-32` |
| 5 | **HttpClient 封装** | `http.createHttp()` + try/finally destroy + options | `HttpClient.ets` |
| 6 | **request.agent 下载** | Config 模板 + progress/completed/failed 回调 | `DownloadManager.ets:70-117` |
| 7 | **AVPlayer 生命周期** | stateChange 回调 + 状态机转换 + 错误处理 | `PlaybackController.ets:296-354` |
| 8 | **后台播放三步** | WantAgent + startBackgroundRunning + AVSession | `BackgroundPlaybackManager.ets:32-89` |
| 9 | **自定义 Tab 栏** | Row + tabBarItem @Builder + SymbolGlyph + 药丸指示器 | `Index.ets:83-111` |
| 10 | **Navigation 路由** | NavPathStack + routerMap @Builder + if-else 匹配 | `Index.ets:48-81` |
| 11 | **路由参数类** | class XxxParam { field: type = default } | `AppRouter.ets:29-60` |
| 12 | **XmlPullParser** | Pull 模式 + 命名空间处理 + Token 循环 | `FeedParser.ets` |
| 13 | **Preferences 双层** | Preferences 持久化 + syncToAppStorage() | `UserPreferences.ets` |
| 14 | **FileUtils 工具** | readText/writeText/copyFile/deleteFile/exists/ensureDirectory | `FileUtils.ets` |
| 15 | **MiniPlayer** | 进度条 + 封面 + 标题 + 播放按钮 + 点击展开 | `Index.ets:152-226` |
| 16 | **封面图 fallback** | Image(url) 显示 / Text(首字母) + 灰色背景 占位 | `Index.ets:162-183` |

---

### 5.2 配置模板（3 个）

#### 模板 1：module.json5 音频应用模板

```json5
{
  "module": {
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
      { "name": "ohos.permission.GET_NETWORK_INFO" },
      { "name": "ohos.permission.KEEP_BACKGROUND_RUNNING" }
    ],
    "abilities": [{
      "backgroundModes": ["audioPlayback"],
      "skills": [{ "entities": ["entity.system.home"], "actions": ["ohos.want.action.home"] }]
    }],
    "extensionAbilities": [{
      "name": "FeedUpdateWorkAbility",
      "srcEntry": "./ets/workers/FeedUpdateWorkAbility.ets",
      "type": "workScheduler"
    }]
  }
}
```

#### 模板 2：CLAUDE.md HarmonyOS 项目模板

关键规则（从本项目验证的 20+ 条规则中提炼）：
- 导入规范：kit 统一导入 vs @ohos.xxx 直接导入
- 类型禁止：any, as, 对象字面量类型, eval(), 动态 import()
- 组件规范：struct not class, 单根容器 build(), @Entry 仅 Page 级
- 数据库规范：单例, ResultSet close(), SQL 占位符, ON CONFLICT
- 播放器规范：fd://, 状态机顺序, backgroundModes 声明
- 导航规范：onReady 取参数, NavPathStack @Provide

#### 模板 3：AppStorage key 注册表

```typescript
// 播放器状态 (8 key)
AppStorage.setOrCreate<boolean>('isPlaying', false);
AppStorage.setOrCreate<string>('currentEpisodeTitle', '');
AppStorage.setOrCreate<string>('currentFeedTitle', '');
AppStorage.setOrCreate<number>('currentEpisodeId', -1);
AppStorage.setOrCreate<string>('currentCoverUrl', '');
AppStorage.setOrCreate<number>('playbackPosition', 0);
AppStorage.setOrCreate<number>('playbackDuration', 0);
AppStorage.setOrCreate<string>('currentEpisodePubDate', '');

// UI 状态 (3 key)
AppStorage.setOrCreate<number>('currentTabIndex', 0);
AppStorage.setOrCreate<boolean>('isPlayerVisible', false);
AppStorage.setOrCreate<boolean>('isFullPlayerVisible', false);

// 应用状态 (2 key)
AppStorage.setOrCreate<boolean>('isFeedUpdateRunning', false);
AppStorage.setOrCreate<boolean>('dbReady', false);

// 偏好设置 (9 key)
AppStorage.setOrCreate<boolean>('enqueueDownloaded', true);
AppStorage.setOrCreate<number>('enqueueLocation', 1);
AppStorage.setOrCreate<number>('playbackSpeed', 1.0);
AppStorage.setOrCreate<number>('fastForwardSecs', 30);
AppStorage.setOrCreate<number>('rewindSecs', 10);
AppStorage.setOrCreate<boolean>('skipSilence', false);
AppStorage.setOrCreate<boolean>('showRemainTime', false);
AppStorage.setOrCreate<boolean>('streamOverDownload', false);
AppStorage.setOrCreate<boolean>('useEpisodeCover', true);
AppStorage.setOrCreate<number>('themeMode', 0);
```

---

### 5.3 测试清单（5 个）

#### 清单 1：播放验证

- [ ] 在线流式播放（网络 URL）
- [ ] 本地文件播放（fd:// 协议）
- [ ] 播放/暂停/停止状态切换
- [ ] 快进/快退（30s/10s）
- [ ] Seek 到指定位置
- [ ] 倍速播放（0.75x ~ 2.0x）
- [ ] 后台播放保持（切到桌面不中断）
- [ ] 通知栏媒体控制（play/pause/next/previous）
- [ ] 位置自动保存（5秒间隔）
- [ ] 恢复上次播放位置
- [ ] 队列自动切歌（当前播完自动播下一首）
- [ ] 睡眠定时器（设置/延长/取消/到期暂停）

#### 清单 2：下载验证

- [ ] 启动下载（进度从 0% 到 100%）
- [ ] 下载进度显示（EventBus 通知 UI 更新）
- [ ] 取消下载（停止任务 + 清理文件）
- [ ] 删除已下载文件（unlink + DB 清除）
- [ ] 文件移动（cacheDir → downloads 目录）
- [ ] 大文件下载（>5MB 正常完成）
- [ ] 并发下载（多个任务同时进行）
- [ ] 下载失败（错误日志 + UI 状态更新）
- [ ] 下载完成后可本地播放

#### 清单 3：Feed 管理验证

- [ ] 添加订阅（URL → 解析 → 存储）
- [ ] 刷新 Feed（HTTP 获取 → 增量合并）
- [ ] 取消订阅（删除 Feed + Items + Media）
- [ ] OPML 导入/导出
- [ ] 搜索 Feed（在线搜索 + 本地搜索）
- [ ] Feed 详情页（剧集列表 + 信息 + 设置）
- [ ] Feed 设置（跳过片头/片尾、自定义标题、自动下载）

#### 清单 4：UI 状态一致性

- [ ] MiniPlayer 显示/隐藏随播放状态切换
- [ ] Tab 栏在子页面中保持可见
- [ ] FullPlayer 打开时隐藏 Tab 栏和 MiniPlayer
- [ ] 播放状态实时同步（PlaybackController ↔ AppStorage ↔ UI）
- [ ] 下载进度实时同步（DownloadManager ↔ EventBus ↔ UI）
- [ ] 主题模式切换（如有实现）
- [ ] 页面返回后数据自动刷新

#### 清单 5：数据库完整性

- [ ] 7 表全部创建成功（含索引）
- [ ] Feed CRUD 操作
- [ ] FeedItem 含 JOIN 查询（FeedItem + FeedMedia + Feed）
- [ ] Queue 添加/移除/排序
- [ ] Favorites 添加/移除
- [ ] DownloadLog 记录
- [ ] Preferences 读写（UserPreferences/PlaybackPreferences/SleepTimerPreferences）
- [ ] ResultSet 不泄漏（所有 finally close）

---

## 附录：项目文件清单统计

| 目录 | 文件数 | 核心文件 |
|------|--------|---------|
| models/ | 9 | Feed, FeedItem, FeedMedia, Chapter, FeedPreferences, FeedFunding, DownloadResult, PodcastSearchResult, TranscriptEntry |
| database/ | 8 | PodDatabase + 7 DAOs |
| network/ | 5 | HttpClient, DownloadManager, FeedUpdateService, PodcastSearcher, DefaultFeedInitializer, NetworkUtils |
| parser/ | 8 | FeedParser, OpmlParser, DateParser, TranscriptParser + 4 Namespace |
| playback/ | 3 | PlaybackController, BackgroundPlaybackManager, SleepTimer |
| pages/ | 1 | Index |
| components/ | 28 | 6 大功能区 UI 组件 |
| viewmodels/ | 10 | Home, Queue, FeedDetail, AllEpisodes, Search, Statistics, Inbox, Downloads, PlaybackHistory, OnlineFeed, VideoPlayer, EpisodeDetail, Subscription |
| datasource/ | 2 | FeedItemDataSource, FeedDataSource |
| helpers/ | 8 | UserPreferences, PlaybackPreferences, SleepTimerPreferences, SyncCredentials, FileUtils, StringUtils, JsonUtils, PermissionHelper |
| workers/ | 2 | FeedUpdateWorker, FeedUpdateWorkAbility |
| common/ | 4 | GlobalState, AppRouter, EventBus, EventData, Constants |
| entryability/ | 1 | EntryAbility |
| **总计** | **~96** | |
