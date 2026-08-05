import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ThemeUtil } from '../utils/ThemeUtil';
import { GlobalDataManager } from '../utils/GlobalDataManager';
import { AppContext } from '../utils/AppContext';
import { AudioManager } from '../utils/AudioManager';

const DOMAIN: number = 0x0000;
const TAG: string = 'ShiHuaMusic';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppContext.init(this.context);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode: %{public}s', JSON.stringify(err));
    }
    GlobalDataManager.getInstance().initialize();
    AudioManager.getInstance().restore();
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const isDark: boolean = newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    ThemeUtil.setSystemDark(isDark);
    hilog.info(DOMAIN, TAG, 'Configuration updated, darkMode: %{public}s', isDark.toString());
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.initApp(windowStage);
  }

  /**
   * 先完成本地配置/会话恢复，再加载首页，避免首次进入数据为空
   */
  private async initApp(windowStage: window.WindowStage): Promise<void> {
    try {
      await GlobalDataManager.getInstance().initialize();
      await AudioManager.getInstance().restore();
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'App init failed: %{public}s', JSON.stringify(error));
    }
    windowStage.loadContent('pages/MainTabs/MainTabs', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
