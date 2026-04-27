// 标签编辑弹窗：逗号分隔，保存到FeedPreferences.tags
@CustomDialog
export struct TagsDialog {
  controller: CustomDialogController;
  onClose?: () => void;
  onConfirm?: (tags: Set<string>) => void;
  currentTagsStr: string = '';
  @State inputText: string = '';

  aboutToAppear(): void {
    this.inputText = this.currentTagsStr;
  }

  build() {
    Column() {
      Text('Edit tags')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 8 })
        .width('100%')
        .textAlign(TextAlign.Center)

      Text('Separate tags with commas')
        .fontSize(13)
        .fontColor('#99000000')
        .margin({ bottom: 16 })

      TextInput({ text: this.inputText, placeholder: 'e.g. news, tech, interviews' })
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
            const newTags = new Set<string>();
            const parts = this.inputText.split(',');
            for (let i = 0; i < parts.length; i++) {
              const tag = parts[i].trim();
              if (tag.length > 0) {
                newTags.add(tag);
              }
            }
            if (this.onConfirm !== undefined) {
              this.onConfirm(newTags);
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
