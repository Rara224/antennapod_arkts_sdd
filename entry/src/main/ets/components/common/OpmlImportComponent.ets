import { OpmlParser, OpmlFeed } from '../../parser/OpmlParser';
import { FeedUpdateService } from '../../network/FeedUpdateService';
import { FileUtils } from '../../helpers/FileUtils';
import { picker } from '@kit.CoreFileKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'OpmlImport';

@Component
export struct OpmlImportComponent {
  @State feeds: OpmlFeed[] = [];
  @State isLoading: boolean = false;
  @State isImporting: boolean = false;
  @State importProgress: string = '';
  @State filePath: string = '';
  @State importedCount: number = 0;
  @State failedCount: number = 0;

  build() {
    NavDestination() {
      Column() {
        // File picker button
        Button('Select OPML File')
          .width('100%')
          .height(44)
          .margin({ bottom: 16 })
          .enabled(!this.isLoading && !this.isImporting)
          .onClick(() => {
            this.selectFile();
          })

        if (this.filePath.length > 0) {
          Text('File: ' + FileUtils.getFileName(this.filePath))
            .fontSize(12)
            .fontColor('#99000000')
            .margin({ bottom: 12 })
            .width('100%')
        }

        if (this.isLoading) {
          LoadingProgress().width(32).height(32).margin({ top: 16 })
        }

        // Feed list preview
        if (this.feeds.length > 0) {
          Text('Found ' + this.feeds.length.toString() + ' feeds:')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
            .width('100%')

          List() {
            ForEach(this.feeds, (feed: OpmlFeed) => {
              ListItem() {
                Column() {
                  Text(feed.title.length > 0 ? feed.title : feed.xmlUrl)
                    .fontSize(14)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(feed.xmlUrl)
                    .fontSize(11)
                    .fontColor('#99000000')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .padding({ top: 8, bottom: 8 })
              }
            }, (feed: OpmlFeed) => feed.xmlUrl)
          }
          .layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: '#F0F0F0' })

          if (this.importProgress.length > 0) {
            Text(this.importProgress)
              .fontSize(12)
              .fontColor('#007DFF')
              .margin({ top: 8 })
              .width('100%')
          }

          Button(this.isImporting ? 'Importing...' : 'Import All')
            .width('100%')
            .height(44)
            .margin({ top: 16 })
            .enabled(!this.isImporting)
            .onClick(() => {
              this.importAll();
            })
        }
      }
      .padding(16)
      .width('100%')
      .height('100%')
    }
    .title('OPML Import')
  }

  private async selectFile(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const result = await documentPicker.select({
        maxSelectNumber: 1,
        fileSuffixFilters: ['.opml', '.xml']
      });
      if (result.length > 0) {
        this.filePath = result[0];
        this.parseFile(result[0]);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'File picker error: %{public}s', JSON.stringify(e));
    }
  }

  private async parseFile(path: string): Promise<void> {
    this.isLoading = true;
    try {
      const content = await FileUtils.readText(path);
      const parser = new OpmlParser();
      this.feeds = parser.parse(content);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Parse error: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: 'Failed to parse OPML file' });
    } finally {
      this.isLoading = false;
    }
  }

  private async importAll(): Promise<void> {
    this.isImporting = true;
    this.importedCount = 0;
    this.failedCount = 0;
    const service = new FeedUpdateService();

    for (let i = 0; i < this.feeds.length; i++) {
      const feed = this.feeds[i];
      this.importProgress = 'Importing ' + (i + 1).toString() + '/' +
        this.feeds.length.toString() + ': ' + (feed.title.length > 0 ? feed.title : feed.xmlUrl);
      try {
        await service.subscribeFeed(feed.xmlUrl);
        this.importedCount++;
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Failed to import %{public}s: %{public}s',
          feed.xmlUrl, JSON.stringify(e));
        this.failedCount++;
      }
    }

    this.isImporting = false;
    this.importProgress = 'Done: ' + this.importedCount.toString() + ' imported, ' +
      this.failedCount.toString() + ' failed';
    promptAction.showToast({
      message: 'Imported ' + this.importedCount.toString() + ' feeds'
    });
  }
}
