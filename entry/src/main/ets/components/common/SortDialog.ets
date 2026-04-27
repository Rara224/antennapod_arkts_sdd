export class SortOption {
  value: number = 0;
  label: string = '';
}

@CustomDialog
export struct SortDialog {
  controller: CustomDialogController;
  sortOptions: SortOption[] = [];
  currentSort: number = 0;
  onSortSelected: (sort: number) => void = () => {};

  build() {
    Column() {
      Text('Sort')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 24, right: 24, top: 24, bottom: 16 })
        .width('100%')

      List() {
        ForEach(this.sortOptions, (option: SortOption) => {
          ListItem() {
            Row() {
              Text(option.label)
                .fontSize(16)
                .layoutWeight(1)
              if (this.currentSort === option.value) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(18)
                  .fontColor(['#007DFF'])
              }
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 14, bottom: 14 })
          }
          .onClick(() => {
            this.onSortSelected(option.value);
            this.controller.close();
          })
        }, (option: SortOption) => 'sort_' + option.value.toString())
      }
      .width('100%')
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 24, endMargin: 24 })

      Button('Cancel')
        .fontSize(14)
        .backgroundColor('#F5F5F5')
        .fontColor('#333333')
        .width('90%')
        .margin({ top: 16, bottom: 24 })
        .onClick(() => {
          this.controller.close();
        })
    }
    .width('100%')
  }
}
