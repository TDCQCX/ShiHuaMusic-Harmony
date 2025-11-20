// 主题管理工具类
import display from '@ohos.display';
import PreferencesUtil from './PreferencesUtil';

export enum ThemeType {
  LIGHT = 'light',
  DARK = 'dark',
  AUTO = 'auto'
}

export interface ThemeColors {
  primary: string;
  primaryVariant: string;
  secondary: string;
  background: string;
  surface: string;
  error: string;
  onPrimary: string;
  onSecondary: string;
  onBackground: string;
  onSurface: string;
  textPrimary: string;
  textSecondary: string;
  textHint: string;
  divider: string;
  shadow: string;
  overlay: string;
}

export interface ThemeConfig {
  name: string;
  colors: ThemeColors;
  spacing: {
    xs: number;
    sm: number;
    md: number;
    lg: number;
    xl: number;
  };
  borderRadius: {
    sm: number;
    md: number;
    lg: number;
    full: number;
  };
  fontSize: {
    xs: number;
    sm: number;
    md: number;
    lg: number;
    xl: number;
    xxl: number;
  };
}

export class ThemeUtil {
  private static currentTheme: ThemeType = ThemeType.AUTO;
  private static listeners: ((theme: ThemeType) => void)[] = [];

  // 浅色主题配置
  static readonly LIGHT_THEME: ThemeConfig = {
    name: 'light',
    colors: {
      primary: '#1976D2',
      primaryVariant: '#1565C0',
      secondary: '#03DAC6',
      background: '#FAFAFA',
      surface: '#FFFFFF',
      error: '#B00020',
      onPrimary: '#FFFFFF',
      onSecondary: '#000000',
      onBackground: '#000000',
      onSurface: '#000000',
      textPrimary: '#212121',
      textSecondary: '#757575',
      textHint: '#BDBDBD',
      divider: '#E0E0E0',
      shadow: 'rgba(0, 0, 0, 0.12)',
      overlay: 'rgba(0, 0, 0, 0.5)'
    },
    spacing: {
      xs: 4,
      sm: 8,
      md: 16,
      lg: 24,
      xl: 32
    },
    borderRadius: {
      sm: 4,
      md: 8,
      lg: 16,
      full: 50
    },
    fontSize: {
      xs: 12,
      sm: 14,
      md: 16,
      lg: 18,
      xl: 20,
      xxl: 24
    }
  };

  // 深色主题配置
  static readonly DARK_THEME: ThemeConfig = {
    name: 'dark',
    colors: {
      primary: '#90CAF9',
      primaryVariant: '#64B5F6',
      secondary: '#03DAC6',
      background: '#121212',
      surface: '#1E1E1E',
      error: '#CF6679',
      onPrimary: '#000000',
      onSecondary: '#000000',
      onBackground: '#FFFFFF',
      onSurface: '#FFFFFF',
      textPrimary: '#FFFFFF',
      textSecondary: '#B3B3B3',
      textHint: '#666666',
      divider: '#333333',
      shadow: 'rgba(255, 255, 255, 0.12)',
      overlay: 'rgba(255, 255, 255, 0.1)'
    },
    spacing: {
      xs: 4,
      sm: 8,
      md: 16,
      lg: 24,
      xl: 32
    },
    borderRadius: {
      sm: 4,
      md: 8,
      lg: 16,
      full: 50
    },
    fontSize: {
      xs: 12,
      sm: 14,
      md: 16,
      lg: 18,
      xl: 20,
      xxl: 24
    }
  };

  /**
   * 初始化主题系统
   */
  static async init(): Promise<void> {
    try {
      // 从本地存储读取主题设置
      const savedTheme = await PreferencesUtil.getString('theme_type', ThemeType.AUTO);
      this.currentTheme = savedTheme as ThemeType;
      
      // 根据系统设置调整主题
      if (this.currentTheme === ThemeType.AUTO) {
        await this.updateAutoTheme();
      }
      
      console.log('主题系统初始化完成，当前主题:', this.currentTheme);
    } catch (error) {
      console.error('主题系统初始化失败:', error);
      this.currentTheme = ThemeType.LIGHT;
    }
  }

  /**
   * 设置主题
   * @param theme 主题类型
   */
  static async setTheme(theme: ThemeType): Promise<void> {
    try {
      this.currentTheme = theme;
      await PreferencesUtil.putString('theme_type', theme);
      
      // 如果设置为自动主题，需要根据系统设置更新
      if (theme === ThemeType.AUTO) {
        await this.updateAutoTheme();
      }
      
      // 通知所有监听器
      this.notifyListeners();
      
      console.log('主题已切换为:', theme);
    } catch (error) {
      console.error('设置主题失败:', error);
    }
  }

  /**
   * 获取当前主题类型
   */
  static getCurrentTheme(): ThemeType {
    return this.currentTheme;
  }

  /**
   * 获取当前主题配置
   */
  static getCurrentThemeConfig(): ThemeConfig {
    if (this.currentTheme === ThemeType.AUTO) {
      // 根据系统主题返回对应配置
      return this.isDarkMode() ? this.DARK_THEME : this.LIGHT_THEME;
    }
    return this.currentTheme === ThemeType.DARK ? this.DARK_THEME : this.LIGHT_THEME;
  }

  /**
   * 获取主题颜色
   */
  static getColor(colorName: keyof ThemeColors): string {
    return this.getCurrentThemeConfig().colors[colorName];
  }

  /**
   * 获取间距
   */
  static getSpacing(size: keyof ThemeConfig['spacing']): number {
    return this.getCurrentThemeConfig().spacing[size];
  }

  /**
   * 获取圆角
   */
  static getBorderRadius(size: keyof ThemeConfig['borderRadius']): number {
    return this.getCurrentThemeConfig().borderRadius[size];
  }

  /**
   * 获取字体大小
   */
  static getFontSize(size: keyof ThemeConfig['fontSize']): number {
    return this.getCurrentThemeConfig().fontSize[size];
  }

  /**
   * 添加主题变更监听器
   */
  static addThemeChangeListener(listener: (theme: ThemeType) => void): void {
    this.listeners.push(listener);
  }

  /**
   * 移除主题变更监听器
   */
  static removeThemeChangeListener(listener: (theme: ThemeType) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 检查是否为深色模式
   */
  static isDarkMode(): boolean {
    try {
      // 鸿蒙系统深色模式检测
      const colorMode = display.getDarkMode();
      return colorMode === display.DarkMode.DARK;
    } catch (error) {
      console.warn('无法检测系统深色模式:', error);
      return false;
    }
  }

  /**
   * 更新自动主题
   */
  private static async updateAutoTheme(): Promise<void> {
    const isDark = this.isDarkMode();
    console.log('系统主题检测结果:', isDark ? '深色' : '浅色');
  }

  /**
   * 通知所有监听器
   */
  private static notifyListeners(): void {
    this.listeners.forEach(listener => {
      try {
        listener(this.currentTheme);
      } catch (error) {
        console.error('主题监听器执行失败:', error);
      }
    });
  }

  /**
   * 销毁主题系统
   */
  static destroy(): void {
    this.listeners = [];
  }
}