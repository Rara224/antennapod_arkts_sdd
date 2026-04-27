import { FeedItem } from './FeedItem';

/**
 * Represents the media file associated with a podcast episode.
 */
export class FeedMedia {
  id: number = 0;
  localFileUrl: string = '';
  downloadUrl: string = '';
  /** Download timestamp in ms */
  downloadDate: number = 0;
  /** Duration in ms */
  duration: number = 0;
  /** Current playback position in ms */
  position: number = 0;
  lastPlayedTimeStatistics: number = 0;
  /** Played duration in ms */
  playedDuration: number = 0;
  /** File size in bytes */
  size: number = 0;
  mimeType: string = '';
  item: FeedItem | null = null;
  itemId: number = 0;
  lastPlayedTimeHistory: number = 0;
  hasEmbeddedPicture: boolean = false;
  startPosition: number = 0;
  playedDurationWhenStarted: number = 0;

  isDownloaded(): boolean {
    return this.localFileUrl.length > 0;
  }

  getDurationStr(): string {
    if (this.duration <= 0) {
      return '--:--';
    }
    const totalSeconds = Math.floor(this.duration / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    if (hours > 0) {
      return pad(hours) + ':' + pad(minutes) + ':' + pad(seconds);
    }
    return pad(minutes) + ':' + pad(seconds);
  }

  getSizeStr(): string {
    if (this.size <= 0) {
      return '';
    }
    if (this.size < 1024 * 1024) {
      return Math.round(this.size / 1024).toString() + ' KB';
    }
    return Math.round(this.size / (1024 * 1024)).toString() + ' MB';
  }

  getPositionStr(): string {
    if (this.position <= 0) {
      return '00:00';
    }
    const totalSeconds = Math.floor(this.position / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    if (hours > 0) {
      return pad(hours) + ':' + pad(minutes) + ':' + pad(seconds);
    }
    return pad(minutes) + ':' + pad(seconds);
  }
}
