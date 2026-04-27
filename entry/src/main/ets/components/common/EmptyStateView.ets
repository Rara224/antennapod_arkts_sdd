@Component
export struct EmptyStateView {
  @Prop icon: string = '';
  @Prop message: string = '';
  @Prop actionLabel: string = '';
  onAction: () => void = () => {};

  build() {
    Column() {
      if (this.icon.length > 0) {
        Text(this.icon)
          .fontSize(48)
          .margin({ bottom: 16 })
      }

      Text(this.message)
        .fontSize(16)
        .fontColor('#99000000')
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })

      if (this.actionLabel.length > 0) {
        Button(this.actionLabel)
          .fontSize(14)
          .margin({ top: 16 })
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
