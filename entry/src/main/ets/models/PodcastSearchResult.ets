export class PodcastSearchResult {
  title: string = '';
  author: string = '';
  feedUrl: string = '';
  artworkUrl: string = '';
  description: string = '';

  constructor(title: string, author: string, feedUrl: string, artworkUrl: string, description: string) {
    this.title = title;
    this.author = author;
    this.feedUrl = feedUrl;
    this.artworkUrl = artworkUrl;
    this.description = description;
  }
}
