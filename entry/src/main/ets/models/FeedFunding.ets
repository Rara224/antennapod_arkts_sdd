/**
 * Represents a podcast funding link (podcast:funding tag).
 */
export class FeedFunding {
  url: string = '';
  content: string = '';

  constructor(url: string = '', content: string = '') {
    this.url = url;
    this.content = content;
  }
}
