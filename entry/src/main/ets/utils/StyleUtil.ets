// 主题样式工具类
import { ThemeUtil, ThemeConfig, ThemeType } from './ThemeUtil';

/**
 * 应用主题样式类
 * 提供统一的样式应用方法
 */
export class StyleUtil {
  private static currentTheme: ThemeType = ThemeType.AUTO;
  private static isInitialized = false;

  /**
   * 初始化样式系统
   */
  static async init(): Promise<void> {
    if (StyleUtil.isInitialized) {
      return;
    }

    try {
      // 初始化主题系统
      await ThemeUtil.init();
      
      // 添加主题变更监听器
      ThemeUtil.addThemeChangeListener((theme: ThemeType) => {
        StyleUtil.currentTheme = theme;
        StyleUtil.updatePageStyles();
      });
      
      // 获取当前主题
      StyleUtil.currentTheme = ThemeUtil.getCurrentTheme();
      StyleUtil.isInitialized = true;
      
      console.log('样式系统初始化完成');
    } catch (error) {
      console.error('样式系统初始化失败:', error);
    }
  }

  /**
   * 获取容器样式
   */
  static getContainerStyle() {
    const theme = ThemeUtil.getCurrentThemeConfig();
    return {
      backgroundColor: theme.colors.background,
      width: '100%',
      height: '100%'
    };
  }

  /**
   * 获取页面内容区域样式
   */
  static getContentAreaStyle() {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const spacing = theme.spacing;
    
    return {
      backgroundColor: theme.colors.background,
      padding: `${spacing.md}px`,
      width: '100%',
      height: '100%'
    };
  }

  /**
   * 获取卡片样式
   */
  static getCardStyle(elevation: number = 1) {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const spacing = theme.spacing;
    const borderRadius = theme.borderRadius;
    
    return {
      backgroundColor: theme.colors.surface,
      borderRadius: `${borderRadius.md}px`,
      padding: `${spacing.md}px`,
      margin: `${spacing.sm}px 0`,
      shadow: elevation > 0 ? `0 ${elevation}px ${elevation + 2}px ${theme.colors.shadow}` : 'none',
      width: '100%'
    };
  }

  /**
   * 获取标题文本样式
   */
  static getTitleStyle(level: number = 1) {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const fontSize = theme.fontSize;
    
    let fontSizeValue: number;
    switch (level) {
      case 1:
        fontSizeValue = fontSize.xxl;
        break;
      case 2:
        fontSizeValue = fontSize.xl;
        break;
      case 3:
        fontSizeValue = fontSize.lg;
        break;
      default:
        fontSizeValue = fontSize.lg;
    }
    
    return {
      fontSize: `${fontSizeValue}px`,
      fontWeight: 'bold',
      color: theme.colors.onBackground,
      margin: `${theme.spacing.md}px 0`
    };
  }

  /**
   * 获取正文文本样式
   */
  static getBodyTextStyle(emphasis: 'primary' | 'secondary' | 'hint' = 'primary') {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const fontSize = theme.fontSize;
    
    let color: string;
    switch (emphasis) {
      case 'primary':
        color = theme.colors.textPrimary;
        break;
      case 'secondary':
        color = theme.colors.textSecondary;
        break;
      case 'hint':
        color = theme.colors.textHint;
        break;
    }
    
    return {
      fontSize: `${fontSize.md}px`,
      color: color,
      lineHeight: '1.5'
    };
  }

  /**
   * 获取小文本样式
   */
  static getCaptionTextStyle() {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const fontSize = theme.fontSize;
    
    return {
      fontSize: `${fontSize.sm}px`,
      color: theme.colors.textSecondary
    };
  }

  /**
   * 获取按钮样式
   */
  static getButtonStyle(variant: 'primary' | 'secondary' | 'outlined' | 'text' = 'primary') {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const spacing = theme.spacing;
    const borderRadius = theme.borderRadius;
    const fontSize = theme.fontSize;
    
    let backgroundColor: string;
    let color: string;
    let borderWidth: string = '0';
    let borderColor: string = '';
    
    switch (variant) {
      case 'primary':
        backgroundColor = theme.colors.primary;
        color = theme.colors.onPrimary;
        break;
      case 'secondary':
        backgroundColor = theme.colors.secondary;
        color = theme.colors.onSecondary;
        break;
      case 'outlined':
        backgroundColor = 'transparent';
        color = theme.colors.primary;
        borderWidth = '1px';
        borderColor = theme.colors.primary;
        break;
      case 'text':
        backgroundColor = 'transparent';
        color = theme.colors.primary;
        break;
    }
    
    return {
      backgroundColor,
      color,
      fontSize: `${fontSize.md}px`,
      fontWeight: '500',
      padding: `${spacing.sm}px ${spacing.md}px`,
      borderRadius: `${borderRadius.sm}px`,
      borderWidth,
      borderColor,
      textAlign: 'center' as const,
      opacity: 1
    };
  }

  /**
   * 获取输入框样式
   */
  static getInputStyle() {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const spacing = theme.spacing;
    const borderRadius = theme.borderRadius;
    const fontSize = theme.fontSize;
    
    return {
      backgroundColor: theme.colors.surface,
      color: theme.colors.onSurface,
      fontSize: `${fontSize.md}px`,
      padding: `${spacing.sm}px ${spacing.md}px`,
      borderRadius: `${borderRadius.sm}px`,
      borderWidth: '1px',
      borderColor: theme.colors.divider,
      width: '100%'
    };
  }

  /**
   * 获取分割线样式
   */
  static getDividerStyle() {
    const theme = ThemeUtil.getCurrentThemeConfig();
    
    return {
      height: '1px',
      backgroundColor: theme.colors.divider,
      width: '100%',
      margin: `${ThemeUtil.getSpacing('md')}px 0`
    };
  }

  /**
   * 获取阴影样式
   */
  static getShadowStyle(elevation: number = 1) {
    const theme = ThemeUtil.getCurrentThemeConfig();
    
    return {
      shadow: `0 ${elevation}px ${elevation + 2}px ${theme.colors.shadow}`,
      borderRadius: `${theme.borderRadius.md}px`
    };
  }

  /**
   * 获取悬浮按钮样式
   */
  static getFabStyle() {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const spacing = theme.spacing;
    
    return {
      backgroundColor: theme.colors.primary,
      color: theme.colors.onPrimary,
      width: '56px',
      height: '56px',
      borderRadius: '28px',
      position: 'absolute' as const,
      bottom: `${spacing.lg}px`,
      right: `${spacing.md}px`,
      shadow: `0 4px 8px ${theme.colors.shadow}`,
      justifyContent: 'center' as const,
      alignItems: 'center' as const
    };
  }

  /**
   * 获取列表项样式
   */
  static getListItemStyle(activated: boolean = false) {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const spacing = theme.spacing;
    
    return {
      backgroundColor: activated ? theme.colors.primaryVariant : theme.colors.surface,
      padding: `${spacing.md}px`,
      borderRadius: `${theme.borderRadius.sm}px`,
      margin: `${spacing.xs}px 0`,
      width: '100%'
    };
  }

  /**
   * 获取标签样式
   */
  static getChipStyle(selected: boolean = false) {
    const theme = ThemeUtil.getCurrentThemeConfig();
    const spacing = theme.spacing;
    const borderRadius = theme.borderRadius;
    
    return {
      backgroundColor: selected ? theme.colors.primary : 'transparent',
      color: selected ? theme.colors.onPrimary : theme.colors.textPrimary,
      fontSize: `${theme.fontSize.sm}px`,
      padding: `${spacing.xs}px ${spacing.sm}px`,
      borderRadius: `${borderRadius.lg}px`,
      borderWidth: '1px',
      borderColor: selected ? theme.colors.primary : theme.colors.divider,
      margin: `0 ${spacing.xs}px ${spacing.xs}px 0`
    };
  }

  /**
   * 更新页面样式
   */
  private static updatePageStyles() {
    // 这里可以根据需要添加全局样式更新逻辑
    console.log('主题已变更，页面样式需要更新');
  }
}