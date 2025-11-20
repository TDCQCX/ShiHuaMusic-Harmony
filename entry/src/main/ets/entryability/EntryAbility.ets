import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { RouteConfig } from '../types/common';

const DOMAIN = 0x0000;

const routes: RouteConfig[] = [
       { name: 'Index', page: 'pages/Index/IndexPage' },
       { name: 'User', page: 'pages/User/UserPage' },
       { name: 'Library', page: 'pages/Library/LibraryPage' }
     ];

export default class EntryAbility extends UIAbility {
  private currentRoute: string = 'Index';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    this.loadPage(windowStage, 'Index');
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  /**
   * 页面导航
   */
  navigateTo(routeName: string): void {
    this.currentRoute = routeName;
    const route = routes.find(r => r.name === routeName);
    if (route) {
      const windowStage = this.context.getWindowStage();
      if (windowStage) {
        this.loadPage(windowStage, routeName);
      }
    } else {
      hilog.error(DOMAIN, 'testTag', 'Route not found: %{public}s', routeName);
    }
  }

  /**
   * 加载页面
   */
  private loadPage(windowStage: window.WindowStage, routeName: string): void {
    const route = routes.find(r => r.name === routeName);
    if (!route) {
      hilog.error(DOMAIN, 'testTag', 'Invalid route: %{public}s', routeName);
      return;
    }

    hilog.info(DOMAIN, 'testTag', 'Loading page: %{public}s', route.page);
    
    windowStage.loadContent(route.page, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load page %{public}s. Cause: %{public}s', routeName, JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading page: %{public}s', routeName);
    });
  }

  /**
   * 获取当前路由
   */
  getCurrentRoute(): string {
    return this.currentRoute;
  }
}