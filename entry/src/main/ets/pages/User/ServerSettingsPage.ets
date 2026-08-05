/**
 * 服务器设置（API / 图片服务器地址）
 * 预览器使用 127.0.0.1；模拟器使用 10.0.2.2
 */
import { HttpUtil } from '../../utils/HttpUtil';
import { NavUtil } from '../../utils/NavUtil';
import { ThemeUtil } from '../../utils/ThemeUtil';

interface ServerPreset {
  name: string;
  apiUrl: string;
  imageUrl: string;
  desc: string;
}

@Entry
@Component
struct ServerSettingsPage {
  @State apiUrl: string = '';
  @State imageUrl: string = '';
  @State errorMessage: string = '';

  private presets: ServerPreset[] = [
    {
      name: '预览器',
      apiUrl: 'http://127.0.0.1:8080',
      imageUrl: 'http://127.0.0.1:9000',
      desc: 'DevEco Previewer 与本机后端'
    },
    {
      name: '模拟器',
      apiUrl: 'http://10.0.2.2:8080',
      imageUrl: 'http://10.0.2.2:9000',
      desc: 'HarmonyOS 模拟器访问宿主机'
    },
    {
      name: '局域网',
      apiUrl: 'http://192.168.66.241:8080',
      imageUrl: 'http://192.168.66.241:9000',
      desc: '真机通过局域网访问后端'
    }
  ];

  aboutToAppear(): void {
    this.apiUrl = HttpUtil.getBaseUrl();
    this.imageUrl = HttpUtil.getImageBaseUrl();
  }

  private applyPreset(preset: ServerPreset): void {
    this.apiUrl = preset.apiUrl;
    this.imageUrl = preset.imageUrl;
  }

  private validate(): boolean {
    if (!this.apiUrl.startsWith('http://') && !this.apiUrl.startsWith('https://')) {
      this.errorMessage = 'API 地址需以 http:// 或 https:// 开头';
      return false;
    }
    if (!this.imageUrl.startsWith('http://') && !this.imageUrl.startsWith('https://')) {
      this.errorMessage = '图片地址需以 http:// 或 https:// 开头';
      return false;
    }
    this.errorMessage = '';
    return true;
  }

  private async handleSave(): Promise<void> {
    if (!this.validate()) {
      return;
    }
    const apiUrl = this.apiUrl.endsWith('/') ? this.apiUrl.substring(0, this.apiUrl.length - 1) : this.apiUrl;
    const imageUrl = this.imageUrl.endsWith('/') ? this.imageUrl.substring(0, this.imageUrl.length - 1) : this.imageUrl;
    await HttpUtil.saveServerConfig(apiUrl, imageUrl);
    NavUtil.back();
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
        Text('服务器设置')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Text('保存')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('primary'))
          .onClick(() => this.handleSave())
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      Scroll() {
        Column() {
          Text('常用环境')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .width('100%')
            .margin({ bottom: ThemeUtil.getSpacing('sm') })

          Column() {
            ForEach(this.presets, (preset: ServerPreset) => {
              Row() {
                Column() {
                  Text(preset.name)
                    .fontSize(ThemeUtil.getFontSize('md'))
                    .fontColor(ThemeUtil.getColor('textPrimary'))
                  Text(preset.desc)
                    .fontSize(ThemeUtil.getFontSize('xs'))
                    .fontColor(ThemeUtil.getColor('textHint'))
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Button('使用')
                  .width(72)
                  .height(32)
                  .fontSize(ThemeUtil.getFontSize('xs'))
                  .fontColor(ThemeUtil.getColor('onPrimary'))
                  .backgroundColor(ThemeUtil.getColor('primary'))
                  .borderRadius(ThemeUtil.getBorderRadius('full'))
                  .onClick(() => this.applyPreset(preset))
              }
              .width('100%')
              .height(64)
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
              .backgroundColor(ThemeUtil.getColor('surface'))
              .borderRadius(ThemeUtil.getBorderRadius('md'))
              .margin({ bottom: ThemeUtil.getSpacing('sm') })
            }, (preset: ServerPreset) => preset.name)
          }
          .width('100%')
          .margin({ bottom: ThemeUtil.getSpacing('lg') })

          Text('API 服务器地址')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .width('100%')
            .margin({ bottom: ThemeUtil.getSpacing('sm') })
          TextInput({ placeholder: 'http://127.0.0.1:8080', text: this.apiUrl })
            .width('100%')
            .height(48)
            .type(InputType.URL)
            .backgroundColor(ThemeUtil.getColor('surface'))
            .borderRadius(ThemeUtil.getBorderRadius('md'))
            .onChange((value: string) => {
              this.apiUrl = value;
            })
            .margin({ bottom: ThemeUtil.getSpacing('lg') })

          Text('图片服务器地址（可选）')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .width('100%')
            .margin({ bottom: ThemeUtil.getSpacing('sm') })
          TextInput({ placeholder: 'http://127.0.0.1:9000（相对路径兜底）', text: this.imageUrl })
            .width('100%')
            .height(48)
            .type(InputType.URL)
            .backgroundColor(ThemeUtil.getColor('surface'))
            .borderRadius(ThemeUtil.getBorderRadius('md'))
            .onChange((value: string) => {
              this.imageUrl = value;
            })
            .margin({ bottom: ThemeUtil.getSpacing('lg') })

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('error'))
              .width('100%')
              .margin({ bottom: ThemeUtil.getSpacing('sm') })
          }

          Text('提示：后端返回的图片/音频地址（minIO）会原样使用，无需在此配置；图片地址仅用于接口返回相对路径时的兜底拼接。Previewer 使用 127.0.0.1，模拟器使用 10.0.2.2，真机使用电脑局域网 IP。')
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .width('100%')
            .lineHeight(18)

          Button('保存并生效')
            .width('100%')
            .height(48)
            .fontSize(ThemeUtil.getFontSize('md'))
            .fontColor(ThemeUtil.getColor('onPrimary'))
            .backgroundColor(ThemeUtil.getColor('primary'))
            .borderRadius(ThemeUtil.getBorderRadius('lg'))
            .onClick(() => this.handleSave())
            .margin({ top: ThemeUtil.getSpacing('lg') })
        }
        .width('100%')
        .padding(ThemeUtil.getSpacing('md'))
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
