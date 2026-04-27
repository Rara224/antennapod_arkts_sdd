@Component
export struct EpisodeListItem {
  @Prop title: string = '';
  @Prop feedTitle: string = '';
  @Prop pubDate: string = '';
  @Prop durationStr: string = '';
  @Prop isNew: boolean = false;
  @Prop isPlayed: boolean = false;
  @Prop isDownloaded: boolean = false;
  @Prop showFeedTitle: boolean = true;
  @Prop hasProgress: boolean = false;
  @Prop progressPercent: number = 0;
  @Prop imageUrl: string = '';

  build() {
    Row() {
      // Cover image or placeholder
      if (this.imageUrl.length > 0) {
        Image(this.imageUrl)
          .width(48)
          .height(48)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .margin({ right: 12 })
      } else {
        Column() {
          Text(this.feedTitle.length > 0 ? this.feedTitle.charAt(0).toUpperCase() : '?')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(48)
        .height(48)
        .borderRadius(6)
        .backgroundColor('#BDBDBD')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 12 })
      }

      // Content
      Column() {
        // Title row with new indicator
        Row() {
          if (this.isNew) {
            Circle()
              .width(6)
              .height(6)
              .fill('#2196F3')
              .margin({ right: 6, top: 7 })
          }
          Text(this.title)
            .fontSize(15)
            .fontWeight(this.isPlayed ? FontWeight.Normal : FontWeight.Medium)
            .fontColor(this.isPlayed ? '#99000000' : '#E6000000')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // Feed title
        if (this.showFeedTitle && this.feedTitle.length > 0) {
          Text(this.feedTitle)
            .fontSize(12)
            .fontColor('#99000000')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }

        // Meta row: date + duration + download icon
        Row() {
          if (this.pubDate.length > 0) {
            Text(this.pubDate)
              .fontSize(12)
              .fontColor('#99000000')
          }
          if (this.pubDate.length > 0 && this.durationStr.length > 0) {
            Text(' · ')
              .fontSize(12)
              .fontColor('#99000000')
          }
          if (this.durationStr.length > 0) {
            Text(this.durationStr)
              .fontSize(12)
              .fontColor('#99000000')
          }
          if (this.isDownloaded) {
            Text(' \u2713')
              .fontSize(12)
              .fontColor('#4CAF50')
          }
        }
        .margin({ top: 2 })
        .width('100%')

        // Progress bar
        if (this.hasProgress && this.progressPercent > 0) {
          Progress({ value: this.progressPercent, total: 100, type: ProgressType.Linear })
            .height(2)
            .width('100%')
            .margin({ top: 4 })
            .color('#2196F3')
            .backgroundColor('#E0E0E0')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Top)
  }
}
