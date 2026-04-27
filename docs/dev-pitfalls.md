# ArkTS 开发踩坑记录

> 本文档记录 AntennaPod ArkTS 迁移过程中遇到的实际问题与解决方案，供后续开发参考。

---

## 1. AVPlayer 本地文件播放必须使用 `fd://` 协议

**问题**：使用 `file:// + 绝对路径` 设置 `avPlayer.url`，AVPlayer 直接进入 error 状态。

**原因**：HarmonyOS AVPlayer 不支持 `file://` 协议。本地文件必须通过文件描述符播放。

**正确做法**：
```typescript
import { fileIo } from '@kit.CoreFileKit';

const file = fileIo.openSync(localPath, fileIo.OpenMode.READ_ONLY);
avPlayer.url = 'fd://' + file.fd.toString();

// 播放结束/停止时必须关闭 fd
fileIo.closeSync(file.fd);
```

**注意**：如果 fd 不关闭会导致文件描述符泄漏；如果过早关闭会导致播放中断。应在 `stopInternal()` 中统一关闭。

---

## 2. `http.request()` 下载大文件有体积限制

**问题**：使用 `http.createHttp().request()` + `expectDataType: ARRAY_BUFFER` 下载播客音频，报错：
```
response data exceeds the maximum limit
CURLcode result 23
error code 2300023
```

**原因**：`http.request()` 的 `ARRAY_BUFFER` 模式将整个响应加载到内存，有约 5MB 的大小限制。播客文件通常 30-100MB。

**错误方案**：`http.requestInStream()` — 虽然支持流式，但 `dataReceiveProgress`/`dataEnd` 事件在实际设备上不可靠，导致下载卡住。

**正确方案**：使用 `request.agent` API（API 12+ 推荐的下载方式）：
```typescript
import { request } from '@kit.BasicServicesKit';

const config: request.agent.Config = {
  action: request.agent.Action.DOWNLOAD,
  url: downloadUrl,
  overwrite: true,
  method: 'GET',
  saveas: './' + fileName,       // 相对于 cacheDir
  mode: request.agent.Mode.FOREGROUND,
  gauge: true                     // 启用进度回调
};

const task = await request.agent.create(context, config);
task.on('progress', (progress: request.agent.Progress) => { ... });
task.on('completed', () => { ... });
task.on('failed', () => { ... });
await task.start();
```

---

## 3. `request.agent` 下载文件路径问题

**问题**：`request.agent` 下载完成后，文件在 `context.cacheDir` 中。使用 `fileIo.copyFileSync()` 复制到 `context.filesDir/downloads/` 时报错 `13900002`（ENOENT）。

**原因排查**：
- `fileIo.copyFileSync` 的 `IsAllPath` 检查失败，目标目录不存在
- `FileUtils.ensureDirectory()` 使用 `fileIo.mkdir()` 不支持递归创建

**解决方案**：
1. 使用 `fileIo.mkdirSync(dir, true)` 递归创建目录
2. 使用 `fileIo.moveFileSync()` 替代 `copyFileSync + unlinkSync`
3. 如果 move 失败，直接使用 cache 路径作为本地文件路径（容错降级）

```typescript
try {
  fileIo.mkdirSync(downloadDir, true);  // 递归创建
  fileIo.moveFileSync(cachePath, destPath);
} catch (e) {
  // 降级：直接使用 cache 路径
  finalPath = cachePath;
}
```

---

## 4. ArkTS 严格模式禁止对象字面量作类型

**问题**：编译报错 `Object literals cannot be used as type declarations (arkts-no-obj-literals-as-types)`。

**触发代码**：
```typescript
// 错误
httpRequest.on('dataReceiveProgress', (data: { receiveSize: number, totalSize: number }) => { ... });
```

**修复**：必须定义独立的 class：
```typescript
class DownloadReceiveProgress {
  receiveSize: number = 0;
  totalSize: number = 0;
}
httpRequest.on('dataReceiveProgress', (data: DownloadReceiveProgress) => { ... });
```

---

## 5. `promptAction.ShowActionMenuSuccessResponse` 不存在

**问题**：使用 `promptAction.showActionMenu()` 时，回调类型写成 `ShowActionMenuSuccessResponse`，编译报错。

**修复**：正确的类型名是 `ActionMenuSuccessResponse`（无 Show 前缀）：
```typescript
promptAction.showActionMenu({ ... })
  .then((result: promptAction.ActionMenuSuccessResponse) => { ... });
```

---

## 6. `sys.symbol` 资源名不一定存在

**问题**：使用 `$r('sys.symbol.xxx')` 时，部分 SF Symbol 名称在 HarmonyOS 中不存在，编译报 `Unknown resource name`。

**已验证不存在的名称**：
- `tray_arrow_down` → 替代：`envelope`
- `dot_3_horizontal` / `ellipsis` → 替代：`line_3_horizontal`
- `chart_bar` → 替代：`square_grid_2x2`
- `xmark_circle` — 需实测

**已验证可用的名称**：
- `house`, `list_bullet`, `envelope`, `square_grid_2x2`, `line_3_horizontal`
- `play_fill`, `pause_fill`, `arrow_down`, `checkmark`, `plus`, `trash`
- `magnifyingglass`, `chevron_right`, `chevron_left`, `lock`, `clock`, `gearshape`

**建议**：优先从项目中已验证使用的 symbol 名称中选取，不要猜测。

---

## 7. Tab 栏在子页面中保持可见

**问题**：使用 `Navigation` 包裹 `Tabs` 时，`NavDestination` 子页面覆盖整个 Navigation 区域，Tab 栏随之隐藏。Android 版子页面仍显示 Tab 栏。

**原因**：`Tabs` 在 `Navigation` 内部，NavDestination 会覆盖包括 Tabs 在内的整个区域。

**解决方案**：将 `Tabs` 替换为自定义 Tab 栏，放在 `Navigation` 外部：

```
Column {
  Navigation { /* 内容区 */ }  .layoutWeight(1)
  MiniPlayer                    // 始终在 Tab 栏上方
  CustomTabBar (Row)            // 始终在最底部
}
```

`Navigation` 通过 `layoutWeight(1)` 占据 Tab 栏上方空间，NavDestination 子页面只覆盖这部分，Tab 栏不受影响。

---

## 8. Emoji 图标在 Tab 栏中大小不一致

**问题**：使用 Unicode emoji（📋📥📡）作为 Tab 图标，与普通 Unicode 字符（⌂）渲染大小差异巨大，药丸背景无法适配。

**原因**：系统 emoji 按平台图片渲染，大小不受 `fontSize` 精确控制；普通 Unicode 按文本渲染。

**解决方案**：统一使用 `SymbolGlyph` + 系统 Symbol 资源：
```typescript
SymbolGlyph($r('sys.symbol.house'))
  .fontSize(22)
  .fontColor([Color.Black])
```
SymbolGlyph 大小由 `fontSize` 精确控制，所有图标一致。

---

## 9. `requestInStream` 的 Promise resolve 时机

**问题（已弃用方案，记录备查）**：`httpRequest.requestInStream()` 返回的 Promise 在收到**响应头**后即 resolve，而非等待所有数据传输完成。如果在 await 后立即关闭文件，文件为空。

**教训**：如果使用 `requestInStream`，必须监听 `dataEnd` 事件确认数据传输完毕后再处理文件。但在实际设备测试中，`dataEnd` 事件不可靠，建议直接使用 `request.agent` API。

---

## 10. `pasteboard` API 导入路径

**正确导入**：
```typescript
import { pasteboard } from '@kit.BasicServicesKit';
```

**使用**：
```typescript
const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
const sysBoard = pasteboard.getSystemPasteboard();
sysBoard.setData(pasteData);
```

---

## 总结：关键原则

| 场景 | 避免 | 推荐 |
|------|------|------|
| 本地文件播放 | `file://` + 路径 | `fd://` + 文件描述符 |
| 大文件下载 | `http.request()` ARRAY_BUFFER | `request.agent` API |
| 流式下载 | `http.requestInStream()` | `request.agent` API |
| Tab 图标 | Unicode emoji | `SymbolGlyph` + `sys.symbol` |
| 子页面保留 Tab 栏 | `Navigation` 包裹 `Tabs` | 自定义 Tab 栏在 Navigation 外部 |
| 目录创建 | `fileIo.mkdir(path)` | `fileIo.mkdirSync(path, true)` 递归 |
| 文件移动 | `copyFileSync` + `unlinkSync` | `moveFileSync` |
| 类型声明 | `{ key: type }` 对象字面量 | 独立 `class` 定义 |
