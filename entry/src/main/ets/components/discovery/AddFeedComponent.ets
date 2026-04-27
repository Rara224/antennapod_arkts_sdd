import { OnlineFeedViewParam, OpmlImportParam, SearchPodcastsParam, RouteName } from '../../common/AppRouter';
import { PodcastSearcher } from '../../network/PodcastSearcher';
import { PodcastSearchResult } from '../../models/PodcastSearchResult';
import { FeedUpdateService } from '../../network/FeedUpdateService';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { FeedDao } from '../../database/FeedDao';
import { FeedItemDao } from '../../database/FeedItemDao';
import { FeedMediaDao } from '../../database/FeedMediaDao';
import { Feed } from '../../models/Feed';
import { FeedItem } from '../../models/FeedItem';
import { FeedMedia } from '../../models/FeedMedia';

@Component
export struct AddFeedComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @State searchQuery: string = '';
  @State searchResults: PodcastSearchResult[] = [];
  @State isSearching: boolean = false;
  @State suggestions: PodcastSearchResult[] = [];
  @State showRssDialog: boolean = false;
  @State rssUrl: string = '';
  @State isSubscribing: boolean = false;
  @State isLoadingSuggestions: boolean = false;
  @State searchProvider: number = 0; // 0=Apple Podcasts, 1=fyyd, 2=Podcast Index
  private feedUpdateService: FeedUpdateService = new FeedUpdateService();
  private debounceTimerId: number = -1;

  aboutToAppear(): void {
    this.loadSuggestions();
  }

  private async loadSuggestions(): Promise<void> {
    this.isLoadingSuggestions = true;
    try {
      // Load top podcasts from Apple iTunes Top Podcasts API
      this.suggestions = await PodcastSearcher.getTopPodcasts('us', 25);
      hilog.info(0x0000, 'AddFeed', 'Top podcasts loaded: %{public}d', this.suggestions.length);
    } catch (e) {
      hilog.warn(0x0000, 'AddFeed', 'Top podcasts API failed: %{public}s, falling back to search',
        JSON.stringify(e));
      // Fallback: use search API
      try {
        this.suggestions = await PodcastSearcher.search('top podcasts');
      } catch (_e2) {
        this.suggestions = [];
      }
    } finally {
      this.isLoadingSuggestions = false;
    }
  }

  private debounceSearch(): void {
    if (this.debounceTimerId !== -1) {
      clearTimeout(this.debounceTimerId);
    }
    if (this.searchQuery.trim().length === 0) {
      this.searchResults = [];
      return;
    }
    this.debounceTimerId = setTimeout(() => {
      this.performSearch();
    }, 500);
  }

  private async performSearch(): Promise<void> {
    const query = this.searchQuery.trim();
    if (query.length === 0) {
      return;
    }
    this.isSearching = true;
    try {
      if (this.searchProvider === 1) {
        this.searchResults = await PodcastSearcher.searchFyyd(query);
      } else if (this.searchProvider === 2) {
        this.searchResults = await PodcastSearcher.searchPodcastIndex(query);
      } else {
        this.searchResults = await PodcastSearcher.search(query);
      }
    } catch (_e) {
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  private getSearchPlaceholder(): string {
    if (this.searchProvider === 1) {
      return 'Search fyyd...';
    } else if (this.searchProvider === 2) {
      return 'Search Podcast Index...';
    }
    return 'Search podcast...';
  }

  private async subscribeByUrl(): Promise<void> {
    let url = this.rssUrl.trim();
    if (url.length === 0) {
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }
    this.isSubscribing = true;
    try {
      await this.feedUpdateService.subscribeFeed(url);
      promptAction.showToast({ message: 'Subscribed successfully!' });
      this.showRssDialog = false;
      this.rssUrl = '';
      this.navPathStack.pop();
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Failed to subscribe';
      promptAction.showToast({ message: msg });
    } finally {
      this.isSubscribing = false;
    }
  }

  private async navigateToFeed(feedUrl: string): Promise<void> {
    let resolvedUrl = feedUrl;
    // If feedUrl is an iTunes ID reference, resolve it to real RSS feed URL
    if (feedUrl.startsWith('itunes:')) {
      const itunesId = feedUrl.substring(7);
      try {
        promptAction.showToast({ message: 'Loading...' });
        resolvedUrl = await PodcastSearcher.resolveItunesFeedUrl(itunesId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : 'Failed to resolve feed URL';
        promptAction.showToast({ message: msg });
        return;
      }
    }
    const param = new OnlineFeedViewParam();
    param.feedUrl = resolvedUrl;
    this.navPathStack.pushPathByName(RouteName.ONLINE_FEED_VIEW, param);
  }

  private async addLocalFolder(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker(getContext(this));
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 100;
      options.fileSuffixFilters = ['.mp3', '.m4a', '.ogg', '.wav', '.flac', '.opus', '.aac'];
      const uris = await documentPicker.select(options);
      if (uris.length === 0) {
        return;
      }

      // Create a local feed
      const feedDao = new FeedDao();
      const feedItemDao = new FeedItemDao();
      const feedMediaDao = new FeedMediaDao();

      const feed = new Feed();
      feed.feedTitle = 'Local Folder';
      feed.downloadUrl = 'local-folder://' + Date.now().toString();
      feed.type = 'local';
      const feedId = await feedDao.setFeed(feed);

      // Create feed items for each selected audio file
      let addedCount = 0;
      for (let i = 0; i < uris.length; i++) {
        const uri = uris[i];
        const fileName = this.extractFileName(uri);

        const item = new FeedItem();
        item.title = fileName;
        item.feedId = feedId;
        item.pubDate = Date.now();
        const itemId = await feedItemDao.setFeedItem(item);

        const media = new FeedMedia();
        media.itemId = itemId;
        media.localFileUrl = uri;
        media.downloadUrl = uri;
        media.mimeType = 'audio/mpeg';
        await feedMediaDao.setFeedMedia(media);
        addedCount++;
      }

      promptAction.showToast({
        message: 'Added ' + addedCount.toString() + ' episodes from local files'
      });
      this.navPathStack.pop();
    } catch (e) {
      hilog.error(0x0000, 'AddFeed', 'addLocalFolder failed: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: 'Failed to add local files' });
    }
  }

  private extractFileName(uri: string): string {
    const parts = uri.split('/');
    let name = parts[parts.length - 1];
    // Remove file extension
    const dotIndex = name.lastIndexOf('.');
    if (dotIndex > 0) {
      name = name.substring(0, dotIndex);
    }
    // Decode URI encoding
    try {
      name = decodeURIComponent(name);
    } catch (_e) {
      // Keep as-is
    }
    return name;
  }

  @Builder
  menuItem(icon: Resource, title: string) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ right: 16 })

      Text(title)
        .fontSize(16)
        .fontColor('#333333')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // Search bar (matching Android — inline search, no separate button)
          Row() {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(18)
              .fontColor(['#99000000'])
              .margin({ right: 8 })
            TextInput({ placeholder: this.getSearchPlaceholder(), text: this.searchQuery })
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .fontSize(15)
              .onChange((value: string) => {
                this.searchQuery = value;
                this.debounceSearch();
              })
              .onSubmit(() => {
                this.performSearch();
              })
          }
          .width('100%')
          .height(44)
          .borderRadius(22)
          .backgroundColor('#F0F0F0')
          .padding({ left: 16, right: 16 })
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })

          if (this.isSearching) {
            LoadingProgress()
              .width(28)
              .height(28)
              .margin({ top: 8 })
          }

          // Content: search results OR discovery page
          if (this.searchResults.length > 0) {
            // Search results list
            List() {
              ForEach(this.searchResults, (result: PodcastSearchResult) => {
                ListItem() {
                  Row() {
                    if (result.artworkUrl.length > 0) {
                      Image(result.artworkUrl)
                        .width(48)
                        .height(48)
                        .borderRadius(6)
                        .objectFit(ImageFit.Cover)
                        .margin({ right: 12 })
                    } else {
                      Column() {
                        Text('\uD83C\uDFA7')
                          .fontSize(22)
                      }
                      .width(48)
                      .height(48)
                      .borderRadius(6)
                      .backgroundColor('#F5F5F5')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .margin({ right: 12 })
                    }

                    Column() {
                      Text(result.title)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                      Text(result.author)
                        .fontSize(13)
                        .fontColor('#99000000')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 2 })
                        .width('100%')
                    }
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                }
                .onClick(() => {
                  const param = new OnlineFeedViewParam();
                  param.feedUrl = result.feedUrl;
                  this.navPathStack.pushPathByName(RouteName.ONLINE_FEED_VIEW, param);
                })
              }, (result: PodcastSearchResult) => result.feedUrl)
            }
            .layoutWeight(1)
            .width('100%')
            .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 76, endMargin: 16 })
          } else {
            // Discovery page (matching Android)
            Scroll() {
              Column() {
                // Suggestions grid (4-column grid of podcast covers)
                if (this.isLoadingSuggestions) {
                  Column() {
                    LoadingProgress()
                      .width(36)
                      .height(36)
                  }
                  .width('100%')
                  .height(120)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                }

                if (this.suggestions.length > 0) {
                  Grid() {
                    ForEach(this.suggestions.slice(0, 12), (result: PodcastSearchResult) => {
                      GridItem() {
                        if (result.artworkUrl.length > 0) {
                          Image(result.artworkUrl)
                            .width('100%')
                            .aspectRatio(1)
                            .borderRadius(8)
                            .objectFit(ImageFit.Cover)
                        } else {
                          Column() {
                            Text(result.title.length > 0 ? result.title.charAt(0) : '?')
                              .fontSize(24)
                              .fontWeight(FontWeight.Bold)
                              .fontColor(Color.White)
                          }
                          .width('100%')
                          .aspectRatio(1)
                          .borderRadius(8)
                          .backgroundColor('#BDBDBD')
                          .justifyContent(FlexAlign.Center)
                          .alignItems(HorizontalAlign.Center)
                        }
                      }
                      .onClick(async () => {
                        await this.navigateToFeed(result.feedUrl);
                      })
                    }, (result: PodcastSearchResult) => 'sug_' + result.feedUrl)
                  }
                  .columnsTemplate('1fr 1fr 1fr 1fr')
                  .columnsGap(8)
                  .rowsGap(8)
                  .padding({ left: 16, right: 16, top: 8 })
                  .width('100%')

                  // "Suggestions by Apple Podcasts" + "Discover more »"
                  Row() {
                    Text('Suggestions by Apple Podcasts')
                      .fontSize(12)
                      .fontColor('#99000000')
                      .layoutWeight(1)
                    Text('Discover more \u00BB')
                      .fontSize(13)
                      .fontColor('#1565C0')
                      .onClick(() => {
                        this.searchQuery = 'top podcasts';
                        this.performSearch();
                      })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 8 })
                }

                // Menu items (matching Android exactly)
                Row() {
                  Image($r('app.media.ic_feed')).width(24).height(24).margin({ right: 16 })
                  Text('Add podcast by RSS address').fontSize(16).fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  this.showRssDialog = true;
                })

                Row() {
                  Image($r('app.media.ic_folder')).width(24).height(24).margin({ right: 16 })
                  Text('Add local folder').fontSize(16).fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  this.addLocalFolder();
                })

                Row() {
                  Image($r('app.media.ic_search')).width(24).height(24).margin({ right: 16 })
                  Text('Search Apple Podcasts').fontSize(16).fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  const p = new SearchPodcastsParam();
                  p.provider = 0;
                  this.navPathStack.pushPathByName(RouteName.SEARCH_PODCASTS, p);
                })

                Row() {
                  Image($r('app.media.ic_search')).width(24).height(24).margin({ right: 16 })
                  Text('Search fyyd').fontSize(16).fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  const p = new SearchPodcastsParam();
                  p.provider = 1;
                  this.navPathStack.pushPathByName(RouteName.SEARCH_PODCASTS, p);
                })

                Row() {
                  Image($r('app.media.ic_search')).width(24).height(24).margin({ right: 16 })
                  Text('Search Podcast Index').fontSize(16).fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  const p = new SearchPodcastsParam();
                  p.provider = 2;
                  this.navPathStack.pushPathByName(RouteName.SEARCH_PODCASTS, p);
                })

                Row() {
                  Image($r('app.media.ic_download')).width(24).height(24).margin({ right: 16 })
                  Text('Import podcast list (OPML)').fontSize(16).fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  this.navPathStack.pushPathByName(RouteName.OPML_IMPORT, new OpmlImportParam());
                })

              }
              .width('100%')
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')

        // RSS URL bottom dialog
        if (this.showRssDialog) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#40000000')
            .onClick(() => {
              this.showRssDialog = false;
            })

          Column() {
            Text('Add podcast by RSS address')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 16 })

            TextInput({ placeholder: 'Enter RSS feed URL', text: this.rssUrl })
              .width('100%')
              .height(48)
              .onChange((value: string) => {
                this.rssUrl = value;
              })

            Row() {
              Text('Cancel')
                .fontSize(16)
                .fontColor('#1565C0')
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .height(44)
                .onClick(() => {
                  this.showRssDialog = false;
                })

              Text(this.isSubscribing ? 'Subscribing...' : 'Subscribe')
                .fontSize(16)
                .fontColor(this.rssUrl.trim().length > 0 ? '#1565C0' : '#99000000')
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .height(44)
                .onClick(() => {
                  if (this.rssUrl.trim().length > 0 && !this.isSubscribing) {
                    this.subscribeByUrl();
                  }
                })
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .shadow({ radius: 8, color: '#33000000', offsetY: -2 })
        }
      }
    }
    .title('Add podcast')
  }
}
