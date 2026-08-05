/**
 * 编辑个人资料（用户名/邮箱/手机/简介 + 头像入口 + 注销）
 * 头像选择/上传将在阶段 2 接入 PhotoViewPicker
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { AppContext } from '../../utils/AppContext';
import { HttpUtil } from '../../utils/HttpUtil';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { UpdateUserInfoRequest, UserInfo } from '../../types/common';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { request } from '@kit.BasicServicesKit';
import { TabManager } from '../../utils/TabManager';

@Entry
@Component
struct UserEditPage {
  @State username: string = '';
  @State email: string = '';
  @State phone: string = '';
  @State introduction: string = '';
  @State avatarUrl: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private userId: number = 0;

  aboutToAppear(): void {
    const userInfo = this.globalData.getUserInfo();
    if (!this.globalData.getIsLoggedIn() || !userInfo) {
      NavUtil.back();
      return;
    }
    this.userId = userInfo.userId;
    this.username = userInfo.username;
    this.email = userInfo.email;
    this.phone = userInfo.phone;
    this.introduction = userInfo.introduction;
    this.avatarUrl = userInfo.avatarUrl || userInfo.userAvatar;
  }

  private validate(): boolean {
    const usernameRegex = /^[a-zA-Z0-9_-]{4,16}$/;
    if (!usernameRegex.test(this.username)) {
      this.errorMessage = '用户名格式：4-16位字符（字母、数字、下划线、连字符）';
      return false;
    }
    if (this.phone && !/^1[3-9]\d{9}$/.test(this.phone)) {
      this.errorMessage = '请输入正确的手机号格式';
      return false;
    }
    this.errorMessage = '';
    return true;
  }

  private async handleSave(): Promise<void> {
    if (!this.validate()) {
      return;
    }
    this.isLoading = true;
    try {
      const request: UpdateUserInfoRequest = {
        userId: this.userId,
        username: this.username,
        phone: this.phone,
        email: this.email,
        introduction: this.introduction
      };
      const result = await ApiService.updateUserInfo(request);
      if (result.code === 0) {
        const userResult = await ApiService.getUserInfo();
        if (userResult.code === 0 && userResult.data) {
          const freshUser: UserInfo = userResult.data;
          freshUser.token = this.globalData.getToken();
          await this.globalData.updateUserInfo(freshUser);
        }
        NavUtil.back();
      } else {
        this.errorMessage = result.message || '更新失败';
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async selectAvatar(): Promise<void> {
    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const result = await photoPicker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      const uri = result.photoUris[0];
      const croppedUri = await this.cropAvatar(uri);
      if (croppedUri) {
        await this.uploadAvatar(croppedUri);
      }
    } catch (error) {
      console.error('选择头像失败:', JSON.stringify(error));
    }
  }

  /**
   * 居中裁剪为正方形并输出 JPEG 文件
   */
  private async cropAvatar(uri: string): Promise<string> {
    try {
      const imageSource = image.createImageSource(uri);
      const pixelMap = await imageSource.createPixelMap();
      const info = pixelMap.getImageInfoSync();
      const side = Math.min(info.size.width, info.size.height);
      const x = Math.floor((info.size.width - side) / 2);
      const y = Math.floor((info.size.height - side) / 2);
      const region: image.Region = {
        x: x,
        y: y,
        size: { width: side, height: side }
      };
      pixelMap.cropSync(region);
      const packer = image.createImagePacker();
      const data = await packer.packToData(pixelMap, { format: 'image/jpeg', quality: 90 });
      pixelMap.release();
      imageSource.release();

      const context = AppContext.getContext();
      if (context === null) {
        return '';
      }
      const filePath = context.cacheDir + '/avatar_' + Date.now().toString() + '.jpg';
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);
      return 'file://' + filePath;
    } catch (error) {
      console.error('裁剪头像失败:', JSON.stringify(error));
      return '';
    }
  }

  /**
   * 上传头像并重新拉取用户信息
   */
  private async uploadAvatar(fileUri: string): Promise<void> {
    this.isLoading = true;
    try {
      const context = AppContext.getContext();
      if (context === null) {
        this.isLoading = false;
        return;
      }
      const token = this.globalData.getToken();
      const headers: Record<string, string> = {
        'Authorization': token ? 'Bearer ' + token : ''
      };
      const config: request.UploadConfig = {
        url: HttpUtil.getBaseUrl() + '/user/updateUserAvatar',
        header: headers,
        method: 'POST',
        files: [
          {
            filename: 'avatar.jpg',
            name: 'avatar',
            uri: fileUri,
            type: 'image/jpeg'
          }
        ],
        data: []
      };
      const task = await request.uploadFile(context, config);
      task.on('complete', (taskInfo: request.TaskState[]) => {
        this.refreshAvatar();
      });
      task.on('fail', (taskInfo: request.TaskState[]) => {
        console.error('头像上传失败');
        this.isLoading = false;
      });
    } catch (error) {
      console.error('头像上传异常:', JSON.stringify(error));
      this.isLoading = false;
    }
  }

  private async refreshAvatar(): Promise<void> {
    try {
      const result = await ApiService.getUserInfo();
      if (result.code === 0 && result.data) {
        const fresh: UserInfo = result.data;
        fresh.token = this.globalData.getToken();
        await this.globalData.updateUserInfo(fresh);
        this.avatarUrl = fresh.avatarUrl || fresh.userAvatar;
      }
    } catch (error) {
      console.error('刷新头像信息失败:', JSON.stringify(error));
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
        Text('编辑个人信息')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Text('保存')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(this.username ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
          .onClick(() => this.handleSave())
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      Scroll() {
        Column() {
          Column() {
            Image(this.avatarUrl ? this.avatarUrl : $r('app.media.default_avatar'))
              .width(80)
              .height(80)
              .borderRadius(ThemeUtil.getBorderRadius('full'))
              .objectFit(ImageFit.Cover)
              .backgroundColor(ThemeUtil.getColor('surface'))
            Text('点击更换头像')
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('primary'))
              .margin({ top: ThemeUtil.getSpacing('sm') })
          }
          .width('100%')
          .height(140)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(ThemeUtil.getColor('surface'))
          .borderRadius(ThemeUtil.getBorderRadius('lg'))
          .shadow({ radius: 6, color: 'rgba(0, 0, 0, 0.06)', offsetY: 2 })
          .onClick(() => this.selectAvatar())

          Column() {
            this.buildInput('用户名', this.username, '请输入用户名', InputType.Normal, (value: string) => {
              this.username = value;
            })
            this.buildInput('邮箱', this.email, '请输入邮箱', InputType.Email, (value: string) => {
              this.email = value;
            })
            this.buildInput('手机号', this.phone, '请输入手机号', InputType.PhoneNumber, (value: string) => {
              this.phone = value;
            })
            this.buildInput('个人简介', this.introduction, '请输入个人简介', InputType.Normal, (value: string) => {
              this.introduction = value;
            })

            if (this.errorMessage.length > 0) {
              Text(this.errorMessage)
                .fontSize(ThemeUtil.getFontSize('xs'))
                .fontColor(ThemeUtil.getColor('error'))
                .margin({ top: ThemeUtil.getSpacing('sm') })
            }
          }
          .width('100%')
          .backgroundColor(ThemeUtil.getColor('surface'))
          .borderRadius(ThemeUtil.getBorderRadius('lg'))
          .shadow({ radius: 6, color: 'rgba(0, 0, 0, 0.06)', offsetY: 2 })
          .padding(ThemeUtil.getSpacing('lg'))
          .margin({ top: ThemeUtil.getSpacing('sm') })

          Button(this.isLoading ? '保存中...' : '保存修改')
            .width('100%')
            .height(48)
            .fontSize(ThemeUtil.getFontSize('md'))
            .fontColor(ThemeUtil.getColor('onPrimary'))
            .backgroundColor(ThemeUtil.getColor('primary'))
            .borderRadius(ThemeUtil.getBorderRadius('lg'))
            .enabled(!this.isLoading)
            .onClick(() => this.handleSave())
            .margin({ top: ThemeUtil.getSpacing('lg') })

        }
        .width('100%')
        .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: ThemeUtil.getSpacing('sm') })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  private buildInput(label: string, value: string, placeholder: string, inputType: InputType, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .width('100%')
        .margin({ bottom: ThemeUtil.getSpacing('sm') })
      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(48)
        .type(inputType)
        .backgroundColor(ThemeUtil.getColor('background'))
        .borderRadius(ThemeUtil.getBorderRadius('sm'))
        .onChange((inputValue: string) => onChange(inputValue))
        .margin({ bottom: ThemeUtil.getSpacing('lg') })
    }
    .width('100%')
  }
}
