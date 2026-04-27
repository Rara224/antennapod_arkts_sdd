import { SubscriptionViewModel } from '../../viewmodels/SubscriptionViewModel';
import {
  EventBus,
  EVENT_FEED_LIST_CHANGED,
  EVENT_SUBSCRIPTION_ADDED,
  EVENT_SUBSCRIPTION_REMOVED,
  EVENT_FEED_UPDATED
} from '../../common/EventBus';
import { Feed } from '../../models/Feed';
import { FeedDetailParam, RouteName } from '../../common/AppRouter';
import { FeedGridItem } from '../common/FeedGridItem';
import { EmptyStateView } from '../common/EmptyStateView';
import { UserPreferences } from '../../helpers/UserPreferences';
import { FeedDao } from '../../database/FeedDao';
import { promptAction } from '@kit.ArkUI';
import { SortDialog, SortOption } from '../common/SortDialog';

@Component
export struct SubscriptionComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @Prop showBackButton: boolean = false;
  private vm: SubscriptionViewModel = new SubscriptionViewModel();
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State feedCount: number = 0;
  @State deleteFeedId: number = 0;
  @State deleteFeedTitle: string = '';
  @State subscriptionColumns: number = 3;
  @State showSubscriptionTitles: boolean = false;
  @State isSelectMode: boolean = false;
  @State selectedFeedIds: Set<number> = new Set<number>();
  @State showTagSheet: boolean = false;
  @State tagInput: string = '';
  @State selectionVersion: number = 0;
  @State showColumnPicker: boolean = false;
  @State counterMode: number = 0; // 0=inbox, 1=unplayed, 2=downloaded, 3=downloaded+unplayed, 4=none
  @State showCounterDialog: boolean = false;
  @State sortOrder: number = 0; // 0=A-Z, 1=Z-A, 2=Latest, 3=Oldest, 4-7=duration/count
  @State filterArchived: boolean = false;
  private unsubscribers: (() => void)[] = [];

  aboutToAppear(): void {
    const prefs = UserPreferences.getInstance();
    this.subscriptionColumns = prefs.getSubscriptionColumns();
    this.showSubscriptionTitles = prefs.isShowSubscriptionTitles();
    this.loadData();
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_LIST_CHANGED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_SUBSCRIPTION_ADDED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_SUBSCRIPTION_REMOVED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_UPDATED, () => {
      this.loadData();
    }));
  }

  aboutToDisappear(): void {
    for (let i = 0; i < this.unsubscribers.length; i++) {
      this.unsubscribers[i]();
    }
    this.unsubscribers = [];
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadFeeds();
    this.feedCount = this.vm.feedDataSource.totalCount();
    this.isLoading = false;
  }

  private enterSelectMode(feedId: number): void {
    const newSet = new Set<number>();
    newSet.add(feedId);
    this.selectedFeedIds = newSet;
    this.selectionVersion++;
    this.isSelectMode = true;
  }

  private toggleSelection(feedId: number): void {
    const newSet = new Set<number>(this.selectedFeedIds);
    if (newSet.has(feedId)) {
      newSet.delete(feedId);
    } else {
      newSet.add(feedId);
    }
    this.selectedFeedIds = newSet;
    this.selectionVersion++;
    if (newSet.size === 0) {
      this.isSelectMode = false;
    }
  }

  private exitSelectMode(): void {
    this.selectedFeedIds = new Set<number>();
    this.selectionVersion++;
    this.isSelectMode = false;
  }

  private selectAll(): void {
    const allFeeds = this.vm.feedDataSource.getAll();
    const newSet = new Set<number>();
    for (let i = 0; i < allFeeds.length; i++) {
      newSet.add(allFeeds[i].id);
    }
    this.selectedFeedIds = newSet;
    this.selectionVersion++;
  }

  private isFeedSelected(feedId: number): boolean {
    return this.selectedFeedIds.has(feedId);
  }

  private getSelectedIds(): number[] {
    return Array.from(this.selectedFeedIds);
  }

  private showDeleteConfirm(): void {
    const message = this.isSelectMode
      ? 'Remove ' + this.selectedFeedIds.size.toString() + ' selected podcasts and all their episodes?'
      : 'Remove "' + this.deleteFeedTitle + '" and all its episodes?';
    AlertDialog.show({
      title: 'Remove Podcast',
      message: message,
      primaryButton: {
        value: 'Cancel',
        action: () => {
        }
      },
      secondaryButton: {
        value: 'Remove',
        fontColor: '#FF5252',
        action: () => {
          this.confirmDelete();
        }
      }
    });
  }

  private async confirmDelete(): Promise<void> {
    if (this.isSelectMode) {
      await this.vm.deleteFeeds(this.getSelectedIds());
      this.exitSelectMode();
    } else {
      await this.vm.deleteFeed(this.deleteFeedId);
    }
  }

  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    try {
      await this.vm.refreshAllFeeds();
      await this.loadData();
    } catch (e) {
      // Refresh errors are logged by FeedUpdateService
    } finally {
      this.isRefreshing = false;
    }
  }

  private getColumnsTemplate(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.subscriptionColumns; i++) {
      parts.push('1fr');
    }
    return parts.join(' ');
  }

  private cycleColumns(): void {
    let next = this.subscriptionColumns + 1;
    if (next > 5) {
      next = 2;
    }
    this.subscriptionColumns = next;
    UserPreferences.getInstance().setSubscriptionColumns(next);
  }

  private setColumns(cols: number): void {
    this.subscriptionColumns = cols;
    UserPreferences.getInstance().setSubscriptionColumns(cols);
    this.showColumnPicker = false;
  }

  private toggleShowTitles(): void {
    this.showSubscriptionTitles = !this.showSubscriptionTitles;
    UserPreferences.getInstance().setShowSubscriptionTitles(this.showSubscriptionTitles);
  }

  private showFilterDialog(): void {
    AlertDialog.show({
      title: 'Filter',
      message: this.filterArchived ? 'Currently showing archived feeds.' : 'Currently showing subscribed feeds.',
      primaryButton: {
        value: this.filterArchived ? 'Show subscribed' : 'Show archived',
        action: () => {
          this.filterArchived = !this.filterArchived;
          this.loadData();
        }
      },
      secondaryButton: { value: 'Cancel', action: () => {} }
    });
  }

  private sortDialogController: CustomDialogController = new CustomDialogController({
    builder: SortDialog({
      sortOptions: this.buildSortOptions(),
      currentSort: this.sortOrder,
      onSortSelected: (sort: number): void => {
        this.sortOrder = sort;
        this.sortFeeds();
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: false
  });

  private buildSortOptions(): SortOption[] {
    const options: SortOption[] = [];
    const labels: string[] = [
      'A \u2192 Z',
      'Z \u2192 A',
      'Most recent',
      'Oldest first',
      'Duration (longest first)',
      'Duration (shortest first)',
      'Episode count (most first)',
      'Episode count (fewest first)'
    ];
    for (let i = 0; i < labels.length; i++) {
      const opt = new SortOption();
      opt.value = i;
      opt.label = labels[i];
      options.push(opt);
    }
    return options;
  }

  private showSortDialog(): void {
    this.sortDialogController.open();
  }

  private sortFeeds(): void {
    const feeds = this.vm.feedDataSource.getAll();
    if (this.sortOrder === 0) {
      feeds.sort((a: Feed, b: Feed) => a.getDisplayTitle().localeCompare(b.getDisplayTitle()));
    } else if (this.sortOrder === 1) {
      feeds.sort((a: Feed, b: Feed) => b.getDisplayTitle().localeCompare(a.getDisplayTitle()));
    } else if (this.sortOrder === 2) {
      feeds.sort((a: Feed, b: Feed) => b.lastRefreshAttempt - a.lastRefreshAttempt);
    } else if (this.sortOrder === 3) {
      feeds.sort((a: Feed, b: Feed) => a.lastRefreshAttempt - b.lastRefreshAttempt);
    } else if (this.sortOrder === 4) {
      feeds.sort((a: Feed, b: Feed) => b.totalDuration - a.totalDuration);
    } else if (this.sortOrder === 5) {
      feeds.sort((a: Feed, b: Feed) => a.totalDuration - b.totalDuration);
    } else if (this.sortOrder === 6) {
      feeds.sort((a: Feed, b: Feed) => b.episodeCount - a.episodeCount);
    } else if (this.sortOrder === 7) {
      feeds.sort((a: Feed, b: Feed) => a.episodeCount - b.episodeCount);
    }
    this.vm.feedDataSource.reloadAll(feeds);
    this.feedCount = feeds.length;
  }

  private async archiveSelectedFeeds(): Promise<void> {
    const feeds = this.vm.feedDataSource.getAll();
    const feedDao = new FeedDao();
    for (let i = 0; i < feeds.length; i++) {
      const feed = feeds[i];
      if (feed.state === 1) {
        feed.state = 2; // ARCHIVED
        await feedDao.setFeed(feed);
      }
    }
    await this.loadData();
    promptAction.showToast({ message: 'Feeds archived' });
  }

  @Builder
  counterRadioRow(label: string, value: number) {
    Row() {
      Radio({ value: label, group: 'counter' })
        .checked(this.counterMode === value)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.counterMode = value;
            this.showCounterDialog = false;
          }
        })
        .margin({ right: 12 })
      Text(label)
        .fontSize(15)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 10, bottom: 10 })
    .onClick(() => {
      this.counterMode = value;
      this.showCounterDialog = false;
    })
  }

  @Builder
  columnRadioRow(label: string, value: number) {
    Row() {
      Text(label)
        .fontSize(16)
        .layoutWeight(1)
      Radio({ value: label, group: 'columns' })
        .checked(this.subscriptionColumns === value)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.setColumns(value);
          }
        })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 12, bottom: 12 })
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
    Column() {
      // Title bar
      if (this.isSelectMode) {
        Row() {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(24)
            .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            .onClick(() => {
              this.exitSelectMode();
            })
            .margin({ right: 12 })

          Text(this.selectedFeedIds.size.toString() + '/' + this.feedCount.toString() + ' selected')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          Text('\u22EE')
            .fontSize(22)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .bindMenu([
              {
                value: 'Select all',
                action: () => {
                  this.selectAll();
                }
              }
            ])
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
      } else {
        Row() {
          if (this.showBackButton) {
            SymbolGlyph($r('sys.symbol.arrow_left'))
              .fontSize(22)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
              .margin({ right: 12 })
              .onClick(() => {
                this.navPathStack.pop();
              })
          }
          Text('Subscriptions')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(22)
            .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            .margin({ right: 16 })
            .onClick(() => {
              this.navPathStack.pushPathByName(RouteName.SEARCH, new Object());
            })

          Text('\u22EE')
            .fontSize(22)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .bindMenu([
              {
                value: 'Filter',
                action: () => {
                  this.showFilterDialog();
                }
              },
              {
                value: 'Sort',
                action: () => {
                  this.showSortDialog();
                }
              },
              {
                value: this.counterMode < 4 ? 'Counter  \u2611' : 'Counter  \u2610',
                action: () => {
                  this.showCounterDialog = true;
                }
              },
              {
                value: 'Number of columns  >',
                action: () => {
                  this.showColumnPicker = true;
                }
              },
              {
                value: this.showSubscriptionTitles ? 'Show titles  \u2611' : 'Show titles  \u2610',
                action: () => {
                  this.toggleShowTitles();
                }
              },
              {
                value: 'Archive',
                action: () => {
                  this.archiveSelectedFeeds();
                }
              },
              {
                value: 'Refresh',
                action: () => {
                  this.onRefresh();
                }
              }
            ])
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
      }

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.feedCount === 0) {
        // Empty state with FAB (matching Android)
        Stack({ alignContent: Alignment.BottomEnd }) {
          Column() {
            Blank().layoutWeight(1)

            SymbolGlyph($r('sys.symbol.square_grid_2x2'))
              .fontSize(36)
              .fontColor(['#333333'])

            Text('No subscriptions')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 12 })
              .textAlign(TextAlign.Center)

            Text('To subscribe to a podcast, press the plus icon below.')
              .fontSize(14)
              .fontColor('#99000000')
              .margin({ top: 8 })
              .textAlign(TextAlign.Center)
              .padding({ left: 32, right: 32 })

            Blank().layoutWeight(2)
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)

          // FAB + button
          Column() {
            Text('+')
              .fontSize(28)
              .fontColor('#333333')
          }
          .width(56)
          .height(56)
          .borderRadius(16)
          .backgroundColor('#D6E4FF')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: 16, bottom: 16 })
          .shadow({ radius: 4, color: '#33000000', offsetY: 2 })
          .onClick(() => {
            this.navPathStack.pushPathByName(RouteName.ADD_FEED, new Object());
          })
        }
        .layoutWeight(1)
        .width('100%')
      } else {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Refresh({ refreshing: $$this.isRefreshing }) {
            Grid() {
              LazyForEach(this.vm.feedDataSource,
                (feed: Feed) => {
                  GridItem() {
                    FeedGridItem({
                      feedTitle: feed.getDisplayTitle(),
                      episodeCount: this.counterMode < 4 ? feed.items.length : 0,
                      imageUrl: feed.imageUrl,
                      showTitle: this.showSubscriptionTitles || this.counterMode < 4,
                      isSelected: this.isFeedSelected(feed.id)
                    })
                  }
                  .onClick(() => {
                    if (this.isSelectMode) {
                      this.toggleSelection(feed.id);
                    } else {
                      const param = new FeedDetailParam();
                      param.feedId = feed.id;
                      this.navPathStack.pushPathByName(RouteName.FEED_DETAIL, param);
                    }
                  })
                  .priorityGesture(
                    LongPressGesture()
                      .onAction(() => {
                        if (!this.isSelectMode) {
                          this.enterSelectMode(feed.id);
                        }
                      })
                  )
                },
                (feed: Feed) => feed.id.toString() + '_' + feed.state.toString() +
                  '_' + (this.isFeedSelected(feed.id) ? '1' : '0') + '_' + this.selectionVersion.toString()
              )
            }
            .columnsTemplate(this.getColumnsTemplate())
            .columnsGap(4)
            .rowsGap(8)
            .padding({ left: 8, right: 8, top: 8 })
            .layoutWeight(1)
            .width('100%')
          }
          .onRefreshing(() => {
            this.onRefresh();
          })

          if (this.isSelectMode) {
            // Bottom action bar
            Row() {
              Column() {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(22)
                  .fontColor(['#007DFF'])
                Text('Edit tags')
                  .fontSize(11)
                  .fontColor('#007DFF')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.tagInput = '';
                this.showTagSheet = true;
              })

              Column() {
                SymbolGlyph($r('sys.symbol.arrow_right'))
                  .fontSize(22)
                  .fontColor(['#007DFF'])
                Text('Share')
                  .fontSize(11)
                  .fontColor('#007DFF')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)

              Column() {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(22)
                  .fontColor(['#007DFF'])
                Text('Remove inbox')
                  .fontSize(11)
                  .fontColor('#007DFF')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .onClick(async () => {
                await this.vm.removeFromInboxForFeeds(this.getSelectedIds());
                this.exitSelectMode();
              })

              Column() {
                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(22)
                  .fontColor(['#FF5252'])
                Text('Unsubscribe')
                  .fontSize(11)
                  .fontColor('#FF5252')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.showDeleteConfirm();
              })
            }
            .width('100%')
            .height(64)
            .backgroundColor(Color.White)
            .shadow({ radius: 8, color: '#20000000', offsetY: -2 })
          } else {
            // FAB "+" button
            Button('+')
              .width(56)
              .height(56)
              .fontSize(28)
              .fontColor('#333333')
              .backgroundColor('#D8E8F0')
              .borderRadius(16)
              .shadow({ radius: 6, color: '#30000000', offsetY: 2 })
              .margin({ right: 16, bottom: 16 })
              .onClick(() => {
                this.navPathStack.pushPathByName(RouteName.ADD_FEED, new Object());
              })
          }
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showTagSheet, this.editTagSheet(), {
      height: SheetSize.FIT_CONTENT,
      showClose: true
    })

    // Column picker overlay — top-end position like Android submenu
    if (this.showColumnPicker) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000000')
        .onClick(() => {
          this.showColumnPicker = false;
        })

      Column() {
        Text('Number of columns')
          .fontSize(15)
          .fontColor('#99000000')
          .padding({ left: 24, top: 14, bottom: 8 })
          .width('100%')

        this.columnRadioRow('List', 1)
        this.columnRadioRow('2', 2)
        this.columnRadioRow('3', 3)
        this.columnRadioRow('4', 4)
        this.columnRadioRow('5', 5)
      }
      .width(220)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .shadow({ radius: 12, color: '#30000000', offsetY: 2 })
      .padding({ bottom: 4 })
      .margin({ top: 56, right: 8 })
    }

    // Counter picker overlay (matching Android radio dialog)
    if (this.showCounterDialog) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showCounterDialog = false;
        })

      Column() {
        Text('Counter')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 24, top: 16, bottom: 12 })
          .width('100%')

        this.counterRadioRow('Number of episodes in the inbox', 0)
        this.counterRadioRow('Number of unplayed episodes', 1)
        this.counterRadioRow('Number of downloaded episodes', 2)
        this.counterRadioRow('Number of downloaded and unplayed episodes', 3)
        this.counterRadioRow('None', 4)

        Row() {
          Blank()
          Text('Cancel')
            .fontSize(14)
            .fontColor('#007DFF')
            .padding({ right: 24, top: 8, bottom: 16 })
            .onClick(() => {
              this.showCounterDialog = false;
            })
        }
        .width('100%')
      }
      .width('85%')
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 16, color: '#30000000', offsetY: 4 })
    }
    }
    .width('100%')
    .height('100%')
    .alignContent(this.showCounterDialog ? Alignment.Center : Alignment.TopEnd)
  }

  @Builder
  editTagSheet() {
    Column() {
      Text('Edit Tags')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      TextInput({ placeholder: 'Enter tag name', text: this.tagInput })
        .onChange((value: string) => {
          this.tagInput = value;
        })
        .width('100%')
        .margin({ bottom: 16 })

      Button('Add Tag')
        .fontSize(14)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .width('100%')
        .onClick(async () => {
          const trimmed = this.tagInput.trim();
          if (trimmed.length > 0) {
            await this.vm.updateTagsForFeeds(this.getSelectedIds(), trimmed);
            this.showTagSheet = false;
            this.exitSelectMode();
          }
        })
    }
    .padding(24)
    .width('100%')
  }
}
