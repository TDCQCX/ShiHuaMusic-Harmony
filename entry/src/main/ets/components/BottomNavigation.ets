/**
 * 底部导航栏组件
 * 对应小程序的 tabBar 功能
 */

import { router } from '@kit.ArkUI';
import { ThemeUtil } from '../utils/ThemeUtil';

/**
 * 底部导航栏组件
 * 模仿微信小程序的tabBar设计
 */
@Component
export struct BottomNavigation {
  @State currentIndex: number = 0;
  private onTabChange?: (index: number) => void;

  // 导航项配置
  private tabItems = [
    {
      name: '发现',
      icon: $r('app.media.find'),
      activeIcon: $r('app.media.find-active'),
      page: 'pages/Index/IndexPage'
    },
    {
      name: '全部音乐',
      icon: $r('app.media.music'),
      activeIcon: $r('app.media.music-active'),
      page: 'pages/Library/LibraryPage'
    },
    {
      name: '我的',
      icon: $r('app.media.mine'),
      activeIcon: $r('app.media.mine-active'),
      page: 'pages/User/UserPage'
    }
  ];

  /**
   * 切换标签页
   */
  private switchTab(index: number, pagePath: string) {
    if (this.currentIndex !== index) {
      this.currentIndex = index;
      try {
        router.pushUrl({
          url: pagePath,
          params: {}
        });
      } catch (error) {
        console.error('导航失败:', error);
      }
    }
  }

  /**
   * 监听页面变化
   */
  aboutToAppear(): void {
    // 获取当前路由
    try {
      const state = router.getState();
      const currentPath = state.path || '';
      
      // 根据当前页面设置激活状态
      if (currentPath.includes('/pages/Index/IndexPage')) {
        this.currentIndex = 0;
      } else if (currentPath.includes('/pages/Library/LibraryPage')) {
        this.currentIndex = 1;
      } else if (currentPath.includes('/pages/User/UserPage')) {
        this.currentIndex = 2;
      }
    } catch (error) {
      console.error('获取路由状态失败:', error);
    }
  }

  build() {
    Row() {
      ForEach(this.tabItems, (item: any, index: number) => {
        Column() {
          Image(index === this.currentIndex ? item.activeIcon : item.icon)
            .width(24)
            .height(24)
            .margin({ bottom: 4 })
          
          Text(item.name)
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(index === this.currentIndex ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
            .fontWeight(index === this.currentIndex ? FontWeight.Medium : FontWeight.Regular)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .height('100%')
        .onClick(() => {
          this.switchTab(index, item.page);
        })
      }, (item: any, index: number) => index.toString())
    }
    .width('100%')
    .height(ThemeUtil.getSpacing('lg') + 20)
    .padding({ bottom: 8 })
    .backgroundColor(ThemeUtil.getColor('surface'))
    .border({ width: { top: 1 }, color: ThemeUtil.getColor('divider') })
  }
}