/**
 * 我的歌单（创建的歌单 / 收藏的歌单）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { PlaylistQuery, RecommendedPlaylist, FavoritePlaylist } from '../../types/common';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';

@Entry
@Component
struct MyPlaylistsPage {
  @State createdPlaylists: RecommendedPlaylist[] = [];
  @State collectedPlaylists: RecommendedPlaylist[] = [];
  @State activeTab: number = 0;
  @State isLoading: boolean = true;

  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private readonly pageSize: number = 30;

  aboutToAppear(): void {
    this.loadCreated();
  }

  private async loadCreated(): Promise<void> {
    try {
      const query: PlaylistQuery = {
        pageNum: 1,
        pageSize: this.pageSize,
        title: undefined,
        style: undefined
      };
      const result = await ApiService.getAllPlaylists(query);
      if (result.code === 0 && result.data) {
        this.createdPlaylists = result.data.items;
      }
    } catch (error) {
      console.error('加载创建的歌单失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private async loadCollected(): Promise<void> {
    try {
      const result = await ApiService.getFavoritePlaylists();
      if (result.code === 0 && result.data) {
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
        this.collectedPlaylists = converted;
      }
    } catch (error) {
      console.error('加载收藏的歌单失败:', error);
    }
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return;
    }
    this.activeTab = index;
    if (index === 1 && this.collectedPlaylists.length === 0) {
      this.loadCollected();
    }
  }

  private goToDetail(playlist: RecommendedPlaylist): void {
    NavUtil.push('pages/PlaylistDetail/PlaylistDetailPage', { playlistId: playlist.playlistId });
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => NavUtil.back())
        Blank()
        Text('我的歌单')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Image($r('app.media.add'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      Row() {
        Text('创建的歌单 (' + this.createdPlaylists.length.toString() + ')')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(this.activeTab === 0 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
          .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => this.switchTab(0))
        Text('收藏的歌单 (' + this.collectedPlaylists.length.toString() + ')')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(this.activeTab === 1 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
          .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => this.switchTab(1))
      }
      .width('100%')
      .height(50)
      .backgroundColor(ThemeUtil.getColor('surface'))
      .margin({ bottom: ThemeUtil.getSpacing('sm') })

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else {
        if (this.activeTab === 0) {
          if (this.createdPlaylists.length === 0) {
            EmptyView({ message: '暂无创建的歌单', subMessage: '去发现更多精彩歌单' })
              .layoutWeight(1)
          } else {
            this.buildPlaylistList(this.createdPlaylists)
          }
        } else {
          if (this.collectedPlaylists.length === 0) {
            EmptyView({ message: '暂无收藏的歌单', subMessage: '去歌单页收藏喜欢的歌单吧' })
              .layoutWeight(1)
          } else {
            this.buildPlaylistList(this.collectedPlaylists)
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  @Builder
  private buildPlaylistList(list: RecommendedPlaylist[]) {
    List() {
      ForEach(list, (playlist: RecommendedPlaylist) => {
        ListItem() {
          Row() {
            Image(playlist.coverUrl ? playlist.coverUrl : $r('app.media.default_cover'))
              .width(60)
              .height(60)
              .borderRadius(ThemeUtil.getBorderRadius('md'))
              .objectFit(ImageFit.Cover)
              .margin({ right: ThemeUtil.getSpacing('md') })
            Text(playlist.title)
              .fontSize(ThemeUtil.getFontSize('md'))
              .fontColor(ThemeUtil.getColor('textPrimary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .alignSelf(ItemAlign.Center)
            Image($r('app.media.arrow_right'))
              .width(20)
              .height(20)
          }
          .width('100%')
          .height(80)
          .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
          .backgroundColor(ThemeUtil.getColor('surface'))
          .onClick(() => this.goToDetail(playlist))
        }
        .margin({ bottom: 1 })
      }, (playlist: RecommendedPlaylist) => playlist.playlistId.toString())
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
  }
}
