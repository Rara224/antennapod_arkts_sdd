@Component
export struct HorizontalEpisodeCard {
  @Prop title: string = '';
  @Prop pubDate: string = '';
  @Prop imageUrl: string = '';
  @Prop showPlayButton: boolean = true;
  onButtonClick: () => void = () => {};
  onCardClick: () => void = () => {};

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.imageUrl.length > 0) {
          Image(this.imageUrl)
            .width('100%')
            .height(128)
            .borderRadius({ topLeft: 12, topRight: 12 })
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.speaker_wave_2_fill'))
              .fontSize(32)
              .fontColor([Color.White])
          }
          .width('100%')
          .height(128)
          .borderRadius({ topLeft: 12, topRight: 12 })
          .backgroundColor('#9E9E9E')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        // Overlay button (play or download)
        Column() {
          if (this.showPlayButton) {
            SymbolGlyph($r('sys.symbol.play_fill'))
              .fontSize(16)
              .fontColor([Color.White])
          } else {
            Image($r('app.media.ic_download'))
              .width(18)
              .height(18)
              .fillColor(Color.White)
          }
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('#2196F3')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 4, bottom: 4 })
        .onClick(() => {
          this.onButtonClick();
        })
      }
      .width('100%')

      Text(this.title)
        .fontSize(14)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4, left: 4, right: 4 })
        .width('100%')

      Text(this.pubDate)
        .fontSize(12)
        .fontColor('#99000000')
        .margin({ top: 2, left: 4, right: 4, bottom: 4 })
        .width('100%')
    }
    .width(128)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000', offsetY: 1 })
    .onClick(() => {
      this.onCardClick();
    })
  }
}
