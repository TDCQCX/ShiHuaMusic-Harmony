/**
 * 意见反馈（对齐 music-client FeedbackDialog）
 */
import { ApiService } from '../../api/ApiService';
import { NavUtil } from '../../utils/NavUtil';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { FeedbackRequest } from '../../types/common';

@Entry
@Component
struct FeedbackPage {
  @State content: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private async handleSubmit(): Promise<void> {
    const text = this.content.trim();
    if (text.length < 10) {
      this.errorMessage = '反馈内容不能少于10个字符';
      return;
    }
    if (text.length > 200) {
      this.errorMessage = '反馈内容不能超过200个字符';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const requestData: FeedbackRequest = {
        content: text
      };
      const result = await ApiService.addFeedback(requestData);
      if (result.code === 0) {
        NavUtil.back();
      } else {
        this.errorMessage = result.message || '提交失败，请稍后再试';
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
        Text('意见反馈')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Text('提交')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(this.content.trim().length >= 10 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
          .onClick(() => this.handleSubmit())
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      Column() {
        TextArea({ placeholder: '请输入您的宝贵意见或建议（10-200字）', text: this.content })
          .width('100%')
          .height(160)
          .backgroundColor(ThemeUtil.getColor('surface'))
          .borderRadius(ThemeUtil.getBorderRadius('md'))
          .onChange((value: string) => {
            this.content = value;
          })

        Row() {
          Text(this.content.length.toString() + '/200')
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textHint'))
          Blank()
        }
        .width('100%')
        .margin({ top: ThemeUtil.getSpacing('xs') })

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('error'))
            .width('100%')
            .margin({ top: ThemeUtil.getSpacing('sm') })
        }

        Button(this.isLoading ? '提交中...' : '提交反馈')
          .width('100%')
          .height(48)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('onPrimary'))
          .backgroundColor(ThemeUtil.getColor('primary'))
          .borderRadius(ThemeUtil.getBorderRadius('lg'))
          .enabled(!this.isLoading)
          .onClick(() => this.handleSubmit())
          .margin({ top: ThemeUtil.getSpacing('lg') })
      }
      .width('100%')
      .padding(ThemeUtil.getSpacing('md'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
