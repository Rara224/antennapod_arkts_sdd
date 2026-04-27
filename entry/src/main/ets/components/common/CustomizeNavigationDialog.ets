export class NavigationItem {
  key: string = '';
  label: string = '';
  visible: boolean = true;
}

@Component
export struct CustomizeNavigationDialog {
  @State items: NavigationItem[] = [
    { key: 'home', label: 'Home', visible: true },
    { key: 'queue', label: 'Queue', visible: true },
    { key: 'inbox', label: 'Inbox', visible: true },
    { key: 'subscriptions', label: 'Subscriptions', visible: true },
    { key: 'episodes', label: 'Episodes', visible: true },
    { key: 'downloads', label: 'Downloads', visible: true },
    { key: 'playback_history', label: 'Playback history', visible: true }
  ];
  onCancel: () => void = () => {};
  onConfirm: (items: NavigationItem[]) => void = () => {};

  private cloneItems(): NavigationItem[] {
    const copiedItems: NavigationItem[] = [];
    for (let i = 0; i < this.items.length; i++) {
      const copiedItem = new NavigationItem();
      copiedItem.key = this.items[i].key;
      copiedItem.label = this.items[i].label;
      copiedItem.visible = this.items[i].visible;
      copiedItems.push(copiedItem);
    }
    return copiedItems;
  }

  private updateItemVisibility(index: number, isVisible: boolean): void {
    if (index < 0 || index >= this.items.length) {
      return;
    }
    const copiedItems = this.cloneItems();
    copiedItems[index].visible = isVisible;
    this.items = copiedItems;
  }

  private swapItems(fromIndex: number, toIndex: number): void {
    if (fromIndex < 0 || toIndex < 0 || fromIndex >= this.items.length || toIndex >= this.items.length) {
      return;
    }
    const newItems = this.cloneItems();
    const temp = newItems[fromIndex];
    newItems[fromIndex] = newItems[toIndex];
    newItems[toIndex] = temp;
    this.items = newItems;
  }

  build() {
    Column() {
      Text('Customize navigation')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 24, right: 24, top: 24, bottom: 16 })
        .width('100%')

      ForEach(this.items, (item: NavigationItem, index: number) => {
        Row() {
          // Checkbox (matching Android)
          Checkbox()
            .select(item.visible)
            .selectedColor('#1565C0')
            .width(20)
            .height(20)
            .margin({ right: 12 })
            .onChange((isChecked: boolean) => {
              this.updateItemVisibility(index, isChecked);
            })

          // Label
          Text(item.label)
            .fontSize(16)
            .fontColor(item.visible ? '#333333' : '#999999')
            .layoutWeight(1)

          // Move up
          Text('\u25B2')
            .fontSize(14)
            .fontColor(index > 0 ? '#666666' : '#CCCCCC')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (index > 0) {
                this.swapItems(index, index - 1);
              }
            })

          // Move down
          Text('\u25BC')
            .fontSize(14)
            .fontColor(index < this.items.length - 1 ? '#666666' : '#CCCCCC')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (index < this.items.length - 1) {
                this.swapItems(index, index + 1);
              }
            })

          // Drag handle (visual, matching Android's hamburger grip)
          Text('\u2630')
            .fontSize(18)
            .fontColor('#999999')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
      }, (item: NavigationItem, index: number) => item.key + '_' + index.toString())

      // Buttons
      Row() {
        Button('Cancel')
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .layoutWeight(1)
          .onClick(() => {
            this.onCancel();
          })
        Button('OK')
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.onConfirm(this.items);
          })
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
