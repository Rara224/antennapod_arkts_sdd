import { SearchViewModel } from '../../viewmodels/SearchViewModel';
import { FeedItem } from '../../models/FeedItem';
import { EpisodeDetailParam, RouteName } from '../../common/AppRouter';
import { EpisodeListItem } from '../common/EpisodeListItem';
import { EmptyStateView } from '../common/EmptyStateView';

@Component
export struct SearchComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  private vm: SearchViewModel = new SearchViewModel();
  @State searchText: string = '';
  @State resultCount: number = 0;
  @State isSearching: boolean = false;

  private async doSearch(): Promise<void> {
    this.isSearching = true;
    await this.vm.search(this.searchText);
    this.resultCount = this.vm.resultCount;
    this.isSearching = false;
  }

  build() {
    NavDestination() {
      Column() {
        Search({ value: this.searchText, placeholder: 'Search episodes...' })
          .width('100%')
          .margin({ top: 8 })
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchText = value;
          })
          .onSubmit(() => {
            this.doSearch();
          })

        if (this.isSearching) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else if (this.searchText.length > 0 && this.resultCount === 0) {
          EmptyStateView({
            icon: '\uD83D\uDD0D',
            message: 'No results found'
          })
        } else if (this.resultCount > 0) {
          Text(this.resultCount.toString() + ' results')
            .fontSize(14)
            .fontColor('#99000000')
            .margin({ top: 8, left: 16 })

          List() {
            LazyForEach(this.vm.searchResultsDataSource,
              (item: FeedItem) => {
                ListItem() {
                  EpisodeListItem({
                    title: item.title,
                    feedTitle: item.feed !== null ? item.feed.getDisplayTitle() : '',
                    pubDate: item.getPubDateStr(),
                    durationStr: item.media !== null ? item.media.getDurationStr() : '',
                    isNew: item.isNew(),
                    isPlayed: item.isPlayed(),
                    isDownloaded: item.media !== null ? item.media.isDownloaded() : false,
                    showFeedTitle: true,
                    hasProgress: false,
                    progressPercent: 0,
                    imageUrl: item.getImageLocation()
                  })
                }
                .onClick(() => {
                  const param = new EpisodeDetailParam();
                  param.episodeId = item.id;
                  param.feedId = item.feedId;
                  this.navPathStack.pushPathByName(RouteName.EPISODE_DETAIL, param);
                })
              },
              (item: FeedItem) => item.id.toString()
            )
          }
          .layoutWeight(1)
          .width('100%')
          .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 76, endMargin: 16 })
        } else {
          EmptyStateView({
            icon: '\uD83D\uDD0D',
            message: 'Search your episodes'
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('Search')
  }
}
