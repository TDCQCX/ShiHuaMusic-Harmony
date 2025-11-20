// 本地存储工具类
import preferences from '@ohos.data.preferences';
import { UserInfo } from '../types/common';

export class StorageUtil {
  private static readonly USER_INFO_KEY: string = 'userInfo';
  private static readonly TOKEN_KEY: string = 'token';
  private static readonly HAS_SHOWN_WELCOME_KEY: string = 'hasShownWelcome';
  private static readonly PREFERENCES_NAME: string = 'music_app_prefs';

  /**
   * 获取Preferences实例
   */
  private static async getPreferences(): Promise<preferences.Preferences> {
    return await preferences.getPreferences(getContext(), this.PREFERENCES_NAME);
  }

  /**
   * 保存用户信息
   * @param userInfo 用户信息
   */
  static async saveUserInfo(userInfo: UserInfo): Promise<void> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      await prefs.put(this.USER_INFO_KEY, JSON.stringify(userInfo));
      await prefs.flush();
    } catch (error) {
      console.error('保存用户信息失败:', error);
    }
  }

  /**
   * 获取用户信息
   */
  static async getUserInfo(): Promise<UserInfo | null> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      const userInfoStr: string = await prefs.get(this.USER_INFO_KEY, '') as string;
      if (userInfoStr) {
        return JSON.parse(userInfoStr);
      }
      return null;
    } catch (error) {
      console.error('获取用户信息失败:', error);
      return null;
    }
  }

  /**
   * 删除用户信息
   */
  static async removeUserInfo(): Promise<void> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      await prefs.delete(this.USER_INFO_KEY);
      await prefs.flush();
    } catch (error) {
      console.error('删除用户信息失败:', error);
    }
  }

  /**
   * 保存Token
   * @param token 认证令牌
   */
  static async saveToken(token: string): Promise<void> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      await prefs.put(this.TOKEN_KEY, token);
      await prefs.flush();
    } catch (error) {
      console.error('保存Token失败:', error);
    }
  }

  /**
   * 获取Token
   */
  static async getToken(): Promise<string> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      return await prefs.get(this.TOKEN_KEY, '') as string;
    } catch (error) {
      console.error('获取Token失败:', error);
      return '';
    }
  }

  /**
   * 删除Token
   */
  static async removeToken(): Promise<void> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      await prefs.delete(this.TOKEN_KEY);
      await prefs.flush();
    } catch (error) {
      console.error('删除Token失败:', error);
    }
  }

  /**
   * 设置欢迎弹窗显示状态
   */
  static async setHasShownWelcome(hasShown: boolean): Promise<void> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      await prefs.put(this.HAS_SHOWN_WELCOME_KEY, hasShown);
      await prefs.flush();
    } catch (error) {
      console.error('设置欢迎弹窗显示状态失败:', error);
    }
  }

  /**
   * 获取欢迎弹窗显示状态
   */
  static async getHasShownWelcome(): Promise<boolean> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      return await prefs.get(this.HAS_SHOWN_WELCOME_KEY, false) as boolean;
    } catch (error) {
      console.error('获取欢迎弹窗显示状态失败:', error);
      return false;
    }
  }

  /**
   * 清空所有数据
   */
  static async clearAll(): Promise<void> {
    try {
      const prefs: preferences.Preferences = await this.getPreferences();
      await prefs.clear();
      await prefs.flush();
    } catch (error) {
      console.error('清空数据失败:', error);
    }
  }
}