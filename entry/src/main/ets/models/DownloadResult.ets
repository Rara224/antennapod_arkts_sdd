import { DOWNLOAD_ERROR_SUCCESS, FEED_FILE_FEED } from '../common/Constants';

/**
 * Represents a download log entry.
 */
export class DownloadResult {
  id: number = 0;
  title: string = '';
  feedfileId: number = 0;
  /** Feed=0, FeedMedia=2 */
  feedfileType: number = FEED_FILE_FEED;
  /** DownloadError code */
  reason: number = DOWNLOAD_ERROR_SUCCESS;
  reasonDetailed: string = '';
  successful: boolean = false;
  /** Completion timestamp in milliseconds */
  completionDate: number = 0;

  constructor(title: string = '', feedfileId: number = 0, feedfileType: number = FEED_FILE_FEED,
    successful: boolean = false, reason: number = DOWNLOAD_ERROR_SUCCESS,
    reasonDetailed: string = '') {
    this.title = title;
    this.feedfileId = feedfileId;
    this.feedfileType = feedfileType;
    this.successful = successful;
    this.reason = reason;
    this.reasonDetailed = reasonDetailed;
    this.completionDate = Date.now();
  }
}
