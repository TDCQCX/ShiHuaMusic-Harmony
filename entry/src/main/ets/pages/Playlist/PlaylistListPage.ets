/**
 * 全部歌单：居中搜索框 + 精选/收藏切换 + 风格下拉筛选 + 卡片列表
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { FavoritePlaylist, PlaylistQuery, RecommendedPlaylist } from '../../types/common';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';
import { TabManager } from '../../utils/TabManager';

@Entry
@Component
struct PlaylistListPage {
  @State playlists: RecommendedPlaylist[] = [];
  @State searchKeyword: string = '';
  @State activeTab: number = 0;
  @State isLoading: boolean = true;
  @State loadingMore: boolean = false;
  @State total: number = 0;

  private currentPage: number = 1;
  private readonly pageSize: number = 12;
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    this.loadPlaylists(true);
  }

  private buildQuery(pageNum: number): PlaylistQuery {
    const query: PlaylistQuery = {
      pageNum: pageNum,
      pageSize: this.pageSize,
      title: this.searchKeyword ? this.searchKeyword : undefined,
      style: undefined
    };
    return query;
  }

  private async loadPlaylists(reset: boolean): Promise<void> {
    if (reset) {
      this.isLoading = true;
      this.currentPage = 1;
    } else {
      this.loadingMore = true;
    }
    try {
      if (this.activeTab === 1) {
        const result = await ApiService.getFavoritePlaylists();
        if (result.code === 0 && result.data && result.data.items) {
          const items = result.data.items;
          const converted: RecommendedPlaylist[] = [];
          items.forEach((item: FavoritePlaylist) => {
            const playlist: RecommendedPlaylist = {
              playlistId: item.id,
              title: item.name,
              coverUrl: item.coverImgUrl
            };
            converted.push(playlist);
          });
          this.playlists = converted;
          this.total = converted.length;
        }
      } else {
        const result = await ApiService.getAllPlaylists(this.buildQuery(this.currentPage));
        if (result.code === 0 && result.data && result.data.items) {
          this.total = result.data.total;
          if (reset) {
            this.playlists = result.data.items;
          } else {
            const merged = this.playlists.concat(result.data.items);
            this.playlists = merged;
          }
          if (result.data.items.length === this.pageSize) {
            this.currentPage++;
          }
        }
      }
    } catch (error) {
      console.error('加载歌单列表失败:', error);
    } finally {
      this.isLoading = false;
      this.loadingMore = false;
    }
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.activeTab = index;
    if (index === 1 && !this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    this.loadPlaylists(true);
  }

  private goToDetail(playlist: RecommendedPlaylist): void {
    NavUtil.push('pages/PlaylistDetail/PlaylistDetailPage', { playlistId: playlist.playlistId });
  }

  private getAvatar(): string | Resource {
    const userInfo = this.globalData.getUserInfo();
    if (userInfo && (userInfo.avatarUrl || userInfo.userAvatar)) {
      return userInfo.avatarUrl || userInfo.userAvatar;
    }
    return $r('app.media.default_avatar');
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
      // 标题栏：返回 + 居中圆角搜索框 + 用户头像
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => NavUtil.back())
        TextInput({ placeholder: '搜索歌单...', text: this.searchKeyword })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ThemeUtil.getColor('surface'))
          .borderRadius(20)
          .fontSize(ThemeUtil.getFontSize('sm'))
          .padding({ left: 16, right: 16 })
          .margin({ left: ThemeUtil.getSpacing('sm'), right: ThemeUtil.getSpacing('sm') })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit(() => this.loadPlaylists(true))
        Image(this.getAvatar())
          .width(36)
          .height(36)
          .borderRadius(ThemeUtil.getBorderRadius('full'))
          .objectFit(ImageFit.Cover)
          .backgroundColor(ThemeUtil.getColor('surface'))
          .onClick(() => TabManager.setTab(2))
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      // 精选/收藏切换（左侧） + 风格下拉（右侧）
      Row() {
        Row() {
          Text('精选歌单')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(this.activeTab === 0 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
            .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
            .onClick(() => this.switchTab(0))
          Text('我的收藏')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(this.activeTab === 1 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
            .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
            .margin({ left: ThemeUtil.getSpacing('lg') })
            .onClick(() => this.switchTab(1))
        }
        .layoutWeight(1)

        Blank()
      }
      .width('100%')
      .height(52)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))
      .margin({ bottom: ThemeUtil.getSpacing('sm') })

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.playlists.length === 0) {
        EmptyView({ message: '暂无歌单', subMessage: '换个筛选条件试试吧' })
          .layoutWeight(1)
      } else {
        Grid() {
          ForEach(this.playlists, (playlist: RecommendedPlaylist) => {
            GridItem() {
              Column() {
                Stack() {
                  Image(playlist.coverUrl ? playlist.coverUrl : $r('app.media.default_cover'))
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(ThemeUtil.getBorderRadius('lg'))
                    .objectFit(ImageFit.Cover)
                    .backgroundColor(ThemeUtil.getColor('surface'))
                    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.10)', offsetY: 4 })
                  Circle()
                    .width(36)
                    .height(36)
                    .fill('#FFFFFF')
                    .opacity(0.9)
                    .position({ x: '72%', y: '68%' })
                    .shadow({ radius: 6, color: 'rgba(0, 0, 0, 0.25)' })
                  SymbolGlyph($r('sys.symbol.play_fill'))
                    .fontSize(18)
                    .fontColor([ThemeUtil.getColor('primary')])
                    .position({ x: '77%', y: '71%' })
                }
                .width('100%')
                .aspectRatio(1)
                Text(playlist.title)
                  .fontSize(ThemeUtil.getFontSize('xs'))
                  .fontColor(ThemeUtil.getColor('textPrimary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .margin({ top: ThemeUtil.getSpacing('xs') })
                Row() {
                  Image($r('app.media.default_avatar'))
                    .width(14)
                    .height(14)
                    .borderRadius(ThemeUtil.getBorderRadius('full'))
                    .objectFit(ImageFit.Cover)
                  Text('ShiHua Music')
                    .fontSize(ThemeUtil.getFontSize('xs'))
                    .fontColor(ThemeUtil.getColor('textHint'))
                    .margin({ left: 4 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .margin({ top: 2 })
              }
              .width('100%')
              .onClick(() => this.goToDetail(playlist))
            }
          }, (playlist: RecommendedPlaylist) => playlist.playlistId.toString())
        }
        .layoutWeight(1)
        .columnsTemplate('1fr 1fr')
        .columnsGap(ThemeUtil.getSpacing('md'))
        .rowsGap(ThemeUtil.getSpacing('lg'))
        .padding(ThemeUtil.getSpacing('md'))
        .scrollBar(BarState.Off)
        .onReachEnd(() => {
          if (this.activeTab === 0 && !this.isLoading && !this.loadingMore && this.playlists.length < this.total) {
            this.loadPlaylists(false);
          }
        })
      }

      if (this.loadingMore) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color(ThemeUtil.getColor('primary'))
          .margin({ top: 8, bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
