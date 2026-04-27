@Component
export struct FeedGridItem {
  @Prop feedTitle: string = '';
  @Prop episodeCount: number = 0;
  @Prop imageUrl: string = '';
  @Prop showTitle: boolean = true;
  @Prop newEpisodeCount: number = 0;
  @Prop isSelected: boolean = false;

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        // Cover image or placeholder
        if (this.imageUrl.length > 0) {
          Image(this.imageUrl)
            .width('100%')
            .aspectRatio(1)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text(this.feedTitle.length > 0 ? this.feedTitle.charAt(0).toUpperCase() : '?')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width('100%')
          .aspectRatio(1)
          .borderRadius(8)
          .backgroundColor('#9E9E9E')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        // New episode counter badge
        if (this.newEpisodeCount > 0) {
          Text(this.newEpisodeCount.toString())
            .fontSize(11)
            .fontColor(Color.White)
            .backgroundColor('#FF5252')
            .borderRadius(10)
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .margin({ top: 4, right: 4 })
            .constraintSize({ minWidth: 20 })
            .textAlign(TextAlign.Center)
        }

        // Selected overlay
        if (this.isSelected) {
          Column()
            .width('100%')
            .aspectRatio(1)
            .borderRadius(8)
            .backgroundColor('#330078D4')

          Column() {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(14)
              .fontColor([Color.White])
          }
          .width(24)
          .height(24)
          .borderRadius(12)
          .backgroundColor('#0078D4')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 6, left: 6 })
        }
      }
      .width('100%')
      .alignContent(Alignment.TopStart)

      if (this.showTitle) {
        // Feed title
        Text(this.feedTitle)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
          .width('100%')

        // Episode count
        if (this.episodeCount > 0) {
          Text(this.episodeCount.toString() + ' episodes')
            .fontSize(11)
            .fontColor('#99000000')
            .margin({ top: 2 })
            .width('100%')
        }
      }
    }
    .padding(6)
    .width('100%')
  }
}
