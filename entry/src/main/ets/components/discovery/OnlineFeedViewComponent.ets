import { OnlineFeedViewParam } from '../../common/AppRouter';
import { OnlineFeedViewModel } from '../../viewmodels/OnlineFeedViewModel';
import { FeedItem } from '../../models/FeedItem';
import { promptAction } from '@kit.ArkUI';

@Component
export struct OnlineFeedViewComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  private vm: OnlineFeedViewModel = new OnlineFeedViewModel();
  @State feedUrl: string = '';
  @State feedTitle: string = '';
  @State feedAuthor: string = '';
  @State feedDescription: string = '';
  @State feedImageUrl: string = '';
  @State previewItems: FeedItem[] = [];
  @State isSubscribed: boolean = false;
  @State isLoading: boolean = true;
  @State isSubscribing: boolean = false;
  @State errorMessage: string = '';

  private async loadFeed(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadFeed(this.feedUrl);
    if (this.vm.feed !== null) {
      this.feedTitle = this.vm.feed.feedTitle;
      this.feedAuthor = this.vm.feed.author;
      this.feedDescription = this.vm.feed.description;
      this.feedImageUrl = this.vm.feed.imageUrl;
      this.previewItems = this.vm.previewItems;
    }
    this.isSubscribed = this.vm.isSubscribed;
    this.errorMessage = this.vm.errorMessage;
    this.isLoading = this.vm.isLoading;
  }

  private async onSubscribe(): Promise<void> {
    this.isSubscribing = true;
    try {
      await this.vm.subscribe(this.feedUrl);
      this.isSubscribed = true;
      promptAction.showToast({ message: 'Subscribed successfully!' });
    } catch (e) {
      if (e instanceof Error) {
        this.errorMessage = e.message;
      } else {
        this.errorMessage = 'Failed to subscribe';
      }
    } finally {
      this.isSubscribing = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40)
            Text('Loading feed...')
              .fontSize(14)
              .fontColor('#99000000')
              .margin({ top: 12 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else if (this.errorMessage.length > 0) {
          Column() {
            Text('\u26A0')
              .fontSize(48)
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#FF5252')
              .margin({ top: 12 })
              .textAlign(TextAlign.Center)
              .padding({ left: 24, right: 24 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else {
          Scroll() {
            Column() {
              // Feed header
              Row() {
                if (this.feedImageUrl.length > 0) {
                  Image(this.feedImageUrl)
                    .width(80)
                    .height(80)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                    .margin({ right: 16 })
                }

                Column() {
                  Text(this.feedTitle)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  if (this.feedAuthor.length > 0) {
                    Text(this.feedAuthor)
                      .fontSize(14)
                      .fontColor('#99000000')
                      .margin({ top: 4 })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 12 })

              // Subscribe button
              Button(this.isSubscribed ? 'Subscribed' : (this.isSubscribing ? 'Subscribing...' : 'Subscribe'))
                .width('90%')
                .height(44)
                .enabled(!this.isSubscribed && !this.isSubscribing)
                .backgroundColor(this.isSubscribed ? '#E0E0E0' : '#FF8C00')
                .fontColor(this.isSubscribed ? '#666666' : Color.White)
                .margin({ bottom: 12 })
                .onClick(() => {
                  this.onSubscribe();
                })

              // Description
              if (this.feedDescription.length > 0) {
                Text(this.feedDescription)
                  .fontSize(14)
                  .fontColor('#666666')
                  .padding({ left: 16, right: 16 })
                  .maxLines(5)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
              }

              Divider().margin({ top: 16, bottom: 8 }).color('#F0F0F0')

              // Episodes preview
              Text('Episodes (' + this.previewItems.length.toString() + ')')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .padding({ left: 16, right: 16 })
                .margin({ bottom: 8 })
                .width('100%')

              ForEach(this.previewItems, (item: FeedItem) => {
                Column() {
                  Text(item.title)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Row() {
                    Text(item.getPubDateStr())
                      .fontSize(12)
                      .fontColor('#99000000')
                    if (item.media !== null) {
                      Text(' \u00B7 ' + item.media.getDurationStr())
                        .fontSize(12)
                        .fontColor('#99000000')
                    }
                  }
                  .margin({ top: 4 })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderWidth({ bottom: 0.5 })
                .borderColor('#F0F0F0')
              }, (item: FeedItem) => item.itemIdentifier)
            }
            .width('100%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('Online Feed')
    .onReady((ctx: NavDestinationContext) => {
      if (ctx.pathInfo.param instanceof OnlineFeedViewParam) {
        const p: OnlineFeedViewParam = ctx.pathInfo.param;
        this.feedUrl = p.feedUrl;
        this.loadFeed();
      }
    })
  }
}
