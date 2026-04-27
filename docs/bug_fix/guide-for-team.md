/Users/chenjiamin/arkTs/antennapod_arkts/docs/bug_fix/guide-for-team.md# 团队 Bug 报告提交指南

## 如何提交 Bug 报告

### 第一步：打开 Issue 页面

进入：**GitHub 仓库 → Issues → New issue → 选择 "Bug Report"**

### 第二步：填写表单

| 字段 | 是否必填 | 填写建议 |
|------|---------|---------|
| **Page Location（页面位置）** | 必填 | 下拉选择 bug 出现的页面。列表里没有的话选 "Other" |
| **Page Location (if Other)** | 选了 Other 时填 | 补充说明具体页面，例如 "通知面板"、"Widget" 等 |
| **Bug Category（问题分类）** | 必填 | 下拉选择最相关的分类。列表里没有的话选 "Other" |
| **Bug Category (if Other)** | 选了 Other 时填 | 补充说明具体分类，例如 "同步问题"、"权限问题" 等 |
| **Actual Behavior（实际行为）** | 必填 | 描述你观察到的现象，越具体越好 |
| **Expected Behavior（期望行为）** | 必填 | 描述正确的行为应该是什么 |
| **Steps to Reproduce（复现步骤）** | 必填 | 触发 bug 的最少步骤。步骤越少，修复越快 |
| **Screenshots（截图）** | 强烈建议 | UI 问题必须附截图。可直接拖拽图片上传 |
| **Android Reference（Android 对照截图）** | 建议 | 如果是"和 Android 不一致"的问题，请贴上 Android 和鸿蒙的对比截图 |
| **Error Log（错误日志）** | 有则必填 | 从 DevEco Studio LogCat 复制，按 `AntennaPod` 关键字过滤 |
| **Device Type（设备类型）** | 必填 | 下拉选择设备。列表里没有的话选 "Other" |
| **Device Type (if Other)** | 选了 Other 时填 | 补充说明具体设备型号，例如 "Huawei Nova 12" 等 |
| **API Version（API 版本）** | 选填 | 例如 API 12 |

### 第三步：提交

点击 "Submit new issue"。修复 PR 创建后你会收到通知。

---

## 好的 Bug 报告示例

**标题**: `[Bug] Feed Detail 页面 — 三点菜单只显示 "Edit feed URL"`

**Page Location**: Feed Detail

**Bug Category**: UI display issue

**Actual Behavior（实际行为）**:
Feed Detail 页面的三点菜单只有一个选项 "Edit feed URL"。

**Expected Behavior（期望行为）**:
应该和 Android 一致，显示 6 个选项：Sort、Refresh、Visit website、Share、Remove all from inbox、Unsubscribe/archive。

**Steps to Reproduce（复现步骤）**:
1. 打开应用 → 进入 Subscriptions
2. 点击任意一个播客
3. 点击右上角三点菜单 (⋮)
4. 只显示了 "Edit feed URL"

**Screenshots（截图）**:
（粘贴 Android 和鸿蒙的对比截图）

---

## 常见填写误区

| 错误做法 | 正确做法 |
|---------|---------|
| "不能用了" | 具体描述发生了什么、你期望的是什么 |
| UI bug 没有截图 | 务必附截图——一图胜千言 |
| 没写复现步骤 | 写出不了解这个 bug 的人也能按步骤复现的操作 |
| 一个 issue 里报多个 bug | 一个 issue 只报一个 bug——方便追踪和修复 |

---

## 如何验证修复

当你在 issue 上收到修复通知后：

1. 拉取修复分支：
   ```bash
   git fetch origin
   git checkout fix/issue-<N>    # 把 <N> 替换成 issue 编号
   ```
2. 在 DevEco Studio 中打开项目
3. 构建并在你的设备/模拟器上运行
4. 按照 issue 评论中的测试步骤进行验证
5. 在 issue 上回复：
   - 修复成功：评论 **"Verified"**
   - 仍有问题：**在 issue 评论中描述还有什么问题**（附截图更佳），负责人会基于你的反馈继续修复
6. 如果继续修复了新一轮，你会再次收到通知，重复上述验证步骤，直到问题完全解决

---

## Issue 状态说明

| 状态 | 含义 |
|------|------|
| `open` | 已提交，等待处理 |
| `in progress` | 修复中——会关联 PR |
| `closed` | 已修复并验证通过 |

## 查看修复报告

每个 issue 修复完成后，完整的修复报告（根因分析、修复方案、修改文件）会归档到仓库的 `issue/issue-<N>.md` 文件中，可随时查阅。
