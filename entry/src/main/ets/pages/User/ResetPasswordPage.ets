/**
 * 重置密码页（邮箱/验证码/新密码/确认密码，对齐 music-client ResetPasswordForm）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { ResetPasswordRequest } from '../../types/common';

@Entry
@Component
struct ResetPasswordPage {
  @State email: string = '';
  @State verificationCode: string = '';
  @State newPassword: string = '';
  @State repeatPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State countdown: number = 0;

  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private validate(): boolean {
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
    if (!pwdRegex.test(this.newPassword)) {
      this.errorMessage = '密码格式：8-18位数字、字母、符号的任意两种组合';
      return false;
    }
    if (this.newPassword !== this.repeatPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return false;
    }
    this.errorMessage = '';
    return true;
  }

  private async handleSendCode(): Promise<void> {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.email)) {
      this.errorMessage = '请先输入正确的邮箱';
      return;
    }
    try {
      const result = await ApiService.sendVerificationCode(this.email);
      if (result.code === 0) {
        this.errorMessage = '';
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
      } else {
        this.errorMessage = result.message || '发送验证码失败';
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private async handleReset(): Promise<void> {
    if (!this.validate()) {
      return;
    }
    this.isLoading = true;
    try {
      const request: ResetPasswordRequest = {
        email: this.email,
        verificationCode: this.verificationCode,
        newPassword: this.newPassword,
        repeatPassword: this.repeatPassword
      };
      const result = await ApiService.resetPassword(request);
      if (result.code === 0) {
        NavUtil.replace('pages/Login/LoginPage');
      } else {
        this.errorMessage = result.message || '密码重置失败';
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
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
        Text('重置密码')
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

      Scroll() {
        Column() {
          Text('重置密码')
            .fontSize(ThemeUtil.getFontSize('xl'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
            .margin({ top: 40, bottom: 8 })
          Text('我们将向您的邮箱发送验证码')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .margin({ bottom: 32 })

          this.buildInput('邮箱', this.email, '请输入邮箱', InputType.Email, (value: string) => {
            this.email = value;
          })

          Row() {
            TextInput({ placeholder: '验证码（6位）', text: this.verificationCode })
              .layoutWeight(1)
              .height(48)
              .backgroundColor(ThemeUtil.getColor('surface'))
              .borderRadius(ThemeUtil.getBorderRadius('md'))
              .onChange((value: string) => {
                this.verificationCode = value;
              })
            Button(this.countdown > 0 ? this.countdown.toString() + 's' : '获取验证码')
              .width(110)
              .height(48)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(this.countdown > 0 ? ThemeUtil.getColor('textHint') : ThemeUtil.getColor('onPrimary'))
              .backgroundColor(this.countdown > 0 ? ThemeUtil.getColor('divider') : ThemeUtil.getColor('primary'))
              .borderRadius(ThemeUtil.getBorderRadius('md'))
              .enabled(this.countdown <= 0)
              .onClick(() => this.handleSendCode())
          }
          .width('88%')
          .margin({ bottom: ThemeUtil.getSpacing('md') })

          this.buildInput('新密码', this.newPassword, '请输入新密码（8-18位）', InputType.Password, (value: string) => {
            this.newPassword = value;
          })
          this.buildInput('确认密码', this.repeatPassword, '请再次输入新密码', InputType.Password, (value: string) => {
            this.repeatPassword = value;
          })

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('error'))
              .margin({ bottom: ThemeUtil.getSpacing('md') })
          }

          Button(this.isLoading ? '提交中...' : '重置密码')
            .width('88%')
            .height(48)
            .fontSize(ThemeUtil.getFontSize('md'))
            .fontColor(ThemeUtil.getColor('onPrimary'))
            .backgroundColor(ThemeUtil.getColor('primary'))
            .borderRadius(ThemeUtil.getBorderRadius('full'))
            .enabled(!this.isLoading)
            .onClick(() => this.handleReset())
            .margin({ bottom: 32 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
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
        .width('88%')
        .margin({ bottom: 4 })
      TextInput({ placeholder: placeholder, text: value })
        .width('88%')
        .height(48)
        .type(inputType)
        .backgroundColor(ThemeUtil.getColor('surface'))
        .borderRadius(ThemeUtil.getBorderRadius('md'))
        .onChange((inputValue: string) => onChange(inputValue))
        .margin({ bottom: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
