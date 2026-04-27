# Issue #1: [Bug] Full Player 三点菜单缺少 Open podcast 和 Visit website

## 基本信息
- **页面**: Full Player
- **分类**: UI display issue
- **日期**: 2026-03-23
- **PR**: #2
- **分支**: fix/issue-1
- **修复轮次**: 2 轮

## 问题描述
全屏播放器右上角三点菜单只有 Sleep Timer、Share、取消三项，缺少 Android 版本中的 Open podcast 和 Visit website。

## 期望行为
应该和 Android 一致，三点菜单包含 Open podcast（跳转到订阅源详情）和 Visit website（打开播客网站）两项，且菜单样式为下拉弹出（非底部弹窗）。

## 根因分析
1. `showOverflowMenu()` 使用 `promptAction.showActionMenu()` 生成底部弹窗，与 Android 的下拉菜单风格不一致
2. 菜单项重复了顶栏已有的 Sleep Timer 和 Share 图标按钮
3. `currentFeedId` 和 feed 的 `link`（网站 URL）未通过 AppStorage 暴露给 FullPlayerComponent，导致无法实现 Open podcast 和 Visit website 功能

## 修复方案

### Round 1: 添加缺失菜单项 + 数据通路
- 在 `GlobalState.initAppStorage()` 中初始化 `currentFeedId` 和 `currentFeedLink`
- 在 `PlaybackController` 的 `playEpisode()`、`restoreLastPlayedEpisode()`、`stopInternal()` 三处同步设置/清理 feedId 和 feedLink
- 在 `FullPlayerComponent` 添加 `@StorageLink` 绑定和菜单项

### Round 2: 修复菜单样式 + 去重
- 将 `promptAction.showActionMenu()`（底部弹窗）改为 `.bindMenu()`（下拉菜单），匹配 Android 风格
- 移除重复的 Sleep Timer 和 Share，overflow 菜单只保留 Open podcast 和 Visit website

## 修改文件
| 文件 | 修改说明 |
|------|---------|
| `GlobalState.ets` | 在 `initAppStorage()` 中初始化 `currentFeedId`、`currentFeedLink` |
| `PlaybackController.ets` | 播放/恢复/停止时同步 feedId 和 feedLink 到 AppStorage |
| `FullPlayerComponent.ets` | 添加 `@StorageLink` 绑定；用 `.bindMenu()` 下拉菜单替代 `showActionMenu` 底部弹窗；只保留 Open podcast 和 Visit website |

## 可复用经验
- **是否通用**: Yes
- **适用场景**: 任何需要在 UI 组件中访问播放器关联数据（feedId、feedLink 等）的场景；以及需要匹配 Android 下拉菜单风格的场景
- **目标 Skill**: arkts-component-builder
- **经验要点**: 用 `.bindMenu()` 实现 Android 风格下拉菜单而非 `showActionMenu` 底部弹窗；新增 AppStorage 键需要在 GlobalState、PlaybackController（设置+清理）、UI 组件三处同步
