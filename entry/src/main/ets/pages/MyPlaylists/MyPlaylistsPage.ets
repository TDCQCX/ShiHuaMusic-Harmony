/**
 * 我的歌单页面 - MyPlaylistsPage
 * 对应小程序 pages/my-playlists/my-playlists
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { ThemeUtil } from '../../utils/ThemeUtil'
import { SongListItem, ApiResponse } from '../../types/common'
import { HttpUtil } from '../../utils/HttpUtil'

interface PlayList {
  id: number
  name: string
  coverImgUrl: string
  description: string
  trackCount: number
  playCount: number
  createTime: number
}

@Component
export struct MyPlaylistsPage {
  @State myPlaylists: PlayList[] = []
  @State createdPlaylists: PlayList[] = []
  @State collectedPlaylists: PlayList[] = []
  @State isLoading: boolean = false
  @State activeTab: 'created' | 'collected' = 'created'
  @State showPlayer: boolean = false

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private httpUtil: HttpUtil = new HttpUtil()

  /**
   * 页面加载
   */
  aboutToAppear(): void {
    this.loadMyPlaylists()
    
    // 检查播放状态
    const currentSong = this.globalDataManager.getCurrentSong()
    this.showPlayer = !!currentSong
  }

  /**
   * 加载我的歌单
   */
  private async loadMyPlaylists(): Promise<void> {
    try {
      this.isLoading = true

      // TODO: 调用真实API
      // const response: ApiResponse = await this.httpUtil.get('/user/playlists')
      
      // 模拟数据
      await new Promise(resolve => setTimeout(resolve, 1000))

      this.createdPlaylists = [
        {
          id: 1,
          name: '我喜欢的音乐',
          coverImgUrl: '',
          description: '收藏的喜欢的歌曲',
          trackCount: 128,
          playCount: 9999,
          createTime: Date.now() - 86400000 * 30
        },
        {
          id: 2,
          name: '工作时的音乐',
          coverImgUrl: '',
          description: '工作时听的轻音乐',
          trackCount: 45,
          playCount: 2345,
          createTime: Date.now() - 86400000 * 15
        }
      ]

      this.collectedPlaylists = [
        {
          id: 3,
          name: '热门推荐歌单',
          coverImgUrl: '',
          description: '精心策划的音乐合集',
          trackCount: 200,
          playCount: 50000,
          createTime: Date.now() - 86400000 * 7
        }
      ]

      this.updateDisplayList()
    } catch (error) {
      console.error('加载我的歌单失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 更新显示列表
   */
  private updateDisplayList(): void {
    this.myPlaylists = this.activeTab === 'created' ? this.createdPlaylists : this.collectedPlaylists
  }

  /**
   * 切换标签页
   */
  private switchTab(tab: 'created' | 'collected'): void {
    this.activeTab = tab
    this.updateDisplayList()
  }

  /**
   * 跳转到歌单详情
   */
  private goToPlaylistDetail(playlist: PlayList): void {
    router.pushUrl({
      url: '/pages/PlaylistDetail/PlaylistDetailPage',
      params: {
        playlistId: playlist.id,
        playlistName: playlist.name
      }
    })
  }

  /**
   * 创建新歌单
   */
  private createNewPlaylist(): void {
    // TODO: 实现创建新歌单功能
    console.log('创建新歌单')
  }

  /**
   * 格式化播放次数
   */
  private formatPlayCount(count: number): string {
    if (count < 10000) {
      return count.toString()
    } else if (count < 100000000) {
      return (count / 10000).toFixed(1) + '万'
    } else {
      return (count / 100000000).toFixed(1) + '亿'
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      // 标签页
      this.buildTabs()

      // 歌单列表
      this.buildPlaylistList()

      // 空白提示
      if (this.myPlaylists.length === 0 && !this.isLoading) {
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

      Text('我的歌单')
        .fontSize(ThemeUtil.getFontSize('lg'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)

      Blank()

      Image($r('app.media.add'))
        .width(24)
        .height(24)
        .onClick(() => this.createNewPlaylist())
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建标签页
   */
  @Builder
  private buildTabs() {
    Row() {
      Text(`创建的歌单 (${this.createdPlaylists.length})`)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.activeTab === 'created' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
        .fontWeight(this.activeTab === 'created' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.switchTab('created'))

      Text(' | ')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('divider'))

      Text(`收藏的歌单 (${this.collectedPlaylists.length})`)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.activeTab === 'collected' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
        .fontWeight(this.activeTab === 'collected' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.switchTab('collected'))
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: ThemeUtil.getSpacing('sm') })
  }

  /**
   * 构建歌单列表
   */
  @Builder
  private buildPlaylistList() {
    List() {
      ForEach(this.myPlaylists, (playlist: PlayList) => {
        ListItem() {
          this.buildPlaylistItem(playlist)
        }
        .margin({ bottom: 1 })
      }, (playlist: PlayList) => playlist.id.toString())
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
   * 构建歌单项
   */
  @Builder
  private buildPlaylistItem(playlist: PlayList) {
    Row() {
      // 歌单封面
      Image(playlist.coverImgUrl || $r('app.media.default-cover'))
        .width(60)
        .height(60)
        .borderRadius(ThemeUtil.getBorderRadius('md'))
        .backgroundColor(ThemeUtil.getColor('surface'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 歌单信息
      Column() {
        Text(playlist.name)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: ThemeUtil.getSpacing('xs') })

        Text(`${playlist.trackCount}首 • ${this.formatPlayCount(playlist.playCount)}次播放 • ${this.formatTime(playlist.createTime)}`)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 更多操作
      Image($r('app.media.more'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(80)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(() => this.goToPlaylistDetail(playlist))
  }

  /**
   * 构建空白视图
   */
  @Builder
  private buildEmptyView() {
    Column() {
      Image($r('app.media.playlist'))
        .width(80)
        .height(80)
        .opacity(0.3)
        .margin({ bottom: 16 })

      Text(this.activeTab === 'created' ? '暂无创建的歌单' : '暂无收藏的歌单')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .margin({ bottom: ThemeUtil.getSpacing('sm') })

      Text(this.activeTab === 'created' ? '创建你的第一个歌单吧' : '去发现更多精彩歌单')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}