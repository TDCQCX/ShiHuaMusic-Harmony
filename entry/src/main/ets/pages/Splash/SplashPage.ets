/**
 * 启动界面（Splash）：深紫渐变背景 + 白色圆角图标卡 + 应用名 + 动态频谱
 * 展示约 1.9s 后淡出并替换到主界面，样式与应用图标（cover.png）保持一致
 */
import { NavUtil } from '../../utils/NavUtil';

@Entry
@Component
struct SplashPage {
  @State coverScale: number = 0.72;
  @State coverOpacity: number = 0;
  @State titleOpacity: number = 0;
  @State titleTranslate: number = 16;
  @State taglineOpacity: number = 0;
  @State pageOpacity: number = 1;
  @State eqTick: number = 0;

  private timerId: number = -1;
  private eqTimer: number = -1;

  aboutToAppear(): void {
    // 图标卡：放大 + 淡入
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 560, curve: Curve.EaseOut }, () => {
        this.coverScale = 1;
        this.coverOpacity = 1;
      });
    }, 60);
    // 标题与副标题：上移淡入
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 480, curve: Curve.EaseOut }, () => {
        this.titleOpacity = 1;
        this.titleTranslate = 0;
      });
    }, 380);
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 460, curve: Curve.EaseOut }, () => {
        this.taglineOpacity = 1;
      });
    }, 560);

    // 动态频谱：模拟播放中的律动
    this.eqTimer = setInterval(() => {
      this.eqTick++;
    }, 120);

    // 停留后整体淡出并替换到主界面
    this.timerId = setTimeout(() => {
      this.getUIContext().animateTo({ duration: 320, curve: Curve.EaseIn }, () => {
        this.pageOpacity = 0;
      });
      setTimeout(() => {
        NavUtil.replace('pages/MainTabs/MainTabs');
      }, 340);
    }, 1900);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (this.eqTimer !== -1) {
      clearInterval(this.eqTimer);
      this.eqTimer = -1;
    }
  }

  private getEqHeight(index: number): number {
    const base: number[] = [10, 16, 24, 16, 10];
    const wave: number = Math.abs(Math.sin(this.eqTick * 0.45 + index * 1.15));
    return 8 + base[index] * (0.35 + 0.65 * wave);
  }

  pageTransition() {
    PageTransitionEnter({ duration: 320, curve: Curve.EaseOut })
      .opacity(0)
    PageTransitionExit({ duration: 240, curve: Curve.EaseIn })
      .opacity(0)
  }

  @Builder
  private buildEqBar(index: number) {
    Column()
      .width(5)
      .height(this.getEqHeight(index))
      .borderRadius(2.5)
      .backgroundColor('rgba(255, 255, 255, 0.85)')
  }

  build() {
    Column() {
      Column() {
        // 白色圆角图标卡，内含应用图标 cover
        Column() {
          Image($r('app.media.cover'))
            .width(92)
            .height(92)
            .objectFit(ImageFit.Cover)
        }
        .width(128)
        .height(128)
        .backgroundColor('#FFFFFF')
        .borderRadius(32)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .shadow({
          radius: 28,
          color: 'rgba(0, 0, 0, 0.28)',
          offsetY: 12
        })
        .scale({ x: this.coverScale, y: this.coverScale })
        .opacity(this.coverOpacity)
        .animation({ duration: 560, curve: Curve.EaseOut })

        Text('拾华音乐')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .letterSpacing(6)
          .margin({ top: 30 })
          .opacity(this.titleOpacity)
          .translate({ y: this.titleTranslate })
          .animation({ duration: 480, curve: Curve.EaseOut })

        Text('听见美好 · 拾起华章')
          .fontSize(14)
          .fontColor('rgba(255, 255, 255, 0.78)')
          .letterSpacing(2)
          .margin({ top: 12 })
          .opacity(this.taglineOpacity)
          .animation({ duration: 460, curve: Curve.EaseOut })

        // 播放中的动态频谱
        Row({ space: 5 }) {
          this.buildEqBar(0)
          this.buildEqBar(1)
          this.buildEqBar(2)
          this.buildEqBar(3)
          this.buildEqBar(4)
        }
        .alignItems(VerticalAlign.Bottom)
        .height(34)
        .margin({ top: 28 })
        .opacity(this.taglineOpacity)
        .animation({ duration: 460, curve: Curve.EaseOut })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .linearGradient({
      angle: 135,
      colors: [['#7E22CE', 0], ['#4C1D95', 0.65], ['#2E1065', 1]]
    })
    .opacity(this.pageOpacity)
    .animation({ duration: 320, curve: Curve.EaseIn })
  }
}
