/**
 * 我的（用户信息栏 + 功能列表）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil, ThemeType } from '../../utils/ThemeUtil';
import { UserInfo } from '../../types/common';
import { TabManager } from '../../utils/TabManager';

@Component
export struct UserPage {
  @State isLoggedIn: boolean = false;
  @State userInfo: UserInfo | null = null;
  @State themeRefresh: number = 0;
  @State showThemeDialog: boolean = false;

  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private tabListener: (index: number) => void = (index: number) => {
    if (index === 2) {
      this.checkLoginStatus();
    }
  };
  private themeListener: (theme: ThemeType) => void = (theme: ThemeType) => {
    this.themeRefresh++;
  };

  aboutToAppear(): void {
    this.checkLoginStatus();
    TabManager.onTabChange(this.tabListener);
    ThemeUtil.addThemeChangeListener(this.themeListener);
  }

  aboutToDisappear(): void {
    TabManager.offTabChange(this.tabListener);
    ThemeUtil.removeThemeChangeListener(this.themeListener);
  }

  private async checkLoginStatus(): Promise<void> {
    this.isLoggedIn = this.globalData.getIsLoggedIn();
    if (this.isLoggedIn) {
      this.userInfo = this.globalData.getUserInfo();
      const valid = await this.globalData.checkLoginStatus();
      this.isLoggedIn = valid;
      this.userInfo = this.globalData.getUserInfo();
    } else {
      this.userInfo = null;
    }
  }

  private goToLogin(): void {
    NavUtil.push('pages/Login/LoginPage');
  }

  private goToEdit(): void {
    if (!this.isLoggedIn) {
      this.goToLogin();
      return;
    }
    NavUtil.push('pages/User/UserEditPage');
  }

  private goToRecent(): void {
    if (!this.isLoggedIn) {
      this.goToLogin();
      return;
    }
    NavUtil.push('pages/RecentPlay/RecentPlayPage');
  }

  private goToPlaylists(): void {
    if (!this.isLoggedIn) {
      this.goToLogin();
      return;
    }
    NavUtil.push('pages/Playlist/PlaylistListPage');
  }

  private goToFavorites(): void {
    if (!this.isLoggedIn) {
      this.goToLogin();
      return;
    }
    NavUtil.push('pages/MyFavorites/MyFavoritesPage');
  }

  private goToFeedback(): void {
    NavUtil.push('pages/User/FeedbackPage');
  }

  private goToTheme(): void {
    this.showThemeDialog = true;
  }

  private async applyTheme(theme: ThemeType): Promise<void> {
    this.showThemeDialog = false;
    await ThemeUtil.setTheme(theme);
  }

  private handleLogout(): void {
    this.getUIContext().showAlertDialog({
      title: '确认退出',
      message: '确定要退出登录吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '退出',
        fontColor: ThemeUtil.getColor('error'),
        action: () => {
          this.doLogout();
        }
      }
    });
  }

  private async doLogout(): Promise<void> {
    try {
      await ApiService.logout();
    } catch (error) {
      console.warn('退出接口调用失败，继续清理本地状态');
    }
    await this.globalData.clearLoginStatus();
    this.isLoggedIn = false;
    this.userInfo = null;
  }

  build() {
    // 显式 TopStart：避免 Stack 默认 Center 导致内容居中
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Scroll() {
          Column() {
            // 顶部用户信息栏
            this.buildUserCard()

            // 功能列表
          Column() {
            this.buildMenuEntry($r('app.media.history'), '最近播放', () => this.goToRecent())
            this.buildSymbolMenuEntry($r('sys.symbol.music_note_list'), '我的歌单', () => this.goToPlaylists())
            this.buildSymbolMenuEntry($r('sys.symbol.heart'), '我的喜欢', () => this.goToFavorites())
          }
            .width('100%')
            .backgroundColor(ThemeUtil.getColor('surface'))
            .borderRadius(ThemeUtil.getBorderRadius('lg'))
            .margin({ bottom: ThemeUtil.getSpacing('sm') })

          Column() {
            this.buildSymbolMenuEntry($r('sys.symbol.paintbrush'), '主题设置', () => this.goToTheme())
            this.buildMenuEntry($r('app.media.comment'), '意见反馈', () => this.goToFeedback())
          }
            .width('100%')
            .backgroundColor(ThemeUtil.getColor('surface'))
            .borderRadius(ThemeUtil.getBorderRadius('lg'))
            .margin({ bottom: ThemeUtil.getSpacing('sm') })

            if (this.isLoggedIn) {
              Button('退出登录')
                .width('100%')
                .height(48)
                .fontSize(ThemeUtil.getFontSize('md'))
                .fontColor(ThemeUtil.getColor('error'))
                .backgroundColor(ThemeUtil.getColor('surface'))
                .borderWidth(1)
                .borderColor(ThemeUtil.getColor('error'))
                .borderRadius(ThemeUtil.getBorderRadius('lg'))
                .onClick(() => this.handleLogout())
                .margin({ top: ThemeUtil.getSpacing('md') })
            }
          }
          .width('100%')
        .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('md') })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)

      // 主题设置：居中弹窗卡片（白色 / 黑色）
      if (this.showThemeDialog) {
        this.buildThemeDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
    .opacity(this.themeRefresh >= 0 ? 1 : 1)
  }

  @Builder
  private buildThemeDialog() {
    Column() {
      Column() {
        Text('主题设置')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .margin({ top: ThemeUtil.getSpacing('lg'), bottom: ThemeUtil.getSpacing('md') })

        Row() {
          this.buildThemeCard('白色', '白天模式', ThemeType.LIGHT)
          this.buildThemeCard('黑色', '深色模式', ThemeType.DARK)
        }
        .width('100%')
        .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })

        Text('取消')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .margin({ top: ThemeUtil.getSpacing('lg'), bottom: ThemeUtil.getSpacing('lg') })
          .onClick(() => this.showThemeDialog = false)
      }
      .width('86%')
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderRadius(ThemeUtil.getBorderRadius('xl'))
      .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.25)' })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('overlay'))
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.showThemeDialog = false)
  }

  @Builder
  private buildThemeCard(name: string, desc: string, theme: ThemeType) {
    Column() {
      Circle()
        .width(48)
        .height(48)
        .fill(theme === ThemeType.DARK ? '#1E1E1E' : '#FFFFFF')
        .stroke(theme === ThemeType.DARK ? '#3A3A3A' : '#D0D0D0')
        .strokeWidth(2)
        .margin({ bottom: ThemeUtil.getSpacing('sm') })
      Text(name)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.getColor('textPrimary'))
      Text(desc)
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .padding(ThemeUtil.getSpacing('md'))
    .backgroundColor(ThemeUtil.getColor('background'))
    .borderRadius(ThemeUtil.getBorderRadius('lg'))
    .margin({ right: ThemeUtil.getSpacing('sm') })
    .onClick(() => this.applyTheme(theme))
  }

  @Builder
  private buildUserCard() {
    Row() {
      Image(this.isLoggedIn && this.userInfo ?
        (this.userInfo.avatarUrl || this.userInfo.userAvatar || $r('app.media.default_avatar')) :
        $r('app.media.default_avatar'))
        .width(64)
        .height(64)
        .borderRadius(ThemeUtil.getBorderRadius('full'))
        .objectFit(ImageFit.Cover)
        .backgroundColor(ThemeUtil.getColor('surface'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      Column() {
        if (this.isLoggedIn && this.userInfo) {
          Text(this.userInfo.username)
            .fontSize(ThemeUtil.getFontSize('lg'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
          Text(this.userInfo.email)
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .margin({ top: 4 })
        } else {
          Text('未登录')
            .fontSize(ThemeUtil.getFontSize('lg'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
          Text('登录后可收藏歌曲、歌单，同步你的音乐')
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.isLoggedIn) {
        Column() {
          Image($r('app.media.arrow_right'))
            .width(20)
            .height(20)
        }
        .onClick(() => this.goToEdit())
      } else {
        Button('登录/注册')
          .width(96)
          .height(36)
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('onPrimary'))
          .backgroundColor(ThemeUtil.getColor('primary'))
          .borderRadius(ThemeUtil.getBorderRadius('full'))
          .onClick(() => this.goToLogin())
      }
    }
    .width('100%')
    .padding(ThemeUtil.getSpacing('lg'))
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('lg'))
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.06)', offsetY: 3 })
    .margin({ bottom: ThemeUtil.getSpacing('md') })
  }

  @Builder
  private buildMenuEntry(icon: Resource, text: string, onClick: () => void) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ right: ThemeUtil.getSpacing('md') })
      Text(text)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .layoutWeight(1)
      Image($r('app.media.arrow_right'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(() => onClick())
  }

  @Builder
  private buildSymbolMenuEntry(symbol: Resource, text: string, onClick: () => void) {
    Row() {
      SymbolGlyph(symbol)
        .fontSize(22)
        .fontColor([ThemeUtil.getColor('textPrimary')])
        .margin({ right: ThemeUtil.getSpacing('md') })
      Text(text)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .layoutWeight(1)
      Image($r('app.media.arrow_right'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(() => onClick())
  }
}
