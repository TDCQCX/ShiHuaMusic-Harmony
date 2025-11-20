/**
 * 最近播放页面 - RecentPlayPage
 * 对应小程序 pages/recent-play/recent-play
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { AudioManager } from '../../utils/AudioManager'
import { ThemeUtil } from '../../utils/ThemeUtil'
import { SongListItem } from '../../types/common'

@Component
export struct RecentPlayPage {
  @State recentSongs: SongListItem[] = []
  @State isLoading: boolean = false
  @State showPlayer: boolean = false

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private audioManager: AudioManager = AudioManager.getInstance()

  /**
   * 页面加载
   */
  aboutToAppear(): void {
    this.loadRecentPlayHistory()
    
    // 检查播放状态
    const currentSong = this.globalDataManager.getCurrentSong()
    this.showPlayer = !!currentSong
  }

  /**
   * 加载最近播放历史
   */
  private loadRecentPlayHistory(): void {
    try {
      this.isLoading = true
      
      // TODO: 从存储中获取最近播放历史
      const recentHistory = this.globalDataManager.getRecentPlayHistory()
      
      if (recentHistory && recentHistory.length > 0) {
        this.recentSongs = recentHistory
      } else {
        // 模拟数据
        this.recentSongs = [
          {
            id: 1,
            name: '示例歌曲1',
            artists: [{ id: 1, name: '示例艺术家1' }],
            duration: 180000,
            picUrl: ''
          },
          {
            id: 2,
            name: '示例歌曲2',
            artists: [{ id: 2, name: '示例艺术家2' }],
            duration: 210000,
            picUrl: ''
          }
        ]
      }
    } catch (error) {
      console.error('加载最近播放历史失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 播放歌曲
   */
  private playSong(song: SongListItem, index: number): void {
    this.globalDataManager.setCurrentSong(song)
    this.globalDataManager.setCurrentSongList(this.recentSongs)
    this.globalDataManager.setCurrentIndex(index)
    
    // 添加到最近播放历史
    this.addToRecentHistory(song)

    this.audioManager.play(song, this.recentSongs)
  }

  /**
   * 添加到最近播放历史
   */
  private addToRecentHistory(song: SongListItem): void {
    try {
      let history = this.globalDataManager.getRecentPlayHistory() || []
      
      // 移除重复项
      history = history.filter(item => item.id !== song.id)
      
      // 添加到开头
      history.unshift(song)
      
      // 限制历史记录数量
      if (history.length > 100) {
        history = history.slice(0, 100)
      }
      
      this.globalDataManager.setRecentPlayHistory(history)
      this.recentSongs = history
    } catch (error) {
      console.error('添加最近播放历史失败:', error)
    }
  }

  /**
   * 清空历史记录
   */
  private clearHistory(): void {
    this.globalDataManager.clearRecentPlayHistory()
    this.recentSongs = []
  }

  /**
   * 格式化时长
   */
  private formatDuration(duration: number): string {
    if (!duration || duration < 0) return '00:00'
    
    const minutes = Math.floor(duration / 60000)
    const seconds = Math.floor((duration % 60000) / 1000)
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      // 歌曲列表
      this.buildSongList()

      // 空白提示
      if (this.recentSongs.length === 0 && !this.isLoading) {
        this.buildEmptyView()
      }

      Blank()
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

      Text('最近播放')
        .fontSize(ThemeUtil.getFontSize('lg'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)

      Blank()

      if (this.recentSongs.length > 0) {
        Text('清空')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('error'))
          .onClick(() => this.clearHistory())
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建歌曲列表
   */
  @Builder
  private buildSongList() {
    List() {
      ForEach(this.recentSongs, (song: SongListItem, index: number) => {
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

    // 加载状态
    if (this.isLoading) {
      Row() {
        LoadingProgress()
          .width(20)
          .height(20)
          .color(ThemeUtil.getColor('primary'))
        Text('加载中...')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
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
        .fontColor(ThemeUtil.getColor('textHint'))
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
          .fontColor(ThemeUtil.getColor('textHint'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .margin({ left: ThemeUtil.getSpacing('md') })

      Text(this.formatDuration(song.duration || 0))
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
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

  /**
   * 构建空白视图
   */
  @Builder
  private buildEmptyView() {
    Column() {
      Image($r('app.media.history'))
        .width(80)
        .height(80)
        .opacity(0.3)
        .margin({ bottom: 16 })

      Text('暂无播放记录')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ bottom: ThemeUtil.getSpacing('sm') })

      Text('开始听歌，记录你的音乐历程')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}