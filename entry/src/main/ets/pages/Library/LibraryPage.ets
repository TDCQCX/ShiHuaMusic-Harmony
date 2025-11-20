/**
 * 音乐库页面 - LibraryPage
 * 对应小程序 pages/library/library
 */

import { AudioManager } from '../../utils/AudioManager'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { HttpUtil } from '../../utils/HttpUtil'
import { ThemeUtil } from '../../utils/ThemeUtil'
import { SongListItem, ApiResponse } from '../../types/common'

@Component
export struct LibraryPage {
  @State recommendedSongs: SongListItem[] = []
  @State searchKeyword: string = ''
  @State isLoading: boolean = false
  @State showBackTop: boolean = false
  @State showPlayer: boolean = false

  private audioManager: AudioManager = AudioManager.getInstance()
  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private httpUtil: HttpUtil = new HttpUtil()

  /**
   * 加载推荐歌曲
   */
  private async loadRecommendedSongs(isAppend: boolean = false): Promise<void> {
    try {
      if (isAppend) {
        this.isLoading = true
      } else {
        this.isLoading = true
      }

      // 调用获取推荐歌曲的API
      const response: ApiResponse = await this.httpUtil.get('/song/getRecommendedSongs')
      console.log('推荐歌曲响应:', response)

      if (response.code === 0 && response.data && Array.isArray(response.data)) {
        // 格式化歌曲时长
        const formattedSongs: SongListItem[] = response.data.map((song: SongListItem) => ({
          ...song,
          duration: this.formatDuration(song.duration || 0)
        }))

        // 确保只获取20条新歌曲
        const newSongs: SongListItem[] = formattedSongs.slice(0, 20)

        if (isAppend) {
          // 追加模式
          const updatedSongs: SongListItem[] = [...this.recommendedSongs, ...newSongs]
          this.recommendedSongs = updatedSongs
        } else {
          // 初始加载模式
          this.recommendedSongs = newSongs
        }
      }

      this.isLoading = false
    } catch (error) {
      console.error('加载歌曲失败:', error)
      this.isLoading = false
      // TODO: 显示错误提示
    }
  }

  /**
   * 格式化时长（秒转分:秒）
   */
  private formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  /**
   * 搜索输入处理
   */
  private onSearchInput(value: string): void {
    this.searchKeyword = value
  }

  /**
   * 搜索确认
   */
  private onSearchConfirm(): void {
    this.loadRecommendedSongs()
  }

  /**
   * 清除搜索
   */
  private onClearSearch(): void {
    this.searchKeyword = ''
    this.loadRecommendedSongs()
  }

  /**
   * 播放歌曲
   */
  private playSong(song: SongListItem, index: number): void {
    // 设置全局播放状态
    this.globalDataManager.setCurrentSong(song)
    this.globalDataManager.setCurrentSongList(this.recommendedSongs)
    this.globalDataManager.setCurrentIndex(index)

    // 使用音频管理器播放歌曲
    this.audioManager.play(song, this.recommendedSongs)
  }

  /**
   * 上拉加载更多
   */
  private onReachBottom(): void {
    // 防止重复加载
    if (!this.isLoading) {
      this.loadRecommendedSongs(true)
    }
  }

  /**
   * 页面滚动处理
   */
  private onPageScroll(scrollTop: number): void {
    this.showBackTop = scrollTop > 300
  }

  /**
   * 回到顶部
   */
  private backToTop(): void {
    // TODO: 实现回到顶部功能
  }

  /**
   * 分享功能
   */
  private shareApp(): void {
    // TODO: 实现分享功能
  }

  aboutToAppear(): void {
    // 加载推荐歌曲
    this.loadRecommendedSongs()
    
    // 检查播放状态
    const currentSong = this.globalDataManager.getCurrentSong()
    this.showPlayer = !!currentSong
  }

  build() {
    Column() {
      // 顶部搜索栏
      this.buildSearchBar()

      // 歌曲列表
      this.buildSongList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 构建搜索栏
   */
  @Builder
  private buildSearchBar() {
    Row() {
      Image($r('app.media.search'))
        .width(20)
        .height(20)
        .margin({ left: ThemeUtil.getSpacing('md') })

      TextInput({ placeholder: '搜索音乐...' })
        .layoutWeight(1)
        .height(40)
        .backgroundColor(Color.Transparent)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .maxLength(50)
        .onChange((value: string) => this.onSearchInput(value))
        .onSubmit(() => this.onSearchConfirm())

      if (this.searchKeyword.length > 0) {
        Image($r('app.media.clear'))
          .width(20)
          .height(20)
          .margin({ right: ThemeUtil.getSpacing('md') })
          .onClick(() => this.onClearSearch())
      }
    }
    .width('100%')
    .height(56)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: ThemeUtil.getSpacing('sm') })
  }

  /**
   * 构建歌曲列表
   */
  @Builder
  private buildSongList() {
    List() {
      ForEach(this.recommendedSongs, (song: SongListItem, index: number) => {
        ListItem() {
          this.buildSongItem(song, index)
        }
        .margin({ bottom: 1 })
      }, (song: SongListItem) => song.id.toString())
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
    .onReachBottom(() => this.onReachBottom())

    // 回到顶部按钮
    if (this.showBackTop) {
      Button() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
      }
      .width(40)
      .height(40)
      .backgroundColor(ThemeUtil.getColor('overlay'))
      .borderRadius(ThemeUtil.getBorderRadius('xl'))
      .position({ x: '85%', y: '80%' })
      .onClick(() => this.backToTop())
    }

    // 加载更多提示
    if (this.isLoading) {
      Row() {
        LoadingProgress()
          .width(20)
          .height(20)
          .color(ThemeUtil.getColor('primary'))
        Text('加载中...')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textSecondary'))
          .margin({ left: ThemeUtil.getSpacing('sm') })
      }
      .width('100%')
      .height(40)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(ThemeUtil.getColor('surface'))
    }
  }

  /**
   * 构建歌曲项
   */
  @Builder
  private buildSongItem(song: SongListItem, index: number) {
    Row() {
      Text((index + 1).toString())
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .width(40)
        .textAlign(TextAlign.Center)

      Column() {
        Text(song.name)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(song.artists?.map(artist => artist.name).join(' / ') || '未知艺术家')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textSecondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .margin({ left: ThemeUtil.getSpacing('md') })

      Text(song.duration || '00:00')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      Image($r('app.media.play'))
        .width(20)
        .height(20)
        .margin({ right: ThemeUtil.getSpacing('md') })
        .onClick(() => this.playSong(song, index))
    }
    .width('100%')
    .height(60)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('sm') })
    .onClick(() => this.playSong(song, index))
  }
}