/**
 * 搜索页面 - SearchPage
 * 对应小程序 pages/search/search
 */

import router from '@ohos.router'
import { GlobalDataManager } from '../../utils/GlobalDataManager'
import { ThemeUtil } from '../../utils/ThemeUtil'
import { SongListItem, ApiResponse } from '../../types/common'
import { HttpUtil } from '../../utils/HttpUtil'

interface SearchKeyword {
  first: string
  second: string
}

interface SearchHistory {
  id: string
  keyword: string
  time: number
}

interface SearchResult {
  songs: SearchSong[]
  artists: SearchArtist[]
  albums: SearchAlbum[]
  playlists: SearchPlaylist[]
}

interface SearchSong {
  id: number
  name: string
  artists: string[]
  album: string
  duration: number
  coverImgUrl: string
  playUrl: string
}

interface SearchArtist {
  id: number
  name: string
  picUrl: string
  alias: string[]
}

interface SearchAlbum {
  id: number
  name: string
  artist: string
  coverImgUrl: string
  publishTime: number
}

interface SearchPlaylist {
  id: number
  name: string
  coverImgUrl: string
  creator: string
  playCount: number
  trackCount: number
}

@Component
export struct SearchPage {
  @State searchKeyword: string = ''
  @State searchHistory: SearchHistory[] = []
  @State hotKeywords: SearchKeyword[] = []
  @State searchResults: SearchResult = {
    songs: [],
    artists: [],
    albums: [],
    playlists: []
  }
  @State showResults: boolean = false
  @State isLoading: boolean = false
  @State activeTab: 'songs' | 'artists' | 'albums' | 'playlists' = 'songs'
  @State showPlayer: boolean = false

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance()
  private httpUtil: HttpUtil = new HttpUtil()
  private searchTimer: number = -1

  /**
   * 页面加载
   */
  aboutToAppear(): void {
    this.loadHotKeywords()
    this.loadSearchHistory()
    
    // 检查播放状态
    const currentSong = this.globalDataManager.getCurrentSong()
    this.showPlayer = !!currentSong
  }

  /**
   * 页面即将消失
   */
  aboutToDisappear(): void {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer)
      this.searchTimer = -1
    }
  }

  /**
   * 加载热搜关键词
   */
  private loadHotKeywords(): void {
    // TODO: 调用真实API
    // 模拟数据
    this.hotKeywords = [
      { first: '周杰伦', second: '热门' },
      { first: '薛之谦', second: '上升最快' },
      { first: '告白气球', second: '歌曲' },
      { first: '青花瓷', second: '经典' },
      { first: '陈奕迅', second: '热门' },
      { first: '邓紫棋', second: '上升最快' },
      { first: '林俊杰', second: '热门' },
      { first: '张杰', second: '上升最快' },
      { first: '李荣浩', second: '热门' },
      { first: '毛不易', second: '上升最快' }
    ]
  }

  /**
   * 加载搜索历史
   */
  private loadSearchHistory(): void {
    // 从本地存储加载搜索历史
    // TODO: 实现本地存储功能
    this.searchHistory = []
  }

  /**
   * 保存搜索历史
   */
  private saveSearchHistory(): void {
    // 保存到本地存储
    // TODO: 实现本地存储功能
  }

  /**
   * 清空搜索历史
   */
  private clearSearchHistory(): void {
    this.searchHistory = []
    // TODO: 清除本地存储
  }

  /**
   * 执行搜索
   */
  private performSearch(): void {
    if (!this.searchKeyword.trim()) {
      return
    }

    this.showResults = true
    this.search()

    // 添加到搜索历史
    this.addToHistory(this.searchKeyword.trim())
  }

  /**
   * 搜索
   */
  private async search(): Promise<void> {
    if (!this.searchKeyword.trim()) return

    try {
      this.isLoading = true

      // TODO: 调用真实API
      // const response: ApiResponse = await this.httpUtil.get(`/search?keywords=${this.searchKeyword}`)
      
      // 模拟搜索结果
      await new Promise(resolve => setTimeout(resolve, 800))

      this.searchResults = {
        songs: [
          {
            id: 1,
            name: '演员',
            artists: ['薛之谦'],
            album: '绅士',
            duration: 232000,
            coverImgUrl: '',
            playUrl: ''
          },
          {
            id: 2,
            name: '告白气球',
            artists: ['周杰伦'],
            album: '周杰伦的床边故事',
            duration: 205000,
            coverImgUrl: '',
            playUrl: ''
          },
          {
            id: 3,
            name: '青花瓷',
            artists: ['周杰伦'],
            album: '我很忙',
            duration: 235000,
            coverImgUrl: '',
            playUrl: ''
          }
        ],
        artists: [
          {
            id: 1,
            name: '周杰伦',
            picUrl: '',
            alias: ['周董']
          },
          {
            id: 2,
            name: '薛之谦',
            picUrl: '',
            alias: ['薛薛']
          }
        ],
        albums: [
          {
            id: 1,
            name: '我很忙',
            artist: '周杰伦',
            coverImgUrl: '',
            publishTime: Date.now()
          }
        ],
        playlists: [
          {
            id: 1,
            name: '经典老歌合集',
            coverImgUrl: '',
            creator: '音乐爱好者',
            playCount: 99999,
            trackCount: 100
          }
        ]
      }
    } catch (error) {
      console.error('搜索失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 实时搜索
   */
  private debounceSearch(): void {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer)
    }

    this.searchTimer = setTimeout(() => {
      if (this.searchKeyword.trim()) {
        this.performSearch()
      } else {
        this.showResults = false
      }
    }, 300)
  }

  /**
   * 添加到搜索历史
   */
  private addToHistory(keyword: string): void {
    // 移除已存在的相同关键词
    this.searchHistory = this.searchHistory.filter(item => item.keyword !== keyword)
    
    // 添加到开头
    this.searchHistory.unshift({
      id: Date.now().toString(),
      keyword: keyword,
      time: Date.now()
    })

    // 限制历史记录数量
    if (this.searchHistory.length > 20) {
      this.searchHistory = this.searchHistory.slice(0, 20)
    }

    this.saveSearchHistory()
  }

  /**
   * 点击热搜关键词
   */
  private clickHotKeyword(keyword: string): void {
    this.searchKeyword = keyword
    this.performSearch()
  }

  /**
   * 点击搜索历史
   */
  private clickHistoryKeyword(keyword: string): void {
    this.searchKeyword = keyword
    this.performSearch()
  }

  /**
   * 播放歌曲
   */
  private playSong(song: SearchSong, index: number): void {
    const songList: SongListItem[] = this.searchResults.songs.map((item, idx) => ({
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
   * 跳转到艺术家页面
   */
  private goToArtist(artist: SearchArtist): void {
    // TODO: 实现艺术家页面
    console.log('跳转到艺术家页面:', artist.name)
  }

  /**
   * 跳转到专辑页面
   */
  private goToAlbum(album: SearchAlbum): void {
    // TODO: 实现专辑页面
    console.log('跳转到专辑页面:', album.name)
  }

  /**
   * 跳转到歌单页面
   */
  private goToPlaylist(playlist: SearchPlaylist): void {
    router.pushUrl({
      url: '/pages/PlaylistDetail/PlaylistDetailPage',
      params: {
        playlistId: playlist.id,
        playlistName: playlist.name
      }
    })
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
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`
  }

  build() {
    Column() {
      // 顶部搜索栏
      this.buildSearchBar()

      // 搜索结果/推荐内容
      if (this.showResults) {
        this.buildSearchResults()
      } else {
        this.buildRecommendContent()
      }

      Blank()
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
      Image($r('app.media.back'))
        .width(24)
        .height(24)
        .onClick(() => router.back())

      // 搜索输入框
      Row() {
        Image($r('app.media.search'))
          .width(16)
          .height(16)
          .margin({ left: 12 })

        TextInput({
          placeholder: '搜索歌曲、歌手、歌词、用户',
          text: this.searchKeyword
        })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontSize(ThemeUtil.getFontSize('sm'))
          .onChange((value: string) => {
            this.searchKeyword = value
            this.debounceSearch()
          })
          .onSubmit(() => {
            this.performSearch()
          })

        if (this.searchKeyword) {
          Image($r('app.media.clear'))
            .width(16)
            .height(16)
            .onClick(() => {
              this.searchKeyword = ''
              this.showResults = false
            })
        }
      }
      .layoutWeight(1)
      .height(36)
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderRadius(ThemeUtil.getBorderRadius('lg'))
      .margin({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })

      Text('搜索')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('primary'))
        .onClick(() => this.performSearch())
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建推荐内容
   */
  @Builder
  private buildRecommendContent() {
    Column() {
      // 搜索历史
      if (this.searchHistory.length > 0) {
        this.buildSearchHistory()
      }

      // 热搜榜
      this.buildHotKeywords()
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建搜索历史
   */
  @Builder
  private buildSearchHistory() {
    Column() {
      Row() {
        Text('搜索历史')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('清空')
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .onClick(() => this.clearSearchHistory())
      }
      .width('100%')
      .height(40)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })

      // 历史关键词
      Wrap() {
        ForEach(this.searchHistory, (item: SearchHistory) => {
          Text(item.keyword)
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .backgroundColor(ThemeUtil.getColor('surface'))
            .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: ThemeUtil.getSpacing('xs'), bottom: ThemeUtil.getSpacing('xs') })
            .borderRadius(ThemeUtil.getBorderRadius('lg'))
            .margin({ right: ThemeUtil.getSpacing('sm'), bottom: ThemeUtil.getSpacing('sm') })
            .onClick(() => this.clickHistoryKeyword(item.keyword))
        }, (item: SearchHistory) => item.id)
      }
      .width('100%')
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: ThemeUtil.getSpacing('sm') })
  }

  /**
   * 构建热搜榜
   */
  @Builder
  private buildHotKeywords() {
    Column() {
      Row() {
        Text('热搜榜')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(40)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })

      // 热搜关键词列表
      List() {
        ForEach(this.hotKeywords, (item: SearchKeyword, index: number) => {
          ListItem() {
            Row() {
              // 排名
              Text((index + 1).toString())
                .fontSize(ThemeUtil.getFontSize('md'))
                .fontColor(this.getRankColor(index))
                .fontWeight(FontWeight.Bold)
                .width(30)

              // 关键词
              Text(item.first)
                .fontSize(ThemeUtil.getFontSize('md'))
                .fontColor(ThemeUtil.getColor('textPrimary'))
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              // 标签
              if (item.second) {
                Text(item.second)
                  .fontSize(ThemeUtil.getFontSize('xs'))
                  .fontColor(ThemeUtil.getColor('textHint'))
                  .backgroundColor(ThemeUtil.getColor('surface'))
                  .padding({ left: ThemeUtil.getSpacing('xs'), right: ThemeUtil.getSpacing('xs'), top: ThemeUtil.getSpacing('xs'), bottom: ThemeUtil.getSpacing('xs') })
                  .borderRadius(ThemeUtil.getBorderRadius('sm'))
              }
            }
            .width('100%')
            .height(40)
            .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
          }
          .onClick(() => this.clickHotKeyword(item.first))
        }, (item: SearchKeyword, index: number) => index.toString())
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
    }
    .width('100%')
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 获取排名颜色
   */
  private getRankColor(rank: number): string {
    switch (rank) {
      case 0:
      case 1:
      case 2:
        return '#ff4757' // 红色前三名
      default:
        return '#999' // 其他灰色
    }
  }

  /**
   * 构建搜索结果
   */
  @Builder
  private buildSearchResults() {
    Column() {
      // 结果标签页
      this.buildResultTabs()

      // 结果列表
      this.buildResultList()
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建结果标签页
   */
  @Builder
  private buildResultTabs() {
    Row() {
      Text('歌曲')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.activeTab === 'songs' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textSecondary'))
        .fontWeight(this.activeTab === 'songs' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.activeTab = 'songs')

      Text(' | ')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textHint'))

      Text('歌手')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.activeTab === 'artists' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textSecondary'))
        .fontWeight(this.activeTab === 'artists' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.activeTab = 'artists')

      Text(' | ')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textHint'))

      Text('专辑')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.activeTab === 'albums' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textSecondary'))
        .fontWeight(this.activeTab === 'albums' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.activeTab = 'albums')

      Text(' | ')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(ThemeUtil.getColor('textHint'))

      Text('歌单')
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontColor(this.activeTab === 'playlists' ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textSecondary'))
        .fontWeight(this.activeTab === 'playlists' ? FontWeight.Bold : FontWeight.Normal)
        .onClick(() => this.activeTab = 'playlists')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .margin({ bottom: 1 })
  }

  /**
   * 构建结果列表
   */
  @Builder
  private buildResultList() {
    List() {
      // 根据活跃标签页显示不同内容
      if (this.activeTab === 'songs') {
        ForEach(this.searchResults.songs, (song: SearchSong, index: number) => {
          ListItem() {
            this.buildSongResult(song, index)
          }
          .margin({ bottom: 1 })
        }, (song: SearchSong) => song.id.toString())
      } else if (this.activeTab === 'artists') {
        ForEach(this.searchResults.artists, (artist: SearchArtist) => {
          ListItem() {
            this.buildArtistResult(artist)
          }
          .margin({ bottom: 1 })
        }, (artist: SearchArtist) => artist.id.toString())
      } else if (this.activeTab === 'albums') {
        ForEach(this.searchResults.albums, (album: SearchAlbum) => {
          ListItem() {
            this.buildAlbumResult(album)
          }
          .margin({ bottom: 1 })
        }, (album: SearchAlbum) => album.id.toString())
      } else if (this.activeTab === 'playlists') {
        ForEach(this.searchResults.playlists, (playlist: SearchPlaylist) => {
          ListItem() {
            this.buildPlaylistResult(playlist)
          }
          .margin({ bottom: 1 })
        }, (playlist: SearchPlaylist) => playlist.id.toString())
      }
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
        Text('搜索中...')
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
   * 构建歌曲结果
   */
  @Builder
  private buildSongResult(song: SearchSong, index: number) {
    Row() {
      // 歌曲封面
      Image(song.coverImgUrl || $r('app.media.default-cover'))
        .width(40)
        .height(40)
        .borderRadius(ThemeUtil.getBorderRadius('sm'))
        .backgroundColor(ThemeUtil.getColor('surface'))
        .onClick(() => this.playSong(song, index))
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
   * 构建歌手结果
   */
  @Builder
  private buildArtistResult(artist: SearchArtist) {
    Row() {
      // 歌手头像
      Image(artist.picUrl || $r('app.media.default-avatar'))
        .width(50)
        .height(50)
        .borderRadius(ThemeUtil.getBorderRadius('full'))
        .backgroundColor(ThemeUtil.getColor('surface'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 歌手信息
      Column() {
        Text(artist.name)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: ThemeUtil.getSpacing('xs') })

        if (artist.alias.length > 0) {
          Text(artist.alias.join('/'))
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.arrow-right'))
        .width(16)
        .height(16)
    }
    .width('100%')
    .height(70)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(() => this.goToArtist(artist))
  }

  /**
   * 构建专辑结果
   */
  @Builder
  private buildAlbumResult(album: SearchAlbum) {
    Row() {
      // 专辑封面
      Image(album.coverImgUrl || $r('app.media.default-cover'))
        .width(50)
        .height(50)
        .borderRadius(ThemeUtil.getBorderRadius('sm'))
        .backgroundColor(ThemeUtil.getColor('surface'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      // 专辑信息
      Column() {
        Text(album.name)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: ThemeUtil.getSpacing('xs') })

        Text(`${album.artist} • ${this.formatTime(album.publishTime)}`)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.arrow-right'))
        .width(16)
        .height(16)
    }
    .width('100%')
    .height(70)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(() => this.goToAlbum(album))
  }

  /**
   * 构建歌单结果
   */
  @Builder
  private buildPlaylistResult(playlist: SearchPlaylist) {
    Row() {
      // 歌单封面
      Image(playlist.coverImgUrl || $r('app.media.default-cover'))
        .width(50)
        .height(50)
        .borderRadius(ThemeUtil.getBorderRadius('sm'))
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

        Text(`by ${playlist.creator} • ${playlist.trackCount}首 • ${this.formatPlayCount(playlist.playCount)}次播放`)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.arrow-right'))
        .width(16)
        .height(16)
    }
    .width('100%')
    .height(70)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(() => this.goToPlaylist(playlist))
  }
}