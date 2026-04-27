// 章节选择弹窗：读取ChapterDao展示列表，点击跳转播放位置
import { Chapter } from '../../models/Chapter';
import { ChapterDao } from '../../database/ChapterDao';
import { PlaybackController } from '../../playback/PlaybackController';

@CustomDialog
export struct ChaptersDialog {
  controller: CustomDialogController;
  onClose?: () => void;
  episodeId: number = -1;
  playbackPosition: number = 0;
  @State chapters: Chapter[] = [];
  @State loading: boolean = true;
  private chapterDao: ChapterDao = new ChapterDao();
  private playbackCtrl: PlaybackController = PlaybackController.getInstance();

  aboutToAppear(): void {
    this.loadChapters();
  }

  async loadChapters(): Promise<void> {
    this.loading = true;
    if (this.episodeId > 0) {
      this.chapters = await this.chapterDao.getChapters(this.episodeId);
    }
    this.loading = false;
  }

  private formatTime(ms: number): string {
    if (ms <= 0) {
      return '00:00';
    }
    const totalSeconds = Math.floor(ms / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    if (hours > 0) {
      return pad(hours) + ':' + pad(minutes) + ':' + pad(seconds);
    }
    return pad(minutes) + ':' + pad(seconds);
  }

  private isCurrentChapter(chapter: Chapter): boolean {
    if (this.chapters.length === 0) {
      return false;
    }
    for (let i = 0; i < this.chapters.length; i++) {
      const nextStart = (i + 1 < this.chapters.length) ? this.chapters[i + 1].start : Number.MAX_VALUE;
      if (this.playbackPosition >= this.chapters[i].start && this.playbackPosition < nextStart) {
        return this.chapters[i].id === chapter.id;
      }
    }
    return false;
  }

  private onChapterTap(chapter: Chapter): void {
    this.playbackCtrl.seekTo(chapter.start);
    this.onClose?.();
  }

  build() {
    Column() {
      Row() {
        Text('Chapters')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('Close')
          .fontSize(16)
          .fontColor('#1565C0')
          .onClick(() => {
            this.onClose?.();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 12 })

      Divider().strokeWidth(0.5).color('#E0E0E0')

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#999999')
          Text('Loading chapters...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.chapters.length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.list_bullet'))
            .fontSize(40)
            .fontColor(['#CCCCCC'])
          Text('No chapters')
            .fontSize(15)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.chapters, (chapter: Chapter, index: number) => {
            ListItem() {
              Row() {
                Text(this.formatTime(chapter.start))
                  .fontSize(13)
                  .fontColor(this.isCurrentChapter(chapter) ? '#1565C0' : '#333333')
                  .fontWeight(this.isCurrentChapter(chapter) ? FontWeight.Medium : FontWeight.Normal)
                  .width(56)
                  .textAlign(TextAlign.Start)

                Text(chapter.title.length > 0 ? chapter.title : 'Chapter ' + (index + 1).toString())
                  .fontSize(15)
                  .fontColor(this.isCurrentChapter(chapter) ? '#1565C0' : '#333333')
                  .fontWeight(this.isCurrentChapter(chapter) ? FontWeight.Medium : FontWeight.Normal)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)

                if (this.isCurrentChapter(chapter)) {
                  SymbolGlyph($r('sys.symbol.play_fill'))
                    .fontSize(16)
                    .fontColor(['#1565C0'])
                    .margin({ left: 8 })
                }
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 14, bottom: 14 })
              .alignItems(VerticalAlign.Center)
            }
            .onClick(() => {
              this.onChapterTap(chapter);
            })
          }, (chapter: Chapter, index: number) => chapter.id.toString() + '_' + index.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('70%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
