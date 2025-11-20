// 首页 - 移植自微信小程序pages/index/index.js
import App from '../../ets/Application';
import { HttpUtil } from '../../utils/HttpUtil';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { SongInfo, PlaylistInfo, BannerInfo, SongListItem } from '../../types/common';
import { AudioManager } from '../../utils/AudioManager';
import { BottomPlayer } from '../../components/BottomPlayer';
import { BottomNavigation } from '../../components/BottomNavigation';
import { router } from '@kit.ArkUI';
import { ThemeUtil, ThemeType } from '../../utils/ThemeUtil';
import { StyleUtil } from '../../utils/StyleUtil';

@Entry
@Component
struct IndexPage {
  @State private banners: BannerInfo[] = [];
  @State private recommendedPlaylists: PlaylistInfo[] = [];
  @State private recommendedSongs: SongListItem[] = [];
  @State private isLoading: boolean = false;
  @State private showWelcomeModal: boolean = false;
  @State private currentSwiperIndex: number = 0;

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance();

  /**
   * 页面即将显示
   */
  aboutToAppear(): void {
    StyleUtil.init();
    this.initializePage();
  }

  /**
   * 初始化页面
   */
  private async initializePage(): Promise<void> {
    // 检查是否需要显示欢迎弹窗
    this.showWelcomeModal = this.globalDataManager.getShowWelcomeModal();
    
    // 加载首页数据
    await this.loadHomePageData();
  }

  /**
   * 加载首页数据
   */
  private async loadHomePageData(): Promise<void> {
    this.isLoading = true;
    try {
      // 并行加载所有数据
      const [bannersResult, playlistsResult, songsResult] = await Promise.all([
        this.loadBanners(),
        this.loadRecommendedPlaylists(),
        this.loadRecommendedSongs()
      ]);

      this.banners = bannersResult;
      this.recommendedPlaylists = playlistsResult;
      this.recommendedSongs = songsResult;

    } catch (error) {
      console.error('加载首页数据失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 加载轮播图数据
   */
  private async loadBanners(): Promise<BannerInfo[]> {
    try {
      const response = await HttpUtil.get<BannerInfo[]>('/banner');
      return response.data || [];
    } catch (error) {
      console.error('加载轮播图失败:', error);
      return [];
    }
  }

  /**
   * 加载推荐歌单
   */
  private async loadRecommendedPlaylists(): Promise<PlaylistInfo[]> {
    try {
      const response = await HttpUtil.get<PlaylistInfo[]>('/playlist/recommended');
      return response.data || [];
    } catch (error) {
      console.error('加载推荐歌单失败:', error);
      return [];
    }
  }

  /**
   * 加载推荐歌曲
   */
  private async loadRecommendedSongs(): Promise<SongListItem[]> {
    try {
      const response = await HttpUtil.get<SongListItem[]>('/song/recommended');
      return response.data || [];
    } catch (error) {
      console.error('加载推荐歌曲失败:', error);
      return [];
    }
  }

  /**
   * 关闭欢迎弹窗
   */
  private async closeWelcomeModal(): Promise<void> {
    this.showWelcomeModal = false;
    await this.globalDataManager.closeWelcomeModal();
  }

  /**
   * 播放歌曲
   */
  private playSong(song: SongListItem, playlist: SongListItem[] = []): void {
    // 转换为完整的SongInfo格式
    const songInfo: SongInfo = {
      id: song.id,
      name: song.name,
      artists: song.artists || [],
      album: song.album || { id: 0, name: '', picUrl: '' },
      duration: song.duration || 0,
      url: song.url || '',
      picUrl: song.picUrl || ''
    };

    const playlistInfo: SongInfo[] = playlist.length > 0 ? 
      playlist.map(item => ({
        id: item.id,
        name: item.name,
        artists: item.artists || [],
        album: item.album || { id: 0, name: '', picUrl: '' },
        duration: item.duration || 0,
        url: item.url || '',
        picUrl: item.picUrl || ''
      })) : [songInfo];

    // 获取音频管理器并播放
    const audioManager = this.globalDataManager.getAudioManager();
    audioManager.setPlaylist(playlistInfo, playlistInfo.findIndex(s => s.id === songInfo.id));
    audioManager.play(songInfo, playlistInfo, playlistInfo.findIndex(s => s.id === songInfo.id));
  }

  /**
   * 轮播图切换回调
   */
  private onSwiperChange(index: number): void {
    this.currentSwiperIndex = index;
  }

  /**
   * 跳转到歌单详情
   */
  private navigateToPlaylistDetail(playlist: PlaylistInfo): void {
    // TODO: 导航到歌单详情页面
    console.log('跳转到歌单详情:', playlist.name);
  }

  /**
   * 跳转到用户页面
   */
  private navigateToUserPage(): void {
    // 导航到用户页面
    try {
      router.pushUrl({
        url: 'pages/User/UserPage',
        params: {}
      });
    } catch (error) {
      console.error('导航到用户页面失败:', error);
    }
  }

  /**
   * 页面构建
   */
  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        this.buildHeader()

        // 主要内容区域
        if (this.isLoading) {
          this.buildLoadingView()
        } else {
          Scroll() {
            Column() {
              // 轮播图
              this.buildBannerSection()

              // 推荐歌单
              this.buildRecommendedPlaylistsSection()

              // 推荐歌曲
              this.buildRecommendedSongsSection()
            }
            .padding({ bottom: 120 }) // 留出底部播放器空间
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }

        Blank()

        // 底部播放器
        BottomPlayer()

        // 底部导航栏
        BottomNavigation()
      }
      .width('100%')
      .height('100%')

      // 欢迎弹窗 - 使用对话框形式
      if (this.showWelcomeModal) {
        this.buildWelcomeModalDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  private buildHeader() {
    Row() {
      Image($r('app.media.search'))
        .width(24)
        .height(24)
        .margin({ right: ThemeUtil.getSpacing('md') })
        .onClick(() => {
          // TODO: 跳转到搜索页面
        })

      Text('发现音乐')
        .fontSize(ThemeUtil.getFontSize('xl'))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.getColor('textPrimary'))

      Blank()

      Image($r('app.media.user'))
        .width(24)
        .height(24)
        .margin({ left: ThemeUtil.getSpacing('md') })
        .onClick(() => this.navigateToUserPage())
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  /**
   * 构建加载视图
   */
  @Builder
  private buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(ThemeUtil.getColor('primary'))
      Text('加载中...')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ top: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 构建轮播图区域
   */
  @Builder
  private buildBannerSection() {
    if (this.banners.length === 0) {
      return;
    }

    Swiper() {
      ForEach(this.banners, (banner: BannerInfo, index: number) => {
        Image(banner.picUrl)
          .width('100%')
          .height(160)
          .borderRadius(ThemeUtil.getBorderRadius('lg'))
          .margin({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })
          .onClick(() => {
            // 处理轮播图点击事件
            console.log('点击轮播图:', banner.title);
          })
      }, (banner: BannerInfo, index: number) => banner.id.toString())
    }
    .width('100%')
    .height(160)
    .indicator(this.banners.length > 1)
    .indicatorStyle({ color: ThemeUtil.getColor('primary') })
    .onChange((index: number) => this.onSwiperChange(index))
    .margin({ bottom: ThemeUtil.getSpacing('md') })
  }

  /**
   * 构建推荐歌单区域
   */
  @Builder
  private buildRecommendedPlaylistsSection() {
    Column() {
      Row() {
        Text('推荐歌单')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        
        Blank()
        
        Text('更多')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .onClick(() => {
            // TODO: 跳转到歌单列表页面
          })
      }
      .width('100%')
      .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg'), bottom: ThemeUtil.getSpacing('sm') })

      Scroll() {
        Row() {
          ForEach(this.recommendedPlaylists, (playlist: PlaylistInfo, index: number) => {
            Column() {
              Image(playlist.coverUrl || playlist.picUrl || '')
                .width(120)
                .height(120)
                .borderRadius(ThemeUtil.getBorderRadius('lg'))
              
              Text(playlist.name)
                .fontSize(ThemeUtil.getFontSize('xs'))
                .fontColor(ThemeUtil.getColor('textPrimary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(120)
                .margin({ top: ThemeUtil.getSpacing('sm') })
            }
            .margin({ right: ThemeUtil.getSpacing('md') })
            .onClick(() => this.navigateToPlaylistDetail(playlist))
          }, (playlist: PlaylistInfo) => playlist.id.toString())
        }
        .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })
      }
      .scrollBar(BarState.Off)
      .height(170)
    }
    .width('100%')
    .margin({ bottom: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ top: ThemeUtil.getSpacing('sm') })
  }

  /**
   * 构建推荐歌曲区域
   */
  @Builder
  private buildRecommendedSongsSection() {
    Column() {
      Row() {
        Text('推荐歌曲')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        
        Blank()
        
        Text('更多')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .onClick(() => {
            // TODO: 跳转到歌曲列表页面
          })
      }
      .width('100%')
      .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg'), bottom: ThemeUtil.getSpacing('sm') })

      ForEach(this.recommendedSongs, (song: SongListItem, index: number) => {
        this.buildSongItem(song, index)
      }, (song: SongListItem) => song.id.toString())
    }
    .width('100%')
    .backgroundColor(ThemeUtil.getColor('surface'))
    .padding({ top: ThemeUtil.getSpacing('sm'), bottom: ThemeUtil.getSpacing('sm') })
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
        .width(30)
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

      Image($r('app.media.ic_play'))
        .width(20)
        .height(20)
        .margin({ left: ThemeUtil.getSpacing('md') })
        .onClick(() => this.playSong(song, this.recommendedSongs))
    }
    .width('100%')
    .height(60)
    .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })
    .onClick(() => this.playSong(song, this.recommendedSongs))
  }

  /**
   * 构建欢迎弹窗
   */
  @Builder
  private buildWelcomeModal() {
    Column() {
      Text('欢迎使用')
        .fontSize(ThemeUtil.getFontSize('xl'))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .margin({ bottom: ThemeUtil.getSpacing('sm') })

      Text('聆听美好，享受音乐')
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('textSecondary'))
        .margin({ bottom: ThemeUtil.getSpacing('xl') })

      Button('开始体验')
        .width(120)
        .height(40)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontColor(ThemeUtil.getColor('onPrimary'))
        .backgroundColor(ThemeUtil.getColor('primary'))
        .borderRadius(ThemeUtil.getBorderRadius('lg'))
        .onClick(() => this.closeWelcomeModal())
    }
    .width(280)
    .padding(24)
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('xl'))
  }
  .width('100%')
  .height('100%')
  .backgroundColor(ThemeUtil.getColor('overlay'))
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}

/**
 * 首页应用程序入口
 */
export default class IndexApplication extends App {
  onCreate(): void {
    console.log('首页应用启动');
  }

  onDestroy(): void {
    console.log('首页应用销毁');
  }
}