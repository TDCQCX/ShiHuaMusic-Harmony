/**
 * 我的喜欢（收藏歌曲）：分页 + 搜索 + 取消收藏
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { Song, SongQuery, TrackModel } from '../../types/common';
import { SongRow } from '../../components/SongRow';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';

@Entry
@Component
struct MyFavoritesPage {
  @State songs: Song[] = [];
  @State searchKeyword: string = '';
  @State isLoading: boolean = true;
  @State loadingMore: boolean = false;
  @State total: number = 0;

  private currentPage: number = 1;
  private readonly pageSize: number = 20;
  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    if (!this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    this.loadFavorites(true);
  }

  private buildQuery(pageNum: number): SongQuery {
    const query: SongQuery = {
      pageNum: pageNum,
      pageSize: this.pageSize,
      songName: this.searchKeyword ? this.searchKeyword : undefined,
      artistName: undefined,
      album: undefined
    };
    return query;
  }

  private async loadFavorites(reset: boolean): Promise<void> {
    if (reset) {
      this.isLoading = true;
      this.currentPage = 1;
    } else {
      this.loadingMore = true;
    }
    try {
      const result = await ApiService.getFavoriteSongs(this.buildQuery(this.currentPage));
      if (result.code === 0 && result.data) {
        this.total = result.data.total;
        if (reset) {
          this.songs = result.data.items;
        } else {
          const merged = this.songs.concat(result.data.items);
          this.songs = merged;
        }
        if (result.data.items.length === this.pageSize) {
          this.currentPage++;
        }
      }
    } catch (error) {
      console.error('加载收藏歌曲失败:', error);
    } finally {
      this.isLoading = false;
      this.loadingMore = false;
    }
  }

  private toTrackModel(song: Song): TrackModel {
    const track: TrackModel = {
      id: song.songId.toString(),
      title: song.songName,
      artist: song.artistName,
      album: song.album,
      cover: song.coverUrl,
      url: song.audioUrl,
      duration: Number(song.duration) * 1000,
      likeStatus: song.likeStatus
    };
    return track;
  }

  private playSong(song: Song, index: number): void {
    const tracks: TrackModel[] = [];
    this.songs.forEach((item: Song) => {
      tracks.push(this.toTrackModel(item));
    });
    this.audioManager.setTrackList(tracks, index);
    this.audioManager.play(index);
    this.globalData.addRecentPlay(tracks[index]);
  }

  private toggleLike(song: Song): void {
    ApiService.cancelCollectSong(song.songId).then((result) => {
      if (result.code === 0) {
        this.audioManager.setLikeStatus(song.songId, 0);
        const updated = this.songs.filter((item: Song) => item.songId !== song.songId);
        this.songs = updated;
      }
    });
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
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => NavUtil.back())
        Blank()
        Text('我的喜欢')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Image($r('app.media.search'))
          .width(22)
          .height(22)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.songs.length === 0) {
        EmptyView({ message: '暂无收藏的歌曲', subMessage: '去发现你喜欢的音乐吧' })
          .layoutWeight(1)
      } else {
        List() {
          ForEach(this.songs, (song: Song, index: number) => {
            ListItem() {
              SongRow({
                song: song,
                index: index,
                onPlay: (item: Song, itemIndex: number) => this.playSong(item, itemIndex),
                onLike: (item: Song) => this.toggleLike(item)
              })
            }
            .margin({ bottom: 1 })
          }, (song: Song) => song.songId.toString())
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
        .onReachEnd(() => {
          if (!this.isLoading && !this.loadingMore && this.songs.length < this.total) {
            this.loadFavorites(false);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
