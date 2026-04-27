# Fix Experience Log

> Entries are appended automatically by `/fix-issue close`. Universal entries are fed back into Skills via `/skill-optimizer`.

| Issue | Page | Category | Root Cause | Solution | Universal? | Target Skill | Date |
|-------|------|----------|------------|----------|------------|-------------|------|
| #1 | Full Player | UI display issue | overflow 菜单用 showActionMenu 底部弹窗且重复了顶栏已有的 Sleep Timer/Share；feedId 和 feedLink 未暴露到 AppStorage | 改用 .bindMenu() 下拉菜单，只保留 Open podcast 和 Visit website；在 PlaybackController 中同步 feedId/feedLink 到 AppStorage | Yes | arkts-component-builder | 2026-03-23 |
