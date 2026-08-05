/**
 * 导航工具（统一封装，避免裸调用抛异常）
 */
import { router } from '@kit.ArkUI';
import { NavParams } from '../types/common';

export class NavUtil {
  static push(url: string, params?: NavParams): void {
    try {
      router.pushUrl({ url: url, params: params });
    } catch (error) {
      console.error('导航失败:', url, JSON.stringify(error));
    }
  }

  static replace(url: string): void {
    try {
      router.replaceUrl({ url: url });
    } catch (error) {
      console.error('导航替换失败:', url, JSON.stringify(error));
    }
  }

  static back(): void {
    try {
      router.back();
    } catch (error) {
      console.error('返回失败:', JSON.stringify(error));
    }
  }

  static getParams(): Object {
    return router.getParams();
  }
}
