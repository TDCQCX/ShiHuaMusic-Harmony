/**
 * 用户编辑页面 - UserEditPage
 * 对应小程序 pages/user/edit
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { HttpUtil } from '../../utils/HttpUtil'
import { UserInfo } from '../../types/common'
import { ThemeUtil } from '../../utils/ThemeUtil'

@Component
export struct UserEditPage {
  @State userInfo: UserInfo = {
    username: '',
    avatarUrl: '',
    userAvatar: '',
    email: '',
    phone: '',
    introduction: ''
  }
  @State userForm: UserInfo = {
    username: '',
    avatarUrl: '',
    userAvatar: '',
    email: '',
    phone: '',
    introduction: ''
  }
  @State errors: Record<string, string> = {}
  @State isLoading: boolean = false
  @State avatarFile: string = ''

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private httpUtil: HttpUtil = new HttpUtil()

  /**
   * 页面加载
   */
  aboutToAppear(): void {
    this.loadUserInfo()
  }

  /**
   * 加载用户信息
   */
  private async loadUserInfo(): Promise<void> {
    try {
      // 检查登录状态
      const token = this.globalDataManager.getToken()
      if (!token) {
        console.log('请先登录')
        router.back()
        return
      }

      // 获取用户信息
      const currentUserInfo = this.globalDataManager.getUserInfo()
      if (currentUserInfo) {
        this.userInfo = { ...currentUserInfo }
        this.userForm = { ...currentUserInfo }
      }
    } catch (error) {
      console.error('加载用户信息失败:', error)
    }
  }

  /**
   * 选择头像
   */
  private async selectAvatar(): Promise<void> {
    try {
      // TODO: 实现鸿蒙原生图片选择
      // 使用鸿蒙的文件选择API
      console.log('选择头像')
      // 临时模拟选择
      this.avatarFile = 'selected_avatar_path'
    } catch (error) {
      console.error('选择头像失败:', error)
    }
  }

  /**
   * 上传头像
   */
  private async uploadAvatar(filePath: string): Promise<void> {
    this.isLoading = true

    try {
      // TODO: 实现鸿蒙原生文件上传
      // 使用鸿蒙的网络请求API上传文件
      console.log('上传头像:', filePath)
      
      // 模拟上传延迟
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      // 模拟上传成功，返回新的头像URL
      const newAvatarUrl = 'uploaded_avatar_url_' + Date.now()
      this.userForm.avatarUrl = newAvatarUrl
      this.userForm.userAvatar = newAvatarUrl
      
      console.log('头像上传成功')
    } catch (error) {
      console.error('头像上传失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 表单验证
   */
  private validateForm(): boolean {
    const errors: Record<string, string> = {}
    const { username, phone } = this.userForm

    // 用户名验证
    if (!username?.trim()) {
      errors.username = '请输入用户名'
    } else {
      const usernameRegex = /^[a-zA-Z0-9_-]{4,16}$/
      if (!usernameRegex.test(username)) {
        errors.username = '用户名格式：4-16位字符（字母、数字、下划线、连字符）'
      }
    }

    // 手机号验证（可选）
    if (phone && !/^1[3-9]\d{9}$/.test(phone)) {
      errors.phone = '请输入正确的手机号格式'
    }

    this.errors = errors
    return Object.keys(errors).length === 0
  }

  /**
   * 保存用户信息
   */
  private async saveUserInfo(): Promise<void> {
    // 表单验证
    if (!this.validateForm()) {
      return
    }

    this.isLoading = true

    try {
      // 获取用户ID
      const userId = this.globalDataManager.getUserInfo()?.userId || 
                    this.globalDataManager.getUserInfo()?.id ||
                    this.globalDataManager.getUserInfo()?.user_id

      if (!userId) {
        console.log('用户信息不完整，请重新登录')
        return
      }

      // 准备提交数据
      const userInfoData = {
        ...this.userForm,
        userId: userId,
        id: userId,
        user_id: userId
      }
      delete userInfoData.avatarUrl // 排除头像URL字段

      console.log('提交的用户信息:', userInfoData)

      // TODO: 调用API保存用户信息
      // const response = await this.httpUtil.put('/user/updateUserInfo', userInfoData)

      // 模拟保存延迟
      await new Promise(resolve => setTimeout(resolve, 1500))

      // 更新全局用户信息
      this.globalDataManager.setUserInfo({
        ...this.userForm,
        userId: userId
      })

      console.log('用户信息保存成功')
      router.back()
    } catch (error) {
      console.error('保存用户信息失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 输入用户名处理
   */
  private onUsernameInput(value: string): void {
    this.userForm.username = value
    if (this.errors.username) {
      this.errors.username = ''
    }
  }

  /**
   * 输入邮箱处理
   */
  private onEmailInput(value: string): void {
    this.userForm.email = value
    if (this.errors.email) {
      this.errors.email = ''
    }
  }

  /**
   * 输入手机号处理
   */
  private onPhoneInput(value: string): void {
    this.userForm.phone = value
    if (this.errors.phone) {
      this.errors.phone = ''
    }
  }

  /**
   * 输入简介处理
   */
  private onIntroductionInput(value: string): void {
    this.userForm.introduction = value
  }

  /**
   * 处理删除账号
   */
  private handleDeleteAccount(): void {
    // TODO: 实现鸿蒙原生确认对话框
    console.log('确认删除账号')
  }

  /**
   * 删除账号
   */
  private async deleteAccount(): Promise<void> {
    this.isLoading = true

    try {
      // TODO: 调用删除账号API
      // const response = await this.httpUtil.delete('/user/deleteUser')

      // 模拟删除延迟
      await new Promise(resolve => setTimeout(resolve, 1000))

      // 清除登录状态
      this.globalDataManager.clearUserInfo()
      this.globalDataManager.clearToken()

      console.log('账号已注销')
      router.pushUrl({ url: '/pages/Login/LoginPage' })
    } catch (error) {
      console.error('删除账号失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      Scroll() {
        Column() {
          // 用户信息表单
          this.buildUserForm()

          // 删除账号按钮
          this.buildDeleteButton()
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 构建头部
   */
  @Builder
  private buildHeader() {
    Row() {
      Image($r('app.media.back'))
        .width(24)
        .height(24)
        .onClick(() => router.back())

      Blank()

      Text('编辑个人信息')
        .fontSize(ThemeUtil.getFontSize('xl'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)

      Blank()

      Text('保存')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(this.userForm.username.trim() ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
        .onClick(() => {
          if (this.userForm.username.trim()) {
            this.saveUserInfo()
          }
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建用户表单
   */
  @Builder
  private buildUserForm() {
    Column() {
      // 头像区域
      this.buildAvatarSection()

      // 输入表单
      this.buildInputForm()

      // 保存按钮
      Button(this.isLoading ? '保存中...' : '保存修改')
        .width('90%')
        .height(48)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('onPrimary'))
        .backgroundColor(ThemeUtil.getColor('primary'))
        .borderRadius(ThemeUtil.getBorderRadius('xl'))
        .enabled(!this.isLoading && !!this.userForm.username.trim())
        .onClick(() => this.saveUserInfo())
        .margin({ top: ThemeUtil.getSpacing('lg') })
    }
    .width('100%')
    .margin({ top: ThemeUtil.getSpacing('sm') })
  }

  /**
   * 构建头像区域
   */
  @Builder
  private buildAvatarSection() {
    Column() {
      Column() {
        Image(this.userForm.userAvatar || this.userForm.avatarUrl || $r('app.media.default-avatar'))
          .width(80)
          .height(80)
          .borderRadius(ThemeUtil.getBorderRadius('full'))
          .backgroundColor(ThemeUtil.getColor('divider'))
      }
      .width(100)
      .height(100)
      .margin({ bottom: ThemeUtil.getSpacing('md') })
      .onClick(() => this.selectAvatar())

      Text('点击更换头像')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('primary'))
    }
    .width('100%')
    .height(140)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: ThemeUtil.getSpacing('sm') })
  }

  /**
   * 构建输入表单
   */
  @Builder
  private buildInputForm() {
    Column({ space: ThemeUtil.getSpacing('lg') }) {
      // 用户名
      this.buildInputItem('用户名', this.userForm.username, '请输入用户名', (value) => this.onUsernameInput(value), InputType.Normal, this.errors.username)

      // 邮箱
      this.buildInputItem('邮箱', this.userForm.email, '请输入邮箱地址', (value) => this.onEmailInput(value), InputType.EmailAddr, '')

      // 手机号
      this.buildInputItem('手机号', this.userForm.phone, '请输入手机号', (value) => this.onPhoneInput(value), InputType.PhoneNumber, this.errors.phone)

      // 简介
      this.buildInputItem('个人简介', this.userForm.introduction || '', '请输入个人简介', (value) => this.onIntroductionInput(value), InputType.Normal, '')
    }
    .width('100%')
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding(ThemeUtil.getSpacing('lg'))
  }

  /**
   * 构建输入项
   */
  @Builder
  private buildInputItem(label: string, value: string, placeholder: string, onChange: (value: string) => void, inputType?: InputType, error?: string) {
    Column() {
      Text(label)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .margin({ bottom: ThemeUtil.getSpacing('sm') })

      TextInput({
        placeholder: placeholder,
        text: value
      })
        .width('100%')
        .height(48)
        .backgroundColor(ThemeUtil.getColor('surface'))
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .type(inputType || InputType.Normal)
        .onChange((inputValue: string) => onChange(inputValue))

      // 错误提示
      if (error) {
        Text(error)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('error'))
          .margin({ top: ThemeUtil.getSpacing('xs') })
      }
    }
    .width('100%')
  }

  /**
   * 构建删除账号按钮
   */
  @Builder
  private buildDeleteButton() {
    Column() {
      Button('删除账号')
        .width('90%')
        .height(44)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('error'))
        .backgroundColor(Color.Transparent)
        .borderWidth(1)
        .borderColor(ThemeUtil.getColor('error'))
        .borderRadius(ThemeUtil.getBorderRadius('md'))
        .enabled(!this.isLoading)
        .onClick(() => this.handleDeleteAccount())
        .margin({ top: ThemeUtil.getSpacing('lg') })

      Text('删除账号后无法恢复，确定要继续吗？')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ top: ThemeUtil.getSpacing('sm') })
    }
    .width('100%')
    .margin({ bottom: ThemeUtil.getSpacing('xl') })
  }
}