import { ThemeUtil } from '../../utils/ThemeUtil';

@Component
export struct ErrorView {
  @Prop message: string = '加载失败';
  onRetry?: () => void;

  build() {
    Column() {
      Text('✕')
        .fontSize(48)
        .fontColor(ThemeUtil.getColor('textHint'))
        .opacity(0.4)
        .margin({ bottom: ThemeUtil.getSpacing('md') })
      Text(this.message)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .margin({ bottom: ThemeUtil.getSpacing('lg') })
      Button('重试')
        .width(120)
        .height(40)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('onPrimary'))
        .backgroundColor(ThemeUtil.getColor('primary'))
        .borderRadius(ThemeUtil.getBorderRadius('lg'))
        .onClick(() => {
          if (this.onRetry) {
            this.onRetry();
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
