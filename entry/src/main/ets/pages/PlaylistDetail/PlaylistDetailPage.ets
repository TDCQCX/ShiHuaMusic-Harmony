/**
 * 歌单详情页面 - PlaylistDetailPage
 * 对应小程序 pages/playlist-detail/playlist-detail
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { SongListItem, ApiResponse } from '../../types/common'
import { HttpUtil } from '../../utils/HttpUtil'
import { ThemeUtil } from '../../utils/ThemeUtil'

interface PlaylistInfo {
  id: number
  name: string
  coverImgUrl: string
  description: string
  creator: {
    nickname: string
    avatarUrl: string
  }
  tags: string[]
  trackCount: number
  playCount: number
  createTime: number
  subscribedCount: number
  commentCount: number
}

interface PlaylistSong {
  id: number
  name: string
  artists: string[]
  album: string
  duration: number
  coverImgUrl: string
  playUrl: string
  order: number
}

@Component
export struct PlaylistDetailPage {
  @State playlistInfo: PlaylistInfo | null = null
  @State playlistSongs: PlaylistSong[] = []
  @State isLoading: boolean = false
  @State isPlaying: boolean = false
  @State isSubscribed: boolean = false
  @State showPlayer: boolean = false
  @State isDescriptionExpanded: boolean = false
  @State selectedSongs: number[] = []
  @State selectedMode: boolean = false

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private httpUtil: HttpUtil = new HttpUtil()
  private playlistId: number = 0

  /**
   * 页面加载
   */
  aboutToAppear(): void {
    const params = router.getParams() as Record<string, any>
    this.playlistId = params?.playlistId || 0
    
    this.loadPlaylistDetail()
    
    // 检查播放状态
    const currentSong = this.globalDataManager.getCurrentSong()
    this.showPlayer = !!currentSong
  }

  /**
   * 加载歌单详情
   */
  private async loadPlaylistDetail(): Promise<void> {
    if (!this.playlistId) return

    try {
      this.isLoading = true

      // TODO: 调用真实API
      // const response: ApiResponse = await this.httpUtil.get(`/playlist/detail?id=${this.playlistId}`)
      
      // 模拟数据
      await new Promise(resolve => setTimeout(resolve, 1000))

      this.playlistInfo = {
        id: this.playlistId,
        name: '我的歌单',
        coverImgUrl: '',
        description: '这是一个精彩的音乐歌单，包含了很多好听的歌曲。这里有各种风格的音乐，从流行到摇滚，从民谣到电子音乐，应有尽有。希望这些歌曲能够陪伴您度过美好的时光，带给您愉悦的听觉体验。',
        creator: {
          nickname: '音乐爱好者',
          avatarUrl: ''
        },
        tags: ['流行', '摇滚', '民谣', '电子'],
        trackCount: 45,
        playCount: 123456,
        createTime: Date.now() - 86400000 * 30,
        subscribedCount: 1234,
        commentCount: 567
      }

      this.playlistSongs = [
        {
          id: 1,
          name: '演员',
          artists: ['薛之谦'],
          album: '绅士',
          duration: 232000,
          coverImgUrl: '',
          playUrl: '',
          order: 1
        },
        {
          id: 2,
          name: '告白气球',
          artists: ['周杰伦'],
          album: '周杰伦的床边故事',
          duration: 205000,
          coverImgUrl: '',
          playUrl: '',
          order: 2
        },
        {
          id: 3,
          name: '青花瓷',
          artists: ['周杰伦'],
          album: '我很忙',
          duration: 235000,
          coverImgUrl: '',
          playUrl: '',
          order: 3
        },
        {
          id: 4,
          name: '夜曲',
          artists: ['周杰伦'],
          album: '十一月的萧邦',
          duration: 238000,
          coverImgUrl: '',
          playUrl: '',
          order: 4
        },
        {
          id: 5,
          name: '简单爱',
          artists: ['周杰伦'],
          album: '范特西',
          duration: 269000,
          coverImgUrl: '',
          playUrl: '',
          order: 5
        }
      ]
    } catch (error) {
      console.error('加载歌单详情失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 播放全部歌曲
   */
  private playAll(): void {
    if (this.playlistSongs.length === 0) return

    const songList: SongListItem[] = this.playlistSongs.map(song => ({
      id: song.id,
      name: song.name,
      artists: song.artists,
      album: song.album,
      duration: song.duration,
      coverImgUrl: song.coverImgUrl,
      playUrl: song.playUrl
    }))

    // 设置全局播放状态
    this.globalDataManager.setCurrentSong(songList[0])
    this.globalDataManager.setSongList(songList)
    this.globalDataManager.setCurrentIndex(0)
    
    this.showPlayer = true
    this.isPlaying = true
  }

  /**
   * 播放指定歌曲
   */
  private playSong(index: number): void {
    const songList: SongListItem[] = this.playlistSongs.map(song => ({
      id: song.id,
      name: song.name,
      artists: song.artists,
      album: song.album,
      duration: song.duration,
      coverImgUrl: song.coverImgUrl,
      playUrl: song.playUrl
    }))

    // 设置全局播放状态
    this.globalDataManager.setCurrentSong(songList[index])
    this.globalDataManager.setSongList(songList)
    this.globalDataManager.setCurrentIndex(index)
    
    this.showPlayer = true
    this.isPlaying = true
  }

  /**
   * 切换收藏状态
   */
  private toggleSubscribe(): void {
    this.isSubscribed = !this.isSubscribed
    if (this.playlistInfo) {
      this.playlistInfo.subscribedCount += this.isSubscribed ? 1 : -1
    }
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

  /**
   * 格式化播放时长
   */
  private formatDuration(duration: number): string {
    const minutes = Math.floor(duration / 60000)
    const seconds = Math.floor((duration % 60000) / 1000)
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }

  /**
   * 切换选择模式
   */
  private toggleSelectMode(): void {
    this.selectedMode = !this.selectedMode
    this.selectedSongs = []
  }

  /**
   * 批量操作
   */
  private handleBatchAction(action: string): void {
    if (this.selectedSongs.length === 0) return

    switch (action) {
      case 'play':
        // 播放选中歌曲
        if (this.selectedSongs.length > 0) {
          const firstSongId = this.selectedSongs[0]
          const index = this.playlistSongs.findIndex(song => song.id === firstSongId)
          if (index > -1) {
            this.playSong(index)
          }
        }
        break
      case 'delete':
        // 从歌单中移除
        this.selectedSongs.forEach(songId => {
          const index = this.playlistSongs.findIndex(song => song.id === songId)
          if (index > -1) {
            this.playlistSongs.splice(index, 1)
          }
        })
        break
    }

    this.selectedSongs = []
    this.selectedMode = false
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      Scroll() {
        Column() {
          // 歌单头部信息
          this.buildPlaylistHeader()

          // 操作按钮
          this.buildActionButtons()

          // 歌曲列表
          this.buildSongList()
        }
        .width('100%')
      }
      .layoutWeight(1)

      // 批量操作栏
      if (this.selectedMode) {
        this.buildBatchBar()
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

      Text('歌单详情')
        .fontSize(ThemeUtil.getFontSize('lg'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)

      Blank()

      if (!this.selectedMode) {
        Image($r('app.media.share'))
          .width(24)
          .height(24)
      } else {
        Text('完成')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('primary'))
          .onClick(() => this.toggleSelectMode())
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建歌单头部
   */
  @Builder
  private buildPlaylistHeader() {
    Column() {
      Row() {
        // 歌单封面
        Image(this.playlistInfo?.coverImgUrl || $r('app.media.default-cover'))
          .width(120)
          .height(120)
          .borderRadius(ThemeUtil.getBorderRadius('lg'))
          .backgroundColor(ThemeUtil.getColor('surface'))

        Blank()

        // 歌单信息
        Column() {
          Text(this.playlistInfo?.name || '')
            .fontSize(ThemeUtil.getFontSize('lg'))
            .fontColor(ThemeUtil.getColor('textPrimary'))
            .fontWeight(FontWeight.Bold)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: ThemeUtil.getSpacing('sm') })

          Text(`by ${this.playlistInfo?.creator.nickname || ''}`)
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .margin({ bottom: ThemeUtil.getSpacing('md') })

          // 歌单统计
          Row() {
            Text(`${this.playlistInfo?.trackCount || 0}首`)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('textHint'))
              .margin({ right: ThemeUtil.getSpacing('md') })

            Text(`${this.formatPlayCount(this.playlistInfo?.playCount || 0)}次播放`)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('textHint'))
            }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  /**
   * 构建操作按钮
   */
  @Builder
  private buildActionButtons() {
    Row() {
      // 播放全部
      Row() {
        Image($r('app.media.play'))
          .width(18)
          .height(18)
          .margin({ right: 6 })

        Text('播放全部')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
      }
      .height(40)
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderRadius(ThemeUtil.getBorderRadius('xl'))
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .margin({ right: ThemeUtil.getSpacing('md') })
      .onClick(() => this.playAll())

      // 收藏
      Row() {
        Image($r('app.media.like-active'))
          .width(18)
          .height(18)
          .margin({ right: 6 })

        Text(this.isSubscribed ? '已收藏' : '收藏')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(this.isSubscribed ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textPrimary'))
      }
      .height(40)
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderRadius(ThemeUtil.getBorderRadius('xl'))
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .margin({ right: ThemeUtil.getSpacing('md') })
      .onClick(() => this.toggleSubscribe())

      // 评论
      Row() {
        Image($r('app.media.comment'))
          .width(18)
          .height(18)
          .margin({ right: 6 })

        Text(`${this.playlistInfo?.commentCount || 0}`)
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
      }
      .height(40)
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderRadius(ThemeUtil.getBorderRadius('xl'))
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('sm') })
    .margin({ bottom: 1 })
  }

  /**
   * 构建歌单描述
   */
  @Builder
  private buildDescription() {
    Column() {
      Text(this.playlistInfo?.description || '')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .maxLines(this.isDescriptionExpanded ? 10 : 2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.playlistInfo?.description && this.playlistInfo.description.length > 50) {
        Text(this.isDescriptionExpanded ? '收起' : '展开')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('primary'))
          .margin({ top: ThemeUtil.getSpacing('xs') })
          .onClick(() => this.isDescriptionExpanded = !this.isDescriptionExpanded)
      }
    }
    .width('100%')
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: ThemeUtil.getSpacing('sm'), bottom: ThemeUtil.getSpacing('sm') })
    .margin({ bottom: 1 })
  }

  /**
   * 构建歌曲列表
   */
  @Builder
  private buildSongList() {
    Column() {
      // 列表标题
      Row() {
        Text(`歌曲列表 (${this.playlistSongs.length})`)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('选择')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('primary'))
          .onClick(() => this.toggleSelectMode())
      }
      .width('100%')
      .height(50)
      .backgroundColor(ThemeUtil.getColor('surface'))
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })

      // 歌曲列表
      List() {
        ForEach(this.playlistSongs, (song: PlaylistSong, index: number) => {
          ListItem() {
            this.buildSongItem(song, index)
          }
          .margin({ bottom: 1 })
        }, (song: PlaylistSong) => song.id.toString())
      }
      .width('100%')
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
    .width('100%')
  }

  /**
   * 构建歌曲项
   */
  @Builder
  private buildSongItem(song: PlaylistSong, index: number) {
    Row() {
      // 选择框
      if (this.selectedMode) {
        Image(this.selectedSongs.includes(song.id) ? 
          $r('app.media.checkbox-active') : 
          $r('app.media.checkbox'))
          .width(18)
          .height(18)
          .margin({ right: 10 })
          .onClick(() => {
            const index = this.selectedSongs.indexOf(song.id)
            if (index > -1) {
              this.selectedSongs.splice(index, 1)
            } else {
              this.selectedSongs.push(song.id)
            }
          })
      }

      // 序号
      Text((index + 1).toString())
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .width(30)
        .textAlign(TextAlign.Center)
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 歌曲封面
      Image(song.coverImgUrl || $r('app.media.default-cover'))
        .width(40)
        .height(40)
        .borderRadius(ThemeUtil.getBorderRadius('sm'))
        .backgroundColor(ThemeUtil.getColor('surface'))
        .onClick(() => this.playSong(index))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 歌曲信息
      Column() {
        Text(song.name)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: ThemeUtil.getSpacing('xs') })

        Text(`${song.artists.join('/')} - ${song.album}`)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 时长
      Text(this.formatDuration(song.duration))
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 播放按钮
      Image($r('app.media.play'))
        .width(20)
        .height(20)
        .onClick(() => this.playSong(index))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 更多操作
      Image($r('app.media.more'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(60)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建批量操作栏
   */
  @Builder
  private buildBatchBar() {
    Row() {
      Text('已选择' + this.selectedSongs.length + '首')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textPrimary'))

      Blank()

      Text('播放')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('primary'))
        .margin({ right: ThemeUtil.getSpacing('md') })
        .onClick(() => this.handleBatchAction('play'))

      Text('删除')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('error'))
        .onClick(() => this.handleBatchAction('delete'))
    }
    .width('100%')
    .height(44)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .border({ width: 1, color: ThemeUtil.getColor('divider') })
  }
}