/**
 * 用户页面 - UserPage
 * 对应小程序 pages/user/user
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { ThemeUtil, ThemeType } from '../../utils/ThemeUtil'
import { StyleUtil } from '../../utils/StyleUtil'
import { UserInfo } from '../../types/common'

@Component
export struct UserPage {
  @State isLoggedIn: boolean = false
  @State userInfo: UserInfo = {
    username: '',
    avatarUrl: '',
    userAvatar: '',
    email: '',
    phone: ''
  }

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()

  /**
   * 检查登录状态
   */
  private async checkLoginStatus(): Promise<void> {
    try {
      const isValid = await this.globalDataManager.checkLoginStatus()
      this.isLoggedIn = isValid
      
      if (isValid) {
        this.fetchUserProfile()
      } else {
        // 确保状态被正确重置为未登录
        this.userInfo = {
          username: '',
          avatarUrl: '',
          userAvatar: '',
          email: '',
          phone: ''
        }
      }
    } catch (error) {
      console.error('检查登录状态失败:', error)
      this.isLoggedIn = false
    }
  }

  /**
   * 获取用户信息
   */
  private async fetchUserProfile(): Promise<void> {
    try {
      // 先检查全局用户信息是否存在
      const savedUserInfo = this.globalDataManager.getUserInfo()
      if (savedUserInfo) {
        this.userInfo = savedUserInfo
        return
      }

      // TODO: 调用API获取用户信息
      // const response: ApiResponse = await this.httpUtil.get('/user/getUserInfo')
      // if (response.success || response.code === 0) {
      //   const userData = response.data || response
      //   this.userInfo = userData
      //   this.globalDataManager.setUserInfo(userData)
      // }

      // 模拟数据
      this.userInfo = {
        username: '测试用户',
        avatarUrl: '/assets/images/default-avatar.png',
        userAvatar: '/assets/images/default-avatar.png',
        email: 'test@example.com',
        phone: '13800138000'
      }
    } catch (error) {
      console.error('获取用户信息失败:', error)
    }
  }

  /**
   * 跳转到登录页面
   */
  private goToLogin(): void {
    router.pushUrl({ url: '/pages/Login/LoginPage' })
  }

  /**
   * 导航到编辑个人信息页面
   */
  private navigateToEdit(): void {
    if (!this.isLoggedIn) {
      this.goToLogin()
      return
    }
    router.pushUrl({ url: '/pages/User/UserEditPage' })
  }

  /**
   * 跳转到最近播放页面
   */
  private goToRecent(): void {
    if (!this.isLoggedIn) {
      this.goToLogin()
      return
    }
    router.pushUrl({ url: '/pages/RecentPlay/RecentPlayPage' })
  }

  /**
   * 跳转到我的歌单页面
   */
  private goToPlaylists(): void {
    if (!this.isLoggedIn) {
      this.goToLogin()
      return
    }
    router.pushUrl({ url: '/pages/MyPlaylists/MyPlaylistsPage' })
  }

  /**
   * 跳转到我的喜欢页面
   */
  private goToFavorites(): void {
    if (!this.isLoggedIn) {
      this.goToLogin()
      return
    }
    router.pushUrl({ url: '/pages/MyFavorites/MyFavoritesPage' })
  }

  /**
   * 退出登录
   */
  private handleLogout(): void {
    // TODO: 实现确认对话框
    try {
      // 清除登录状态和用户信息
      this.globalDataManager.clearUserInfo()
      this.globalDataManager.clearToken()
      
      // 刷新页面以显示未登录状态
      this.isLoggedIn = false
      this.userInfo = {
        username: '',
        avatarUrl: '',
        userAvatar: '',
        email: '',
        phone: ''
      }

      // TODO: 显示成功提示
      console.log('已退出登录')
    } catch (error) {
      console.error('退出登录失败:', error)
    }
  }

  aboutToAppear(): void {
    this.checkLoginStatus()
    // 初始化样式系统
    StyleUtil.init()
  }

  build() {
    Column() {
      // 用户信息区域
      if (!this.isLoggedIn) {
        // 未登录状态
        this.buildUnloggedInView()
      } else {
        // 已登录状态
        this.buildLoggedInView()
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 构建未登录状态视图
   */
  @Builder
  private buildUnloggedInView() {
    Column() {
      // 头像容器
      Column() {
        Image($r('app.media.logo'))
          .width(80)
          .height(80)
          .borderRadius(ThemeUtil.getBorderRadius('full'))
          .backgroundColor(ThemeUtil.getColor('surface'))
      }
      .width(100)
      .height(100)
      .margin({ top: ThemeUtil.getSpacing('xl'), bottom: ThemeUtil.getSpacing('lg') })

      // 登录按钮
      Button('登录/注册')
        .width(200)
        .height(48)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('onPrimary'))
        .backgroundColor(ThemeUtil.getColor('primary'))
        .borderRadius(ThemeUtil.getBorderRadius('lg'))
        .onClick(() => this.goToLogin())
        .margin({ bottom: ThemeUtil.getSpacing('md') })

      // 提示文字
      Text('登录后可体验更多功能')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textHint'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 构建已登录状态视图
   */
  @Builder
  private buildLoggedInView() {
    Column() {
      // 顶部用户信息区
      this.buildProfileHeader()

      // 我的音乐功能区
      this.buildMusicSection()

      // 退出登录按钮
      this.buildLogoutButton()
    }
    .width('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 构建个人资料头部
   */
  @Builder
  private buildProfileHeader() {
    Row() {
      // 头像
      Column() {
        Image(this.userInfo.userAvatar || this.userInfo.avatarUrl || $r('app.media.default-avatar'))
          .width(60)
          .height(60)
          .borderRadius(ThemeUtil.getBorderRadius('full'))
          .backgroundColor(ThemeUtil.getColor('surface'))
      }
      .width(80)
      .height(80)
      .margin({ right: ThemeUtil.getSpacing('md') })

      // 用户信息
      Column() {
        Text(this.userInfo.username || '未知用户')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .margin({ bottom: ThemeUtil.getSpacing('xs') })

        Text('点击编辑个人信息')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 箭头
      Image($r('app.media.arrow-right'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(100)
    .padding(ThemeUtil.getSpacing('md'))
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: ThemeUtil.getSpacing('sm') })
    .onClick(() => this.navigateToEdit())
  }

  /**
   * 构建音乐功能区
   */
  @Builder
  private buildMusicSection() {
    Column() {
      // 最近播放
      this.buildMusicItem($r('app.media.history'), '最近播放', () => this.goToRecent())

      // 我的歌单
      this.buildMusicItem($r('app.media.playlist'), '我的歌单', () => this.goToPlaylists())

      // 我的喜欢
      this.buildMusicItem($r('app.media.like-active'), '我的喜欢', () => this.goToFavorites())
    }
    .width('100%')
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: ThemeUtil.getSpacing('sm') })
  }

  /**
   * 构建音乐功能项
   */
  @Builder
  private buildMusicItem(icon: Resource, text: string, onClick: () => void) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ right: ThemeUtil.getSpacing('md') })

      Text(text)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .layoutWeight(1)

      Image($r('app.media.arrow-right'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(60)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(onClick)
  }

  /**
   * 构建退出登录按钮
   */
  @Builder
  private buildLogoutButton() {
    Button('退出登录')
      .width('90%')
      .height(48)
      .fontSize(ThemeUtil.getFontSize('md'))
      .fontColor(ThemeUtil.getColor('error'))
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderWidth(1)
      .borderColor(ThemeUtil.getColor('error'))
      .borderRadius(ThemeUtil.getBorderRadius('lg'))
      .onClick(() => this.handleLogout())
      .margin({ top: ThemeUtil.getSpacing('xl') })
  }
}