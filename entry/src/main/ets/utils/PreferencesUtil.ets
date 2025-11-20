// 本地存储工具类
import preferences from '@ohos.data.preferences';
import { Context } from '@ohos.abilityAccessCtrl';

export class PreferencesUtil {
  private static readonly STORE_NAME = 'MusicAppPreferences';
  private static context: Context | null = null;
  private static initPromise: Promise<void> | null = null;

  /**
   * 初始化PreferencesUtil
   * @param context 应用上下文
   */
  static init(context: Context): void {
    PreferencesUtil.context = context;
    PreferencesUtil.initPromise = null; // 重置初始化状态
  }

  /**
   * 获取Preferences实例
   */
  private static async getPreferences(): Promise<preferences.Preferences> {
    if (!PreferencesUtil.context) {
      throw new Error('PreferencesUtil未初始化，请先调用init方法');
    }

    if (!PreferencesUtil.initPromise) {
      PreferencesUtil.initPromise = PreferencesUtil.ensureInit();
    }
    await PreferencesUtil.initPromise;

    return preferences.getPreferences(PreferencesUtil.context, PreferencesUtil.STORE_NAME);
  }

  /**
   * 确保初始化完成
   */
  private static async ensureInit(): Promise<void> {
    // 这里可以添加一些初始化逻辑
    console.log('PreferencesUtil初始化中...');
  }

  /**
   * 存储字符串值
   * @param key 键
   * @param value 值
   */
  static async putString(key: string, value: string): Promise<void> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      console.error(`存储字符串失败: ${key}`, error);
      throw error;
    }
  }

  /**
   * 获取字符串值
   * @param key 键
   * @param defaultValue 默认值
   */
  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      const value = await prefs.get(key, defaultValue);
      return value as string;
    } catch (error) {
      console.error(`获取字符串失败: ${key}`, error);
      return defaultValue;
    }
  }

  static async putNumber(key: string, value: number): Promise<void> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      console.error(`存储数字失败: ${key}`, error);
      throw error;
    }
  }

  static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      const value = await prefs.get(key, defaultValue);
      return value as number;
    } catch (error) {
      console.error(`获取数字失败: ${key}`, error);
      return defaultValue;
    }
  }

  static async putBoolean(key: string, value: boolean): Promise<void> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      console.error(`存储布尔值失败: ${key}`, error);
      throw error;
    }
  }

  static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      const value = await prefs.get(key, defaultValue);
      return value as boolean;
    } catch (error) {
      console.error(`获取布尔值失败: ${key}`, error);
      return defaultValue;
    }
  }

  static async putObject<T>(key: string, value: T): Promise<void> {
    try {
      const jsonString = JSON.stringify(value);
      await PreferencesUtil.putString(key, jsonString);
    } catch (error) {
      console.error(`存储对象失败: ${key}`, error);
      throw error;
    }
  }

  static async getObject<T>(key: string, defaultValue: T | null = null): Promise<T | null> {
    try {
      const jsonString = await PreferencesUtil.getString(key, '');
      if (!jsonString) {
        return defaultValue;
      }
      return JSON.parse(jsonString) as T;
    } catch (error) {
      console.error(`获取对象失败: ${key}`, error);
      return defaultValue;
    }
  }

  static async delete(key: string): Promise<void> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      await prefs.delete(key);
      await prefs.flush();
    } catch (error) {
      console.error(`删除键失败: ${key}`, error);
      throw error;
    }
  }

  static async clear(): Promise<void> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      await prefs.clear();
      await prefs.flush();
    } catch (error) {
      console.error('清空数据失败:', error);
      throw error;
    }
  }

  /**
   * 检查是否包含指定键
   * @param key 键
   */
  static async has(key: string): Promise<boolean> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      return await prefs.has(key);
    } catch (error) {
      console.error(`检查键是否存在失败: ${key}`, error);
      return false;
    }
  }

  /**
   * 获取所有键
   */
  static async getAllKeys(): Promise<string[]> {
    try {
      const prefs = await PreferencesUtil.getPreferences();
      return await prefs.getAllKeys();
    } catch (error) {
      console.error('获取所有键失败:', error);
      return [];
    }
  }
}