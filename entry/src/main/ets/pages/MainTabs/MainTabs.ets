/**
 * 主框架：三个主 Tab（发现 / 全部音乐 / 我的）+ 全局底部播放器
 * 使用 Tabs 实现平滑切换，底部导航状态与 Tab 同步
 */
import { IndexPage } from '../Index/IndexPage';
import { LibraryPage } from '../Library/LibraryPage';
import { UserPage } from '../User/UserPage';
import { BottomPlayer } from '../../components/BottomPlayer';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { TabManager } from '../../utils/TabManager';

@Entry
@Component
struct MainTabs {
  @State currentTab: number = 0;
  @StorageLink('themeVersion') themeVersion: number = 0;
  @State touchStartY: number = -1;
  private tabsController: TabsController = new TabsController();
  private tabListener: (index: number) => void = (index: number) => {
    this.currentTab = index;
    this.tabsController.changeIndex(index);
  };

  aboutToAppear(): void {
    TabManager.onTabChange(this.tabListener);
  }

  aboutToDisappear(): void {
    TabManager.offTabChange(this.tabListener);
  }

  private switchTab(index: number): void {
    this.currentTab = index;
    this.tabsController.changeIndex(index);
  }

  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut })
      .opacity(0)
    PageTransitionExit({ duration: 200, curve: Curve.EaseIn })
      .opacity(0)
  }

  @Builder
  private tabBuilder(index: number, name: string, icon: Resource, activeIcon: Resource) {
    Column() {
      Image(this.currentTab === index ? activeIcon : icon)
        .width(24)
        .height(24)
        .margin({ bottom: 4 })
      Text(name)
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(this.currentTab === index ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentTab,
        controller: this.tabsController
      }) {
        TabContent() {
          IndexPage()
        }
        .tabBar(this.tabBuilder(0, '发现', $r('app.media.find'), $r('app.media.find_active')))

        TabContent() {
          LibraryPage()
        }
        .tabBar(this.tabBuilder(1, '全部音乐', $r('app.media.music'), $r('app.media.music_active')))

        TabContent() {
          UserPage()
        }
        .tabBar(this.tabBuilder(2, '我的', $r('app.media.mine'), $r('app.media.mine_active')))
      }
      .layoutWeight(1)
      .barHeight(56)
      .onChange((index: number) => {
        this.currentTab = index;
        TabManager.setTab(index);
      })
      .width('100%')
      .height('100%')

      // 全局悬浮播放器：圆角卡片，悬浮于底部 bar 上方
      BottomPlayer()
        .width('92%')
        .margin({ bottom: 66 })

      Text(this.themeVersion.toString())
        .fontSize(0)
        .width(0)
        .height(0)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
    .onTouch((event: TouchEvent) => {
      // 全局触摸：界面向上滑动收起播放器为圆形，向下滑动恢复
      if (event.type === TouchType.Down) {
        this.touchStartY = event.touches[0].y;
      } else if (event.type === TouchType.Move && this.touchStartY >= 0) {
        const dy: number = event.touches[0].y - this.touchStartY;
        if (dy < -60) {
          AppStorage.setOrCreate('playerCollapsed', true);
          this.touchStartY = -1;
        } else if (dy > 60) {
          AppStorage.setOrCreate('playerCollapsed', false);
          this.touchStartY = -1;
        }
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.touchStartY = -1;
      }
    })
  }
}
