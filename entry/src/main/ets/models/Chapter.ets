/**
 * Represents a chapter mark within a podcast episode.
 */
export class Chapter {
  id: number = 0;
  /** Chapter start time in milliseconds */
  start: number = 0;
  title: string = '';
  link: string = '';
  imageUrl: string = '';
  chapterId: string = '';

  constructor(start: number = 0, title: string = '', link: string = '', imageUrl: string = '') {
    this.start = start;
    this.title = title;
    this.link = link;
    this.imageUrl = imageUrl;
  }
}
