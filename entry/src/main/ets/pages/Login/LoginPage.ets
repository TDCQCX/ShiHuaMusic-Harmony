/**
 * 登录页（邮箱 + 密码，对齐 music-client LoginForm）
 */
import { NavUtil } from '../../utils/NavUtil';
import { HttpUtil } from '../../utils/HttpUtil';
import { ApiService } from '../../api/ApiService';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { LoginRequest } from '../../types/common';
import { TabManager } from '../../utils/TabManager';

@Entry
@Component
struct LoginPage {
  @State email: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    if (this.globalData.getIsLoggedIn()) {
      NavUtil.back();
    }
  }

  private validate(): boolean {
    if (!this.email) {
      this.errorMessage = '请输入邮箱';
      return false;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.email)) {
      this.errorMessage = '请输入正确的邮箱格式';
      return false;
    }
    if (!this.password) {
      this.errorMessage = '请输入密码';
      return false;
    }
    this.errorMessage = '';
    return true;
  }

  private async handleLogin(): Promise<void> {
    if (!this.validate()) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const request: LoginRequest = {
        email: this.email,
        password: this.password
      };
      const result = await ApiService.login(request);
      if (result.code !== 0 || !result.data) {
        // 账号或密码错误等常见错误：显示在输入框上方
        this.errorMessage = result.message || '登录失败，请检查邮箱和密码';
        return;
      }
      const token = result.data;
      // 先设置 token，后续请求才会携带认证头
      HttpUtil.setToken(token);
      const userResult = await ApiService.getUserInfo();
      if (userResult.code === 0 && userResult.data) {
        const userInfo = userResult.data;
        userInfo.token = token;
        await this.globalData.setLoginStatus(userInfo, token);
        // 居中悬浮欢迎提示
        this.getUIContext().getPromptAction().showToast({
          message: '欢迎回来，' + userInfo.username,
          duration: 2000
        });
        // 跳转到“我的”Tab 并返回
        TabManager.setTab(2);
        NavUtil.back();
      } else {
        this.errorMessage = userResult.message || '获取用户信息失败';
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private goToRegister(): void {
    NavUtil.push('pages/Register/RegisterPage');
  }

  private goToReset(): void {
    NavUtil.push('pages/User/ResetPasswordPage');
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
        Text('登录')
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
          Text('欢迎回来')
            .fontSize(ThemeUtil.getFontSize('xl'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 56, bottom: 4 })
          Text('登录以继续你的音乐之旅')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: ThemeUtil.getSpacing('lg') })

          // 错误信息显示在账户输入框上方左侧
          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('error'))
              .width('100%')
              .margin({ bottom: ThemeUtil.getSpacing('sm') })
          }

          TextInput({ placeholder: '请输入邮箱', text: this.email })
            .width('100%')
            .height(48)
            .type(InputType.Email)
            .backgroundColor(ThemeUtil.getColor('surface'))
            .borderRadius(ThemeUtil.getBorderRadius('md'))
            .onChange((value: string) => {
              this.email = value;
              this.errorMessage = '';
            })
            .margin({ bottom: ThemeUtil.getSpacing('md') })

          TextInput({ placeholder: '请输入密码', text: this.password })
            .width('100%')
            .height(48)
            .type(InputType.Password)
            .backgroundColor(ThemeUtil.getColor('surface'))
            .borderRadius(ThemeUtil.getBorderRadius('md'))
            .onChange((value: string) => {
              this.password = value;
              this.errorMessage = '';
            })
            .margin({ bottom: ThemeUtil.getSpacing('md') })

          Button(this.isLoading ? '登录中...' : '登录')
            .width('100%')
            .height(48)
            .fontSize(ThemeUtil.getFontSize('md'))
            .fontColor(ThemeUtil.getColor('onPrimary'))
            .backgroundColor(ThemeUtil.getColor('primary'))
            .borderRadius(ThemeUtil.getBorderRadius('full'))
            .enabled(!this.isLoading)
            .onClick(() => this.handleLogin())

          Row() {
            Text('忘记密码？')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('primary'))
              .onClick(() => this.goToReset())
            Blank()
            Text('没有账户？去注册')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('primary'))
              .onClick(() => this.goToRegister())
          }
          .width('100%')
          .margin({ top: ThemeUtil.getSpacing('lg') })
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
}
