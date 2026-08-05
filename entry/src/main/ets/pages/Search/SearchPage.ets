/**
 * 全局搜索（歌曲/歌手/歌单）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { StorageUtil } from '../../utils/StorageUtil';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { Artist, ArtistQuery, PlaylistQuery, RecommendedPlaylist, Song, SongQuery, TrackModel } from '../../types/common';
import { SongRow } from '../../components/SongRow';
import { BottomPlayer } from '../../components/BottomPlayer';
import { LoadingView } from '../../components/common/LoadingView';

interface HotKeyword {
  first: string;
  second: string;
}

@Entry
@Component
struct SearchPage {
  @State searchKeyword: string = '';
  @State searchHistory: string[] = [];
  @State hotKeywords: HotKeyword[] = [];
  @State showResults: boolean = false;
  @State activeTab: number = 0;
  @State songs: Song[] = [];
  @State artists: Artist[] = [];
  @State playlists: RecommendedPlaylist[] = [];
  @State isLoading: boolean = false;
  @State noResult: boolean = false;
  @State recommendSongs: Song[] = [];

  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private searchTimer: number = -1;

  aboutToAppear(): void {
    this.initHotKeywords();
    this.loadHistory();
  }

  aboutToDisappear(): void {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
      this.searchTimer = -1;
    }
  }

  private initHotKeywords(): void {
    const list: HotKeyword[] = [
      { first: '周杰伦', second: '热门' },
      { first: '薛之谦', second: '热门' },
      { first: '告白气球', second: '歌曲' },
      { first: '青花瓷', second: '经典' },
      { first: '陈奕迅', second: '热门' },
      { first: '邓紫棋', second: '热门' },
      { first: '林俊杰', second: '热门' },
      { first: '毛不易', second: '热门' }
    ];
    this.hotKeywords = list;
  }

  private async loadHistory(): Promise<void> {
    const history = await StorageUtil.getObject<string[]>('search_history', null);
    if (history) {
      this.searchHistory = history;
    }
  }

  private async saveHistory(keyword: string): Promise<void> {
    const updated = this.searchHistory.filter((item: string) => item !== keyword);
    updated.unshift(keyword);
    if (updated.length > 20) {
      updated.pop();
    }
    this.searchHistory = updated;
    await StorageUtil.putObject<string[]>('search_history', this.searchHistory);
  }

  private clearHistory(): void {
    this.searchHistory = [];
    StorageUtil.remove('search_history');
  }

  private performSearch(): void {
    const keyword = this.searchKeyword.trim();
    if (!keyword) {
      return;
    }
    this.showResults = true;
    this.saveHistory(keyword);
    this.search();
  }

  private debounceSearch(): void {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }
    this.searchTimer = setTimeout(() => {
      if (this.searchKeyword.trim()) {
        this.performSearch();
      } else {
        this.showResults = false;
      }
    }, 400);
  }

  private async search(): Promise<void> {
    this.isLoading = true;
    try {
      const keyword = this.searchKeyword.trim();
      const songQuery: SongQuery = {
        pageNum: 1,
        pageSize: 30,
        songName: keyword,
        artistName: undefined,
        album: undefined
      };
      const songResult = await ApiService.getAllSongs(songQuery);
      // 同时按歌手名查询，合并显示（支持搜索歌手及其音乐）
      const artistSongQuery: SongQuery = {
        pageNum: 1,
        pageSize: 30,
        songName: undefined,
        artistName: keyword,
        album: undefined
      };
      const artistSongResult = await ApiService.getAllSongs(artistSongQuery);
      const mergedSongs: Song[] = [];
      const merge = (list: Song[] | undefined) => {
        if (!list) {
          return;
        }
        list.forEach((song: Song) => {
          if (!mergedSongs.some((item: Song) => item.songId === song.songId)) {
            mergedSongs.push(song);
          }
        });
      };
      merge(songResult.code === 0 && songResult.data ? songResult.data.items : undefined);
      merge(artistSongResult.code === 0 && artistSongResult.data ? artistSongResult.data.items : undefined);
      this.songs = mergedSongs;

      const artistQuery: ArtistQuery = {
        pageNum: 1,
        pageSize: 20,
        name: keyword,
        gender: undefined,
        area: undefined
      };
      const artistResult = await ApiService.getAllArtists(artistQuery);
      if (artistResult.code === 0 && artistResult.data && artistResult.data.items) {
        this.artists = artistResult.data.items;
      } else {
        this.artists = [];
      }

      const playlistQuery: PlaylistQuery = {
        pageNum: 1,
        pageSize: 20,
        title: keyword,
        style: undefined
      };
      const playlistResult = await ApiService.getAllPlaylists(playlistQuery);
      if (playlistResult.code === 0 && playlistResult.data && playlistResult.data.items) {
        this.playlists = playlistResult.data.items;
      } else {
        this.playlists = [];
      }

      // 歌曲与歌手均无结果：提示并加载推荐歌曲
      this.noResult = this.songs.length === 0 && this.artists.length === 0;
      if (this.noResult) {
        await this.loadRecommendSongs();
      }
    } catch (error) {
      console.error('搜索失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private async loadRecommendSongs(): Promise<void> {
    try {
      const result = await ApiService.getRecommendedSongs();
      if (result.code === 0 && result.data) {
        this.recommendSongs = result.data.slice(0, 10);
      }
    } catch (error) {
      console.error('加载推荐歌曲失败:', error);
    }
  }

  private playRecommend(song: Song, index: number): void {
    const tracks: TrackModel[] = [];
    this.recommendSongs.forEach((item: Song) => {
      tracks.push(this.toTrackModel(item));
    });
    this.audioManager.setTrackList(tracks, index);
    this.audioManager.play(index);
    this.globalData.addRecentPlay(tracks[index]);
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

  private goToArtist(artist: Artist): void {
    NavUtil.push('pages/Artist/ArtistDetailPage', { artistId: artist.artistId });
  }

  private goToPlaylist(playlist: RecommendedPlaylist): void {
    NavUtil.push('pages/PlaylistDetail/PlaylistDetailPage', { playlistId: playlist.playlistId });
  }

  private getRankColor(rank: number): string {
    if (rank < 3) {
      return '#FF4757';
    }
    return '#999999';
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
        Row() {
          Image($r('app.media.search'))
            .width(16)
            .height(16)
            .margin({ left: 12 })
          TextInput({ placeholder: '搜索歌曲、歌手、歌单', text: this.searchKeyword })
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .fontSize(ThemeUtil.getFontSize('sm'))
            .onChange((value: string) => {
              this.searchKeyword = value;
              this.debounceSearch();
            })
            .onSubmit(() => this.performSearch())
          if (this.searchKeyword.length > 0) {
            Image($r('app.media.clear'))
              .width(16)
              .height(16)
              .margin({ right: 8 })
              .onClick(() => {
                this.searchKeyword = '';
                this.showResults = false;
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

      if (this.showResults) {
        this.buildResults()
      } else {
        this.buildRecommend()
      }

      BottomPlayer()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  @Builder
  private buildRecommend() {
    Column() {
      if (this.searchHistory.length > 0) {
        Row() {
          Text('搜索历史')
            .fontSize(ThemeUtil.getFontSize('md'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
          Blank()
          Text('清空')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('textHint'))
            .onClick(() => this.clearHistory())
        }
        .width('100%')
        .height(44)
        .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.searchHistory, (keyword: string) => {
            Text(keyword)
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('textSecondary'))
              .backgroundColor(ThemeUtil.getColor('surface'))
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: ThemeUtil.getSpacing('xs'), bottom: ThemeUtil.getSpacing('xs') })
              .borderRadius(ThemeUtil.getBorderRadius('lg'))
              .margin({ right: ThemeUtil.getSpacing('sm'), bottom: ThemeUtil.getSpacing('sm') })
              .onClick(() => {
                this.searchKeyword = keyword;
                this.performSearch();
              })
          }, (keyword: string) => keyword)
        }
        .width('100%')
        .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      }

      Row() {
        Text('热搜榜')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
      }
      .width('100%')
      .height(44)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })

      List() {
        ForEach(this.hotKeywords, (item: HotKeyword, index: number) => {
          ListItem() {
            Row() {
              Text((index + 1).toString())
                .fontSize(ThemeUtil.getFontSize('md'))
                .fontColor(this.getRankColor(index))
                .fontWeight(FontWeight.Bold)
                .width(30)
              Text(item.first)
                .fontSize(ThemeUtil.getFontSize('md'))
                .fontColor(ThemeUtil.getColor('textPrimary'))
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.second)
                .fontSize(ThemeUtil.getFontSize('xs'))
                .fontColor(ThemeUtil.getColor('textHint'))
            }
            .width('100%')
            .height(44)
            .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
          }
          .onClick(() => {
            this.searchKeyword = item.first;
            this.performSearch();
          })
        }, (item: HotKeyword, index: number) => index.toString())
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  private buildResults() {
    Column() {
      Row() {
        Text('歌曲')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(this.activeTab === 0 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textSecondary'))
          .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => this.activeTab = 0)
        Text('歌手')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(this.activeTab === 1 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textSecondary'))
          .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => this.activeTab = 1)
        Text('歌单')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(this.activeTab === 2 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textSecondary'))
          .fontWeight(this.activeTab === 2 ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => this.activeTab = 2)
      }
      .width('100%')
      .height(48)
      .backgroundColor(ThemeUtil.getColor('surface'))

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.activeTab === 0) {
        if (this.noResult) {
          Column() {
            Text('搜索不到，以下为您推荐其他歌曲')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('textSecondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('sm') })

            List() {
              ForEach(this.recommendSongs, (song: Song, index: number) => {
                ListItem() {
                  SongRow({
                    song: song,
                    index: index,
                    onPlay: (item: Song, itemIndex: number) => this.playRecommend(item, itemIndex)
                  })
                }
                .margin({ bottom: 1 })
              }, (song: Song) => song.songId.toString())
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
          }
          .layoutWeight(1)
        } else {
          List() {
            ForEach(this.songs, (song: Song, index: number) => {
              ListItem() {
                SongRow({
                  song: song,
                  index: index,
                  onPlay: (item: Song, itemIndex: number) => this.playSong(item, itemIndex)
                })
              }
              .margin({ bottom: 1 })
            }, (song: Song) => song.songId.toString())
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
        }
      } else if (this.activeTab === 1) {
        List() {
          ForEach(this.artists, (artist: Artist) => {
            ListItem() {
              Row() {
                Image(artist.avatar ? artist.avatar : $r('app.media.default_avatar'))
                  .width(50)
                  .height(50)
                  .borderRadius(ThemeUtil.getBorderRadius('full'))
                  .objectFit(ImageFit.Cover)
                  .margin({ right: ThemeUtil.getSpacing('md') })
                Text(artist.artistName)
                  .fontSize(ThemeUtil.getFontSize('md'))
                  .fontColor(ThemeUtil.getColor('textPrimary'))
                  .layoutWeight(1)
                Image($r('app.media.arrow_right'))
                  .width(16)
                  .height(16)
              }
              .width('100%')
              .height(70)
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
              .onClick(() => this.goToArtist(artist))
            }
            .margin({ bottom: 1 })
          }, (artist: Artist) => artist.artistId.toString())
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
      } else {
        List() {
          ForEach(this.playlists, (playlist: RecommendedPlaylist) => {
            ListItem() {
              Row() {
                Image(playlist.coverUrl ? playlist.coverUrl : $r('app.media.default_cover'))
                  .width(50)
                  .height(50)
                  .borderRadius(ThemeUtil.getBorderRadius('sm'))
                  .objectFit(ImageFit.Cover)
                  .margin({ right: ThemeUtil.getSpacing('md') })
                Text(playlist.title)
                  .fontSize(ThemeUtil.getFontSize('md'))
                  .fontColor(ThemeUtil.getColor('textPrimary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                Image($r('app.media.arrow_right'))
                  .width(16)
                  .height(16)
              }
              .width('100%')
              .height(70)
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
              .onClick(() => this.goToPlaylist(playlist))
            }
            .margin({ bottom: 1 })
          }, (playlist: RecommendedPlaylist) => playlist.playlistId.toString())
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
}
