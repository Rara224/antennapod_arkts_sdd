import { FeedInfoParam, RouteName } from '../../common/AppRouter';
import { FeedDao } from '../../database/FeedDao';
import { FeedMediaDao } from '../../database/FeedMediaDao';
import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

@Component
export struct FeedInfoComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @State feedId: number = 0;
  @State feedTitle: string = '';
  @State author: string = '';
  @State description: string = '';
  @State feedUrl: string = '';
  @State imageUrl: string = '';
  @State isLoading: boolean = true;
  @State playedHoursStr: string = '0 hours';
  @State startedEpisodes: number = 0;
  @State storageSizeStr: string = '0 MB';
  private feedDao: FeedDao = new FeedDao();
  private feedMediaDao: FeedMediaDao = new FeedMediaDao();

  private async loadData(): Promise<void> {
    this.isLoading = true;
    const feed = await this.feedDao.getFeed(this.feedId);
    if (feed !== null) {
      this.feedTitle = feed.getDisplayTitle();
      this.author = feed.author;
      this.description = feed.description;
      this.feedUrl = feed.downloadUrl;
      this.imageUrl = feed.imageUrl;
    }

    // Load statistics
    const playedMs = await this.feedMediaDao.getFeedPlayedDuration(this.feedId);
    this.playedHoursStr = this.formatHours(playedMs);
    this.startedEpisodes = await this.feedMediaDao.getFeedStartedEpisodeCount(this.feedId);
    const storageBytes = await this.feedMediaDao.getFeedStorageSize(this.feedId);
    this.storageSizeStr = this.formatBytes(storageBytes);

    this.isLoading = false;
  }

  // Format as "X.X hours" (matching Android)
  private formatHours(ms: number): string {
    if (ms <= 0) {
      return '0 hours';
    }
    const hours = ms / 3600000;
    if (hours < 0.1) {
      return '0 hours';
    }
    if (hours < 1) {
      return hours.toFixed(1) + ' hours';
    }
    if (hours >= 10) {
      return Math.round(hours).toString() + ' hours';
    }
    return hours.toFixed(1) + ' hours';
  }

  private formatBytes(bytes: number): string {
    if (bytes <= 0) {
      return '0 MB';
    }
    if (bytes < 1024 * 1024) {
      return Math.round(bytes / 1024).toString() + ' KB';
    }
    return Math.round(bytes / (1024 * 1024)).toString() + ' MB';
  }

  private copyToClipboard(text: string): void {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    const sysBoard = pasteboard.getSystemPasteboard();
    sysBoard.setData(pasteData);
    promptAction.showToast({ message: 'Copied to clipboard' });
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else {
          Scroll() {
            Column() {
              // Dark header: blurred background + cover left + title right (matching Android)
              Stack() {
                if (this.imageUrl.length > 0) {
                  Image(this.imageUrl)
                    .width('100%')
                    .height('100%')
                    .objectFit(ImageFit.Cover)
                    .blur(60)
                } else {
                  Column()
                    .width('100%')
                    .height('100%')
                    .backgroundColor('#37474F')
                }

                Column()
                  .width('100%')
                  .height('100%')
                  .backgroundColor('#66000000')

                // Content: top bar + cover/title row
                Column() {
                  // Top bar: back + globe + share + more
                  Row() {
                    SymbolGlyph($r('sys.symbol.arrow_left'))
                      .fontSize(22)
                      .fontColor([Color.White])
                      .width(40)
                      .height(40)
                      .onClick(() => {
                        this.navPathStack.pop();
                      })

                    Blank()

                    Image($r('app.media.ic_share_white'))
                      .width(22)
                      .height(22)
                      .margin({ right: 8 })

                    Text('\u22EE')
                      .fontSize(24)
                      .fontColor(Color.White)
                      .width(40)
                      .height(40)
                      .textAlign(TextAlign.Center)
                  }
                  .width('100%')
                  .padding({ left: 4, right: 4 })

                  // Cover image + title/author (horizontal, matching Android)
                  Row() {
                    if (this.imageUrl.length > 0) {
                      Image(this.imageUrl)
                        .width(110)
                        .height(110)
                        .borderRadius(12)
                        .objectFit(ImageFit.Cover)
                    } else {
                      Column() {
                        Text(this.feedTitle.length > 0 ? this.feedTitle.charAt(0).toUpperCase() : '?')
                          .fontSize(48)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.White)
                      }
                      .width(130)
                      .height(130)
                      .borderRadius(12)
                      .backgroundColor('#78909C')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                    }

                    Column() {
                      Text(this.feedTitle)
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.White)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      if (this.author.length > 0) {
                        Text(this.author)
                          .fontSize(14)
                          .fontColor('#CCFFFFFF')
                          .margin({ top: 4 })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 16 })
                    .justifyContent(FlexAlign.Center)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, bottom: 12 })
                }
                .width('100%')
                .height('100%')
              }
              .width('100%')
              .height(190)

              // Statistics section (matching Android)
              Row() {
                Text('Statistics')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                Blank()
                Text('All podcasts \u00BB')
                  .fontSize(14)
                  .fontColor('#1565C0')
                  .onClick(() => {
                    this.navPathStack.pushPathByName(RouteName.STATISTICS, new Object());
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 20, bottom: 8 })

              // Stats cards grid — row 1 (matching Android card layout)
              Row() {
                // Played hours
                Column() {
                  Text(this.playedHoursStr)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text('played')
                    .fontSize(12)
                    .fontColor('#99000000')
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding(12)
                .borderRadius(8)
                .backgroundColor('#F5F5F5')

                Column()
                  .width(8)

                // Started episodes
                Column() {
                  Text(this.startedEpisodes.toString() + ' episodes')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text('started')
                    .fontSize(12)
                    .fontColor('#99000000')
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding(12)
                .borderRadius(8)
                .backgroundColor('#F5F5F5')

                Column()
                  .width(8)

                // Storage size
                Column() {
                  Text(this.storageSizeStr)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text('space taken')
                    .fontSize(12)
                    .fontColor('#99000000')
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding(12)
                .borderRadius(8)
                .backgroundColor('#F5F5F5')
              }
              .width('100%')
              .padding({ left: 16, right: 16 })

              // Description section (matching Android)
              if (this.description.length > 0) {
                Text('Description')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .padding({ left: 16, right: 16, top: 20, bottom: 8 })
                  .width('100%')

                Text(this.description)
                  .fontSize(14)
                  .fontColor('#CC000000')
                  .lineHeight(22)
                  .padding({ left: 16, right: 16, bottom: 16 })
                  .width('100%')
              }

              // URL section (matching Android)
              if (this.feedUrl.length > 0) {
                Text('URL')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .padding({ left: 16, right: 16, top: 12, bottom: 4 })
                  .width('100%')

                Row() {
                  Text(this.feedUrl)
                    .fontSize(13)
                    .fontColor('#CC000000')
                    .layoutWeight(1)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text('\u2398')
                    .fontSize(20)
                    .fontColor('#007DFF')
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.copyToClipboard(this.feedUrl);
                    })
                }
                .width('100%')
                .padding({ left: 16, right: 8, bottom: 16 })
                .alignItems(VerticalAlign.Center)
              }
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
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      if (ctx.pathInfo.param instanceof FeedInfoParam) {
        const p: FeedInfoParam = ctx.pathInfo.param;
        this.feedId = p.feedId;
        this.loadData();
      }
    })
  }
}
