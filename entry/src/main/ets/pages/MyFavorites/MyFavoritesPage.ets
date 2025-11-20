/**
 * 我的收藏页面 - MyFavoritesPage
 * 对应小程序 pages/my-favorites/my-favorites
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { SongListItem, ApiResponse } from '../../types/common'
import { HttpUtil } from '../../utils/HttpUtil'
import { ThemeUtil } from '../../utils/ThemeUtil'

interface FavoriteSong {
  id: number
  name: string
  artists: string[]
  album: string
  duration: number
  coverImgUrl: string
  playUrl: string
  addTime: number
}

@Component
export struct MyFavoritesPage {
  @State favoriteSongs: FavoriteSong[] = []
  @State isLoading: boolean = false
  @State selectedMode: boolean = false
  @State selectedSongs: number[] = []
  @State showPlayer: boolean = false
  @State searchKeyword: string = ''

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private httpUtil: HttpUtil = new HttpUtil()

  /**
   * 页面加载
   */
  aboutToAppear(): void {
    this.loadFavoriteSongs()
    
    // 检查播放状态
    const currentSong = this.globalDataManager.getCurrentSong()
    this.showPlayer = !!currentSong
  }

  /**
   * 加载收藏歌曲
   */
  private async loadFavoriteSongs(): Promise<void> {
    try {
      this.isLoading = true

      // TODO: 调用真实API
      // const response: ApiResponse = await this.httpUtil.get('/user/likelist')
      
      // 模拟数据
      await new Promise(resolve => setTimeout(resolve, 1000))

      this.favoriteSongs = [
        {
          id: 1,
          name: '演员',
          artists: ['薛之谦'],
          album: '绅士',
          duration: 232000,
          coverImgUrl: '',
          playUrl: '',
          addTime: Date.now() - 86400000 * 2
        },
        {
          id: 2,
          name: '告白气球',
          artists: ['周杰伦'],
          album: '周杰伦的床边故事',
          duration: 205000,
          coverImgUrl: '',
          playUrl: '',
          addTime: Date.now() - 86400000 * 1
        },
        {
          id: 3,
          name: '青花瓷',
          artists: ['周杰伦'],
          album: '我很忙',
          duration: 235000,
          coverImgUrl: '',
          playUrl: '',
          addTime: Date.now() - 3600000 * 12
        }
      ]
    } catch (error) {
      console.error('加载收藏歌曲失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 搜索过滤歌曲
   */
  private getFilteredSongs(): FavoriteSong[] {
    if (!this.searchKeyword) {
      return this.favoriteSongs
    }
    
    return this.favoriteSongs.filter(song => 
      song.name.toLowerCase().includes(this.searchKeyword.toLowerCase()) ||
      song.artists.some(artist => artist.toLowerCase().includes(this.searchKeyword.toLowerCase())) ||
      song.album.toLowerCase().includes(this.searchKeyword.toLowerCase())
    )
  }

  /**
   * 播放歌曲
   */
  private playSong(song: FavoriteSong, index: number): void {
    const songList: SongListItem[] = this.getFilteredSongs().map((item, idx) => ({
      id: item.id,
      name: item.name,
      artists: item.artists,
      album: item.album,
      duration: item.duration,
      coverImgUrl: item.coverImgUrl,
      playUrl: item.playUrl
    }))

    // 设置全局播放状态
    this.globalDataManager.setCurrentSong(songList[index])
    this.globalDataManager.setSongList(songList)
    this.globalDataManager.setCurrentIndex(index)
    
    this.showPlayer = true
  }

  /**
   * 切换收藏状态
   */
  private toggleFavorite(songId: number): void {
    const index = this.favoriteSongs.findIndex(song => song.id === songId)
    if (index > -1) {
      this.favoriteSongs.splice(index, 1)
    }
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
          const firstSong = this.favoriteSongs.find(song => song.id === this.selectedSongs[0])
          const index = this.getFilteredSongs().findIndex(song => song.id === this.selectedSongs[0])
          if (firstSong && index > -1) {
            this.playSong(firstSong, index)
          }
        }
        break
      case 'delete':
        // 取消收藏
        this.selectedSongs.forEach(songId => {
          this.toggleFavorite(songId)
        })
        break
    }

    this.selectedSongs = []
    this.selectedMode = false
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
   * 格式化添加时间
   */
  private formatAddTime(timestamp: number): string {
    const now = Date.now()
    const diff = now - timestamp

    if (diff < 3600000) {
      const minutes = Math.floor(diff / 60000)
      return `${minutes}分钟前`
    } else if (diff < 86400000) {
      const hours = Math.floor(diff / 3600000)
      return `${hours}小时前`
    } else if (diff < 86400000 * 7) {
      const days = Math.floor(diff / 86400000)
      return `${days}天前`
    } else {
      const date = new Date(timestamp)
      return `${date.getMonth() + 1}/${date.getDate()}`
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      // 搜索框
      if (!this.selectedMode) {
        this.buildSearchBar()
      }

      // 列表操作栏
      if (this.selectedMode) {
        this.buildBatchBar()
      }

      // 歌曲列表
      this.buildSongList()

      // 空白提示
      if (this.favoriteSongs.length === 0 && !this.isLoading) {
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

      Text('我的收藏')
        .fontSize(ThemeUtil.getFontSize('xl'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .fontWeight(FontWeight.Bold)

      Blank()

      if (!this.selectedMode) {
        Text('编辑')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('primary'))
          .onClick(() => this.selectedMode = true)
      } else {
        Text('取消')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('primary'))
          .onClick(() => {
            this.selectedMode = false
            this.selectedSongs = []
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建搜索栏
   */
  @Builder
  private buildSearchBar() {
    Row() {
      Image($r('app.media.search'))
        .width(16)
        .height(16)
        .margin({ left: 12 })

      TextInput({ placeholder: '搜索收藏的歌曲...' })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => {
          this.searchKeyword = value
        })

      if (this.searchKeyword) {
        Image($r('app.media.clear'))
          .width(16)
          .height(16)
          .onClick(() => {
            this.searchKeyword = ''
          })
      }
    }
    .width('100%')
    .height(40)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: 1 })
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

      Text('取消收藏')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('error'))
        .onClick(() => this.handleBatchAction('delete'))
    }
    .width('100%')
    .height(44)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建歌曲列表
   */
  @Builder
  private buildSongList() {
    List() {
      ForEach(this.getFilteredSongs(), (song: FavoriteSong, index: number) => {
        ListItem() {
          this.buildSongItem(song, index)
        }
        .margin({ bottom: 1 })
      }, (song: FavoriteSong) => song.id.toString())
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
  private buildSongItem(song: FavoriteSong, index: number) {
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

      // 歌曲封面
      Image(song.coverImgUrl || $r('app.media.default-cover'))
        .width(40)
        .height(40)
        .borderRadius(ThemeUtil.getBorderRadius('sm'))
        .backgroundColor(ThemeUtil.getColor('divider'))
        .onClick(() => this.playSong(song, index))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 歌曲信息
      Column() {
        Text(song.name)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 2 })

        Text(`${song.artists.join('/')} - ${song.album}`)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textSecondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 添加时间
      Text(this.formatAddTime(song.addTime))
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 播放按钮
      Image($r('app.media.play'))
        .width(20)
        .height(20)
        .onClick(() => this.playSong(song, index))
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
   * 构建空白视图
   */
  @Builder
  private buildEmptyView() {
    Column() {
      Image($r('app.media.like-active'))
        .width(80)
        .height(80)
        .opacity(0.3)
        .margin({ bottom: ThemeUtil.getSpacing('md') })

      Text('暂无收藏的歌曲')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .margin({ bottom: ThemeUtil.getSpacing('sm') })

      Text('去发现你喜欢的音乐吧')
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}