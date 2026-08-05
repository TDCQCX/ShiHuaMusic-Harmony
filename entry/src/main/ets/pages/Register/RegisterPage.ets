/**
 * 注册页（用户名/邮箱/验证码/密码/确认密码）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { RegisterRequest } from '../../types/common';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State email: string = '';
  @State verificationCode: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State fieldError: string = '';
  @State countdown: number = 0;

  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private validate(): boolean {
    const usernameRegex = /^[a-zA-Z0-9_-]{4,16}$/;
    if (!usernameRegex.test(this.username)) {
      this.errorMessage = '用户名格式：4-16位字符（字母、数字、下划线、连字符）';
      return false;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.email)) {
      this.errorMessage = '请输入正确的邮箱格式';
      return false;
    }
    const codeRegex = /^[0-9a-zA-Z]{6}$/;
    if (!codeRegex.test(this.verificationCode)) {
      this.errorMessage = '验证码格式：6位字符（大小写字母、数字）';
      return false;
    }
    const pwdRegex = /^(?![0-9]+$)(?![a-zA-Z]+$)[0-9A-Za-z\W]{8,18}$/;
    if (!pwdRegex.test(this.password)) {
      this.errorMessage = '密码格式：8-18位数字、字母、符号的任意两种组合';
      return false;
    }
    if (!this.confirmPassword) {
      this.errorMessage = '请再次输入密码';
      return false;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return false;
    }
    this.errorMessage = '';
    return true;
  }

  private async handleSendCode(): Promise<void> {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.email)) {
      this.fieldError = '请先输入正确的邮箱';
      return;
    }
    try {
      const result = await ApiService.sendVerificationCode(this.email);
      if (result.code === 0) {
        this.fieldError = '';
        this.startCountdown();
      } else {
        this.fieldError = result.message || '发送验证码失败';
      }
    } catch (error) {
      this.fieldError = (error as Error).message;
    }
  }

  private startCountdown(): void {
    this.countdown = 60;
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
    this.timerId = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        clearInterval(this.timerId);
        this.timerId = -1;
      }
    }, 1000);
  }

  private async handleRegister(): Promise<void> {
    if (!this.validate()) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const request: RegisterRequest = {
        username: this.username,
        email: this.email,
        password: this.password,
        verificationCode: this.verificationCode
      };
      const result = await ApiService.register(request);
      if (result.code === 0) {
        this.getUIContext().getPromptAction().showToast({
          message: '注册成功，请登录',
          duration: 1500
        });
        NavUtil.replace('pages/Login/LoginPage');
      } else {
        this.errorMessage = result.message || '注册失败';
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private goToLogin(): void {
    NavUtil.replace('pages/Login/LoginPage');
  }

  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut })
      .opacity(0)
      .translate({ y: 24 })
    PageTransitionExit({ duration: 200, curve: Curve.EaseIn })
      .opacity(0)
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => NavUtil.back())
        Blank()
        Text('注册')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Text('')
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      // 整体靠上，与登录页保持一致的位置感
      Scroll() {
        Column() {
          Text('创建账户')
            .fontSize(ThemeUtil.getFontSize('xl'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 56, bottom: 4 })
          Text('发现更多好音乐')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: ThemeUtil.getSpacing('lg') })

          this.buildInput('用户名', this.username, '请输入用户名（4-16位）', InputType.Normal, (value: string) => {
            this.username = value;
            this.errorMessage = '';
          })
          this.buildInput('邮箱', this.email, '请输入邮箱', InputType.Email, (value: string) => {
            this.email = value;
            this.errorMessage = '';
          })

          Column() {
            Row() {
              TextInput({ placeholder: '验证码（6位）', text: this.verificationCode })
                .layoutWeight(1)
                .height(48)
                .backgroundColor(ThemeUtil.getColor('surface'))
                .borderRadius(ThemeUtil.getBorderRadius('md'))
                .onChange((value: string) => {
                  this.verificationCode = value;
                  this.errorMessage = '';
                })
              if (this.countdown > 0) {
                Button(this.countdown.toString() + 's 后重试')
                  .width(120)
                  .height(48)
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(ThemeUtil.getColor('error'))
                  .backgroundColor(ThemeUtil.getColor('surface'))
                  .borderWidth(1)
                  .borderColor(ThemeUtil.getColor('error'))
                  .borderRadius(ThemeUtil.getBorderRadius('md'))
                  .margin({ left: ThemeUtil.getSpacing('sm') })
              } else {
                Button('获取验证码')
                  .width(120)
                  .height(48)
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(ThemeUtil.getColor('onPrimary'))
                  .backgroundColor(ThemeUtil.getColor('primary'))
                  .borderRadius(ThemeUtil.getBorderRadius('md'))
                  .margin({ left: ThemeUtil.getSpacing('sm') })
                  .onClick(() => this.handleSendCode())
              }
            }
            .width('100%')

            if (this.fieldError.length > 0) {
              Text(this.fieldError)
                .fontSize(ThemeUtil.getFontSize('xs'))
                .fontColor(ThemeUtil.getColor('error'))
                .width('100%')
                .margin({ top: ThemeUtil.getSpacing('xs') })
            }
          }
          .width('100%')
          .margin({ bottom: ThemeUtil.getSpacing('md') })

          this.buildInput('密码', this.password, '请输入密码（8-18位）', InputType.Password, (value: string) => {
            this.password = value;
            this.errorMessage = '';
          })
          this.buildInput('确认密码', this.confirmPassword, '请再次输入密码', InputType.Password, (value: string) => {
            this.confirmPassword = value;
            this.errorMessage = '';
          })

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('error'))
              .width('100%')
              .margin({ bottom: ThemeUtil.getSpacing('md') })
          }

          Button(this.isLoading ? '注册中...' : '注册')
            .width('100%')
            .height(48)
            .fontSize(ThemeUtil.getFontSize('md'))
            .fontColor(ThemeUtil.getColor('onPrimary'))
            .backgroundColor(ThemeUtil.getColor('primary'))
            .borderRadius(ThemeUtil.getBorderRadius('full'))
            .enabled(!this.isLoading)
            .onClick(() => this.handleRegister())
            .margin({ bottom: ThemeUtil.getSpacing('md') })

          Row() {
            Text('已有账户？')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('textHint'))
            Text('去登录')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('primary'))
              .onClick(() => this.goToLogin())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: ThemeUtil.getSpacing('xl') })
        }
        .width('100%')
        .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  @Builder
  private buildInput(label: string, value: string, placeholder: string, inputType: InputType, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .width('100%')
        .margin({ bottom: 4 })
      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(48)
        .type(inputType)
        .backgroundColor(ThemeUtil.getColor('surface'))
        .borderRadius(ThemeUtil.getBorderRadius('md'))
        .onChange((inputValue: string) => onChange(inputValue))
        .margin({ bottom: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
  }
}
