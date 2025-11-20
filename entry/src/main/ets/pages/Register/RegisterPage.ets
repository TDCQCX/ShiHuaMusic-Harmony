/**
 * 注册页面 - RegisterPage
 * 对应小程序 pages/register/register
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { HttpUtil } from '../../utils/HttpUtil'
import { ThemeUtil } from '../../utils/ThemeUtil'

interface RegisterData {
  phone: string
  email: string
  password: string
  confirmPassword: string
  nickname: string
  captcha: string
}

@Component
export struct RegisterPage {
  @State registerData: RegisterData = {
    phone: '',
    email: '',
    password: '',
    confirmPassword: '',
    nickname: '',
    captcha: ''
  }
  @State registerMethod: 'phone' | 'email' = 'phone'
  @State captchaCountdown: number = 0
  @State isLoading: boolean = false
  @State showPassword: boolean = false
  @State showConfirmPassword: boolean = false

  private httpUtil: HttpUtil = new HttpUtil()
  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private captchaTimer: number = -1

  /**
   * 页面即将消失
   */
  aboutToDisappear(): void {
    if (this.captchaTimer !== -1) {
      clearInterval(this.captchaTimer)
    }
  }

  /**
   * 发送验证码
   */
  private async sendCaptcha(): Promise<void> {
    const contact = registerMethod === 'phone' ? this.registerData.phone : this.registerData.email
    
    if (!contact) {
      return
    }

    if (registerMethod === 'phone' && !/^1[3-9]\d{9}$/.test(contact)) {
      return
    }

    if (registerMethod === 'email' && !/^\w+([.-]\w+)*@\w+([.-]\w+)*\.\w+$/.test(contact)) {
      return
    }

    try {
      // TODO: 调用真实API
      // const response = await this.httpUtil.post('/auth/send-captcha', {
      //   type: 'register',
      //   contact: contact,
      //   method: registerMethod
      // })

      // 模拟发送验证码
      console.log(`发送验证码到 ${contact}`)
      
      // 开始倒计时
      this.captchaCountdown = 60
      this.captchaTimer = setInterval(() => {
        if (this.captchaCountdown > 0) {
          this.captchaCountdown--
        } else {
          clearInterval(this.captchaTimer)
          this.captchaTimer = -1
        }
      }, 1000)
    } catch (error) {
      console.error('发送验证码失败:', error)
    }
  }

  /**
   * 注册验证
   */
  private validateForm(): boolean {
    const { password, confirmPassword, nickname, captcha } = this.registerData
    const contact = this.registerMethod === 'phone' ? this.registerData.phone : this.registerData.email

    // 验证联系方式
    if (!contact) {
      return false
    }

    if (this.registerMethod === 'phone' && !/^1[3-9]\d{9}$/.test(contact)) {
      return false
    }

    if (this.registerMethod === 'email' && !/^\w+([.-]\w+)*@\w+([.-]\w+)*\.\w+$/.test(contact)) {
      return false
    }

    // 验证密码
    if (!password || password.length < 6) {
      return false
    }

    // 验证确认密码
    if (password !== confirmPassword) {
      return false
    }

    // 验证昵称
    if (!nickname || nickname.length < 2) {
      return false
    }

    // 验证验证码
    if (!captcha) {
      return false
    }

    return true
  }

  /**
   * 提交注册
   */
  private async submitRegister(): Promise<void> {
    if (!this.validateForm()) {
      return
    }

    try {
      this.isLoading = true

      const requestData = {
        password: this.registerData.password,
        nickname: this.registerData.nickname,
        captcha: this.registerData.captcha
      }

      if (this.registerMethod === 'phone') {
        Object.assign(requestData, { phone: this.registerData.phone })
      } else {
        Object.assign(requestData, { email: this.registerData.email })
      }

      // TODO: 调用真实API
      // const response = await this.httpUtil.post('/auth/register', requestData)
      
      // 模拟注册成功
      await new Promise(resolve => setTimeout(resolve, 2000))

      // 注册成功，跳转到首页
      router.pushUrl({ url: '/pages/Index/IndexPage' })
    } catch (error) {
      console.error('注册失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 切换注册方式
   */
  private switchMethod(method: 'phone' | 'email'): void {
    this.registerMethod = method
    this.registerData.captcha = '' // 切换方式时清空验证码
  }

  /**
   * 跳转到用户协议
   */
  private goToUserAgreement(): void {
    // TODO: 实现用户协议页面
    console.log('跳转到用户协议')
  }

  /**
   * 跳转到隐私政策
   */
  private goToPrivacyPolicy(): void {
    // TODO: 实现隐私政策页面
    console.log('跳转到隐私政策')
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      Scroll() {
        Column() {
          // 应用logo
          this.buildLogo()

          // 注册表单
          this.buildRegisterForm()

          // 注册按钮
          this.buildSubmitButton()

          // 底部协议
          this.buildAgreementText()
        }
        .width('100%')
      }
      .layoutWeight(1)

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
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

      Text('注册')
        .fontSize(ThemeUtil.getFontSize('xl'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建Logo
   */
  @Builder
  private buildLogo() {
    Column() {
      Image($r('app.media.logo'))
        .width(80)
        .height(80)
        .margin({ bottom: ThemeUtil.getSpacing('md') })

      Text('欢迎注册')
        .fontSize(ThemeUtil.getFontSize('xxl'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: ThemeUtil.getSpacing('sm') })

      Text('发现更多好音乐')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
    }
    .width('100%')
    .height(180)
    .justifyContent(FlexAlign.Center)
    .margin({ top: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('xl') })
  }

  /**
   * 构建注册表单
   */
  @Builder
  private buildRegisterForm() {
    Column() {
      // 注册方式切换
      this.buildMethodTabs()

      // 联系方式输入
      this.buildContactInput()

      // 昵称输入
      this.buildNicknameInput()

      // 密码输入
      this.buildPasswordInput()

      // 确认密码输入
      this.buildConfirmPasswordInput()

      // 验证码输入
      this.buildCaptchaInput()
    }
    .width('100%')
    .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })
  }

  /**
   * 构建方式切换
   */
  @Builder
  private buildMethodTabs() {
    Row() {
      Text('手机号注册')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.registerMethod === 'phone' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
        .fontWeight(this.registerMethod === 'phone' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.switchMethod('phone'))

      Text(' | ')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textHint'))

      Text('邮箱注册')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.registerMethod === 'email' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
        .fontWeight(this.registerMethod === 'email' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.switchMethod('email'))
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建联系方式输入
   */
  @Builder
  private buildContactInput() {
    Row() {
      Image($r('app.media.user'))
        .width(16)
        .height(16)
        .margin({ right: 10 })

      TextInput({
        placeholder: this.registerMethod === 'phone' ? '请输入手机号' : '请输入邮箱',
        text: this.registerMethod === 'phone' ? this.registerData.phone : this.registerData.email
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .type(this.registerMethod === 'phone' ? InputType.PhoneNumber : InputType.Email)
        .onChange((value: string) => {
          if (this.registerMethod === 'phone') {
            this.registerData.phone = value
          } else {
            this.registerData.email = value
          }
        })

      if (this.captchaCountdown > 0) {
        Text(`${this.captchaCountdown}s`)
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('textHint'))
      } else {
        Text('获取验证码')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('primary'))
          .onClick(() => this.sendCaptcha())
      }
    }
    .width('100%')
    .height(50)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('md'))
    .padding({ left: ThemeUtil.getSpacing('sm'), right: ThemeUtil.getSpacing('sm') })
    .margin({ bottom: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建昵称输入
   */
  @Builder
  private buildNicknameInput() {
    Row() {
      Image($r('app.media.user'))
        .width(16)
        .height(16)
        .margin({ right: 10 })

      TextInput({
        placeholder: '请输入昵称（2-20个字符）',
        text: this.registerData.nickname
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => {
          this.registerData.nickname = value
        })
    }
    .width('100%')
    .height(50)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('md'))
    .padding({ left: ThemeUtil.getSpacing('sm'), right: ThemeUtil.getSpacing('sm') })
    .margin({ bottom: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建密码输入
   */
  @Builder
  private buildPasswordInput() {
    Row() {
      Image($r('app.media.lock'))
        .width(16)
        .height(16)
        .margin({ right: 10 })

      TextInput({
        placeholder: '请输入密码（至少6位）',
        text: this.registerData.password
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .type(this.showPassword ? InputType.Normal : InputType.Password)
        .onChange((value: string) => {
          this.registerData.password = value
        })

      Image(this.showPassword ? $r('app.media.eye-open') : $r('app.media.eye-close'))
        .width(16)
        .height(16)
        .onClick(() => {
          this.showPassword = !this.showPassword
        })
    }
    .width('100%')
    .height(50)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('md'))
    .padding({ left: ThemeUtil.getSpacing('sm'), right: ThemeUtil.getSpacing('sm') })
    .margin({ bottom: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建确认密码输入
   */
  @Builder
  private buildConfirmPasswordInput() {
    Row() {
      Image($r('app.media.lock'))
        .width(16)
        .height(16)
        .margin({ right: 10 })

      TextInput({
        placeholder: '请再次输入密码',
        text: this.registerData.confirmPassword
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .type(this.showConfirmPassword ? InputType.Normal : InputType.Password)
        .onChange((value: string) => {
          this.registerData.confirmPassword = value
        })

      Image(this.showConfirmPassword ? $r('app.media.eye-open') : $r('app.media.eye-close'))
        .width(16)
        .height(16)
        .onClick(() => {
          this.showConfirmPassword = !this.showConfirmPassword
        })
    }
    .width('100%')
    .height(50)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('md'))
    .padding({ left: ThemeUtil.getSpacing('sm'), right: ThemeUtil.getSpacing('sm') })
    .margin({ bottom: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建验证码输入
   */
  @Builder
  private buildCaptchaInput() {
    Row() {
      Image($r('app.media.captcha'))
        .width(16)
        .height(16)
        .margin({ right: 10 })

      TextInput({
        placeholder: '请输入验证码',
        text: this.registerData.captcha
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .type(InputType.Number)
        .onChange((value: string) => {
          this.registerData.captcha = value
        })
    }
    .width('100%')
    .height(50)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('md'))
    .padding({ left: ThemeUtil.getSpacing('sm'), right: ThemeUtil.getSpacing('sm') })
    .margin({ bottom: ThemeUtil.getSpacing('lg') })
  }

  /**
   * 构建提交按钮
   */
  @Builder
  private buildSubmitButton() {
    Button('注册')
      .width('100%')
      .height(48)
      .backgroundColor(ThemeUtil.getColor('primary'))
      .fontSize(ThemeUtil.getFontSize('md'))
      .fontColor(ThemeUtil.getColor('onPrimary'))
      .enabled(this.validateForm() && !this.isLoading)
      .onClick(() => this.submitRegister())
      .margin({ bottom: ThemeUtil.getSpacing('md') })

    if (this.isLoading) {
      LoadingProgress()
        .width(20)
        .height(20)
        .color(ThemeUtil.getColor('primary'))
        .margin({ bottom: ThemeUtil.getSpacing('md') })
    }
  }

  /**
   * 构建协议文本
   */
  @Builder
  private buildAgreementText() {
    Row() {
      Text('注册即表示同意')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))

      Text('《用户协议》')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('primary'))
        .onClick(() => this.goToUserAgreement())

      Text('和')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))

      Text('《隐私政策》')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('primary'))
        .onClick(() => this.goToPrivacyPolicy())
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: ThemeUtil.getSpacing('xl') })
  }
}