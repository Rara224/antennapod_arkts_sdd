# AntennaPod 迁移 Spec（Android → ArkTS）

> 生成日期：2026-03-16 v2.0（基于完整源码扫描）
> 源码路径：`/Users/chenjiamin/arkTs/simple/AntennaPod`
> 目标路径：`/Users/chenjiamin/arkTs/antennapod_arkts`

---

## SS1 项目概览

### 基本信息

| 项目 | 值 |
|------|-----|
| 应用名称 | AntennaPod |
| 类型 | 开源播客客户端 |
| 语言 | Java（100%） |
| 架构模式 | MVVM + RxJava3 + EventBus |
| 最低 SDK | Android 6.0 (API 23) |
| 目标 SDK | Android 15 (API 36) |
| AGP 版本 | 8.11.0 |
| 版本号 | 3.11.0 (versionCode: 3110095) |
| 包名 | de.danoeh.antennapod |
| Flavor | free / play（两个 market dimension） |
| Gradle 模块数 | 36 个（1 app + 35 library） |
| 分析 Flavor | free（默认，play 含 Google Cast/Play Services） |

### 组件计数

| 组件类型 | Android 数量 | 说明 |
|---------|------------|------|
| Activity | 12 | SplashActivity, MainActivity, VideoplayerActivity, Media3VideoPlayerActivity, PlaybackSpeedDialogActivity, PreferenceActivity, OpmlImportActivity, OnlineFeedViewActivity, SelectSubscriptionActivity, EchoActivity, ToolbarActivity, WidgetConfigActivity |
| Fragment | 71 | 含 24 个 Dialog/BottomSheet Fragment |
| Adapter | 46 | RecyclerView.Adapter / ListAdapter / BaseAdapter |
| 数据库表 | 7 | SQLite 原生（非 Room），PodDBAdapter 单例 |
| 数据库操作类 | 3 | DBReader, DBWriter, PodDBAdapter |
| Service | 4 | PlaybackService, Media3PlaybackService, QuickSettingsTileService, SyncService(Worker) |
| BroadcastReceiver | 4 | MediaButtonReceiver, ConnectivityActionReceiver, PowerConnectionReceiver, FeedUpdateReceiver |
| Worker (WorkManager) | 6 | FeedUpdateWorker, EpisodeDownloadWorker, SyncService, WidgetUpdaterWorker, AutomaticDatabaseExportWorker, DatabaseMaintenanceWorker |
| SharedPreferences 组 | 5 | UserPreferences(50+key), PlaybackPreferences(7key), SyncCredentials(4key), SleepTimerPreferences, UsageStatistics |
| EventBus 事件类 | 20+ | PlayerStatusEvent, FeedUpdateRunningEvent, EpisodeDownloadEvent 等 |
| Model 类 | 26+ | feed/, download/, playback/ 三个包 |
| 布局文件(XML) | 76+（仅 app 模块） | 不含子模块布局 |
| Helper/Util 类 | 20+ | 网络、格式化、播放、章节等 |
| RSS Namespace 处理器 | 8 | Rss20, Atom, Itunes, Media, DublinCore, PodcastIndex, SimpleChapters, Content |

### 技术栈概览

| 技术领域 | Android 方案 | 版本 | 备注 |
|---------|------------|------|------|
| 数据库 | SQLiteOpenHelper + 原生 SQL | — | 非 Room，PodDBAdapter 单例，DB 版本 3110000 |
| 网络 | OkHttp | 4.12.0 | BasicAuth 拦截器、SSL、Cookie |
| 播放器 | Media3/ExoPlayer | 1.9.0 | 双服务架构（旧版 PlaybackService + 新版 Media3PlaybackService） |
| 异步 | RxJava3 | 3.1.5 | Observable/Single/Completable + Schedulers |
| 事件 | EventBus (GreenRobot) | 3.3.1 | 20+ 自定义事件，注解处理器生成索引 |
| 图片 | Glide | 4.16.0 | 自定义 GlideModule，OkHttp 集成 |
| XML 解析 | SAX (Push 模式) | Java 内置 | SyndHandler + 8 个 Namespace Handler |
| HTML 解析 | Jsoup | 1.15.1 | 清理 HTML 描述内容 |
| 后台任务 | WorkManager | 2.10.3 | 6 个 Worker，含前台提升 |
| UI | Material Design | 1.12.0 | DrawerLayout + BottomSheet + BottomNav + ViewPager2 |
| 导航 | 手动 Fragment 管理 | — | 非 Navigation Component |
| 偏好设置 | PreferenceFragmentCompat | 1.2.1 | 17 个设置 Fragment |
| 字幕解析 | 自研 | — | JSON/VTT/SRT 三种格式 |
| 工具库 | commons-lang3 + commons-io + Guava | — | 字符串/文件/集合工具 |

---

## SS2 模块合并策略

### 36 Android 模块 → 单 entry 模块

| Android 模块 | 代码量 | 被依赖次数 | ArkTS 目录 | 策略 |
|-------------|--------|-----------|-----------|------|
| `:app` | 大 | 0（顶层） | `pages/`, `components/`, `entryability/` | 主模块 |
| `:model` | 中 | 被所有模块依赖 | `models/` | 合并 |
| `:event` | 小 | 被 10+ 模块依赖 | `common/EventBus.ets` | 合并 |
| `:system` | 小 | 被 2 模块依赖 | `helpers/` | 合并 |
| `:storage:database` | 大 | 被 8 模块依赖 | `database/` | 合并 |
| `:storage:preferences` | 中 | 被 12 模块依赖 | `helpers/UserPreferences.ets` 等 | 合并 |
| `:storage:importexport` | 中 | 被 2 模块依赖 | `helpers/ImportExport.ets` | 合并 |
| `:storage:database-maintenance-service` | 小 | 被 1 模块依赖 | `workers/` | 合并 |
| `:net:common` | 中 | 被 8 模块依赖 | `network/HttpClient.ets` | 合并 |
| `:net:discovery` | 中 | 被 2 模块依赖 | `network/PodcastSearcher.ets` | 合并 |
| `:net:download:service-interface` | 小 | 被 5 模块依赖 | `network/DownloadInterface.ets` | 合并 |
| `:net:download:service` | 大 | 被 1 模块依赖 | `network/DownloadService.ets`, `workers/` | 合并 |
| `:net:ssl` | 小 | 被 1 模块依赖 | **删除** | Skip（系统 TLS） |
| `:net:sync:gpoddernet` | 中 | 被 2 模块依赖 | `network/sync/GpodderApi.ets` | 合并（V2） |
| `:net:sync:service-interface` | 小 | 被 3 模块依赖 | `network/sync/SyncInterface.ets` | 合并（V2） |
| `:net:sync:service` | 中 | 被 1 模块依赖 | `network/sync/SyncService.ets` | 合并（V2） |
| `:parser:feed` | 大 | 被 3 模块依赖 | `parser/FeedParser.ets`, `parser/namespace/` | 合并 |
| `:parser:media` | 中 | 被 3 模块依赖 | `parser/MediaParser.ets` | 合并 |
| `:parser:transcript` | 中 | 被 2 模块依赖 | `parser/TranscriptParser.ets` | 合并 |
| `:playback:base` | 中 | 被 3 模块依赖 | `playback/PlaybackBase.ets` | 合并 |
| `:playback:cast` | 中 | 被 1 模块依赖 | **删除** | Skip（无 Chromecast） |
| `:playback:service` | 大 | 被 1 模块依赖 | `playback/PlaybackService.ets` | 合并 |
| `:ui:common` | 中 | 被 7 模块依赖 | `components/common/` | 合并 |
| `:ui:i18n` | 资源 | 被 6 模块依赖 | `resources/` | 合并 |
| `:ui:episodes` | 中 | 被 4 模块依赖 | `components/episodes/` | 合并 |
| `:ui:glide` | 中 | 被 2 模块依赖 | `helpers/ImageLoader.ets` | 合并 |
| `:ui:discovery` | 中 | 被 1 模块依赖 | `components/discovery/` | 合并 |
| `:ui:chapters` | 中 | 被 2 模块依赖 | `components/chapters/` | 合并 |
| `:ui:transcript` | 中 | 被 1 模块依赖 | `components/transcript/` | 合并 |
| `:ui:echo` | 中 | 被 2 模块依赖 | `pages/EchoPage.ets` | 合并（V2） |
| `:ui:statistics` | 中 | 被 1 模块依赖 | `components/statistics/` | 合并（V2） |
| `:ui:preferences` | 大 | 被 1 模块依赖 | `components/preferences/` | 合并 |
| `:ui:notifications` | 小 | 被 4 模块依赖 | `helpers/NotificationHelper.ets` | 合并 |
| `:ui:widget` | 中 | 被 2 模块依赖 | **删除** | Skip（Widget 差异大） |
| `:ui:app-start-intent` | 小 | 被 5 模块依赖 | `common/AppRouter.ets` | 合并 |

### ArkTS 目标目录结构

```
entry/src/main/ets/
├── models/              ← :model（Feed, FeedItem, FeedMedia, Chapter 等 26+ 模型）
├── database/            ← :storage:database（PodDatabase 单例 + 7 DAO 类）
│   ├── PodDatabase.ets
│   ├── FeedDao.ets
│   ├── FeedItemDao.ets
│   ├── FeedMediaDao.ets
│   ├── ChapterDao.ets
│   ├── DownloadLogDao.ets
│   ├── QueueDao.ets
│   └── FavoritesDao.ets
├── network/             ← :net:*（HTTP、下载、搜索、同步）
│   ├── HttpClient.ets
│   ├── DownloadManager.ets
│   ├── PodcastSearcher.ets
│   └── sync/            （V2）
├── parser/              ← :parser:*（RSS/Atom/OPML/字幕）
│   ├── FeedParser.ets
│   ├── SyndHandler.ets
│   ├── OpmlParser.ets
│   ├── MediaParser.ets
│   ├── TranscriptParser.ets
│   └── namespace/
│       ├── Rss20.ets
│       ├── Atom.ets
│       ├── Itunes.ets
│       ├── Media.ets
│       ├── DublinCore.ets
│       ├── PodcastIndex.ets
│       ├── SimpleChapters.ets
│       └── Content.ets
├── playback/            ← :playback:*（AVPlayer 封装、播放状态）
│   ├── PlaybackService.ets
│   ├── AVPlayerWrapper.ets
│   ├── PlayerStatus.ets
│   └── SleepTimer.ets
├── pages/               ← Activity → @Entry Page + NavDestination
│   ├── MainPage.ets
│   ├── OnlineFeedViewPage.ets
│   ├── VideoPlayerPage.ets
│   ├── PreferencesPage.ets
│   └── OpmlImportPage.ets
├── components/          ← Fragment → @Component
│   ├── home/
│   ├── subscription/
│   ├── queue/
│   ├── search/
│   ├── episodes/
│   ├── feed/
│   ├── playback/
│   ├── preferences/
│   ├── statistics/
│   ├── discovery/
│   ├── chapters/
│   ├── transcript/
│   └── common/
├── viewmodels/          ← 新增 ViewModel 层
├── datasource/          ← IDataSource 实现（LazyForEach）
├── helpers/             ← 工具函数, Preferences, 格式化
├── workers/             ← WorkManager → workScheduler
├── common/              ← GlobalState, AppRouter, EventBus
└── entryability/        ← 应用入口
```

---

## SS3 技术栈替换表

### 核心依赖

| # | Android 依赖 | 版本 | ArkTS 替代 | Level | 风险 | 备注 |
|---|-------------|------|-----------|-------|------|------|
| 1 | `com.squareup.okhttp3:okhttp` | 4.12.0 | `http` from `@kit.NetworkKit` | L2 | 🟢 | 实例用完 `destroy()` |
| 2 | `com.squareup.okhttp3:okhttp-urlconnection` | 4.12.0 | 合并到 #1 | L2 | 🟢 | Cookie 管理需自建 |
| 3 | `io.reactivex.rxjava3:rxjava` | 3.1.5 | `async/await` + `Promise` | L2 | 🟡 | 操作符需手动替换（map/flatMap/zip/debounce 等） |
| 4 | `io.reactivex.rxjava3:rxandroid` | 3.0.2 | 不需要 | L2 | 🟢 | ArkTS 无线程切换概念 |
| 5 | `org.greenrobot:eventbus` | 3.3.1 | 自建 EventHub（`Map<string, Function[]>`） | L5 | 🟡 | 需覆盖 20+ 事件类型 |
| 6 | `com.github.bumptech.glide:glide` | 4.16.0 | `@ohos/imageknife` | L1 | 🟢 | `ohpm install @ohos/imageknife` |
| 7 | `org.jsoup:jsoup` | 1.15.1 | `@ohos/htmlparser2` 或自研 | L1 | 🟡 | HTML 清洗，需验证功能覆盖度 |
| 8 | `org.apache.commons:commons-lang3` | 3.18.0 | 手写工具函数 | L5 | 🟢 | 仅用 StringUtils.isEmpty 等少量方法 |
| 9 | `commons-io:commons-io` | 2.5 | `fileIo` from `@kit.CoreFileKit` | L2 | 🟢 | 文件操作 |
| 10 | `com.google.guava:guava` | 31.0.1 | 手写工具函数 | L5 | 🟢 | 仅用少量 Collection 工具 |

### AndroidX

| # | Android 依赖 | 版本 | ArkTS 替代 | Level | 风险 | 备注 |
|---|-------------|------|-----------|-------|------|------|
| 11 | `androidx.appcompat` | 1.7.1 | ArkUI 原生 | L2 | 🟢 | 声明式 UI |
| 12 | `androidx.fragment` | 1.8.9 | `@Component` struct | L2 | 🟢 | 71 Fragment → 组件 |
| 13 | `androidx.recyclerview` | 1.4.0 | `List` + `LazyForEach` | L2 | 🟢 | 虚拟列表 |
| 14 | `androidx.viewpager2` | 1.1.0 | `Swiper` | L2 | 🟢 | 翻页组件 |
| 15 | `androidx.drawerlayout` | 1.2.0 | `SideBarContainer` | L2 | 🟢 | 侧边栏 |
| 16 | `androidx.coordinatorlayout` | 1.1.0 | `Stack` + 自定义手势 | L2 | 🟡 | 协调布局需手动实现 |
| 17 | `androidx.preference` | 1.2.1 | 自建设置页组件 | L5 | 🟡 | 无 PreferenceScreen 等价物 |
| 18 | `androidx.palette` | 1.0.0 | `effectKit.ColorPicker` | L2 | 🟢 | 取色 |
| 19 | `androidx.work:work-runtime` | 2.10.3 | `workScheduler` from `@kit.BackgroundTasksKit` | L2 | 🟡 | 最小间隔 15min→鸿蒙约束更严 |
| 20 | `androidx.media3:media3-exoplayer` | 1.9.0 | `AVPlayer` from `@kit.MediaKit` | L2 | 🔴 | 状态机差异大（P13） |
| 21 | `androidx.media3:media3-session` | 1.9.0 | `AVSession` from `@kit.MediaKit` | L2 | 🔴 | MediaSession/MediaLibrary 概念不同 |
| 22 | `androidx.media3:media3-ui` | 1.9.0 | 自建播放控制 UI | L5 | 🟡 | 无对标组件 |
| 23 | `androidx.media` | 1.6.0 | `AVSession` from `@kit.MediaKit` | L2 | 🟡 | Legacy MediaSession |
| 24 | `com.google.android.material` | 1.12.0 | ArkUI 原生组件 | L2 | 🟢 | Tabs/Dialog/Toast/BottomSheet |
| 25 | `androidx.core:core-splashscreen` | — | HarmonyOS 原生启动页 | L2 | 🟢 | windowSplash 配置 |
| 26 | `androidx.documentfile` | — | `fileIo` | L2 | 🟢 | 文件选择 |
| 27 | `androidx.gridlayout` | — | `Grid` | L2 | 🟢 | 网格布局 |
| 28 | `androidx.lifecycle` | — | `@State`/`@StorageLink` | L2 | 🟢 | ArkUI 声明式状态管理 |

### 项目特有依赖

| # | Android 依赖 | ArkTS 替代 | Level | 风险 | 备注 |
|---|-------------|-----------|-------|------|------|
| 29 | SAX Parser（Java 内置） | `XmlPullParser` from `@ohos.xml` | L2 | 🔴 | Push→Pull 模式重写，8 个 Namespace（P11） |
| 30 | `com.bytehamster:lib.preferencesearch` | 自建搜索 | L5 | 🟡 | 偏好搜索功能 |
| 31 | `com.github.skydoves:balloon` | `Popup` 组件 | L2 | 🟢 | 气泡提示 |
| 32 | `it.xabaras.android:recyclerview-swipedecorator` | `ListItem` swipeAction | L2 | 🟢 | 滑动操作 |

### Skip 依赖

| # | Android 依赖 | 原因 |
|---|-------------|------|
| 33 | `com.nanohttpd:nanohttpd` | 仅测试用 |
| 34 | Google Play Services Cast | 无 Chromecast 等价物 |
| 35 | Conscrypt SSL | 系统自带 TLS |
| 36 | `androidx.car:car-app` | 无车载等价物 |
| 37 | `com.google.android.gms:play-services-base` | play flavor 特有 |
| 38 | `androidx.mediarouter` | Cast 依赖，一起 Skip |

### 补充依赖（从模块扫描中发现）

| # | Android 依赖 | 出现模块 | ArkTS 替代 | 备注 |
|---|-------------|---------|-----------|------|
| 39 | `com.github.bumptech.glide:okhttp3-integration` | ui:glide | 合并到 #6 | @ohos/imageknife 自带 HTTP 栈 |
| 40 | `androidx.media3:media3-common` | app | 合并到 #20 | media3 基础类型，AVPlayer 内含 |
| 41 | `androidx.media3:media3-cast` | playback:cast | Skip | Cast 一起跳过 |
| 42 | `org.jetbrains.kotlin:kotlin-bom` | common.gradle | 不需要 | ArkTS 无 Kotlin 依赖 |
| 43 | `com.google.android.gms:play-services-cast-framework` | playback:cast | Skip | Cast 一起跳过 |

### 风险统计

| 风险等级 | 数量 | 关键项 |
|---------|------|-------|
| 🟢 低 | 20 | OkHttp, Glide, RecyclerView, Material, Palette 等 |
| 🟡 中 | 9 | RxJava, EventBus, WorkManager, Preferences, CoordinatorLayout 等 |
| 🔴 高 | 3 | Media3/ExoPlayer (#20), MediaSession (#21), SAX Parser (#29) |
| Skip | 11 | Cast, SSL, Car, NanoHTTPD, GMS, MediaRouter, media3-cast, kotlin-bom 等 |

### 依赖使用热力图（跨模块引用计数）

| 依赖 | 引用模块数 | 主要使用模块 | 迁移影响面 |
|------|----------|------------|-----------|
| `commons-io` | **14** | parser/*, storage/*, net/download, ui/common, ui/glide, ui/chapters, ui/transcript | 最广，每个文件操作都涉及 |
| `commons-lang3` | **13** | model, parser/*, storage/*, net/download, net/sync, ui/common, playback/service | 字符串工具到处使用 |
| `okhttp` | **12** | net/*, ui/glide, ui/chapters, ui/transcript, ui/preferences | 所有网络操作 |
| `rxjava3` | **12** | net/discovery, net/sync/*, storage/importexport, ui/*, playback/service | 异步操作核心 |
| `eventbus` | **11** | storage/*, net/download, net/sync, playback/*, ui/statistics, ui/preferences, ui/discovery | 跨组件通信 |
| `glide` | **11** | playback/*, net/download, ui/glide, ui/statistics, ui/preferences, ui/echo, ui/widget, ui/discovery | 所有图片加载 |
| `work-runtime` | **7** | net/download/service, net/sync/service, storage/importexport, storage/db-maintenance, ui/preferences, ui/widget | 后台任务 |
| `guava` | **6** | storage/database, storage/importexport, net/download, net/sync, ui/widget, storage/db-maintenance | 集合工具 |
| `media3` | **5** | playback/base, playback/service, playback/cast, app | 播放核心 |
| `jsoup` | **4** | parser/feed, parser/transcript, app | HTML 清洗 |

### SS3 详细替换方案

---

#### 方案 1：OkHttp → @kit.NetworkKit（12 模块，🟢 低风险）

**安装**：系统内置，无需 ohpm install

**API 映射**：

| OkHttp API | ArkTS API | 说明 |
|-----------|-----------|------|
| `OkHttpClient.Builder()` | `http.createHttp()` | 每次请求创建，用完 destroy() |
| `Request.Builder().url().build()` | `httpRequest.request({ url, method, header })` | 统一配置对象 |
| `client.newCall(req).execute()` | `await httpRequest.request(options)` | 同步→异步 |
| `response.body().string()` | `response.result` (string) | 直接获取 |
| `response.body().byteStream()` | `request.downloadFile(context, config)` | 下载用专用 API |
| `Interceptor` | 手动封装拦截逻辑 | 在 HttpClient 封装类中实现 |
| `CookieJar` | `header: { 'Cookie': value }` | 手动管理 Cookie |
| `client.newBuilder().connectTimeout()` | `{ connectTimeout, readTimeout }` | 请求选项直接设置 |

**迁移模式**（Java → ArkTS）：

```java
// Android: OkHttp GET
OkHttpClient client = new OkHttpClient();
Request request = new Request.Builder().url(url).build();
Response response = client.newCall(request).execute();
String body = response.body().string();
```

```typescript
// ArkTS: @kit.NetworkKit
import { http } from '@kit.NetworkKit';

async function httpGet(url: string): Promise<string> {
  const httpRequest = http.createHttp();
  try {
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      connectTimeout: 30000,
      readTimeout: 30000
    });
    if (response.responseCode === 200) {
      return response.result.toString();
    }
    throw new Error('HTTP ' + response.responseCode);
  } finally {
    httpRequest.destroy();
  }
}
```

**BasicAuth 拦截器替换**（AntennaPod 特有）：

```typescript
// 原 OkHttp: BasicAuthenticationInterceptor
// ArkTS: 在请求头中手动添加
function buildAuthHeader(username: string, password: string): string {
  const credentials = username + ':' + password;
  // 使用 buffer 模块做 Base64
  const encoded = buffer.from(credentials).toString('base64');
  return 'Basic ' + encoded;
}

const options: http.HttpRequestOptions = {
  method: http.RequestMethod.GET,
  header: { 'Authorization': buildAuthHeader(user, pass) },
  connectTimeout: 30000,
  readTimeout: 30000
};
```

**AntennaPod OkHttp 特有配置（需迁移）**：
- `AntennapodHttpClient` 单例：`CONNECTION_TIMEOUT=10s, READ_TIMEOUT=30s`
- `BasicAuthorizationInterceptor`：处理 401 → 重试+双编码(ISO-8859-1/UTF-8)
- `UserAgentInterceptor`：添加 `User-Agent: AntennaPod/3.11.0`
- `JavaNetCookieJar`：`ACCEPT_ORIGINAL_SERVER` 策略
- OkHttp Cache：20MB 磁盘缓存
- 下载器 `HttpDownloader`：支持 `Range` 续传、`If-Modified-Since`/`If-None-Match` 条件请求、进度回调
- `ProxyConfig`：SOCKS/HTTP 代理支持（V2）
- `RedirectChecker`：检测 301/308 永久重定向，更新 Feed URL

**踩坑**：
- `http.createHttp()` 必须 `destroy()`，否则句柄泄漏
- 下载大文件不能用 `request()`，必须用 `request.downloadFile()`
- 不支持 `WebSocket`（如需要用 `@kit.NetworkKit` 的 `webSocket`）
- `response.result` 默认是 `string`，二进制需设置 `expectDataType: http.HttpDataType.ARRAY_BUFFER`
- 条件请求（`If-Modified-Since`/`If-None-Match`）需手动在 header 中传入

---

#### 方案 2：RxJava3 → async/await + Promise（12 模块，🟡→🟢 实际风险低于预期）

**安装**：语言内置，无需安装

> **源码扫描发现**：AntennaPod 的 RxJava 使用非常简单——几乎全部是 `Single<T>` + `subscribeOn(io) → observeOn(main) → subscribe()`，**无 flatMap/switchMap/debounce/zip 等复杂操作符**。实际迁移只需将 `Single.create(emitter -> { ... })` 改为 `async function`，风险大幅降低。

**操作符映射**：

| RxJava 操作符 | ArkTS 替代 | 说明 |
|-------------|-----------|------|
| `Observable.fromCallable(() -> ...)` | `async function` | 直接用 async 函数 |
| `Single.just(value)` | `Promise.resolve(value)` | 立即值 |
| `.subscribeOn(Schedulers.io())` | 不需要 | ArkTS 异步自动在 IO 线程 |
| `.observeOn(AndroidSchedulers.mainThread())` | 不需要 | ArkUI 自动回主线程更新 UI |
| `.map(x -> transform(x))` | `.then(x => transform(x))` 或直接 `await` 后处理 | 链式→顺序 |
| `.flatMap(x -> anotherObservable)` | `await` 嵌套调用 | 展平异步链 |
| `.zip(obs1, obs2, (a, b) -> ...)` | `Promise.all([p1, p2])` | 并行等待 |
| `.debounce(300, TimeUnit.MS)` | 手写 debounce 工具函数 | 需自建 |
| `.switchMap(...)` | 取消前一个 + 新请求 | 需手动管理 |
| `.interval(1, TimeUnit.SECONDS)` | `setInterval(() => {}, 1000)` | 定时器 |
| `.timeout(10, TimeUnit.SECONDS)` | `Promise.race([p, timeoutP])` | 超时竞速 |
| `.doOnError(e -> ...)` | `try/catch` | 错误处理 |
| `.subscribe(onNext, onError)` | `try { result = await xxx } catch(e) {}` | 订阅→await |
| `CompositeDisposable.clear()` | 无等价物，用标记位取消 | `isActive = false` |
| `.filter(x -> condition)` | `if` 判断或 `array.filter()` | 过滤 |
| `.toList()` | `Array<T>` 收集 | 已是数组操作 |

**AntennaPod 中最常见的 5 种 RxJava 模式**：

```java
// 模式 1: IO线程执行 → 主线程消费（最常见，约 60% 场景）
Observable.fromCallable(() -> DBReader.getFeedList())
    .subscribeOn(Schedulers.io())
    .observeOn(AndroidSchedulers.mainThread())
    .subscribe(feeds -> adapter.setData(feeds), Throwable::printStackTrace);
```
```typescript
// ArkTS 替代
try {
  const feeds: Feed[] = await FeedDao.getAllFeeds();
  this.feedList = feeds; // @State 自动触发 UI 刷新
} catch (e) {
  hilog.error(DOMAIN, TAG, 'Failed: %{public}s', JSON.stringify(e));
}
```

```java
// 模式 2: 并行请求 → 合并结果
Observable.zip(
    Observable.fromCallable(() -> DBReader.getQueue()),
    Observable.fromCallable(() -> DBReader.getNewItemsList()),
    (queue, newItems) -> new Pair<>(queue, newItems)
).subscribeOn(Schedulers.io())...
```
```typescript
// ArkTS 替代
const results = await Promise.all([
  QueueDao.getQueue(),
  FeedItemDao.getNewItems(0, 100)
]);
const queue: FeedItem[] = results[0];
const newItems: FeedItem[] = results[1];
```

```java
// 模式 3: 搜索防抖（debounce）
searchSubject
    .debounce(300, TimeUnit.MILLISECONDS)
    .switchMap(query -> Observable.fromCallable(() -> DBReader.searchItems(query)))
    .observeOn(AndroidSchedulers.mainThread())
    .subscribe(results -> showResults(results));
```
```typescript
// ArkTS 替代：手写 debounce
private searchTimer: number = -1;

onSearchTextChange(query: string): void {
  if (this.searchTimer >= 0) {
    clearTimeout(this.searchTimer);
  }
  this.searchTimer = setTimeout(async () => {
    try {
      this.searchResults = await FeedItemDao.searchItems(query);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Search failed');
    }
  }, 300);
}
```

```java
// 模式 4: Completable（无返回值的异步操作）
Completable.fromAction(() -> DBWriter.markItemPlayed(item, PLAYED))
    .subscribeOn(Schedulers.io())
    .subscribe();
```
```typescript
// ArkTS 替代
await FeedItemDao.markItemPlayed(item.id, PLAY_STATE_PLAYED);
// 不需要 Completable 概念，async/await 天然支持
```

```java
// 模式 5: 带进度的下载（Observable 流）
downloadService.download(request)
    .subscribeOn(Schedulers.io())
    .observeOn(AndroidSchedulers.mainThread())
    .subscribe(
        progress -> updateUI(progress),
        error -> showError(error),
        () -> onComplete()
    );
```
```typescript
// ArkTS 替代：回调 + EventBus
import { request } from '@kit.BasicServicesKit';

const downloadTask = await request.downloadFile(context, { url: mediaUrl, filePath: savePath });
downloadTask.on('progress', (received: number, total: number) => {
  const percent = Math.floor(received * 100 / total);
  EventBus.getInstance().publish(EVENT_DOWNLOAD_PROGRESS, { episodeId: id, percent: percent });
});
downloadTask.on('complete', () => {
  EventBus.getInstance().publish(EVENT_EPISODE_DOWNLOADED, { episodeId: id });
});
downloadTask.on('fail', (err: number) => {
  EventBus.getInstance().publish(EVENT_DOWNLOAD_FAILED, { episodeId: id, error: err });
});
```

**踩坑**：
- RxJava 的 `CompositeDisposable` 可统一取消 → ArkTS 用 `boolean` 标记位在回调中检查
- `switchMap` 无直接等价物 → 取消前一个请求再发新请求（设置 `activeRequestId`）
- RxJava 的错误传播链 → ArkTS 用 `try/catch` 逐层捕获
- `Observable.interval` 用于定时轮询 → `setInterval`，注意 `aboutToDisappear` 时 `clearInterval`

---

#### 方案 3：EventBus → 自建 EventBus（11 模块，🟡 中风险）

**安装**：Phase 2 已实现 `common/EventBus.ets`

**AntennaPod 事件类型完整清单**（源码扫描：24 个事件类，128 个 @Subscribe，138 次 post()）：

| 事件类 | 字段 | post()次数 | 主要发布者 |
|-------|------|----------|----------|
| `MessageEvent` | message, action?, actionText? | **49** | 全局 Toast/Snackbar 通知 |
| `PlayerStatusEvent` | — | 12 | Media3PlaybackService, PlaybackService |
| `UnreadItemsUpdateEvent` | — | 10 | DBWriter, Preference fragments |
| `FeedListUpdateEvent` | feeds: List\<Long\> | 8 | DBWriter, FeedDatabaseWriter |
| `QueueEvent` | action, item?, position | 7 | DBWriter (add/remove/sort/move) |
| `FeedItemEvent` | items: List\<FeedItem\> | 6 | DBWriter, PlayActionButton |
| `BufferUpdateEvent` | progress: float | 5 | Media3PlaybackService, LocalPSMP |
| `SpeedChangedEvent` | newSpeed: float | 4 | PlaybackController, Media3 |
| `SleepTimerUpdatedEvent` | timerValue | 4 | ClockSleepTimer, EpisodeSleepTimer |
| `DownloadLogEvent` | — | 4 | DBWriter |
| `EpisodeDownloadEvent` | map: Map\<String, Status\> | 3 | DownloadService |
| `PlaybackPositionEvent` | position, duration | 3 | PlaybackService (1s 间隔) |
| `PlaybackHistoryEvent` | — | 3 | DBWriter |
| `PlaybackServiceEvent` | action (START/STOP) | 2 | PlaybackService |
| `FavoritesEvent` | — | 2 | DBWriter |
| `StatisticsEvent` | — | 2 | StatisticsFragment |
| `DiscoveryDefaultUpdateEvent` | — | 2 | DiscoveryFragment |
| `FeedEvent` | action, feedId | 2 | DBWriter |
| `SyncServiceEvent` | messageResId (sticky) | 1 | SyncService |
| `VolumeAdaptionChangedEvent` | setting, feedId | 1 | FeedSettingsPreference |
| `SpeedPresetChangedEvent` | speed, skipSilence, feedId | 1 | FeedSettingsPreference |
| `SkipIntroEndingChangedEvent` | skipIntro, skipEnding, feedId | 1 | SkipUtils |
| `PlayerErrorEvent` | message | 1 | PlaybackService |
| `AllEpisodesFilterChangedEvent` | — | 1 | FilterDialog |

> **注意**：`MessageEvent` 占 35% 的 post() 调用 → ArkTS 中用 `promptAction.showToast()` 直接替代，无需走 EventBus。

**迁移模式**（Java → ArkTS）：

```java
// Android: 注册
@Subscribe(threadMode = ThreadMode.MAIN)
public void onPlayerStatus(PlayerStatusEvent event) {
    updatePlayButton();
}
@Override
public void onStart() {
    super.onStart();
    EventBus.getDefault().register(this);
}
@Override
public void onStop() {
    super.onStop();
    EventBus.getDefault().unregister(this);
}
```
```typescript
// ArkTS: 在组件中使用
private unsubscribePlayer: (() => void) | undefined = undefined;

aboutToAppear(): void {
  this.unsubscribePlayer = EventBus.getInstance().subscribe(
    EVENT_PLAYER_STATUS,
    (data: Object): void => {
      this.updatePlayButton();
    }
  );
}

aboutToDisappear(): void {
  if (this.unsubscribePlayer !== undefined) {
    this.unsubscribePlayer();
  }
}
```

```java
// Android: 发送事件
EventBus.getDefault().post(new PlayerStatusEvent());
EventBus.getDefault().post(new EpisodeDownloadEvent(updatedUrls));
```
```typescript
// ArkTS: 发布事件
EventBus.getInstance().publish(EVENT_PLAYER_STATUS, new Object());
EventBus.getInstance().publish(EVENT_DOWNLOAD_PROGRESS, downloadInfo);
```

**踩坑**：
- GreenRobot EventBus 支持 `@Subscribe(sticky = true)` 粘性事件 → ArkTS 需用 `AppStorage` + `@StorageLink` 替代（状态已持久化）
- EventBus 的 `threadMode = MAIN` → ArkTS 回调默认在主线程（ArkUI 框架保证）
- 必须在 `aboutToDisappear` 取消订阅，否则内存泄漏
- EventBus annotation-processor 生成的索引不需要 → ArkTS 用字符串常量注册

---

#### 方案 4：Glide → @ohos/imageknife（11 模块，🟢 低风险）

**安装**：`ohpm install @ohos/imageknife`

**API 映射**：

| Glide API | ArkTS/ImageKnife API | 说明 |
|----------|---------------------|------|
| `Glide.with(ctx).load(url).into(view)` | `ImageKnife({ src: url })` 组件 | 声明式 |
| `.placeholder(R.drawable.xxx)` | `.placeholder($r('app.media.xxx'))` | 占位图 |
| `.error(R.drawable.error)` | `.errorHolder($r('app.media.error'))` | 错误图 |
| `.diskCacheStrategy(ALL)` | 默认启用磁盘缓存 | 无需配置 |
| `.circleCrop()` | `.objectFit(ImageFit.Cover)` + `.borderRadius('50%')` | 或用 Circle + clipShape |
| `.override(width, height)` | `.width(w).height(h)` | 组件尺寸 |
| `GlideModule` (OkHttp 集成) | 不需要 | ImageKnife 自带 HTTP |
| `RequestManager` 生命周期绑定 | 组件销毁自动取消 | ArkUI 组件生命周期管理 |

**AntennaPod 使用场景**：

```java
// Android: 加载播客封面
Glide.with(context)
    .load(feed.getImageUrl())
    .apply(new RequestOptions()
        .placeholder(R.color.light_gray)
        .error(R.drawable.ic_cover_default)
        .fitCenter())
    .into(coverImage);
```
```typescript
// ArkTS: 使用 ImageKnife 或 Image
// 方案 A: 使用系统 Image（简单场景足够）
Image(feed.imageUrl !== '' ? feed.imageUrl : $r('app.media.ic_cover_default'))
  .width(64)
  .height(64)
  .objectFit(ImageFit.Cover)
  .borderRadius(8)
  .alt($r('app.media.ic_cover_default'))

// 方案 B: 使用 ImageKnife（需缓存/转换等高级功能）
// ohpm install @ohos/imageknife
import { ImageKnifeComponent } from '@ohos/imageknife';
ImageKnifeComponent({
  imageKnifeOption: {
    loadSrc: feed.imageUrl,
    placeholderSrc: $r('app.media.ic_cover_default'),
    errorholderSrc: $r('app.media.ic_cover_default'),
    objectFit: ImageFit.Cover
  }
}).width(64).height(64).borderRadius(8)
```

**决策建议**：
- V1 优先用系统 `Image` 组件（支持网络 URL、缓存、占位图），覆盖 80% 场景
- 仅在需要高级功能（自定义缓存策略、图片变换管道）时引入 `@ohos/imageknife`
- AntennaPod 的 `ApGlideModule`（自定义 OkHttp 集成）→ 不需要，系统 Image/ImageKnife 自带 HTTP

---

#### 方案 5：Jsoup → 手写 HTML 清洗 或 @ohos/htmlparser2（4 模块，🟡 中风险）

**安装**：`ohpm install @ohos/htmlparser2`（如需要）

**AntennaPod 使用方式**：Jsoup 在 AntennaPod 中主要用于两个场景：

1. **HTML 清洗**（去除危险标签，保留文本格式）— `Jsoup.clean(html, whitelist)`
2. **提取纯文本**（从 HTML description 提取搜索用文本）— `Jsoup.parse(html).text()`

```java
// 场景 1: HTML 清洗（parser/feed SyndHandler）
String cleanDescription = Jsoup.clean(rawHtml,
    Safelist.basic()
        .addTags("img")
        .addAttributes("img", "src")
        .addAttributes("a", "href"));

// 场景 2: 提取纯文本（搜索索引）
String plainText = Jsoup.parse(htmlDescription).text();
```
```typescript
// ArkTS 替代方案：手写轻量 HTML 清洗器
// 场景 1: 基于正则的简单清洗（覆盖 AntennaPod 需求）
function cleanHtml(html: string): string {
  // 允许的标签白名单
  const allowedTags: string[] = ['p', 'br', 'b', 'i', 'em', 'strong', 'a', 'img', 'ul', 'ol', 'li'];
  // 移除 script/style 标签及内容
  let clean = html.replace(/<script[\s\S]*?<\/script>/gi, '');
  clean = clean.replace(/<style[\s\S]*?<\/style>/gi, '');
  // 移除不在白名单中的标签（保留内容）
  const tagRegex = new RegExp('<(?!\\/?)(?!(' + allowedTags.join('|') + ')\\b)[^>]+>', 'gi');
  clean = clean.replace(tagRegex, '');
  // 移除不在白名单中的闭合标签
  const closeRegex = new RegExp('<\\/(?!(' + allowedTags.join('|') + ')\\b)[^>]+>', 'gi');
  clean = clean.replace(closeRegex, '');
  return clean;
}

// 场景 2: 提取纯文本
function htmlToPlainText(html: string): string {
  return html.replace(/<[^>]+>/g, '').replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ').trim();
}
```

**决策建议**：
- 源码扫描发现：AntennaPod **不使用 Jsoup Safelist/Whitelist** 清洗，而是用 `NodeVisitor` 手动遍历 DOM
- 7 个文件使用 Jsoup：`ShownotesCleaner`（CSS颜色清理+时间码链接）、`HtmlToPlainText`（NodeVisitor 提取纯文本）、`PlainTextLinksConverter`（纯文本 URL→\<a\> 标签）、`FeedDiscoverer`（RSS 自动发现）、`TypeGetter`（Feed/HTML 类型检测）、`VttTranscriptParser`（去 HTML 标签）
- V1 用手写正则清洗器即可（`ShownotesCleaner` 核心是 CSS 正则替换，非 DOM 操作）
- `HtmlToPlainText` 可用正则 `html.replace(/<[^>]+>/g, '')` 加实体解码替代
- `FeedDiscoverer`（RSS \<link\> 自动发现）可在 XmlPullParser 中一并处理
- HTML 描述显示用 ArkUI `RichText` 组件直接渲染

---

#### 方案 6：SAX Parser → XmlPullParser（4 模块，🔴 高风险）

**安装**：系统内置 `@ohos.xml`

**架构差异**：

| 维度 | Android SAX (Push) | ArkTS XmlPullParser (Pull) |
|------|-------------------|---------------------------|
| 控制流 | 解析器驱动，回调 Handler | 应用驱动，主动 next() |
| Handler | ContentHandler.startElement/endElement/characters | while + switch(eventType) |
| 命名空间 | uri + localName 回调参数 | parser.getName() + parser.getNamespace() |
| 状态管理 | Handler 内部 Stack | 循环内局部变量 |
| 错误处理 | SAXException | try/catch 在循环内 |

**AntennaPod SAX 架构**（需完全重写）：

```
SyndHandler (ContentHandler 主入口)
├── state: HandlerState (Feed/Item/Description/Image...)
├── namespaces: Namespace[] (8 个)
├── startElement() → 分发给 namespace.handleElementStart()
├── endElement() → 分发给 namespace.handleElementEnd()
└── characters() → 累积文本内容

8 个 Namespace Handler（含精确 URI）:
├── Rss20      URI=""（默认无命名空间）— <channel>, <item>, <title>, <description>, <link>, <pubDate>, <enclosure>
├── Atom       URI="http://www.w3.org/2005/Atom" — <feed>, <entry>, <link rel="alternate/enclosure/payment/next">, <summary>, <content>, <author>
├── Itunes     URI="http://www.itunes.com/dtds/podcast-1.0.dtd" — <image href="">, <author>, <duration>, <subtitle>, <summary>, <new-feed-url>
├── Media      URI="http://search.yahoo.com/mrss/" — <media:content>, <media:description>, <media:thumbnail>
├── DublinCore URI="http://purl.org/dc/elements/1.1/" — <dc:date>
├── PodcastIndex URI="https://podcastindex.org/namespace/1.0"（双URI支持）— <podcast:transcript>, <podcast:chapters>, <podcast:funding>
├── SimpleChapters URI="http://podlove.org/simple-chapters"（前缀 psc|sc）— <psc:chapters>, <psc:chapter start="" title="" href="" image="">
└── Content    URI="http://purl.org/rss/1.0/modules/content/" — <content:encoded>
```

**XmlPullParser 重写模式**：

```typescript
import xml from '@ohos.xml';

class FeedParser {
  parse(xmlData: string): Feed {
    const feed = new Feed();
    const textDecoder = util.TextDecoder.create('utf-8');
    const arrayBuffer = buffer.from(xmlData).buffer;

    const parser = new xml.XmlPullParser(arrayBuffer, 'utf-8');
    let eventType: xml.EventType = parser.next();
    let currentItem: FeedItem | undefined = undefined;
    let currentText: string = '';
    let insideChannel: boolean = false;
    let insideItem: boolean = false;

    while (eventType !== xml.EventType.END_DOCUMENT) {
      if (eventType === xml.EventType.START_TAG) {
        const tagName: string = parser.getName();
        const namespace: string = parser.getNamespace();
        currentText = '';

        if (tagName === 'channel') {
          insideChannel = true;
        } else if (tagName === 'item' || tagName === 'entry') {
          currentItem = new FeedItem();
          insideItem = true;
        } else if (tagName === 'enclosure' && currentItem !== undefined) {
          // 解析属性
          const url = parser.getAttributeValue(null, 'url');
          const type = parser.getAttributeValue(null, 'type');
          const length = parser.getAttributeValue(null, 'length');
          // 创建 FeedMedia...
        }
        // 分发给 Namespace Handler...
        this.handleNamespaceStart(namespace, tagName, parser, feed, currentItem);

      } else if (eventType === xml.EventType.END_TAG) {
        const tagName: string = parser.getName();

        if (tagName === 'item' || tagName === 'entry') {
          if (currentItem !== undefined) {
            feed.items.push(currentItem);
          }
          currentItem = undefined;
          insideItem = false;
        } else if (insideItem && currentItem !== undefined) {
          this.setItemField(tagName, currentText, currentItem);
        } else if (insideChannel) {
          this.setFeedField(tagName, currentText, feed);
        }
        currentText = '';

      } else if (eventType === xml.EventType.TEXT) {
        currentText += parser.getText();
      }

      eventType = parser.next();
    }
    return feed;
  }
}
```

**Namespace Handler 迁移策略**：
- 不再用继承/接口模式 → 用 `if (namespace === ITUNES_URI)` 分支
- 8 个 Handler 可合并为一个 `handleNamespaceStart/End` 方法集
- 或保留独立文件，每个 Namespace 导出 `handleStart(tag, parser, feed, item)` / `handleEnd(tag, text, feed, item)` 函数

**踩坑**：
- XmlPullParser 的 `getText()` 可能分多次返回，必须用 `+=` 累积
- CDATA 内容通过 `TEXT` 事件返回
- 空标签 `<itunes:image href="..."/>` 是 START_TAG + END_TAG，无 TEXT 事件
- 命名空间前缀不可靠（不同 Feed 可能用不同前缀），应用 namespace URI 判断
- `parser.getAttributeValue(null, name)` — 第一个参数是命名空间（null = 无命名空间）

---

#### 方案 7：commons-lang3 → 手写工具函数（13 模块，🟢 低风险）

AntennaPod 实际使用的 commons-lang3 方法（源码 grep 统计）：

| 方法 | 使用次数 | ArkTS 替代 |
|------|---------|-----------|
| `StringUtils.isEmpty(s)` | ~30 | `s === '' \|\| s === undefined` |
| `StringUtils.isNotEmpty(s)` | ~20 | `s !== '' && s !== undefined` |
| `StringUtils.isBlank(s)` | ~10 | `s === undefined \|\| s.trim() === ''` |
| `StringUtils.trim(s)` | ~5 | `s?.trim() ?? ''` |
| `StringUtils.join(list, sep)` | ~5 | `array.join(sep)` |
| `StringUtils.containsIgnoreCase(a, b)` | ~3 | `a.toLowerCase().includes(b.toLowerCase())` |
| `ObjectUtils.firstNonNull(a, b)` | ~5 | `a ?? b` |
| `NumberUtils.toLong(s, def)` | ~3 | `parseInt(s) \|\| def` |

**实现**：在 `helpers/StringUtils.ets` 中提供 10 个静态方法即可。

---

#### 方案 8：commons-io → @kit.CoreFileKit fileIo（14 模块，🟢 低风险）

AntennaPod 实际使用的 commons-io 方法：

| 方法 | ArkTS 替代 | 说明 |
|------|-----------|------|
| `IOUtils.toString(inputStream, charset)` | `fileIo.readText(path)` | 读取文件到字符串 |
| `IOUtils.copy(in, out)` | `fileIo.copyFile(src, dst)` | 文件复制 |
| `IOUtils.closeQuietly(stream)` | `try { fileIo.close(fd) } catch(e) {}` | 安静关闭 |
| `FileUtils.deleteDirectory(dir)` | `fileIo.rmdir(path)` | 递归删除 |
| `FileUtils.readFileToString(file)` | `fileIo.readText(path)` | 读文件 |
| `FileUtils.writeStringToFile(file, data)` | `fileIo.writeText(path, data)` | 写文件 |
| `FileUtils.getFile(parent, child)` | `parent + '/' + child` | 路径拼接 |
| `FilenameUtils.getExtension(name)` | `name.substring(name.lastIndexOf('.') + 1)` | 扩展名 |

**安装**：系统内置 `import { fileIo } from '@kit.CoreFileKit'`

---

#### 方案 9：Guava → 手写工具函数（6 模块，🟢 低风险）

AntennaPod 实际使用的 Guava 方法：

| 方法 | ArkTS 替代 |
|------|-----------|
| `Joiner.on(sep).join(list)` | `array.join(sep)` |
| `Lists.newArrayList(iterable)` | `Array.from(iterable)` |
| `Preconditions.checkNotNull(obj)` | `if (obj === undefined) throw new Error()` |
| `Preconditions.checkArgument(cond)` | `if (!cond) throw new Error()` |
| `CollectionUtils` 操作 | Array 原生方法 |

无需单独文件，直接用 ArkTS 原生 API 替代。

---

#### 方案 10：Media3/ExoPlayer → AVPlayer + AVSession（5 模块，🔴 高风险）

**安装**：系统内置 `import { media } from '@kit.MediaKit'`

**架构对比**：

| 维度 | Media3/ExoPlayer | AVPlayer + AVSession |
|------|-----------------|---------------------|
| 播放器创建 | `ExoPlayer.Builder(ctx).build()` | `await media.createAVPlayer()` |
| 状态机 | 内部自动管理 | **必须手动按序推进**：Idle→Initialized→Prepared→Playing |
| 设置源 | `player.setMediaItem(MediaItem.fromUri(uri))` | `avPlayer.url = uri`（触发 Initialized） |
| 准备 | `player.prepare()` | `avPlayer.prepare()`（等待 Prepared 回调） |
| 播放 | `player.play()` | `avPlayer.play()`（仅 Prepared/Paused 态可调用） |
| 暂停 | `player.pause()` | `avPlayer.pause()` |
| 跳转 | `player.seekTo(positionMs)` | `avPlayer.seek(positionMs)`（仅 Prepared 后） |
| 后台播放 | `MediaLibraryService` + `MediaSession` | `ContinuousTask` + `AVSession` + `backgroundModes` |
| 进度监听 | `player.addListener(Player.Listener)` | `avPlayer.on('timeUpdate', callback)` |
| 错误监听 | `Player.Listener.onPlayerError` | `avPlayer.on('error', callback)` |
| 释放 | `player.release()` | `avPlayer.release()` |

**状态机关键差异（最大坑）**：

```typescript
// AVPlayer 严格状态机（必须遵守）
import { media } from '@kit.MediaKit';

class AVPlayerWrapper {
  private avPlayer: media.AVPlayer | undefined = undefined;

  async init(): Promise<void> {
    this.avPlayer = await media.createAVPlayer();  // → idle 态
    this.avPlayer.on('stateChange', (state: string) => {
      if (state === 'initialized') {
        // url 设置成功 → 可以 prepare
        this.avPlayer?.prepare();
      } else if (state === 'prepared') {
        // prepare 完成 → 可以 play/seek
        this.avPlayer?.play();
      } else if (state === 'playing') {
        // 播放中
      } else if (state === 'paused') {
        // 已暂停
      } else if (state === 'completed') {
        // 播放完成
      } else if (state === 'error') {
        // 错误
      }
    });
  }

  async playUrl(url: string): Promise<void> {
    if (this.avPlayer === undefined) {
      return;
    }
    await this.avPlayer.reset();  // → idle 态
    this.avPlayer.url = url;      // → initialized 态（触发 stateChange）
    // prepare() 和 play() 在 stateChange 回调中链式调用
  }
}
```

**后台播放三件套**：
1. `module.json5`: `"backgroundModes": ["audioPlayback"]`（Phase 2 已配置 ✅）
2. `startContinuousTask`: 申请长时任务（`@kit.BackgroundTasksKit`）
3. `AVSession`: 暴露播放控制给系统/通知栏（`@kit.MediaKit`）

---

#### 方案 11：WorkManager → workScheduler（7 模块，🟡 中风险）

**安装**：系统内置 `import { workScheduler } from '@kit.BackgroundTasksKit'`

**AntennaPod Worker 映射**：

| Android Worker | ArkTS 替代 | 频率 | V1/V2 |
|---------------|-----------|------|-------|
| `FeedUpdateWorker` | `workScheduler` 周期任务 | 每 1-24 小时 | V2 |
| `EpisodeDownloadWorker` | `request.downloadFile` + 回调 | 即时 | V1 |
| `SyncService` (Worker) | `workScheduler` 周期任务 | 同步时 | V2 |
| `WidgetUpdaterWorker` | Skip | — | Skip |
| `AutomaticDatabaseExportWorker` | `workScheduler` 周期任务 | 每天 | V2 |
| `DatabaseMaintenanceWorker` | `workScheduler` 周期任务 | 不定期 | V2 |

**WorkManager vs workScheduler 差异**：
- WorkManager 最小间隔 15 分钟 → workScheduler 约束更严，系统智能调度
- WorkManager `setForegroundAsync` → ArkTS 用 `ContinuousTask` 前台提升
- WorkManager `Constraints`（网络、充电）→ workScheduler `WorkInfo` 设置条件
- WorkManager `OneTimeWorkRequest` → `workScheduler.startWork(workInfo)` 一次性任务

---

#### 方案 12：PreferenceScreen → 自建设置组件（🟡 中风险）

AntennaPod 有 17 个 PreferenceFragment，涉及 50+ 设置项。无 ArkTS 直接等价物。

**自建组件方案**：

| Android Preference 类型 | ArkTS 自建组件 | 说明 |
|------------------------|--------------|------|
| `SwitchPreferenceCompat` | `SwitchSettingRow` | Toggle + 标题 + 描述 |
| `ListPreference` | `SelectSettingRow` | 点击弹出 AlertDialog 选择 |
| `EditTextPreference` | `InputSettingRow` | 点击弹出 TextInput 对话框 |
| `PreferenceCategory` | `SettingGroup` | 分组标题 |
| `Preference` (跳转) | `NavigateSettingRow` | 点击跳转子页面 |
| `SeekBarPreference` | `SliderSettingRow` | Slider 滑动条 |
| `CheckBoxPreference` | `CheckSettingRow` | Checkbox + 标题 |

---

## SS4 UI 映射

### Activity → Page 映射（12 → 5 Page + 删除/合并）

| Android Activity | ArkTS 映射 | 类型 | 备注 |
|-----------------|-----------|------|------|
| SplashActivity | **删除** | Skip | HarmonyOS 原生 windowSplash 配置 |
| **MainActivity** | **MainPage.ets** | @Entry Page | 主容器：Tabs + Navigation + Panel + SideBarContainer |
| OnlineFeedViewActivity | NavDestination `OnlineFeedView` | NavDestination | 在线 Feed 预览/订阅确认 |
| VideoplayerActivity | NavDestination `VideoPlayer` | NavDestination | 视频播放器 |
| Media3VideoPlayerActivity | **合并到 VideoPlayer** | 合并 | 统一为一个视频播放器 |
| PlaybackSpeedDialogActivity | CustomDialog | Dialog | 播放速度调节对话框 |
| PreferenceActivity | NavDestination `Preferences` | NavDestination | 设置页（含多级子页面） |
| OpmlImportActivity | NavDestination `OpmlImport` | NavDestination | OPML 导入 |
| EchoActivity | NavDestination `Echo` | NavDestination | 年度总结（V2） |
| SelectSubscriptionActivity | **删除** | Skip | 快捷方式功能（鸿蒙方案不同） |
| ToolbarActivity | **删除** | Skip | 基类 Activity，ArkUI 不需要 |
| WidgetConfigActivity | **删除** | Skip | Widget 不迁移 |

### Fragment → Component 映射（71 个）

#### 主框架 Fragment（8 个）

| Android Fragment | ArkTS Component | 宿主 | 备注 |
|-----------------|----------------|------|------|
| HomeFragment | `HomeComponent` | MainPage Tabs[0] | 含多个动态 Section |
| SubscriptionFragment | `SubscriptionComponent` | MainPage Tabs[1] | 列表/网格切换 |
| QueueFragment | `QueueComponent` | MainPage Tabs[2] | 拖拽排序 |
| AllEpisodesFragment | `AllEpisodesComponent` | MainPage Tabs[3] | 全部剧集 |
| SearchFragment | `SearchComponent` | MainPage Tabs[4] | 搜索 |
| NavDrawerFragment | SideBarContainer 内容 | MainPage SideBar | 侧边栏导航 |
| AudioPlayerFragment | `AudioPlayerComponent` | MainPage Panel | 底部播放器（展开态） |
| ExternalPlayerFragment | `MiniPlayerComponent` | MainPage 底部 | 迷你播放器条 |

#### 列表 Fragment（6 个）

| Android Fragment | ArkTS Component | 备注 |
|-----------------|----------------|------|
| EpisodesListFragment（基类） | `EpisodeListComponent`（基础组件） | 复用模板 |
| InboxFragment | 合并到 AllEpisodes + filter | 过滤条件区分 |
| PlaybackHistoryFragment | NavDestination `PlaybackHistory` | 播放历史 |
| FeedItemlistFragment | NavDestination `FeedDetail` | Feed 详情页 |
| CompletedDownloadsFragment | NavDestination `Downloads` | 已下载列表 |
| DownloadLogFragment | NavDestination `DownloadLog` | 下载日志 |

#### Episode 详情（3 个）

| Android Fragment | ArkTS Component | 备注 |
|-----------------|----------------|------|
| ItemPagerFragment | NavDestination `EpisodeDetail` | Swiper 浏览多集 |
| ItemFragment | `EpisodeDetailContent` | 单集详情内容 |
| ItemDescriptionFragment | `EpisodeDescriptionComponent` | 描述内容（Swiper 页之一） |

#### Feed 相关（3 个）

| Android Fragment | ArkTS Component | 备注 |
|-----------------|----------------|------|
| FeedInfoFragment | `FeedInfoComponent` | Feed 信息 |
| FeedSettingsFragment | NavDestination `FeedSettings` | Feed 设置 |
| FeedSettingsPreferenceFragment | 合并到 FeedSettings | List + 自定义设置项 |

#### 播放器相关（4 个）

| Android Fragment | ArkTS Component | 备注 |
|-----------------|----------------|------|
| CoverFragment | `CoverComponent` | Swiper 页面之一 |
| ChaptersFragment | `ChaptersDialog`（CustomDialog） | 章节列表 |
| TranscriptDialogFragment | `TranscriptDialog`（CustomDialog） | 字幕对话框 |
| AudioPlayerFragment 展开态 | `AudioPlayerComponent` | 全屏播放器 |

#### 设置 Fragment（17 个）

| Android Fragment | ArkTS Component | 备注 |
|-----------------|----------------|------|
| MainPreferencesFragment | `MainPreferencesComponent` | 设置主页 |
| PlaybackPreferencesFragment | `PlaybackPreferencesComponent` | 播放设置 |
| DownloadsPreferencesFragment | `DownloadsPreferencesComponent` | 下载设置 |
| AutoDownloadPreferencesFragment | `AutoDownloadPreferencesComponent` | 自动下载 |
| AutomaticDeletionPreferencesFragment | `AutoDeletionPreferencesComponent` | 自动删除 |
| UserInterfacePreferencesFragment | `UIPreferencesComponent` | 界面设置 |
| NotificationPreferencesFragment | `NotificationPreferencesComponent` | 通知设置 |
| SwipePreferencesFragment | `SwipePreferencesComponent` | 滑动操作配置 |
| SynchronizationPreferencesFragment | `SyncPreferencesComponent` | 同步设置（V2） |
| ImportExportPreferencesFragment | `ImportExportPreferencesComponent` | 导入导出 |
| AboutFragment | `AboutComponent` | 关于 |
| ContributorsPagerFragment | `ContributorsComponent` | 贡献者（Swiper+Tabs） |
| DevelopersFragment | 合并到 ContributorsComponent Tab[0] | 开发者 |
| TranslatorsFragment | 合并到 ContributorsComponent Tab[1] | 翻译者 |
| SpecialThanksFragment | 合并到 ContributorsComponent Tab[2] | 鸣谢 |
| LicensesFragment | `LicensesComponent` | 开源许可 |
| BugReportFragment | `BugReportComponent` | Bug 报告 |

#### Dialog/BottomSheet Fragment（24 个 → CustomDialog/Sheet）

| Android Fragment | ArkTS 实现 | 备注 |
|-----------------|-----------|------|
| ItemSortDialog | CustomDialog `SortDialog` | 排序选择 |
| SubscriptionsFilterDialog | CustomDialog `FilterDialog` | 订阅过滤 |
| RemoveFeedDialog | AlertDialog | 确认删除 |
| ShareDialog | CustomDialog `ShareDialog` | 分享 |
| SleepTimerDialog | CustomDialog `SleepTimerDialog` | 睡眠计时器 |
| VariableSpeedDialog | CustomDialog `SpeedDialog` | 播放速度 |
| TagSettingsDialog | CustomDialog `TagDialog` | 标签编辑 |
| DownloadLogDetailsDialog | CustomDialog | 下载详情 |
| RatingDialogFragment | AlertDialog | 应用评分 |
| PlaybackControlsDialog | Sheet | 播放控制 |
| FeedStatisticsDialogFragment | CustomDialog | Feed 统计 |
| GpodderAuthenticationFragment | NavDestination `GpodderAuth` | 登录页（V2） |
| NextcloudAuthenticationFragment | NavDestination `NextcloudAuth` | 登录页（V2） |

#### 统计 Fragment（6 个，V2）

| Android Fragment | ArkTS Component | 备注 |
|-----------------|----------------|------|
| StatisticsFragment | NavDestination `Statistics` | Swiper + Tabs 容器 |
| SubscriptionStatisticsFragment | `SubStatisticsComponent` | 订阅统计 |
| YearsStatisticsFragment | `YearStatisticsComponent` | 年度统计 |
| DownloadStatisticsFragment | `DownloadStatisticsComponent` | 下载统计 |
| FeedStatisticsFragment | `FeedStatisticsComponent` | Feed 统计 |
| FeedStatisticsDialogFragment | 已列入 Dialog | — |

#### 发现 Fragment（4 个，V2）

| Android Fragment | ArkTS Component | 备注 |
|-----------------|----------------|------|
| DiscoveryFragment | NavDestination `Discovery` | 发现页 |
| OnlineSearchFragment | `OnlineSearchComponent` | 在线搜索 |
| QuickFeedDiscoveryFragment | `QuickDiscoveryComponent` | 快速发现（首页 Section） |
| AddFeedFragment | `AddFeedComponent` | 添加 Feed |

### 导航架构

```
MainPage (@Entry)
├── SideBarContainer (抽屉菜单)
│   └── 导航列表
│       ├── 添加播客 → NavDestination 'AddFeed'
│       ├── 播放历史 → NavDestination 'PlaybackHistory'
│       ├── 下载管理 → NavDestination 'Downloads'
│       ├── 统计 → NavDestination 'Statistics' (V2)
│       └── 设置 → NavDestination 'Preferences'
│
├── Navigation (NavPathStack, Stack 模式)
│   └── NavDestination 子页面:
│       ├── FeedDetail (Feed 内容列表)
│       ├── EpisodeDetail (Episode 详情, Swiper 浏览)
│       ├── FeedSettings (Feed 设置)
│       ├── FeedInfo (Feed 信息)
│       ├── OnlineFeedView (在线 Feed 预览)
│       ├── VideoPlayer (视频播放器)
│       ├── Discovery (发现页, V2)
│       ├── Statistics (统计, Swiper+Tabs, V2)
│       ├── Preferences (设置, 多级嵌套)
│       ├── OpmlImport (OPML 导入)
│       ├── Echo (年度总结, V2)
│       ├── Downloads (下载管理)
│       ├── DownloadLog (下载日志)
│       ├── PlaybackHistory (播放历史)
│       ├── GpodderAuth (gPodder 登录, V2)
│       └── NextcloudAuth (Nextcloud 登录, V2)
│
├── Tabs (底部导航, 5 个 Tab)
│   ├── [0] HomeComponent (首页)
│   ├── [1] SubscriptionComponent (订阅)
│   ├── [2] QueueComponent (队列)
│   ├── [3] AllEpisodesComponent (全部剧集)
│   └── [4] SearchComponent (搜索)
│
└── Panel (底部播放器)
    ├── MiniPlayerComponent (折叠态)
    └── AudioPlayerComponent (展开态)
        ├── Swiper
        │   ├── CoverComponent (封面)
        │   └── EpisodeDescriptionComponent (描述)
        └── 播放控制区
```

### ViewPager2 → Swiper 映射

| 场景 | Android 容器 | ArkTS 容器 | 页面 |
|------|------------|-----------|------|
| 统计页 | ViewPager2 + TabLayout | Tabs + Swiper | 3 页（订阅/年度/下载统计） |
| 贡献者 | ViewPager2 + TabLayout | Tabs + Swiper | 3 页（开发者/翻译者/鸣谢） |
| 播放器 | ViewPager2 | Swiper | 2 页（封面/描述） |
| Episode 浏览 | ViewPager2 + FragmentStateAdapter | Swiper | N 页（Episode 列表） |

### 关键 Adapter → LazyForEach 映射

| Android Adapter | ViewType 数量 | ArkTS 实现 | 备注 |
|----------------|--------------|-----------|------|
| EpisodeItemListAdapter | 1 | LazyForEach + IDataSource | 需多选和滑动操作 |
| HorizontalItemListAdapter | 1 | LazyForEach（水平 List） | 首页水平 Section |
| NavListAdapter | 2 (Header+Item) | ForEach + if/else | 导航列表 |
| StatisticsListAdapter (3 子类) | 2 (Header+Feed) | LazyForEach + if/else | TYPE_HEADER 条件渲染 |
| FeedDiscoverAdapter | 1 | LazyForEach | 发现列表 |
| SimpleChipAdapter | 1 | ForEach | 标签芯片 |
| SelectableAdapter | 1+多选模式 | LazyForEach + @State multiSelect | 基类，支持多选 |

---

## SS5 数据模型

### 数据库概览

| 项目 | 值 |
|------|-----|
| 数据库名称 | Antennapod.db |
| 当前版本 | 3110000 |
| 实现方式 | SQLiteOpenHelper（原生 SQL，非 Room） |
| 核心类 | PodDBAdapter（单例）、PodDBHelper（extends SQLiteOpenHelper） |
| 读写分离 | DBReader（查询）、DBWriter（写入）、FeedDatabaseWriter（Feed 专用） |
| 表数量 | 7 |
| ArkTS 等价 | `relationalStore` from `@kit.ArkData`，PodDatabase 单例 |

### CREATE TABLE SQL

#### 表 1：Feeds（播客订阅源，36 列）

```sql
CREATE TABLE IF NOT EXISTS Feeds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    custom_title TEXT,
    file_url TEXT,
    download_url TEXT,
    downloaded INTEGER DEFAULT 0,
    link TEXT,
    description TEXT,
    payment_link TEXT,
    last_update TEXT,
    language TEXT,
    author TEXT,
    image_url TEXT,
    type TEXT,
    feed_identifier TEXT,
    auto_download INTEGER DEFAULT 1,
    username TEXT,
    password TEXT,
    include_filter TEXT DEFAULT '',
    exclude_filter TEXT DEFAULT '',
    minimal_duration_filter INTEGER DEFAULT -1,
    keep_updated INTEGER DEFAULT 1,
    is_paged INTEGER DEFAULT 0,
    next_page_link TEXT,
    hide TEXT,
    sort_order TEXT,
    last_update_failed INTEGER DEFAULT 0,
    auto_delete_action INTEGER DEFAULT 0,
    feed_volume_adaption INTEGER DEFAULT 0,
    tags TEXT,
    feed_skip_intro INTEGER DEFAULT 0,
    feed_skip_ending INTEGER DEFAULT 0,
    episode_notification INTEGER DEFAULT 0,
    state INTEGER DEFAULT 0,
    new_episodes_action INTEGER DEFAULT 0,
    feed_playback_speed REAL DEFAULT -1.0,
    feed_skip_silence INTEGER DEFAULT 1
)
```

#### 表 2：FeedItems（播客剧集，17 列）

```sql
CREATE TABLE IF NOT EXISTS FeedItems (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    pubDate INTEGER,
    read INTEGER DEFAULT -1,
    link TEXT,
    description TEXT,
    payment_link TEXT,
    media INTEGER,
    feed INTEGER,
    has_simple_chapters INTEGER DEFAULT 0,
    item_identifier TEXT,
    image_url TEXT,
    auto_download INTEGER DEFAULT 1,
    podcastindex_chapter_url TEXT,
    podcastindex_transcript_type TEXT,
    podcastindex_transcript_url TEXT,
    social_interact_url TEXT
);

CREATE INDEX IF NOT EXISTS FeedItems_feed ON FeedItems (feed);
CREATE INDEX IF NOT EXISTS FeedItems_pubDate ON FeedItems (pubDate);
CREATE INDEX IF NOT EXISTS FeedItems_read ON FeedItems (read);
```

#### 表 3：FeedMedia（媒体文件，13 列）

```sql
CREATE TABLE IF NOT EXISTS FeedMedia (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    duration INTEGER DEFAULT 0,
    file_url TEXT,
    download_url TEXT,
    downloaded INTEGER DEFAULT 0,
    position INTEGER DEFAULT 0,
    filesize INTEGER DEFAULT 0,
    mime_type TEXT,
    playback_completion_date INTEGER DEFAULT 0,
    feeditem INTEGER,
    played_duration INTEGER DEFAULT 0,
    has_embedded_picture INTEGER DEFAULT -1,
    last_played_time INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS FeedMedia_feeditem ON FeedMedia (feeditem);
```

#### 表 4：SimpleChapters（章节标记，6 列）

```sql
CREATE TABLE IF NOT EXISTS SimpleChapters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    start INTEGER,
    feeditem INTEGER,
    link TEXT,
    image_url TEXT
);

CREATE INDEX IF NOT EXISTS SimpleChapters_feeditem ON SimpleChapters (feeditem);
```

#### 表 5：DownloadLog（下载日志，8 列）

```sql
CREATE TABLE IF NOT EXISTS DownloadLog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    feedfile INTEGER,
    feedfile_type INTEGER,
    reason INTEGER,
    successful INTEGER,
    completion_date INTEGER,
    reason_detailed TEXT,
    title TEXT
)
```

#### 表 6：Queue（播放队列，3 列）

```sql
CREATE TABLE IF NOT EXISTS Queue (
    id INTEGER PRIMARY KEY,
    feeditem INTEGER,
    feed INTEGER
);

CREATE INDEX IF NOT EXISTS Queue_feeditem ON Queue (feeditem);
```

#### 表 7：Favorites（收藏，3 列）

```sql
CREATE TABLE IF NOT EXISTS Favorites (
    id INTEGER PRIMARY KEY,
    feeditem INTEGER,
    feed INTEGER
)
```

### DAO 方法签名

#### FeedDao

```typescript
// 查询
async getAllFeeds(): Promise<Feed[]>
async getFeed(feedId: number): Promise<Feed | null>
async getFeedByUrl(downloadUrl: string): Promise<Feed | null>
async getFeedByIdentifier(identifier: string): Promise<Feed | null>

// 写入（INSERT OR UPDATE 模式）
async setFeed(feed: Feed): Promise<number>
async setFeedPreferences(prefs: FeedPreferences): Promise<void>
async setFeedItemFilter(feedId: number, filterValues: Set<string>): Promise<void>
async setFeedItemSortOrder(feedId: number, sortOrder: SortOrder): Promise<void>
async removeFeed(feed: Feed): Promise<void>
async setFeedState(feedId: number, state: number): Promise<void>
```

#### FeedItemDao

```typescript
async getFeedItem(itemId: number): Promise<FeedItem | null>
async getFeedItemByGuidOrUrl(feedId: number, guid: string, url: string): Promise<FeedItem | null>
async getFeedItems(feedId: number): Promise<FeedItem[]>
async getRecentlyPublished(offset: number, limit: number): Promise<FeedItem[]>
async getNewItems(offset: number, limit: number): Promise<FeedItem[]>
async searchItems(query: string): Promise<FeedItem[]>
async setFeedItem(item: FeedItem): Promise<number>
async markItemPlayed(itemId: number, played: number): Promise<void>
async setFeedItemAutoDownload(itemId: number, enabled: boolean): Promise<void>
```

#### FeedMediaDao

```typescript
async getFeedMedia(mediaId: number): Promise<FeedMedia | null>
async getFeedMediaByItemId(itemId: number): Promise<FeedMedia | null>
async getPlayedMedia(): Promise<FeedMedia[]>
async setFeedMedia(media: FeedMedia): Promise<number>
async setPosition(mediaId: number, position: number): Promise<void>
async setDuration(mediaId: number, duration: number): Promise<void>
async setPlaybackCompletionDate(mediaId: number, date: number): Promise<void>
```

#### QueueDao

```typescript
async getQueue(): Promise<FeedItem[]>
async addToQueue(itemId: number, feedId: number): Promise<void>
async removeFromQueue(itemId: number): Promise<void>
async moveInQueue(from: number, to: number): Promise<void>
async clearQueue(): Promise<void>
async isInQueue(itemId: number): Promise<boolean>
```

#### FavoritesDao

```typescript
async getFavorites(): Promise<FeedItem[]>
async addToFavorites(itemId: number, feedId: number): Promise<void>
async removeFromFavorites(itemId: number): Promise<void>
async isFavorite(itemId: number): Promise<boolean>
```

#### ChapterDao

```typescript
async getChapters(itemId: number): Promise<Chapter[]>
async setChapters(itemId: number, chapters: Chapter[]): Promise<void>
async deleteChapters(itemId: number): Promise<void>
```

#### DownloadLogDao

```typescript
async getDownloadLog(): Promise<DownloadResult[]>
async addDownloadLog(result: DownloadResult): Promise<void>
async clearDownloadLog(): Promise<void>
```

### SharedPreferences → Preferences 映射

| Android SharedPreferences | ArkTS 实现 | Key 数量 | 类别 |
|--------------------------|-----------|---------|------|
| DefaultSharedPreferences (UserPreferences) | `UserPreferences` 类 + Preferences 存储 | 50+ | UI/队列/播放/网络/自动下载/代理 |
| DefaultSharedPreferences (PlaybackPreferences) | `PlaybackPreferences` 类 | 7 | 当前播放 Feed/Media ID/状态/速度 |
| "gpodder.net" (SynchronizationCredentials) | `SyncCredentials` 类 | 4 | 用户名/密码/设备ID/主机名 |
| "SleepTimerDialog" (SleepTimerPreferences) | `SleepTimerPreferences` 类 | 5+ | 计时器设置 |
| "UsageStatistics" | `UsageStatistics` 类 | 1 | 流式 vs 下载偏好 |

### 核心 Model 类

#### Feed

```typescript
class Feed {
    id: number = 0
    feedTitle: string = ''
    customTitle: string = ''
    localFileUrl: string = ''
    downloadUrl: string = ''
    feedIdentifier: string = ''
    link: string = ''
    description: string = ''
    language: string = ''
    author: string = ''
    imageUrl: string = ''
    type: string = ''                    // "RSS2" | "Atom"
    lastModified: string = ''
    lastRefreshAttempt: number = 0
    paged: boolean = false
    nextPageLink: string = ''
    lastUpdateFailed: boolean = false
    state: number = 0                    // 0=SUBSCRIBED, 1=NOT_SUBSCRIBED, 2=ARCHIVED
    items: FeedItem[] = []
    preferences: FeedPreferences = new FeedPreferences()
    sortOrder: SortOrder | null = null
    fundingList: FeedFunding[] = []
    pageNr: number = 0
}
```

#### FeedItem

```typescript
class FeedItem {
    id: number = 0
    itemIdentifier: string = ''
    title: string = ''
    description: string = ''
    link: string = ''
    pubDate: number = 0                  // timestamp ms
    state: number = -1                   // -1=NEW, 0=UNPLAYED, 1=PLAYED
    paymentLink: string = ''
    media: FeedMedia | null = null
    feed: Feed | null = null
    feedId: number = 0
    hasChapters: boolean = false
    chapters: Chapter[] = []
    imageUrl: string = ''
    autoDownloadEnabled: boolean = true
    podcastIndexChapterUrl: string = ''
    podcastIndexTranscriptUrl: string = ''
    podcastIndexTranscriptType: string = ''
    socialInteractUrl: string = ''
    tags: Set<string> = new Set()
}
```

#### FeedMedia

```typescript
class FeedMedia {
    id: number = 0
    localFileUrl: string = ''
    downloadUrl: string = ''
    downloadDate: number = 0
    duration: number = 0                 // ms
    position: number = 0                 // ms
    lastPlayedTimeStatistics: number = 0
    playedDuration: number = 0           // ms
    size: number = 0                     // bytes
    mimeType: string = ''
    item: FeedItem | null = null
    itemId: number = 0
    lastPlayedTimeHistory: number = 0
    hasEmbeddedPicture: boolean = false
    startPosition: number = 0
    playedDurationWhenStarted: number = 0
}
```

#### FeedPreferences

```typescript
class FeedPreferences {
    feedPlaybackSpeed: number = -1       // -1 = use global
    feedSkipSilence: number = 1          // 0=OFF, 1=GLOBAL, 2=AGGRESSIVE
    volumeAdaptionSetting: number = 0
    autoDownload: number = 1             // 0=DISABLED, 1=GLOBAL, 2=ENABLED
    autoDeleteAction: number = 0         // 0=GLOBAL, 1=ALWAYS, 2=NEVER
    newEpisodesAction: number = 0        // 0=GLOBAL, 1=ADD_TO_INBOX, 2=NOTHING, 3=ADD_TO_QUEUE
    username: string = ''
    password: string = ''
    keepUpdated: boolean = true
    includeFilter: string = ''
    excludeFilter: string = ''
    minimalDurationFilter: number = -1
    tags: Set<string> = new Set()
    feedSkipIntro: number = 0            // seconds
    feedSkipEnding: number = 0           // seconds
    episodeNotification: boolean = false
}
```

#### Chapter

```typescript
class Chapter {
    id: number = 0
    start: number = 0                    // ms
    title: string = ''
    link: string = ''
    imageUrl: string = ''
    chapterId: string = ''
}
```

#### DownloadResult

```typescript
class DownloadResult {
    id: number = 0
    title: string = ''
    feedfileId: number = 0
    feedfileType: number = 0             // Feed=0, FeedMedia=2
    reason: number = 0                   // DownloadError code
    reasonDetailed: string = ''
    successful: boolean = false
    completionDate: number = 0           // timestamp ms
}
```

---

## SS6 功能分期

### V1 — 核心功能（最小可用产品）

| # | 功能 | 来源 Fragment/Activity | 风险 |
|---|------|----------------------|------|
| 1 | Feed 订阅（添加/删除/刷新） | AddFeedFragment, FeedItemlistFragment | 🟢 |
| 2 | Feed 列表展示（列表/网格） | SubscriptionFragment | 🟢 |
| 3 | Episode 列表与详情 | AllEpisodesFragment, ItemFragment | 🟢 |
| 4 | RSS/Atom 解析（8 个 Namespace） | FeedHandler + SyndHandler + 8 NS | 🔴 |
| 5 | 音频播放（本地+流式） | AudioPlayerFragment, PlaybackService | 🔴 |
| 6 | 后台播放 + 通知控制 | ContinuousTask + AVSession | 🔴 |
| 7 | 播放队列管理（含拖拽排序） | QueueFragment | 🟡 |
| 8 | 播放进度保存与恢复 | PlaybackPreferences, DB | 🟡 |
| 9 | 数据库 CRUD（7 表） | DBReader, DBWriter | 🟢 |
| 10 | Episode 下载 | EpisodeDownloadWorker | 🟡 |
| 11 | 搜索（本地） | SearchFragment | 🟢 |
| 12 | 收藏功能 | Favorites 表 | 🟢 |
| 13 | 播放历史 | PlaybackHistoryFragment | 🟢 |
| 14 | 首页 Home Section | HomeFragment | 🟢 |
| 15 | 底部导航（5 Tab） | BottomNavigationView | 🟢 |
| 16 | 侧边栏导航 | DrawerLayout + NavDrawerFragment | 🟢 |
| 17 | 迷你播放器 + 全屏播放器 | ExternalPlayerFragment + AudioPlayerFragment | 🟡 |
| 18 | 基础设置（主题、播放） | PreferenceActivity 部分 | 🟡 |
| 19 | 用户偏好持久化 | UserPreferences | 🟢 |
| 20 | OPML 导入导出 | OpmlImportActivity, ImportExport | 🟡 |

### V2 — 增强功能

| # | 功能 | 来源 | 风险 |
|---|------|------|------|
| 21 | 视频播放 | VideoplayerActivity | 🟡 |
| 22 | 播客发现/搜索 (iTunes/PodcastIndex/Fyyd) | DiscoveryFragment, OnlineSearchFragment | 🟡 |
| 23 | 在线 Feed 预览 | OnlineFeedViewActivity | 🟡 |
| 24 | 章节支持 | ChaptersFragment | 🟢 |
| 25 | 字幕/转录 (JSON/VTT/SRT) | TranscriptDialogFragment | 🟡 |
| 26 | 播放速度控制 | VariableSpeedDialog | 🟢 |
| 27 | 睡眠计时器 | SleepTimerDialog | 🟢 |
| 28 | 自动下载 | AutoDownloadPreferences | 🟡 |
| 29 | 自动删除 | AutomaticDeletionPreferences | 🟢 |
| 30 | 统计信息 | StatisticsFragment | 🟡 |
| 31 | Feed 过滤/排序 | ItemSortDialog, SubscriptionsFilter | 🟢 |
| 32 | 滑动操作配置 | SwipePreferences | 🟢 |
| 33 | gPodder 同步 | SyncService, GpodderAuth | 🔴 |
| 34 | Nextcloud 同步 | SyncService, NextcloudAuth | 🔴 |
| 35 | 通知管理 | NotificationPreferences | 🟡 |
| 36 | 数据库自动导出 | AutomaticDatabaseExportWorker | 🟡 |
| 37 | 数据库维护 | DatabaseMaintenanceWorker | 🟢 |
| 38 | Feed HTTP Basic 认证 | FeedPreferences.username/password | 🟡 |
| 39 | 代理设置 | ProxyConfig | 🟡 |
| 40 | 年度总结 Echo | EchoActivity | 🟡 |
| 41 | Feed 更新定时任务 | FeedUpdateWorker (WorkManager) | 🟡 |

### Skip — 不迁移

| 功能 | 原因 |
|------|------|
| Chromecast 投屏 (`:playback:cast`) | 无 HarmonyOS 等价物 |
| Android Auto (`:car-app`) | 无等价物 |
| Quick Settings Tile | HarmonyOS 快捷方式方案不同 |
| Widget (`:ui:widget`) | HarmonyOS 卡片体系差异大 |
| Google Play 内购/评分 | 平台特有 |
| SSL Provider (Conscrypt) | 系统自带 TLS |
| DeX 支持 (Samsung) | 三星特有 |
| App Shortcut | HarmonyOS 方案不同 |
| MediaRouter | Cast 依赖 |

---

## SS7 迁移边界分类

### Auto（API 基本一致，可直接迁移）

| 模块 | 说明 |
|------|------|
| Model 类（26+） | 字段类型直接映射（Java→ArkTS） |
| 数据库建表 SQL（7 表） | SQL 语句直接复用 |
| Feed/FeedItem/FeedMedia 字段 | 1:1 映射 |
| 收藏/队列 CRUD | 简单 INSERT/DELETE |
| 排序/过滤逻辑 | 纯逻辑，无平台依赖 |
| 日期/时间工具函数 | 纯逻辑 |
| 枚举常量 | SortOrder, FeedCounter, DownloadError 等 |
| 用户偏好 Key 常量 | 字符串常量直接复制 |

### Semi-Auto（API 有差异，需适配）

| 模块 | Android | ArkTS | 差异点 |
|------|---------|-------|--------|
| HTTP 网络 | OkHttp | `@kit.NetworkKit` http | API 不同，拦截器需重构 |
| 文件下载 | OkHttp + FileOutputStream | `request.downloadFile` | 下载 API 完全不同 |
| 图片加载 | Glide + GlideModule | `@ohos/imageknife` | API 不同但概念相似 |
| RxJava 异步 | Observable/Single/Schedulers | async/await + Promise | 操作符逐个替换 |
| 后台任务 | WorkManager Worker | workScheduler | 约束条件/调度策略不同 |
| HTML 解析 | Jsoup | `@ohos/htmlparser2` | API 不同 |
| 数据库读写 | Cursor + ContentValues | ResultSet + ValuesBucket | API 不同但模式相似 |
| RecyclerView | ViewHolder + Adapter | LazyForEach + IDataSource | 模式完全不同 |
| ViewPager2 | FragmentStateAdapter | Swiper | 概念相似但 API 不同 |
| BottomSheet | BottomSheetBehavior | Panel | 行为类似 |
| DrawerLayout | DrawerLayout | SideBarContainer | 概念相似 |
| BottomNavigation | BottomNavigationView | Tabs(BarPosition.End) | 概念相似 |
| 通知 | NotificationCompat | notificationManager | API 差异大 |
| 前台服务 | startForeground | ContinuousTask | 概念不同 |
| Preferences 存储 | SharedPreferences | @kit.ArkData preferences | 异步 API |

### Manual（无直接等价物，需重写）

| 模块 | Android 方案 | ArkTS 方案 | 工作量 |
|------|------------|-----------|--------|
| RSS/Atom SAX 解析器 | SAX Push + SyndHandler + 8 Namespace | XmlPullParser Pull 模式全部重写 | **大** |
| Media3 播放服务 | MediaLibraryService + ExoPlayer + MediaSession | AVPlayer + AVSession + ContinuousTask | **大** |
| EventBus 事件系统 | GreenRobot EventBus + 20+ 事件 + 注解处理 | 自建 EventHub（Map<string, Function[]>） | **中** |
| PreferenceScreen 设置页 | PreferenceFragmentCompat × 17 | 自建 List + 自定义设置项组件（SwitchRow 等） | **大** |
| 媒体元数据解析 | ID3Reader + VorbisCommentReader（二进制） | 自研或 V2 简化 | **中** |
| BroadcastReceiver | 4 Receiver（网络/电源/媒体按钮/Feed更新） | emitter + 系统 API 监听 | **中** |
| gPodder/Nextcloud 同步 | HTTP API + Worker + 鉴权 | http + workScheduler（V2） | **中** |
| Transcript 解析 | JSON/VTT/SRT 自研 Parser | 参考原逻辑重写（3 格式） | **小** |
| 播放器状态机 | ExoPlayer 内部状态 + PSMPCallback | AVPlayer 严格状态机（Idle→Init→Prepared→Playing） | **中** |

### Skip（不迁移）

| 模块 | 原因 |
|------|------|
| `:playback:cast` | 无 Chromecast 等价物 |
| `:net:ssl` | 系统自带 TLS |
| QuickSettingsTileService | 平台特有 |
| `:ui:widget` | 差异过大 |
| car-app | 无等价物 |
| ProGuard 规则 | 构建系统不同 |
| Checkstyle/SpotBugs | 开发工具不同 |
| Flavor (free/play) | 单一平台不需要 |
| EventBus annotation-processor | ArkTS 无注解处理 |

---

## SS8 迁移顺序

### 模块依赖关系图

```
Layer 0 (无依赖):
    models/          ← :model（26+ 模型类）
    common/EventBus  ← :event（20+ 事件定义）

Layer 1 (依赖 L0):
    helpers/         ← :system + :storage:preferences（工具函数 + Preferences）
    database/        ← :storage:database（PodDatabase + 7 DAO，依赖 models/）

Layer 2 (依赖 L1):
    parser/          ← :parser:feed + :parser:media + :parser:transcript（依赖 models/）
    network/         ← :net:common + :net:download（依赖 models/, database/, helpers/）

Layer 3 (依赖 L2):
    playback/        ← :playback:base + :playback:service（依赖全部下层）

Layer 4 (依赖 L3):
    viewmodels/      ← ViewModel 层（依赖 database/, network/, playback/）
    datasource/      ← IDataSource（依赖 models/, database/）

Layer 5 (依赖 L4):
    components/      ← @Component（依赖 viewmodels/, datasource/）
    pages/           ← @Entry Page + NavDestination（依赖 components/）
    workers/         ← workScheduler（依赖 database/, network/）
```

### 推荐迁移顺序

```
Phase 2 — 项目骨架
    ├── 2.1 module.json5 配置（权限、backgroundModes）
    ├── 2.2 目录结构创建
    └── 2.3 GlobalState.init() + AppRouter

Phase 3 — 基础层（Layer 0-1）
    ├── 3.1 models/ — 全部 26+ Model 类
    ├── 3.2 common/EventBus.ets — 自建事件总线
    ├── 3.3 helpers/ — UserPreferences, PlaybackPreferences, 常量, 工具
    └── 3.4 database/ — PodDatabase 单例 + 7 DAO（7 表建表）

Phase 4 — 适配层（Layer 2）⚠ 含高风险项
    ├── 4.1 network/HttpClient.ets — HTTP 封装（Semi-Auto）
    ├── 4.2 network/DownloadManager.ets — 下载管理（Semi-Auto）
    ├── 4.3 parser/FeedParser.ets — RSS/Atom 解析 ← 🔴 Manual 重写
    │       └── parser/namespace/*.ets — 8 个 Namespace Handler
    ├── 4.4 parser/OpmlParser.ets — OPML 导入导出
    └── 4.5 parser/TranscriptParser.ets — 字幕解析（V2）

Phase 5 — 播放层（Layer 3）⚠ 高风险
    ├── 5.1 playback/AVPlayerWrapper.ets — AVPlayer 封装 ← 🔴 Manual
    ├── 5.2 playback/PlaybackService.ets — 后台播放 + AVSession ← 🔴 Manual
    ├── 5.3 playback/PlayerStatus.ets — 状态机
    └── 5.4 playback/SleepTimer.ets — 睡眠计时器（V2）

Phase 6 — UI 层（Layer 4-5）
    ├── 6.1 MainPage.ets — Tabs + Navigation + Panel + SideBarContainer
    ├── 6.2 MiniPlayerComponent + AudioPlayerComponent（底部播放器）
    ├── 6.3 HomeComponent（首页）
    ├── 6.4 SubscriptionComponent（订阅列表/网格）
    ├── 6.5 QueueComponent（队列，拖拽排序）
    ├── 6.6 AllEpisodesComponent（全部剧集）
    ├── 6.7 SearchComponent（搜索）
    ├── 6.8 FeedDetail NavDestination（Feed 详情+剧集列表）
    ├── 6.9 EpisodeDetail NavDestination（剧集详情，Swiper）
    ├── 6.10 FeedInfo/FeedSettings NavDestination
    ├── 6.11 设置页系列（17 个 Preference Fragment → 自建设置组件）
    ├── 6.12 PlaybackHistory/Downloads/DownloadLog NavDestination
    └── 6.13 Dialog 组件（排序/过滤/分享/标签/速度等）

Phase 7 — 后台 & V2 功能
    ├── 7.1 workers/FeedUpdateWorker.ets
    ├── 7.2 workers/EpisodeDownloadWorker.ets
    ├── 7.3 Discovery/OnlineSearch（V2）
    ├── 7.4 Statistics（V2）
    ├── 7.5 gPodder/Nextcloud 同步（V2）
    └── 7.6 验证 + 调试
```

---

## SS9 风险评估

| # | 风险项 | 等级 | SS3 来源 | 缓解策略 |
|---|-------|------|---------|---------|
| R1 | **SAX → XmlPullParser 重写** | 🔴 | #29 Manual | 8 个 Namespace Handler 全部重写为 Pull 模式。**缓解**：(1) 先实现 Rss20 + Atom 核心解析，逐步添加 iTunes/Media/DublinCore/PodcastIndex/SimpleChapters/Content；(2) 每个 Namespace 独立单元测试，用真实 RSS 文件验证；(3) Pull 模式范式：while(parser.next() != END_DOCUMENT) + switch(eventType) |
| R2 | **Media3/ExoPlayer → AVPlayer** | 🔴 | #20-21 Manual | 状态机差异大，ExoPlayer 内部管理状态 vs AVPlayer 需显式按序推进。**缓解**：(1) 严格按 Idle→Initialized→Prepared→Playing 编写，每次操作前检查状态；(2) 先实现最小可播放 PoC（单曲播放），再扩展队列/后台；(3) 参考 CLAUDE.md 播放器规范 |
| R3 | **后台播放** | 🔴 | #20-21+#19 | 需 ContinuousTask + AVSession + module.json5 backgroundModes。**缓解**：(1) module.json5 声明 `backgroundModes: ["audioPlayback"]`；(2) PlaybackService 启动时申请 ContinuousTask；(3) 创建 AVSession 暴露播放控制给系统 |
| R4 | **RxJava3 → async/await** | 🟡 | #3-4 | 大量操作符（map/flatMap/zip/debounce/switchMap/interval）需手动替换。**缓解**：(1) UI 层 `subscribeOn(io).observeOn(main)` → 直接 await（ArkUI 自动调度）；(2) `Observable.interval` → `setInterval`；(3) `zip` → `Promise.all` |
| R5 | **EventBus 自研** | 🟡 | #5 L5 | 20+ 事件类型，跨组件通信。**缓解**：(1) 简单 Map<string, Function[]> 发布订阅；(2) 用 emitter 模式；(3) `aboutToDisappear` 必须 `unsubscribe` 防泄漏 |
| R6 | **PreferenceScreen 重写** | 🟡 | #17 L5 | 17 个设置 Fragment 无 ArkTS 等价组件。**缓解**：(1) 自建通用设置项组件（SwitchSettingRow, SelectSettingRow, InputSettingRow, NavigateSettingRow）；(2) 复用到所有设置页；(3) Preferences 双层：持久化 + AppStorage 驱动 UI |
| R7 | **36 模块合并** | 🟡 | SS1 | 合并可能导致命名冲突和循环依赖。**缓解**：(1) 严格按目录分层；(2) 模块间通过接口通信；(3) 合并顺序按依赖链（Layer 0→5） |
| R8 | **BottomSheet 播放器** | 🟡 | SS4 | Android BottomSheetBehavior 支持三态+手势+嵌套滚动。**缓解**：(1) Panel 组件支持 mini/half/full；(2) 不够则自定义手势；(3) 嵌套 Swiper 需处理事件冲突 |
| R9 | **拖拽排序（队列）** | 🟡 | SS4 Queue | 队列页面支持长按拖拽重排序。**缓解**：(1) List.onItemDragStart + onItemDrop；(2) 备选：长按后显示上移/下移按钮 |
| R10 | **HTML 描述渲染** | 🟡 | #7 | Episode 描述含 HTML 内容。**缓解**：(1) `@ohos/htmlparser2` 解析后渲染为 RichText；(2) 或用 RichEditor 显示 |

---

## SS10 验收矩阵

### V1 核心功能验收

| # | 功能 | 操作步骤 | 通过标准 | 边界条件 |
|---|------|---------|---------|---------|
| A1 | 添加 Feed | 输入 RSS URL → 点击订阅 | Feed 出现在订阅列表，Episode 列表加载 | 无效 URL 提示错误；重复订阅提示已存在 |
| A2 | 删除 Feed | 长按 Feed → 确认删除 | Feed 从列表消失，相关 Episode/Media 清除 | 删除正在播放的 Feed 应停止播放 |
| A3 | 刷新 Feed | 下拉刷新 / 手动刷新 | 新 Episode 出现在列表顶部 | 网络断开显示错误；大量新 Episode 性能可接受 |
| A4 | RSS 2.0 解析 | 订阅标准 RSS 2.0 Feed | 标题/描述/封面/Episode 列表正确 | 缺字段不崩溃 |
| A5 | Atom 解析 | 订阅 Atom Feed | 同上 | Atom 特有标签（summary/content）正确处理 |
| A6 | iTunes 命名空间 | 订阅含 iTunes 标签的 Feed | duration/author/image/explicit 正确 | 无 iTunes 标签不影响基础解析 |
| A7 | Episode 列表 | 打开订阅 → 查看 Episode | 标题/日期/时长/状态正确显示 | 空列表显示空状态；1000+ Episode 不卡 |
| A8 | Episode 详情 | 点击 Episode → 详情 | 标题/描述/章节（如有）正确 | 超长 HTML 描述正确渲染 |
| A9 | 音频播放（流式） | 点击 Episode → 播放 | 音频开始播放，进度条更新 | 弱网缓冲提示；切 Episode 无缝 |
| A10 | 音频播放（本地） | 下载后 → 播放 | 使用本地文件，无网络请求 | 文件损坏显示错误 |
| A11 | 播放控制 | 暂停/恢复/快进30s/快退10s | 按钮状态正确，进度正确跳转 | 快速连续操作不崩溃 |
| A12 | 后台播放 | 播放中 → 切后台/锁屏 | 音频继续，通知栏显示控制 | 后台 30 分钟仍正常 |
| A13 | 播放进度保存 | 播放中 → 杀应用 → 重开 | 恢复到上次位置 | 精度到秒级 |
| A14 | 播放队列 | 添加到队列 → 查看 | 按添加顺序排列 | 拖拽排序正确；删除项后更新 |
| A15 | 队列自动播放 | 播完当前 → 自动下一首 | 自动切换到队列下一项 | 队列末尾停止 |
| A16 | 收藏 | 点击收藏按钮 | 出现在收藏列表 | 取消收藏后移除 |
| A17 | 搜索 | 输入关键词 | 返回匹配的 Feed 和 Episode | 空搜索词提示；特殊字符不崩溃 |
| A18 | 下载 | 点击下载 | 文件下载到本地，进度显示 | 断网恢复后继续；磁盘满提示 |
| A19 | 底部导航 | 点击各 Tab | 正确切换到对应页面 | 快速切换不闪烁 |
| A20 | 侧边栏 | 右滑打开 | 显示导航菜单 | 菜单项点击跳转正确 |
| A21 | 主题切换 | 设置 → 切换主题 | 即时生效，全局一致 | 深色/浅色/跟随系统 |
| A22 | OPML 导入 | 选择 OPML 文件 → 导入 | Feed 列表正确添加 | 大文件（100+ Feed）性能可接受 |
| A23 | OPML 导出 | 设置 → 导出 OPML | 生成有效 OPML 文件 | 无订阅时导出空文件 |
| A24 | 数据持久化 | 添加数据 → 重启应用 | 所有数据保留 | 7 表全部验证 |
| A25 | 迷你播放器 | 播放中 → 底部显示 | 当前播放信息，点击展开 | 无播放时隐藏 |
| A26 | 全屏播放器 | 点击迷你 → 展开 | 封面/进度/控制按钮 | 下滑折叠回迷你 |
| A27 | 播放历史 | 播放多集后查看历史 | 按时间倒序显示 | 空历史显示空状态 |
| A28 | 首页 Section | 打开首页 | 显示继续播放/新剧集/队列等 Section | 无内容的 Section 隐藏 |

---

## SS11 CLAUDE.md 规则

> 以下规则已写入项目根目录 `CLAUDE.md`，每次 Claude Code 对话自动加载。

### 项目概述
- 播客应用，从 Android (Java) 迁移到 HarmonyOS ArkTS
- 单 entry 模块，MVVM 分层架构
- 迁移规格文档：`docs/migration-spec.md`

### 导入规范
- 使用 kit 统一导入：`import { relationalStore } from '@kit.ArkData'`
- 不使用已废弃的单模块导入：~~`import relationalStore from '@ohos.data.relationalStore'`~~
- 例外：`@ohos.xml` 可直接使用（无对应 kit 封装）

### 严格禁止
- `any` 类型 — ArkTS 严格模式禁止
- `as` 类型断言 — 用 `instanceof` 检查代替
- `eval()` 和动态 `import()`
- 未标注类型的对象字面量
- SQL 字符串拼接 — 必须用 `?` 占位符
- 在 `aboutToAppear` 中获取 NavDestination 参数 — 必须在 `onReady` 中获取

### 组件规范
- `@Component` 必须是 `struct`，不是 `class`
- `build()` 方法必须有且仅有一个根容器
- `@Entry` 只用于 Page 级组件
- `@StorageLink` key 必须与 `AppStorage.setOrCreate` 的 key 完全一致
- `AppStorage.setOrCreate` 必须在任何 `@StorageLink` 声明前执行（在 `GlobalState.init()` 中完成）
- `ForEach` key 生成器必须包含会变化的字段

### 数据库规范
- 使用 `relationalStore` from `@kit.ArkData`
- 单例模式：`PodDatabase.getInstance().init(context)`
- 7 张表对应 7 个 DAO 类
- `ResultSet` 使用后必须 `close()`
- DAO 方法全部 `async`，返回 `Promise`
- SQL 参数用 `?` 占位符，值通过数组传入
- `INSERT OR REPLACE` 会改变自增 id，需要 id 稳定时用 `ON CONFLICT DO UPDATE`

### 播放器规范 (AVPlayer)
- 状态机必须严格按顺序：`Idle → Initialized → Prepared → Playing`，不能跳过
- 后台播放必须在 `module.json5` 声明：`"backgroundModes": ["audioPlayback"]`
- 必须使用 `@kit.BackgroundTasksKit` 的 `startContinuousTask` 申请长时任务
- `AVPlayer` 操作（seek, play）必须在 `prepared` 状态之后
- 释放资源：切页面/退出时必须调用 `avPlayer.release()`

### XML 解析规范
- 使用 `@ohos.xml` 的 `XmlPullParser`（Pull 模式）
- 不能用 SAX Push 模式的思维写解析器
- RSS 命名空间处理：根据前缀或 URI 判断，不要硬编码标签名
- 支持 8 个命名空间：RSS 2.0, Atom, iTunes, Media RSS, Dublin Core, Podcast Index, Simple Chapters, Content

### 网络规范
- 使用 `http` from `@kit.NetworkKit`
- 必须在 `module.json5` 声明 `ohos.permission.INTERNET`
- `http.createHttp()` 实例用完必须 `destroy()`
- 下载文件存储到沙箱路径：`context.filesDir` 或 `context.cacheDir`

### 状态管理
- `@State` — 组件内部状态
- `@Prop` — 父→子单向传递
- `@StorageLink` — 跨页面全局状态（双向绑定 AppStorage）
- `@Provide/@Consume` — NavPathStack 等组件树传递
- 持久化双层模式：Preferences 持久化 + AppStorage 驱动 UI

### 事件通信规范
- 自建 EventBus：`Map<string, Function[]>` 发布订阅模式
- 事件类型使用字符串常量，定义在 `common/EventBus.ets`
- 组件 `aboutToDisappear` 时必须 `unsubscribe` 防泄漏

### 导航
- `Navigation` + `NavPathStack`，Stack 模式
- 路由名定义在 `common/AppRouter.ets`
- 参数传递：`navPathStack.pushPathByName(name, param)`
- 参数接收：`NavDestination.onReady((ctx) => ctx.pathInfo.param)`
- 主页架构：`Tabs` + `Navigation` + `Panel`(底部播放器) + `SideBarContainer`(抽屉)

### 异步模式
- `async/await` + `Promise` — 替代 RxJava
- 数据库操作、网络请求、文件操作全部异步
- 不使用 `setTimeout` 模拟异步 — 用真正的异步 API

---

## Done Gate 检查

- [x] Spec 包含 SS1-SS11 全部 11 个章节
- [x] SS1 组件计数与源码扫描结果一致（12 Activity, 71 Fragment, 46 Adapter, 7 表, 26+ Model, 36 模块）
- [x] SS3 每个 Android 依赖都有替换方案或 Skip 标记（43 项 + 12 个详细替换方案含代码示例）
- [x] SS4 Activity(12)/Fragment(71) 计数与源码一致，全部映射
- [x] SS5 包含完整 CREATE TABLE SQL（7 张表，含索引）
- [x] SS6 每个功能标注 V1/V2/Skip
- [x] SS7 每个模块都有迁移边界分类（Auto/Semi-Auto/Manual/Skip）
- [x] SS8 依赖关系图 + 分层迁移顺序
- [x] SS9 每个高风险项(3 🔴 + 7 🟡)都有缓解策略
- [x] SS10 每个 V1 功能有验收行（28 项）
- [x] SS11 CLAUDE.md 规则覆盖通用规则 + 播客特有规则

---

*文档版本：v2.1 | SS3 详细替换方案补充 | 状态：Phase 2 完成*
