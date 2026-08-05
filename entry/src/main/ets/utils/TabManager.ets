/**
 * 主 Tab 切换管理（避免跨组件直接耦合）
 */
export type TabChangeListener = (index: number) => void;

export class TabManager {
  private static listeners: TabChangeListener[] = [];

  static setTab(index: number): void {
    AppStorage.setOrCreate('mainTabIndex', index);
    TabManager.listeners.forEach((listener: TabChangeListener) => {
      listener(index);
    });
  }

  static onTabChange(listener: TabChangeListener): void {
    TabManager.listeners.push(listener);
  }

  static offTabChange(listener: TabChangeListener): void {
    const index = TabManager.listeners.indexOf(listener);
    if (index > -1) {
      TabManager.listeners.splice(index, 1);
    }
  }
}
