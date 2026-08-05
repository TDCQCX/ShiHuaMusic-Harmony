/**
 * 应用级上下文持有者（避免使用已弃用的全局 getContext）
 */
import { common } from '@kit.AbilityKit';

export class AppContext {
  private static context: common.UIAbilityContext | null = null;

  static init(context: common.UIAbilityContext): void {
    AppContext.context = context;
  }

  static getContext(): common.UIAbilityContext | null {
    return AppContext.context;
  }
}
