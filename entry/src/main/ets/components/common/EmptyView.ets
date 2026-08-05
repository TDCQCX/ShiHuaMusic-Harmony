import { ThemeUtil } from '../../utils/ThemeUtil';

@Component
export struct EmptyView {
  @Prop message: string = '暂无数据';
  @Prop subMessage: string = '';

  build() {
    Column() {
      Text('♪')
        .fontSize(56)
        .fontColor(ThemeUtil.getColor('textHint'))
        .opacity(0.4)
        .margin({ bottom: ThemeUtil.getSpacing('md') })
      Text(this.message)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .margin({ bottom: ThemeUtil.getSpacing('sm') })
      if (this.subMessage.length > 0) {
        Text(this.subMessage)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
