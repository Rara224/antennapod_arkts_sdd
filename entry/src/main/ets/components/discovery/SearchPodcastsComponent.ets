import { OnlineFeedViewParam, SearchPodcastsParam, RouteName } from '../../common/AppRouter';
import { PodcastSearcher } from '../../network/PodcastSearcher';
import { PodcastSearchResult } from '../../models/PodcastSearchResult';
import { promptAction } from '@kit.ArkUI';

@Component
export struct SearchPodcastsComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @State searchQuery: string = '';
  @State searchResults: PodcastSearchResult[] = [];
  @State isSearching: boolean = false;
  @State provider: number = 0;
  private navContext: NavDestinationContext | undefined = undefined;

  private getTitle(): string {
    if (this.provider === 1) {
      return 'Search fyyd';
    } else if (this.provider === 2) {
      return 'Search Podcast Index';
    }
    return 'Search Apple Podcasts';
  }

  private getPlaceholder(): string {
    if (this.provider === 1) {
      return 'Search fyyd...';
    } else if (this.provider === 2) {
      return 'Search Podcast Index...';
    }
    return 'Search Apple Podcasts...';
  }

  private async performSearch(): Promise<void> {
    const query = this.searchQuery.trim();
    if (query.length === 0) {
      return;
    }
    this.isSearching = true;
    try {
      if (this.provider === 1) {
        this.searchResults = await PodcastSearcher.searchFyyd(query);
      } else if (this.provider === 2) {
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

  private async navigateToFeed(feedUrl: string): Promise<void> {
    let resolvedUrl = feedUrl;
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

  build() {
    NavDestination() {
      Column() {
        Search({ value: this.searchQuery, placeholder: this.getPlaceholder() })
          .width('100%')
          .height(44)
          .margin({ top: 8, bottom: 8 })
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchQuery = value;
          })
          .onSubmit(() => {
            this.performSearch();
          })

        if (this.isSearching) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else if (this.searchResults.length > 0) {
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
                      Text('\uD83C\uDFA7').fontSize(22)
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
                this.navigateToFeed(result.feedUrl);
              })
            }, (result: PodcastSearchResult) => result.feedUrl)
          }
          .layoutWeight(1)
          .width('100%')
          .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 76, endMargin: 16 })
        } else {
          Column() {
            Text('\uD83D\uDD0D').fontSize(48).margin({ bottom: 12 })
            Text('Search for podcasts').fontSize(16).fontColor('#99000000')
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
    }
    .title(this.getTitle())
    .onReady((ctx: NavDestinationContext) => {
      this.navContext = ctx;
      if (ctx.pathInfo.param instanceof SearchPodcastsParam) {
        this.provider = ctx.pathInfo.param.provider;
      }
    })
  }
}
