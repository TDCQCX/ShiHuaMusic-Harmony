/**
 * 本地存储工具（Preferences 封装，ArkTS 规范）
 */
import preferences from '@ohos.data.preferences';
import { AppContext } from './AppContext';

export class StorageUtil {
  private static readonly PREFERENCES_NAME: string = 'shihua_music';

  private static async getPreferences(): Promise<preferences.Preferences> {
    try {
      const context = AppContext.getContext();
      if (context === null) {
        throw new Error('AppContext 未初始化');
      }
      return await preferences.getPreferences(context, StorageUtil.PREFERENCES_NAME);
    } catch (error) {
      console.error('获取 Preferences 失败:', error);
      throw error as Error;
    }
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    try {
      const prefs = await StorageUtil.getPreferences();
      const value = await prefs.get(key, defaultValue);
      return value as string;
    } catch (error) {
      console.error('StorageUtil.getString failed:', key, error);
      return defaultValue;
    }
  }

  static async putString(key: string, value: string): Promise<void> {
    try {
      const prefs = await StorageUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      console.error('StorageUtil.putString failed:', key, error);
    }
  }

  static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    try {
      const prefs = await StorageUtil.getPreferences();
      const value = await prefs.get(key, defaultValue);
      return value as number;
    } catch (error) {
      console.error('StorageUtil.getNumber failed:', key, error);
      return defaultValue;
    }
  }

  static async putNumber(key: string, value: number): Promise<void> {
    try {
      const prefs = await StorageUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      console.error('StorageUtil.putNumber failed:', key, error);
    }
  }

  static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    try {
      const prefs = await StorageUtil.getPreferences();
      const value = await prefs.get(key, defaultValue);
      return value as boolean;
    } catch (error) {
      console.error('StorageUtil.getBoolean failed:', key, error);
      return defaultValue;
    }
  }

  static async putBoolean(key: string, value: boolean): Promise<void> {
    try {
      const prefs = await StorageUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      console.error('StorageUtil.putBoolean failed:', key, error);
    }
  }

  static async getObject<T>(key: string, defaultValue: T | null = null): Promise<T | null> {
    try {
      const json = await StorageUtil.getString(key, '');
      if (!json) {
        return defaultValue;
      }
      return JSON.parse(json) as T;
    } catch (error) {
      console.error('StorageUtil.getObject failed:', key, error);
      return defaultValue;
    }
  }

  static async putObject<T>(key: string, value: T): Promise<void> {
    await StorageUtil.putString(key, JSON.stringify(value));
  }

  static async remove(key: string): Promise<void> {
    try {
      const prefs = await StorageUtil.getPreferences();
      await prefs.delete(key);
      await prefs.flush();
    } catch (error) {
      console.error('StorageUtil.remove failed:', key, error);
    }
  }

  static async clear(): Promise<void> {
    try {
      const prefs = await StorageUtil.getPreferences();
      await prefs.clear();
      await prefs.flush();
    } catch (error) {
      console.error('StorageUtil.clear failed:', error);
    }
  }
}
