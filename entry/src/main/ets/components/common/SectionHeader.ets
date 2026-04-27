@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop showMore: boolean = false;
  @Prop moreText: string = '';
  @Prop badgeCount: number = 0;
  @Prop showShuffleIcon: boolean = false;
  onMoreClick: () => void = () => {};

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      if (this.badgeCount > 0) {
        Text(this.badgeCount.toString())
          .fontSize(11)
          .fontColor('#007DFF')
          .borderWidth(1)
          .borderColor('#007DFF')
          .borderRadius(10)
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .margin({ left: 8 })
      }

      if (this.showShuffleIcon) {
        Text('\u2928')
          .fontSize(16)
          .fontColor('#333333')
          .margin({ left: 8 })
      }

      Blank()

      if (this.showMore) {
        Text(this.moreText.length > 0 ? this.moreText : 'More')
          .fontSize(14)
          .fontColor('#007DFF')
          .onClick(() => {
            this.onMoreClick();
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }
}
