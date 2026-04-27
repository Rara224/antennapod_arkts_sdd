import { QueueViewModel } from '../../viewmodels/QueueViewModel';
import {
  EventBus,
  EVENT_QUEUE_CHANGED,
  EVENT_EPISODE_DOWNLOADED,
  EVENT_EPISODE_PLAY_STATE_CHANGED
} from '../../common/EventBus';
import { FeedItem } from '../../models/FeedItem';
import { EpisodeDetailParam, RouteName } from '../../common/AppRouter';
import { EmptyStateView } from '../common/EmptyStateView';
import { UserPreferences } from '../../helpers/UserPreferences';
import { PlaybackController } from '../../playback/PlaybackController';
import { DownloadManager } from '../../network/DownloadManager';

@Component
export struct QueueComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @Prop showBackButton: boolean = false;
  private vm: QueueViewModel = new QueueViewModel();
  @State queueSize: number = 0;
  @State durationStr: string = '';
  @State isLoading: boolean = true;
  @State dragIndex: number = -1;
  @State isQueueLocked: boolean = false;
  @StorageLink('isPlaying') isPlaying: boolean = false;
  @StorageLink('currentEpisodeId') currentEpisodeId: number = 0;
  private unsubscribers: (() => void)[] = [];

  aboutToAppear(): void {
    this.isQueueLocked = UserPreferences.getInstance().isQueueLocked();
    this.loadData();
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_QUEUE_CHANGED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_DOWNLOADED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_PLAY_STATE_CHANGED, () => {
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
    await this.vm.loadQueue();
    this.queueSize = this.vm.queueSize;
    this.durationStr = this.vm.getDurationStr();
    this.isLoading = false;
  }

  private async removeItem(itemId: number): Promise<void> {
    await this.vm.removeFromQueue(itemId);
    this.queueSize = this.vm.queueSize;
    this.durationStr = this.vm.getDurationStr();
  }

  private async clearQueue(): Promise<void> {
    const allItems = this.vm.queueDataSource.getAll();
    for (let i = allItems.length - 1; i >= 0; i--) {
      await this.vm.removeFromQueue(allItems[i].id);
    }
    this.queueSize = 0;
    this.durationStr = '';
  }

  private toggleLockQueue(): void {
    this.isQueueLocked = !this.isQueueLocked;
    UserPreferences.getInstance().setQueueLocked(this.isQueueLocked);
  }

  private getProgressPercent(item: FeedItem): number {
    if (item.media !== null && item.media.duration > 0 && item.media.position > 0) {
      return Math.round(item.media.position * 100 / item.media.duration);
    }
    return 0;
  }

  @Builder
  queueItem(item: FeedItem) {
    Row() {
      // Drag handle
      if (!this.isQueueLocked) {
        Column() {
          Circle().width(4).height(4).fill('#99000000')
          Circle().width(4).height(4).fill('#99000000').margin({ top: 3 })
          Circle().width(4).height(4).fill('#99000000').margin({ top: 3 })
        }
        .margin({ left: 12, right: 4 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // Cover image
      if (item.getImageLocation().length > 0) {
        Image(item.getImageLocation())
          .width(56)
          .height(56)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .margin({ left: this.isQueueLocked ? 16 : 0, right: 12 })
      } else {
        Column() {
          Text(item.feed !== null && item.feed.getDisplayTitle().length > 0 ?
            item.feed.getDisplayTitle().charAt(0).toUpperCase() : '?')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(56)
        .height(56)
        .borderRadius(6)
        .backgroundColor('#BDBDBD')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: this.isQueueLocked ? 16 : 0, right: 12 })
      }

      // Content
      Column() {
        // Meta row: date · size
        Row() {
          Text(item.getShortPubDateStr())
            .fontSize(12)
            .fontColor('#99000000')
          if (item.media !== null && item.media.getSizeStr().length > 0) {
            Text(' \u00B7 ' + item.media.getSizeStr())
              .fontSize(12)
              .fontColor('#99000000')
          }
        }

        // Title
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
          .width('100%')

        // Duration / progress
        if (item.media !== null && item.media.position > 0 && item.media.duration > 0) {
          Row() {
            Text(item.media.getPositionStr())
              .fontSize(11)
              .fontColor('#007DFF')
            Progress({
              value: this.getProgressPercent(item),
              total: 100,
              type: ProgressType.Linear
            })
              .layoutWeight(1)
              .height(3)
              .margin({ left: 6, right: 6 })
              .color('#007DFF')
              .backgroundColor('#E0E0E0')
            Text(item.media.getDurationStr())
              .fontSize(11)
              .fontColor('#99000000')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 4 })
        } else if (item.media !== null) {
          Text(item.media.getDurationStr())
            .fontSize(12)
            .fontColor('#99000000')
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // Play/Pause or Download button based on download and playback status
      Column() {
        if (item.media !== null && item.media.isDownloaded()) {
          SymbolGlyph(this.isPlaying && this.currentEpisodeId === item.id ?
            $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
            .fontSize(18)
            .fontColor(['#333333'])
        } else {
          Image($r('app.media.ic_download'))
            .width(20)
            .height(20)
            .fillColor('#333333')
        }
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor('#333333')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ left: 8, right: 16 })
      .onClick(() => {
        if (item.media !== null && item.media.isDownloaded()) {
          if (this.isPlaying && this.currentEpisodeId === item.id) {
            PlaybackController.getInstance().pause();
          } else {
            PlaybackController.getInstance().playEpisode(item.id);
          }
        } else if (item.media !== null && item.media.downloadUrl.length > 0) {
          DownloadManager.getInstance().downloadEpisode(
            item.id, item.media.downloadUrl, item.media.mimeType);
        }
      })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  deleteButton(item: FeedItem) {
    Row() {
      Button('Remove')
        .fontSize(14)
        .backgroundColor('#FF5252')
        .fontColor(Color.White)
        .height('100%')
        .onClick(() => {
          this.removeItem(item.id);
        })
    }
    .height('100%')
    .padding({ left: 4, right: 4 })
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      // Title bar with overflow menu (matching Android)
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
        Column() {
          Text('Queue')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          Text(this.queueSize.toString() + ' episodes')
            .fontSize(12)
            .fontColor('#99000000')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

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
              value: 'Sort',
              action: () => {
              }
            },
            {
              value: 'Clear queue',
              action: () => {
                this.clearQueue();
              }
            },
            {
              value: 'Refresh',
              action: () => {
                this.loadData();
              }
            },
            {
              value: this.isQueueLocked ? 'Lock queue  \u2611' : 'Lock queue  \u2610',
              action: () => {
                this.toggleLockQueue();
              }
            }
          ])
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.queueSize === 0) {
        // Empty state (matching Android)
        Column() {
          Blank().layoutWeight(1)

          // Queue/playlist icon (matching Android ≡▶ style)
          Text('\u2630\u25B6')
            .fontSize(36)
            .fontColor('#333333')

          Text('No queued episodes')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)

          Text('Add an episode by downloading it, or long press an episode and select "Add to queue".')
            .fontSize(14)
            .fontColor('#99000000')
            .margin({ top: 8 })
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })

          Blank().layoutWeight(2)
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      } else {
        // Queue header with count and duration
        Row() {
          Text(this.queueSize.toString() + ' episodes')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          if (this.durationStr.length > 0) {
            Text(' \u00B7 ' + this.durationStr)
              .fontSize(14)
              .fontColor('#99000000')
          }
          if (this.isQueueLocked) {
            SymbolGlyph($r('sys.symbol.lock'))
              .fontSize(14)
              .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        List() {
          LazyForEach(this.vm.queueDataSource,
            (item: FeedItem, index: number) => {
              ListItem() {
                this.queueItem(item)
              }
              .swipeAction({ end: this.deleteButton(item) })
              .onClick(() => {
                const param = new EpisodeDetailParam();
                param.episodeId = item.id;
                param.feedId = item.feedId;
                this.navPathStack.pushPathByName(RouteName.EPISODE_DETAIL, param);
              })
            },
            (item: FeedItem) => item.id.toString() + '_' + item.state.toString()
          )
        }
        .layoutWeight(1)
        .width('100%')
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 76, endMargin: 16 })
        .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
          if (this.isQueueLocked) {
            return;
          }
          this.dragIndex = itemIndex;
        })
        .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
          if (isSuccess && this.dragIndex >= 0 && this.dragIndex !== insertIndex) {
            this.vm.moveInQueue(this.dragIndex, insertIndex);
          }
          this.dragIndex = -1;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
