/**
 * 主题管理工具（浅色/深色/自动 + 可配置主题色，ArkTS 规范）
 */
import display from '@ohos.display';
import { StorageUtil } from './StorageUtil';

export enum ThemeType {
  LIGHT = 'light',
  DARK = 'dark',
  AUTO = 'auto'
}

export interface ThemeColors {
  primary: string;
  primaryVariant: string;
  background: string;
  surface: string;
  textPrimary: string;
  textSecondary: string;
  textHint: string;
  divider: string;
  overlay: string;
  onPrimary: string;
  error: string;
}

export interface SpacingConfig {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

export interface BorderRadiusConfig {
  sm: number;
  md: number;
  lg: number;
  xl: number;
  full: number;
}

export interface FontSizeConfig {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
}

export interface ThemeConfig {
  name: string;
  colors: ThemeColors;
  spacing: SpacingConfig;
  borderRadius: BorderRadiusConfig;
  fontSize: FontSizeConfig;
}

export class ThemeUtil {
  private static currentTheme: ThemeType = ThemeType.AUTO;
  private static customPrimary: string = '#7E22CE';
  private static systemDark: boolean = false;
  private static initialized: boolean = false;
  private static listeners: ((theme: ThemeType) => void)[] = [];

  static readonly LIGHT: ThemeConfig = {
    name: 'light',
    colors: {
      primary: '#7E22CE',
      primaryVariant: '#6B21A8',
      background: '#F5F5F5',
      surface: '#FFFFFF',
      textPrimary: '#212121',
      textSecondary: '#757575',
      textHint: '#BDBDBD',
      divider: '#E5E5E5',
      overlay: 'rgba(0, 0, 0, 0.45)',
      onPrimary: '#FFFFFF',
      error: '#D32F2F'
    },
    spacing: {
      xs: 4,
      sm: 8,
      md: 16,
      lg: 24,
      xl: 32
    },
    borderRadius: {
      sm: 8,
      md: 12,
      lg: 16,
      xl: 24,
      full: 999
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

  static readonly DARK: ThemeConfig = {
    name: 'dark',
    colors: {
      primary: '#A855F7',
      primaryVariant: '#9333EA',
      background: '#121212',
      surface: '#1E1E1E',
      textPrimary: '#FFFFFF',
      textSecondary: '#B3B3B3',
      textHint: '#666666',
      divider: '#333333',
      overlay: 'rgba(0, 0, 0, 0.65)',
      onPrimary: '#FFFFFF',
      error: '#EF5350'
    },
    spacing: {
      xs: 4,
      sm: 8,
      md: 16,
      lg: 24,
      xl: 32
    },
    borderRadius: {
      sm: 8,
      md: 12,
      lg: 16,
      xl: 24,
      full: 999
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

  static async init(): Promise<void> {
    if (ThemeUtil.initialized) {
      return;
    }
    ThemeUtil.initialized = true;
    const savedTheme = await StorageUtil.getString('theme_type', ThemeType.AUTO);
    ThemeUtil.currentTheme = savedTheme as ThemeType;
    const savedPrimary = await StorageUtil.getString('theme_primary', '#7E22CE');
    ThemeUtil.customPrimary = savedPrimary;
    const savedDark = await StorageUtil.getBoolean('system_dark', false);
    ThemeUtil.systemDark = savedDark;
  }

  /**
   * 由 Ability 配置回调更新系统深色状态
   */
  static setSystemDark(isDark: boolean): void {
    ThemeUtil.systemDark = isDark;
    StorageUtil.putBoolean('system_dark', isDark);
  }

  static getCurrentTheme(): ThemeType {
    return ThemeUtil.currentTheme;
  }

  static async setTheme(theme: ThemeType): Promise<void> {
    ThemeUtil.currentTheme = theme;
    await StorageUtil.putString('theme_type', theme);
    ThemeUtil.notifyListeners();
    ThemeUtil.bumpVersion();
  }

  static getCurrentThemeConfig(): ThemeConfig {
    if (ThemeUtil.currentTheme === ThemeType.DARK ||
      (ThemeUtil.currentTheme === ThemeType.AUTO && ThemeUtil.isDarkMode())) {
      return ThemeUtil.DARK;
    }
    return ThemeUtil.LIGHT;
  }

  static async setPrimary(color: string): Promise<void> {
    ThemeUtil.customPrimary = color;
    await StorageUtil.putString('theme_primary', color);
    ThemeUtil.bumpVersion();
    ThemeUtil.notifyListeners();
  }

  /**
   * 通知全局主题版本变化，触发订阅组件重建
   */
  private static bumpVersion(): void {
    const current = AppStorage.get<number>('themeVersion');
    AppStorage.setOrCreate('themeVersion', (current ?? 0) + 1);
  }

  static getPrimary(): string {
    return ThemeUtil.customPrimary;
  }

  static isDarkMode(): boolean {
    return ThemeUtil.systemDark;
  }

  static getColor(colorName: string): string {
    const config = ThemeUtil.getCurrentThemeConfig();
    const colors = config.colors;
    let result: string = colors.primary;
    switch (colorName) {
      case 'primary':
        result = ThemeUtil.customPrimary;
        break;
      case 'primaryVariant':
        result = colors.primaryVariant;
        break;
      case 'background':
        result = colors.background;
        break;
      case 'surface':
        result = colors.surface;
        break;
      case 'textPrimary':
        result = colors.textPrimary;
        break;
      case 'textSecondary':
        result = colors.textSecondary;
        break;
      case 'textHint':
        result = colors.textHint;
        break;
      case 'divider':
        result = colors.divider;
        break;
      case 'overlay':
        result = colors.overlay;
        break;
      case 'onPrimary':
        result = colors.onPrimary;
        break;
      case 'error':
        result = colors.error;
        break;
      default:
        break;
    }
    return result;
  }

  static getSpacing(size: string): number {
    const spacing = ThemeUtil.getCurrentThemeConfig().spacing;
    let result: number = spacing.md;
    switch (size) {
      case 'xs':
        result = spacing.xs;
        break;
      case 'sm':
        result = spacing.sm;
        break;
      case 'md':
        result = spacing.md;
        break;
      case 'lg':
        result = spacing.lg;
        break;
      case 'xl':
        result = spacing.xl;
        break;
      default:
        break;
    }
    return result;
  }

  static getBorderRadius(size: string): number {
    const borderRadius = ThemeUtil.getCurrentThemeConfig().borderRadius;
    let result: number = borderRadius.md;
    switch (size) {
      case 'sm':
        result = borderRadius.sm;
        break;
      case 'md':
        result = borderRadius.md;
        break;
      case 'lg':
        result = borderRadius.lg;
        break;
      case 'xl':
        result = borderRadius.xl;
        break;
      case 'full':
        result = borderRadius.full;
        break;
      default:
        break;
    }
    return result;
  }

  static getFontSize(size: string): number {
    const fontSize = ThemeUtil.getCurrentThemeConfig().fontSize;
    let result: number = fontSize.md;
    switch (size) {
      case 'xs':
        result = fontSize.xs;
        break;
      case 'sm':
        result = fontSize.sm;
        break;
      case 'md':
        result = fontSize.md;
        break;
      case 'lg':
        result = fontSize.lg;
        break;
      case 'xl':
        result = fontSize.xl;
        break;
      case 'xxl':
        result = fontSize.xxl;
        break;
      default:
        break;
    }
    return result;
  }

  static addThemeChangeListener(listener: (theme: ThemeType) => void): void {
    ThemeUtil.listeners.push(listener);
  }

  static removeThemeChangeListener(listener: (theme: ThemeType) => void): void {
    const index = ThemeUtil.listeners.indexOf(listener);
    if (index > -1) {
      ThemeUtil.listeners.splice(index, 1);
    }
  }

  private static notifyListeners(): void {
    ThemeUtil.listeners.forEach((listener: (theme: ThemeType) => void) => {
      listener(ThemeUtil.currentTheme);
    });
  }
}
