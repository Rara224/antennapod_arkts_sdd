import { request } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FeedMediaDao } from '../database/FeedMediaDao';
import { FeedItemDao } from '../database/FeedItemDao';
import { DownloadLogDao } from '../database/DownloadLogDao';
import { FileUtils } from '../helpers/FileUtils';
import { GlobalState } from '../common/GlobalState';
import {
  EventBus,
  EVENT_DOWNLOAD_PROGRESS,
  EVENT_EPISODE_DOWNLOADED,
  EVENT_DOWNLOAD_FAILED,
  EVENT_DOWNLOAD_LOG
} from '../common/EventBus';
import { DownloadResult } from '../models/DownloadResult';
import { DownloadProgressData, DownloadFailedData, DownloadLogData } from '../common/EventData';
import {
  DOWNLOAD_ERROR_CONNECTION,
  DOWNLOAD_ERROR_HTTP_DATA,
  DOWNLOAD_ERROR_SUCCESS,
  DOWNLOAD_ERROR_UNAUTHORIZED,
  FEED_FILE_FEED_MEDIA
} from '../common/Constants';

const DOMAIN: number = 0x0000;
const TAG: string = 'DownloadManager';

export class DownloadManager {
  private static instance: DownloadManager | undefined = undefined;
  private activeDownloads: Set<number> = new Set();
  private activeTasks: Map<number, request.agent.Task> = new Map();
  private mediaDao: FeedMediaDao = new FeedMediaDao();
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private downloadLogDao: DownloadLogDao = new DownloadLogDao();

  private constructor() {
  }

  static getInstance(): DownloadManager {
    if (DownloadManager.instance === undefined) {
      DownloadManager.instance = new DownloadManager();
    }
    return DownloadManager.instance;
  }

  async downloadEpisode(itemId: number, downloadUrl: string, mimeType: string): Promise<void> {
    if (this.activeDownloads.has(itemId)) {
      hilog.warn(DOMAIN, TAG, 'Download already in progress for item %{public}d', itemId);
      return;
    }

    const dir = GlobalState.downloadDir;
    await FileUtils.ensureDirectory(dir);

    const ext = DownloadManager.getExtension(mimeType, downloadUrl);
    const fileName = 'episode_' + itemId.toString() + '.' + ext;
    const destPath = dir + '/' + fileName;

    // URL 中的 &amp; 需要还原为 &
    const cleanUrl = downloadUrl.replace(/&amp;/g, '&');

    hilog.info(DOMAIN, TAG, 'Starting download item %{public}d -> %{public}s', itemId, destPath);
    hilog.info(DOMAIN, TAG, 'Download URL: %{public}s', cleanUrl.substring(0, 120));

    this.activeDownloads.add(itemId);
    EventBus.getInstance().publish(EVENT_DOWNLOAD_PROGRESS,
      new DownloadProgressData(itemId, 0));

    try {
      const context = GlobalState.getContext();
      const agentConfig: request.agent.Config = {
        action: request.agent.Action.DOWNLOAD,
        url: cleanUrl,
        overwrite: true,
        method: 'GET',
        saveas: './' + fileName,
        mode: request.agent.Mode.FOREGROUND,
        gauge: true
      };

      const task = await request.agent.create(context, agentConfig);
      this.activeTasks.set(itemId, task);

      task.on('progress', (progress: request.agent.Progress) => {
        if (progress.sizes.length >= 2) {
          const received = progress.sizes[0];
          const total = progress.sizes[1];
          if (total > 0) {
            const percent = Math.floor(received * 100 / total);
            EventBus.getInstance().publish(EVENT_DOWNLOAD_PROGRESS,
              new DownloadProgressData(itemId, percent));
          }
        }
      });

      task.on('completed', (_progress: request.agent.Progress) => {
        hilog.info(DOMAIN, TAG, 'Agent download completed for item %{public}d', itemId);
        this.activeTasks.delete(itemId);
        this.finalizeDownload(itemId, fileName, destPath);
      });

      task.on('failed', (_progress: request.agent.Progress) => {
        hilog.error(DOMAIN, TAG, 'Agent download failed for item %{public}d', itemId);
        this.activeTasks.delete(itemId);
        this.failDownload(itemId, DOWNLOAD_ERROR_CONNECTION, 'Agent download failed', destPath);
      });

      await task.start();
      hilog.info(DOMAIN, TAG, 'Agent task started for item %{public}d', itemId);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to create agent task for item %{public}d: %{public}s',
        itemId, JSON.stringify(e));
      this.activeTasks.delete(itemId);
      await this.failDownload(itemId, DOWNLOAD_ERROR_CONNECTION, JSON.stringify(e), destPath);
    }
  }

  private async finalizeDownload(itemId: number, fileName: string, _destPath: string): Promise<void> {
    // agent API 下载到 cacheDir，直接使用 cache 路径作为本地文件
    const filePath = GlobalState.cacheDir + '/' + fileName;
    try {
      hilog.info(DOMAIN, TAG, 'Finalizing item %{public}d at: %{public}s', itemId, filePath);

      // 验证文件
      let finalSize: number = 0;
      try {
        const stat = fileIo.statSync(filePath);
        finalSize = stat.size;
        hilog.info(DOMAIN, TAG, 'File size: %{public}d', finalSize);
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'File not found: %{public}s', filePath);
        await this.failDownload(itemId, DOWNLOAD_ERROR_HTTP_DATA, 'File not found', filePath);
        return;
      }

      if (finalSize === 0) {
        await this.failDownload(itemId, DOWNLOAD_ERROR_HTTP_DATA, 'Empty file', filePath);
        return;
      }

      // 尝试移到 downloads 目录，失败则就地使用 cache 路径
      let finalPath = filePath;
      try {
        const dir = GlobalState.downloadDir;
        fileIo.mkdirSync(dir, true);
        const destPath = dir + '/' + fileName;
        fileIo.moveFileSync(filePath, destPath);
        finalPath = destPath;
        hilog.info(DOMAIN, TAG, 'Moved to: %{public}s', destPath);
      } catch (moveErr) {
        hilog.warn(DOMAIN, TAG, 'Move failed, using cache path: %{public}s', JSON.stringify(moveErr));
      }

      // 更新数据库
      const media = await this.mediaDao.getFeedMediaByItemId(itemId);
      if (media !== null) {
        media.localFileUrl = finalPath;
        media.downloadDate = Date.now();
        media.size = finalSize;
        await this.mediaDao.setFeedMedia(media);
        hilog.info(DOMAIN, TAG, 'DB updated for item %{public}d, path=%{public}s', itemId, finalPath);
      }

      await this.completeDownload(itemId);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'finalizeDownload error: %{public}s', JSON.stringify(e));
      await this.failDownload(itemId, DOWNLOAD_ERROR_HTTP_DATA, JSON.stringify(e), filePath);
    }
  }

  cancelDownload(itemId: number): void {
    const task = this.activeTasks.get(itemId);
    if (task !== undefined) {
      task.stop().then(() => {
        hilog.info(DOMAIN, TAG, 'Download stopped for item %{public}d', itemId);
      }).catch((e: Error) => {
        hilog.warn(DOMAIN, TAG, 'Stop failed for item %{public}d: %{public}s', itemId, e.message);
      });
      this.activeTasks.delete(itemId);
    }
    this.clearTracking(itemId);
    hilog.info(DOMAIN, TAG, 'Cancellation requested for item %{public}d', itemId);
  }

  async deleteDownload(itemId: number): Promise<void> {
    const media = await this.mediaDao.getFeedMediaByItemId(itemId);
    if (media !== null && media.localFileUrl.length > 0) {
      try {
        fileIo.unlinkSync(media.localFileUrl);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'File not found when deleting: %{public}s', media.localFileUrl);
      }
      media.localFileUrl = '';
      media.downloadDate = 0;
      await this.mediaDao.setFeedMedia(media);
      hilog.info(DOMAIN, TAG, 'Deleted download for item %{public}d', itemId);
    }
  }

  isDownloading(itemId: number): boolean {
    return this.activeDownloads.has(itemId);
  }

  private static getExtension(mimeType: string, url: string): string {
    const lowerMimeType = mimeType.toLowerCase();
    if (lowerMimeType.indexOf('mp3') >= 0 || lowerMimeType.indexOf('mpeg') >= 0) {
      return 'mp3';
    }
    if (lowerMimeType.indexOf('video/mp4') >= 0) {
      return 'mp4';
    }
    if (lowerMimeType.indexOf('mp4') >= 0 || lowerMimeType.indexOf('m4a') >= 0) {
      return 'm4a';
    }
    if (lowerMimeType.indexOf('ogg') >= 0) {
      return 'ogg';
    }
    if (lowerMimeType.indexOf('opus') >= 0) {
      return 'opus';
    }
    if (lowerMimeType.indexOf('aac') >= 0) {
      return 'aac';
    }
    const urlExt = FileUtils.getExtension(url.split('?')[0]).toLowerCase();
    if (urlExt.length > 0 && urlExt.length <= 5) {
      return urlExt;
    }
    return 'mp3';
  }

  private async completeDownload(itemId: number): Promise<void> {
    this.clearTracking(itemId);
    EventBus.getInstance().publish(EVENT_DOWNLOAD_PROGRESS,
      new DownloadProgressData(itemId, 100));
    await this.writeDownloadLog(itemId, true, DOWNLOAD_ERROR_SUCCESS, '');
    const logData = new DownloadLogData(itemId, true);
    EventBus.getInstance().publish(EVENT_EPISODE_DOWNLOADED, logData);
    EventBus.getInstance().publish(EVENT_DOWNLOAD_LOG, logData);
  }

  private async failDownload(
    itemId: number,
    errorCode: number,
    reasonDetailed: string,
    destPath: string
  ): Promise<void> {
    await this.removeIncompleteFile(destPath);
    this.clearTracking(itemId);
    await this.writeDownloadLog(itemId, false, errorCode, reasonDetailed);
    EventBus.getInstance().publish(EVENT_DOWNLOAD_FAILED,
      new DownloadFailedData(itemId, errorCode));
  }

  private clearTracking(itemId: number): void {
    this.activeDownloads.delete(itemId);
    this.activeTasks.delete(itemId);
  }

  private async removeIncompleteFile(destPath: string): Promise<void> {
    if (await FileUtils.exists(destPath)) {
      await FileUtils.deleteFile(destPath);
    }
  }

  private async writeDownloadLog(
    itemId: number,
    successful: boolean,
    reason: number,
    reasonDetailed: string
  ): Promise<void> {
    try {
      const item = await this.feedItemDao.getFeedItem(itemId);
      const media = await this.mediaDao.getFeedMediaByItemId(itemId);
      const result = new DownloadResult(
        item !== null ? item.title : '',
        media !== null ? media.id : itemId,
        FEED_FILE_FEED_MEDIA,
        successful,
        reason,
        reasonDetailed
      );
      await this.downloadLogDao.addDownloadLog(result);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Failed to write download log for item %{public}d: %{public}s',
        itemId, JSON.stringify(e));
    }
  }

  private static mapHttpError(statusCode: number): number {
    if (statusCode === 401 || statusCode === 403) {
      return DOWNLOAD_ERROR_UNAUTHORIZED;
    }
    return DOWNLOAD_ERROR_HTTP_DATA;
  }
}
