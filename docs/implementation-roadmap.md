# AntennaPod ArkTS 实施路线图

> 更新日期：2026-04-27
> 基于：`progress-vs-android.md` + `migration-spec.md` SS6 + 本会话验证

---

## 一、路线概览

```
已完成 ████████████████████████░░░░  80% V1 核心功能
  ↓
第一批 ░░░░░░░░░░░░░░░░░░░░░░░░░░  1-2天，队列排序 + OPML 导出 + 分享文件
  ↓
第二批 ░░░░░░░░░░░░░░░░░░░░░░░░░░  1周，设置页补全 + 统计图表
  ↓
第三批 ░░░░░░░░░░░░░░░░░░░░░░░░░░  2周，在线发现 + 字幕 + 自动下载/删除
  ↓
第四批 ░░░░░░░░░░░░░░░░░░░░░░░░░░  3周，视频播放器 + 通知 + 定时任务
  ↓
第五批 ░░░░░░░░░░░░░░░░░░░░░░░░░░  3-4周，gPodder/Nextcloud 同步
```

---

## 二、第一批：快速收尾（1-2天，6 项）

这些是当前代码中离"完整"最近的功能，改动量小、风险低。

| # | 功能 | 涉及文件 | 当前状态 |
|---|------|---------|---------|
| RP1 | **队列拖拽排序** | `QueueComponent.ets` | 删除/添加已有，缺 `List.onItemDragStart`/`onItemDrop` 长按拖拽 |
| RP2 | **OPML 导出** | `OpmlParser.ets` + 新按钮在 Settings | 导入已完成；导出 = FeedDao.getAllFeeds() → 生成 OPML XML → 写文件 |
| RP3 | **分享媒体文件** | `FullPlayerComponent.ets` | 目前 Toast 显示路径；改用系统 Want 分享文件 URI |
| RP4 | **设置页全局跳过片头/片尾** | `SettingsDetailComponent.ets` | Feed 级已配置，缺全局默认值设置入口 |
| RP5 | **下载日志详情** | `DownloadsComponent.ets` 新增 dialog | 列表已有，点击条目应展示下载失败原因和时间 |
| RP6 | **视频播放器手势控制** | `VideoPlayerComponent.ets` | 播放/暂停已有，缺手势快进/快退/亮度/音量 |

---

## 三、第二批：设置和统计完善（~1周，5 项）

生产就绪需要完整的功能配置入口和用户可感知的数据面板。

| # | 功能 | 涉及文件 | 说明 |
|---|------|---------|------|
| RP7 | **Feed 内剧集排序/过滤** | `FeedDetailComponent.ets` + SortDialog | 排序按钮已有，需要接入 SortDialog 和过滤条件 |
| RP8 | **滑动操作配置页** | 新建 `SwipePreferencesComponent.ets` | 剧集列表项左右滑动行为：加入队列/标记已播放/下载/收藏 |
| RP9 | **订阅统计** | `StatisticsComponent.ets` 子页 | 按 Feed 统计听时/集数，表格 + 横向对比 |
| RP10 | **年度统计** | `StatisticsComponent.ets` 子页 | 每月播放时长趋势图，对标 Android StatisticsFragment |
| RP11 | **下载统计** | `StatisticsComponent.ets` 子页 | 下载总量/成功/失败统计，数据来自 DownloadLogDao |

---

## 四、第三批：内容发现和自动化（~2周，6 项）

| # | 功能 | 涉及文件 | 说明 |
|---|------|---------|------|
| RP12 | **播客发现在线搜索** | `PodcastSearcher.ets` + `SearchPodcastsComponent.ets` | 对接 iTunes Search API / PodcastIndex API；已有雏形 |
| RP13 | **远程章节 JSON 下载解析** | `FeedParser.ets` + `PodcastIndexNamespace.ets` | `<podcast:chapters url="">` → fetch JSON → parse → save |
| RP14 | **字幕/转录对话框** | 新建 `TranscriptDialog.ets` | `TranscriptParser.ets` 已支持 3 格式解析，缺 UI |
| RP15 | **自动下载** | `AutoDownloadPreferencesComponent.ets` | 基于 Feed 偏好的自动下载触发逻辑 |
| RP16 | **自动删除** | `AutoDeletionPreferencesComponent.ets` | 策略驱动清理（空间/时间/已播放状态） |
| RP17 | **播放设置完善** | `SettingsDetailComponent.ets` 子页 | 播放速度默认值、快进快退秒数、跳过静音、自动播放等全局设置 |

---

## 五、第四批：系统级能力（~3周，5 项）

| # | 功能 | 涉及文件 | 说明 |
|---|------|---------|------|
| RP18 | **视频播放器全屏/小窗** | `VideoPlayerComponent.ets` | 全屏切换、画中画小窗、横竖屏适配 |
| RP19 | **通知管理** | 新建 `NotificationHelper.ets` + `NotificationPreferences.ets` | 新剧集通知、下载完成通知、播放通知栏控制 |
| RP20 | **Feed HTTP Basic 认证 UI** | `FeedSettingsComponent.ets` | username/password 配置入口；HttpClient 已支持 |
| RP21 | **Feed 定时更新** | `workers/` + module.json5 | workScheduler 周期任务配置；FeedUpdateWorker 已有 |
| RP22 | **数据库自动导出/维护** | 新建 `workers/DatabaseExportWorker.ets` | 定期 VACUUM + OPML 自动备份 |

---

## 六、第五批：外部同步（3-4周，3 项）

需要额外的 API 调研和网络调试。

| # | 功能 | 涉及文件 | 说明 |
|---|------|---------|------|
| RP23 | **gPodder 同步** | 新建 `network/sync/GpodderApi.ets` + `SyncService.ets` + 登录页 | 设备注册、双向状态同步、冲突解决 |
| RP24 | **Nextcloud 同步** | 新建 `network/sync/NextcloudApi.ets` + 登录页 | Nextcloud News API |
| RP25 | **代理设置** | `SettingsDetailComponent.ets` 子页 | SOCKS/HTTP 代理配置，需 NetworkUtils 扩展 |

---

## 七、Skip 项（不列入计划）

| 功能 | 原因 |
|------|------|
| Chromecast 投屏 | HarmonyOS 无等价物 |
| Android Auto / Car | 无等价物 |
| Widget 卡片 | 差异过大 |
| Google Play 内购/评分 | 平台特有 |
| Conscrypt SSL | 系统自带 TLS |
| 快捷方式 | 鸿蒙方案不同 |

---

## 八、Skills / 工具链路线（独立推进，不阻塞功能）

| # | 行动 | 工作量 | 预期效果 |
|---|------|--------|---------|
| SK1 | Memory 5 类文件整理 | 0.5周 | 踩坑不复发 |
| SK2 | CLAUDE.md 合并 Top-10 踩坑 | 0.5天 | 每次会话自动加载约束 |
| SK3 | Smoke test 7 条核心路径检查清单 | 1天 | 回归有据可依 |
| SK4 | hilog 统一规范 + 错误码映射 | 1天 | 问题定位加速 |
| SK5 | ArkTS Linter (any/as/对象字面量) | 1-2周 | 秒级编译反馈 |
| SK6 | UI 截图对比工作流 | 1周 | Android vs ArkTS 视觉差异自动化 |

---

## 九、优先级矩阵

```
                    低复杂度              中复杂度              高复杂度
                   ─────────            ─────────            ─────────
 高用户价值  │ RP1 队列拖拽排序      RP7 排序/过滤         RP12 在线搜索
             │ RP2 OPML 导出          RP8 滑动操作配置      RP15 自动下载
             │                        RP9-11 统计           RP19 通知管理
             │                                              RP21 Feed定时更新
             │
 中用户价值  │ RP3 分享文件           RP13 远程章节          RP18 视频增强
             │ RP4 跳过片头/片尾      RP14 字幕/转录         RP23/24 同步
             │ RP5 下载日志详情       RP17 播放设置完整      RP22 数据库维护
             │ RP6 视频手势
             │
 低用户价值  │ RP20 HTTP Basic Auth   RP25 代理设置         
```

---

*文档版本：v1.0 | 基于 2026-04-27 代码状态*
