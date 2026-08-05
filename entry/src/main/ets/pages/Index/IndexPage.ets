/**
 * 发现首页（Banner / 推荐歌单两行三列横向滑动 / 猜你喜欢）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { Banner, RecommendedPlaylist, Song, TrackModel } from '../../types/common';
import { SongRow } from '../../components/SongRow';
import { LoadingView } from '../../components/common/LoadingView';
import { TabManager } from '../../utils/TabManager';
import { ThemeType } from '../../utils/ThemeUtil';

@Component
export struct IndexPage {
  @StorageLink('themeVersion') themeVersion: number = 0;
  @State banners: Banner[] = [];
  @State recommendedPlaylists: RecommendedPlaylist[] = [];
  @State recommendedSongs: Song[] = [];
  @State isLoading: boolean = true;
  @State refreshing: boolean = false;
  @State themeRefresh: number = 0;

  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private audioManager: AudioManager = AudioManager.getInstance();
  private themeListener: (theme: ThemeType) => void = (theme: ThemeType) => {
    this.themeRefresh++;
  };

  aboutToAppear(): void {
    this.loadHomeData();
    ThemeUtil.addThemeChangeListener(this.themeListener);
  }

  aboutToDisappear(): void {
    ThemeUtil.removeThemeChangeListener(this.themeListener);
  }

  private async loadHomeData(): Promise<void> {
    try {
      const bannerResult = await ApiService.getBanner();
      if (bannerResult.code === 0 && bannerResult.data) {
        this.banners = bannerResult.data;
      }
      const playlistResult = await ApiService.getRecommendedPlaylists();
      if (playlistResult.code === 0 && playlistResult.data) {
        // 推荐歌单：仅保留两行三列共 6 个
        this.recommendedPlaylists = playlistResult.data.slice(0, 6);
      }
      const songResult = await ApiService.getRecommendedSongs();
      if (songResult.code === 0 && songResult.data) {
        // 猜你喜欢：限定 10 首
        this.recommendedSongs = songResult.data.slice(0, 10);
      }
    } catch (error) {
      console.error('加载首页数据失败:', error);
    } finally {
      this.isLoading = false;
      this.refreshing = false;
    }
  }

  private onRefresh(): void {
    this.refreshing = true;
    this.loadHomeData();
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
    this.recommendedSongs.forEach((item: Song) => {
      tracks.push(this.toTrackModel(item));
    });
    this.audioManager.setTrackList(tracks, index);
    this.audioManager.play(index);
    if (index >= 0 && index < tracks.length) {
      this.globalData.addRecentPlay(tracks[index]);
    }
  }

  private goToPlaylistDetail(playlist: RecommendedPlaylist): void {
    NavUtil.push('pages/PlaylistDetail/PlaylistDetailPage', { playlistId: playlist.playlistId });
  }

  private goToAllPlaylists(): void {
    NavUtil.push('pages/Playlist/PlaylistListPage');
  }

  private goToSearch(): void {
    NavUtil.push('pages/Search/SearchPage');
  }

  private switchToUser(): void {
    TabManager.setTab(2);
  }

  build() {
    Column() {
      this.buildHeader()
      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else {
        Refresh({ refreshing: this.refreshing }) {
          Scroll() {
            Column() {
              this.buildBanner()
              this.buildRecommendedPlaylists()
              this.buildGuessYouLike()
            }
            .padding({ bottom: 24 })
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .layoutWeight(1)
        .onRefreshing(() => this.onRefresh())
      }
      Text(this.themeVersion.toString())
        .fontSize(0)
        .width(0)
        .height(0)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
    .opacity(this.themeRefresh >= 0 ? 1 : 1)
  }

  @Builder
  private buildHeader() {
    Row() {
      Image($r('app.media.search'))
        .width(24)
        .height(24)
        .onClick(() => this.goToSearch())
      Blank()
      Text('发现音乐')
        .fontSize(ThemeUtil.getFontSize('lg'))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.getColor('textPrimary'))
      Blank()
      Image($r('app.media.logo'))
        .width(24)
        .height(24)
        .onClick(() => this.switchToUser())
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  @Builder
  private buildBanner() {
    if (this.banners.length > 0) {
      Swiper() {
        ForEach(this.banners, (banner: Banner) => {
          Image(banner.bannerUrl)
            .width('100%')
            .height(150)
            .borderRadius(ThemeUtil.getBorderRadius('lg'))
            .objectFit(ImageFit.Contain)
            .margin({ left: ThemeUtil.getSpacing('sm'), right: ThemeUtil.getSpacing('sm') })
        }, (banner: Banner) => banner.bannerId.toString())
      }
      .width('100%')
      .height(150)
      .autoPlay(true)
      .loop(true)
      .interval(4000)
      .indicator(true)
      .margin({ bottom: ThemeUtil.getSpacing('md') })
    }
  }

  @Builder
  private buildRecommendedPlaylists() {
    Column() {
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
            .onClick(() => this.goToAllPlaylists())
        }
        .width('100%')
        .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg'), bottom: ThemeUtil.getSpacing('sm') })

        // 固定两行三列，共 6 个
        Row({ space: 10 }) {
          ForEach(this.getPlaylistRow(0), (playlist: RecommendedPlaylist) => {
            this.buildPlaylistCard(playlist)
          }, (playlist: RecommendedPlaylist) => playlist.playlistId.toString())
        }
        .width('100%')
        .padding({ left: 12, right: 12 })

        Row({ space: 10 }) {
          ForEach(this.getPlaylistRow(1), (playlist: RecommendedPlaylist) => {
            this.buildPlaylistCard(playlist)
          }, (playlist: RecommendedPlaylist) => playlist.playlistId.toString())
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
        .margin({ top: 12 })
      }
      .width('100%')
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderRadius(16)
      .padding({ top: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .margin({ bottom: 12 })
  }

  /**
   * 歌单行数据：第 0 行前 3 个，第 1 行后 3 个
   */
  private getPlaylistRow(rowIndex: number): RecommendedPlaylist[] {
    if (rowIndex === 0) {
      return this.recommendedPlaylists.slice(0, 3);
    }
    return this.recommendedPlaylists.slice(3, 6);
  }

  @Builder
  private buildPlaylistCard(playlist: RecommendedPlaylist) {
    Column() {
      Image(playlist.coverUrl ? playlist.coverUrl : $r('app.media.default_cover'))
        .width('100%')
        .aspectRatio(1)
        .borderRadius(ThemeUtil.getBorderRadius('md'))
        .objectFit(ImageFit.Cover)
        .backgroundColor(ThemeUtil.getColor('background'))

      Text(playlist.title)
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .height(24)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .onClick(() => this.goToPlaylistDetail(playlist))
  }

  @Builder
  private buildGuessYouLike() {
    Column() {
      Column() {
        Row() {
          Text('猜你喜欢')
            .fontSize(ThemeUtil.getFontSize('lg'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
          Blank()
          Text('换一批')
            .fontSize(ThemeUtil.getFontSize('xs'))
            .fontColor(ThemeUtil.getColor('primary'))
            .onClick(() => this.refreshGuessYouLike())
        }
        .width('100%')
        .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg'), bottom: ThemeUtil.getSpacing('sm') })

        // 一行一首，播放键在右侧
        ForEach(this.recommendedSongs, (song: Song, index: number) => {
          SongRow({
            song: song,
            index: index,
            showLike: true,
            onPlay: (item: Song, itemIndex: number) => this.playSong(item, itemIndex),
            onLike: (item: Song) => this.toggleLike(item)
          })
        }, (song: Song) => song.songId.toString())
      }
      .width('100%')
      .backgroundColor(ThemeUtil.getColor('surface'))
      .borderRadius(16)
      .padding({ top: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('md') })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
  }

  private async refreshGuessYouLike(): Promise<void> {
    try {
      const songResult = await ApiService.getRecommendedSongs();
      if (songResult.code === 0 && songResult.data) {
        this.recommendedSongs = songResult.data.slice(0, 10);
      }
    } catch (error) {
      console.error('刷新猜你喜欢失败:', error);
    }
  }

  private toggleLike(song: Song): void {
    if (!this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    if (song.likeStatus === 1) {
      ApiService.cancelCollectSong(song.songId).then((result) => {
        if (result.code === 0) {
          song.likeStatus = 0;
          this.audioManager.setLikeStatus(song.songId, 0);
        }
      });
    } else {
      ApiService.collectSong(song.songId).then((result) => {
        if (result.code === 0) {
          song.likeStatus = 1;
          this.audioManager.setLikeStatus(song.songId, 1);
        }
      });
    }
  }
}
