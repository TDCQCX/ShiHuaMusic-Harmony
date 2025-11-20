/**
 * 登录页面 - LoginPage
 * 对应小程序 pages/login/login
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { HttpUtil } from '../../utils/HttpUtil'
import { UserInfo } from '../../types/common'
import { ThemeUtil } from '../../utils/ThemeUtil'

@Component
export struct LoginPage {
  @State phoneNumber: string = ''
  @State password: string = ''
  @State isLoading: boolean = false
  @State loginMethod: 'phone' | 'email' = 'phone'

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private httpUtil: HttpUtil = new HttpUtil()

  /**
   * 输入手机号处理
   */
  private onPhoneInput(value: string): void {
    this.phoneNumber = value
  }

  /**
   * 输入密码处理
   */
  private onPasswordInput(value: string): void {
    this.password = value
  }

  /**
   * 切换登录方式
   */
  private toggleLoginMethod(): void {
    this.loginMethod = this.loginMethod === 'phone' ? 'email' : 'phone'
    // 清空输入
    this.phoneNumber = ''
    this.password = ''
  }

  /**
   * 验证输入
   */
  private validateInput(): boolean {
    if (!this.phoneNumber.trim()) {
      // TODO: 显示错误提示
      console.log('请输入手机号')
      return false
    }

    if (!this.password.trim()) {
      // TODO: 显示错误提示
      console.log('请输入密码')
      return false
    }

    if (this.phoneNumber.length < 11) {
      // TODO: 显示错误提示
      console.log('手机号格式不正确')
      return false
    }

    return true
  }

  /**
   * 登录处理
   */
  private async handleLogin(): Promise<void> {
    if (!this.validateInput()) {
      return
    }

    this.isLoading = true

    try {
      // TODO: 实现真实登录API调用
      // const response: ApiResponse = await this.httpUtil.post('/auth/login', {
      //   phone: this.phoneNumber,
      //   password: this.password,
      //   loginType: this.loginMethod
      // })

      // 模拟登录成功
      await new Promise(resolve => setTimeout(resolve, 1000)) // 模拟网络请求延迟

      const mockUserInfo: UserInfo = {
        username: '测试用户',
        avatarUrl: '/assets/images/default-avatar.png',
        userAvatar: '/assets/images/default-avatar.png',
        email: 'test@example.com',
        phone: this.phoneNumber
      }

      // 保存用户信息到全局数据管理器
      this.globalDataManager.setUserInfo(mockUserInfo)
      this.globalDataManager.setToken('mock_token_' + Date.now())
      this.globalDataManager.setLoginStatus(true)

      // TODO: 显示成功提示
      console.log('登录成功')

      // 返回上一页或跳转到首页
      try {
        router.back()
      } catch (error) {
        router.pushUrl({ url: '/pages/Index/IndexPage' })
      }

    } catch (error) {
      console.error('登录失败:', error)
      // TODO: 显示错误提示
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 跳转到注册页面
   */
  private goToRegister(): void {
    // TODO: 跳转到注册页面
    router.pushUrl({ url: '/pages/Register/RegisterPage' })
  }

  /**
   * 游客登录
   */
  private guestLogin(): void {
    // TODO: 实现游客登录逻辑
    console.log('游客登录')
    
    try {
      router.back()
    } catch (error) {
      router.pushUrl({ url: '/pages/Index/IndexPage' })
    }
  }

  /**
   * 第三方登录
   */
  private thirdPartyLogin(provider: string): void {
    // TODO: 实现第三方登录
    console.log(`${provider}登录`)
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      // 登录表单
      this.buildLoginForm()

      // 其他登录方式
      this.buildOtherLoginMethods()

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
    .padding({ top: 20 })
  }

  /**
   * 构建头部
   */
  @Builder
  private buildHeader() {
    Row() {
      Image($r('app.media.back'))
        .width(24)
        .height(24)
        .onClick(() => router.back())

      Blank()

      Text('登录')
        .fontSize(ThemeUtil.getFontSize('xl'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)

      Blank()

      Text('注册')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('primary'))
        .onClick(() => this.goToRegister())
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建登录表单
   */
  @Builder
  private buildLoginForm() {
    Column() {
      // Logo
      Column() {
        Image($r('app.media.logo'))
          .width(80)
          .height(80)
          .borderRadius(ThemeUtil.getBorderRadius('full'))
      }
      .width(100)
      .height(100)
      .margin({ top: ThemeUtil.getSpacing('xl'), bottom: ThemeUtil.getSpacing('xl') })

      // 登录方式切换
      Row() {
        Text(`手机号登录`)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(this.loginMethod === 'phone' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
          .fontWeight(this.loginMethod === 'phone' ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => {
            if (this.loginMethod !== 'phone') {
              this.toggleLoginMethod()
            }
          })

        Text(' | ')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textHint'))

        Text(`邮箱登录`)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(this.loginMethod === 'email' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
          .fontWeight(this.loginMethod === 'email' ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => {
            if (this.loginMethod !== 'email') {
              this.toggleLoginMethod()
            }
          })
      }
      .margin({ bottom: ThemeUtil.getSpacing('xl') })

      // 输入框容器
      Column({ space: ThemeUtil.getSpacing('lg') }) {
        // 手机号/邮箱输入
        TextInput({
          placeholder: this.loginMethod === 'phone' ? '请输入手机号' : '请输入邮箱地址',
          text: this.phoneNumber
        })
          .width('100%')
          .height(48)
          .backgroundColor(ThemeUtil.getColor('surface'))
          .fontSize(ThemeUtil.getFontSize('md'))
          .type(this.loginMethod === 'phone' ? InputType.PhoneNumber : InputType.EmailAddr)
          .onChange((value: string) => this.onPhoneInput(value))

        // 密码输入
        TextInput({
          placeholder: '请输入密码',
          text: this.password
        })
          .width('100%')
          .height(48)
          .backgroundColor(ThemeUtil.getColor('surface'))
          .fontSize(ThemeUtil.getFontSize('md'))
          .type(InputType.Password)
          .onChange((value: string) => this.onPasswordInput(value))
      }
      .width('90%')
      .margin({ bottom: ThemeUtil.getSpacing('xl') })

      // 登录按钮
      Button(this.isLoading ? '登录中...' : '登录')
        .width('90%')
        .height(48)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('onPrimary'))
        .backgroundColor(ThemeUtil.getColor('primary'))
        .borderRadius(ThemeUtil.getBorderRadius('full'))
        .enabled(!this.isLoading)
        .onClick(() => this.handleLogin())

      // 忘记密码
      Text('忘记密码？')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('primary'))
        .margin({ top: ThemeUtil.getSpacing('md') })
        .onClick(() => {
          // TODO: 跳转到忘记密码页面
          console.log('忘记密码')
        })
    }
    .width('100%')
    .margin({ top: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建其他登录方式
   */
  @Builder
  private buildOtherLoginMethods() {
    Column() {
      // 分隔线
      Row() {
        Text('或')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
          .backgroundColor(ThemeUtil.getColor('background'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: ThemeUtil.getSpacing('xl'), bottom: ThemeUtil.getSpacing('lg') })

      // 第三方登录按钮
      Row({ space: ThemeUtil.getSpacing('xl') }) {
        // 微信登录
        Column() {
          Image($r('app.media.share'))
            .width(40)
            .height(40)
            .borderRadius(ThemeUtil.getBorderRadius('full'))
            .backgroundColor(ThemeUtil.getColor('success'))
            .onClick(() => this.thirdPartyLogin('微信'))
          
          Text('微信')
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .margin({ top: ThemeUtil.getSpacing('sm') })
        }

        // QQ登录
        Column() {
          Image($r('app.media.user'))
            .width(40)
            .height(40)
            .borderRadius(ThemeUtil.getBorderRadius('full'))
            .backgroundColor(ThemeUtil.getColor('info'))
            .onClick(() => this.thirdPartyLogin('QQ'))
          
          Text('QQ')
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .margin({ top: ThemeUtil.getSpacing('sm') })
        }

        // 游客登录
        Column() {
          Image($r('app.media.user'))
            .width(40)
            .height(40)
            .borderRadius(ThemeUtil.getBorderRadius('full'))
            .backgroundColor(ThemeUtil.getColor('textHint'))
            .onClick(() => this.guestLogin())
          
          Text('游客')
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .margin({ top: ThemeUtil.getSpacing('sm') })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .margin({ top: ThemeUtil.getSpacing('xl') })
  }
}