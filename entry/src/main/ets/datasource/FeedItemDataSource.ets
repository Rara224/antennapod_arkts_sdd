import { FeedItem } from '../models/FeedItem';

export class FeedItemDataSource implements IDataSource {
  private items: FeedItem[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): FeedItem {
    return this.items[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  reloadAll(newItems: FeedItem[]): void {
    this.items = newItems;
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }

  appendItems(moreItems: FeedItem[]): void {
    const startIndex = this.items.length;
    for (let i = 0; i < moreItems.length; i++) {
      this.items.push(moreItems[i]);
      for (let j = 0; j < this.listeners.length; j++) {
        this.listeners[j].onDataAdd(startIndex + i);
      }
    }
  }

  removeItem(index: number): void {
    this.items.splice(index, 1);
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataDelete(index);
    }
  }

  moveItem(from: number, to: number): void {
    const item = this.items.splice(from, 1)[0];
    this.items.splice(to, 0, item);
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataMove(from, to);
    }
  }

  getAll(): FeedItem[] {
    return this.items;
  }
}
