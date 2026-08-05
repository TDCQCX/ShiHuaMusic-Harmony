import { ThemeUtil } from '../../utils/ThemeUtil';

@Component
export struct LoadingView {
  @Prop message: string = '加载中...';

  build() {
    Column() {
      LoadingProgress()
        .width(36)
        .height(36)
        .color(ThemeUtil.getColor('primary'))
      Text(this.message)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ top: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
