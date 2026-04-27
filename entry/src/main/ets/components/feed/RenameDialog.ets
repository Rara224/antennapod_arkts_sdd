// 重命名弹窗：编辑Feed自定义标题，保存到FeedDao
@CustomDialog
export struct RenameDialog {
  controller: CustomDialogController;
  onClose?: () => void;
  onConfirm?: (newTitle: string) => void;
  currentTitle: string = '';
  @State inputText: string = '';

  aboutToAppear(): void {
    this.inputText = this.currentTitle;
  }

  build() {
    Column() {
      Text('Rename podcast')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)

      TextInput({ text: this.inputText, placeholder: 'Enter new title' })
        .width('100%')
        .height(44)
        .fontSize(16)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .padding({ left: 12, right: 12 })
        .margin({ left: 20, right: 20, bottom: 24 })
        .onChange((value: string) => {
          this.inputText = value;
        })

      Row() {
        Button('Cancel')
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .layoutWeight(1)
          .onClick(() => {
            this.onClose?.();
          })
        Button('OK')
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            const trimmed = this.inputText.trim();
            if (this.onConfirm !== undefined) {
              this.onConfirm(trimmed);
            }
            this.onClose?.();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 34 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
