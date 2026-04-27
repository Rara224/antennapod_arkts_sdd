// 首页配置对话框：修复@CustomDialog闪退(onClose回调替代controller.close)
export class HomeSectionConfig {
  key: string = '';
  label: string = '';
  visible: boolean = true;
}

@CustomDialog
export struct HomeConfigureDialog {
  controller: CustomDialogController;
  onClose?: () => void;
  sections: HomeSectionConfig[] = [
    { key: 'continue_listening', label: 'Continue listening', visible: true },
    { key: 'new_episodes', label: "See what's new", visible: true },
    { key: 'surprise', label: 'Get surprised', visible: true },
    { key: 'classics', label: 'Check your classics', visible: true },
    { key: 'downloads', label: 'Manage downloads', visible: true }
  ];
  onConfirm: (sections: HomeSectionConfig[]) => void = () => {};

  build() {
    Column() {
      Text('Configure home screen')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 24, right: 24, top: 24, bottom: 16 })
        .width('100%')

      Text('Shown')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#007DFF')
        .padding({ left: 24, bottom: 8 })
        .width('100%')

      ForEach(this.sections, (section: HomeSectionConfig) => {
        Row() {
          SymbolGlyph($r('sys.symbol.line_3_horizontal'))
            .fontSize(18)
            .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
            .margin({ right: 12 })
          Text(section.label)
            .fontSize(16)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: section.visible })
            .onChange((isOn: boolean) => {
              section.visible = isOn;
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
      }, (section: HomeSectionConfig) => section.key)

      // Buttons
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
            this.onConfirm(this.sections);
            this.onClose?.();
          })
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
  }
}
