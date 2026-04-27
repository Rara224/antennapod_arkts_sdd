# ArkTS 播客应用开发经验 Skill

> 来源：AntennaPod Android→ArkTS 迁移实战
> 项目产出：105 .ets 文件，7 @CustomDialog，37 @Component，13 ViewModel
> 更新日期：2026-04-27

---

## SKILL 元信息

- **ID**: `arkts-podcast-app`
- **类别**: 代码迁移类 + 语法风格类
- **触发场景**: HarmonyOS 播客/媒体应用开发、Android→ArkTS 迁移、@CustomDialog 对话框开发
- **成熟度**: L2（已在本项目验证，可移植到下个项目）
- **优先级**: P0

---

## 一、@CustomDialog 安全模式（最重要）

### 问题

`@CustomDialog` 的 `controller: CustomDialogController` 字段在通过 `new CustomDialogController({ builder: Dialog({}) })` 创建时，**框架不会自动绑定 controller**。调用 `this.controller.close()` 导致 `TypeError: Cannot read property close of undefined` 闪退。

### 正确模式：onClose 回调

**对话框中** — 用 `onClose?.()` 代替 `this.controller.close()`：

```typescript
@CustomDialog
export struct MyDialog {
  controller: CustomDialogController;  // 框架要求保留
  onClose?: () => void;                // 新增：安全关闭回调
  // ... 其他参数

  build() {
    Column() {
      Button('Done')
        .onClick(() => {
          // 正确：走回调
          this.onClose?.();
          // 错误：this.controller.close(); ← 必崩
        })
    }
  }
}
```

**调用方中** — 使用 `controllerRef` 模式：

```typescript
private showMyDialog(): void {
  let ref: CustomDialogController | undefined = undefined;
  const ctrl = new CustomDialogController({
    builder: MyDialog({
      // ... 其他参数
      onClose: (): void => {
        ref?.close();  // 闭包捕获 ref，打开时才赋值
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  ref = ctrl;   // 必须在 open() 之前赋值
  ctrl.open();
}
```

### 关键点

1. **永远不要**在 @CustomDialog struct 内调用 `this.controller.close()`
2. `ref` 必须在 `new CustomDialogController(...)` 之后、`open()` 之前赋值
3. `onClose` 只在异步回调（用户点击）时触发，此时 `ref` 一定已赋值
4. 使用 `autoCancel: true` 保留点击遮罩关闭行为

---

## 二、AVPlayer 状态机规则

### 必须严格遵守的顺序

```
Idle → Initialized → Prepared → Playing/Paused
         ↑               ↑
    url = "..."     prepare()
```

**不能跳过任何步骤**。

### 本地文件播放

```typescript
// 错误：file:// 协议 → AVPlayer 直接 error
avPlayer.url = 'file://' + localPath;   // ❌

// 正确：fd:// 协议
const file = fileIo.openSync(localPath, fileIo.OpenMode.READ_ONLY);
avPlayer.url = 'fd://' + file.fd.toString();  // ✅

// 停止时关闭 fd
fileIo.closeSync(file.fd);
```

### 后台播放三要素

1. `module.json5`: `"backgroundModes": ["audioPlayback"]`
2. `startContinuousTask`: 申请长时任务
3. `AVSession`: 暴露播放控制给系统和通知栏

**缺任何一个都会被系统杀死**。

---

## 三、大文件下载：request.agent

### 问题

`http.request()` ARRAY_BUFFER 模式有 ~5MB 限制。播客文件通常 30-100MB，会报错 `Response data exceeds maximum limit`。

### 正确方案

```typescript
import { request } from '@kit.BasicServicesKit';

const config: request.agent.Config = {
  action: request.agent.Action.DOWNLOAD,
  url: downloadUrl,
  overwrite: true,
  method: 'GET',
  saveas: './' + fileName,
  mode: request.agent.Mode.FOREGROUND,
  gauge: true  // 启用进度回调
};

const task = await request.agent.create(context, config);
task.on('progress', (progress: request.agent.Progress) => { /* 进度 */ });
task.on('completed', () => { /* 完成 */ });
task.on('failed', () => { /* 失败 */ });
await task.start();
```

### 下载后文件迁移

```typescript
// agent 下载到 cacheDir，需迁移到 filesDir
fileIo.mkdirSync(destDir, true);        // 递归创建目录
fileIo.moveFileSync(cachePath, destPath); // 移动
```

---

## 四、ArkTS 严格模式常见编译错误

| 错误 | 原因 | 修复 |
|------|------|------|
| `arkts-no-obj-literals-as-types` | 回调参数用 `{ key: type }` 字面量 | 定义独立 `class` |
| `any` 类型不允许 | TS 合法但 ArkTS 禁止 | 用具体类型，不确定用 `Object` |
| `as` 类型断言不允许 | TS 合法但 ArkTS 禁止 | 用 `instanceof` 检查 |
| `Cannot find name 'xxx'` | sys.symbol 名称在鸿蒙不存在 | 从已验证清单选取，不猜测 |

---

## 五、已验证 sys.symbol 清单

### 可用（项目中已验证）

`house`, `list_bullet`, `envelope`, `square_grid_2x2`, `line_3_horizontal`, `play_fill`, `pause_fill`, `arrow_down`, `checkmark`, `plus`, `trash`, `magnifyingglass`, `chevron_right`, `chevron_left`, `lock`, `clock`, `gearshape`

### 不可用（编译报错）

`tray_arrow_down` → 替代 `envelope`
`dot_3_horizontal` / `ellipsis` → 替代 `line_3_horizontal`
`chart_bar` → 替代 `square_grid_2x2`
`xmark_circle` → 需实测，不确定

---

## 六、导航架构规则

### Tab 栏必须在 Navigation 外部

```typescript
// 错误：Tab 栏随子页面隐藏
Navigation { Tabs { ... } }   // ❌

// 正确：自定义 Tab 栏在 Navigation 外部
Column {
  Navigation { /* 内容 */ }.layoutWeight(1)
  MiniPlayer
  CustomTabBar (Row)          // ✅ 始终可见
}
```

### NavDestination 参数获取时机

```typescript
// 错误：aboutToAppear 时参数为 undefined
aboutToAppear(): void {
  // ctx.pathInfo.param ← undefined  ❌
}

// 正确：在 onReady 回调中获取
build() {
  NavDestination() {
    // ...
  }
  .onReady((ctx: NavDestinationContext) => {
    if (ctx.pathInfo.param instanceof MyParam) {
      this.myParam = ctx.pathInfo.param;  // ✅
    }
  })
}
```

---

## 七、数据库规范

### INSERT OR REPLACE 会改变自增 ID

```typescript
// 问题：一条 SQL 重写所有字段，id 重新分配
// 解决：两步法
const existingId = await findFeedIdByUrl(url);
if (existingId > 0) {
  await store.update(bucket, predicates);  // 保持原 id
} else {
  await store.insert(TABLE, bucket);       // 新 id
}
```

### ResultSet 必须关闭

```typescript
const rs = await store.querySql(sql, args);
try {
  // 遍历 rs
} finally {
  rs.close();  // 必须 — 否则数据库锁
}
```

---

## 八、常用 Kit 导入速查

| 场景 | 导入 |
|------|------|
| HTTP 请求 | `import { http } from '@kit.NetworkKit'` |
| 文件操作 | `import { fileIo } from '@kit.CoreFileKit'` |
| 数据库 | `import { relationalStore } from '@kit.ArkData'` |
| XML 解析 | `import xml from '@ohos.xml'`（唯一例外，直接用 @ohos） |
| 播放器 | `import { media } from '@kit.MediaKit'` |
| 后台任务 | `import { backgroundTaskManager } from '@kit.BackgroundTasksKit'` |
| 下载 | `import { request } from '@kit.BasicServicesKit'` |
| 剪贴板 | `import { pasteboard } from '@kit.BasicServicesKit'` |
| 通知 | `import { notificationManager } from '@kit.NotificationKit'` |
| 打开链接 | `import { common } from '@kit.AbilityKit'` → `context.openLink(url)` |
| 日志 | `import { hilog } from '@kit.PerformanceAnalysisKit'` |

---

## 九、组件生命周期常用模式

```typescript
@Component
export struct MyComponent {
  private unsubPlayer: (() => void) | undefined;

  aboutToAppear(): void {
    // 初始化数据
    this.loadData();
    // 订阅事件
    this.unsubPlayer = EventBus.getInstance().subscribe(EVENT_XXX, (data) => { ... });
  }

  aboutToDisappear(): void {
    // 取消订阅 — 否则内存泄漏
    if (this.unsubPlayer !== undefined) {
      this.unsubPlayer();
    }
  }
}
```

---

## 十、AppStorage 初始化时序

```typescript
// GlobalState.initAppStorage() 必须在所有 @StorageLink 声明之前执行
// 推荐在 EntryAbility.onCreate() 中最早调用

GlobalState.initAppStorage(context);
// 之后才能安全使用 @StorageLink('key') xxx: type = default
```

---

*Skill 版本：v1.0 | 基于 AntennaPod ArkTS v3 实战沉淀 | 可移植到下个 HarmonyOS 项目*
