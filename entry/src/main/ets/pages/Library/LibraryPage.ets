/**
 * 全部音乐：搜索图标+收缩搜索框 + 榜单入口 + 歌手/地区筛选 + 歌曲列表
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil, ThemeType } from '../../utils/ThemeUtil';
import { ArtistQuery, Song, SongQuery, TrackModel } from '../../types/common';
import { SongRow } from '../../components/SongRow';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';
import { TabManager } from '../../utils/TabManager';

interface FilterOption {
  label: string;
  value: string;
}

@Component
export struct LibraryPage {
  @StorageLink('themeVersion') themeVersion: number = 0;
  @State songs: Song[] = [];
  @State searchKeyword: string = '';
  @State searchFocused: boolean = false;
  @State isLoading: boolean = true;
  @State loadingMore: boolean = false;
  @State total: number = 0;
  @State themeRefresh: number = 0;
  @State genderFilter: string = '-1';
  @State areaFilter: string = '-1';

  private currentPage: number = 1;
  private readonly pageSize: number = 20;
  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private genderOptions: FilterOption[] = [
    { label: '全部', value: '-1' },
    { label: '男歌手', value: '0' },
    { label: '女歌手', value: '1' },
    { label: '组合/乐队', value: '2' }
  ];
  private areaOptions: FilterOption[] = [
    { label: '全部', value: '-1' },
    { label: '中国', value: '中国' },
    { label: '美国', value: '美国' },
    { label: '韩国', value: '韩国' },
    { label: '日本', value: '日本' },
    { label: '其他', value: '其他' }
  ];
  private themeListener: (theme: ThemeType) => void = (theme: ThemeType) => {
    this.themeRefresh++;
  };

  aboutToAppear(): void {
    this.loadSongs(true);
    ThemeUtil.addThemeChangeListener(this.themeListener);
  }

  aboutToDisappear(): void {
    ThemeUtil.removeThemeChangeListener(this.themeListener);
  }

  private buildQuery(pageNum: number, bySongName: boolean): SongQuery {
    const query: SongQuery = {
      pageNum: pageNum,
      pageSize: this.pageSize,
      songName: bySongName && this.searchKeyword ? this.searchKeyword : undefined,
      artistName: !bySongName && this.searchKeyword ? this.searchKeyword : undefined,
      album: undefined
    };
    return query;
  }

  /**
   * 无筛选：按歌名 + 歌手名合并查询（支持搜索歌手及其音乐）
   */
  private async loadSongs(reset: boolean): Promise<void> {
    if (reset) {
      this.isLoading = true;
      this.currentPage = 1;
    } else {
      this.loadingMore = true;
    }
    try {
      const songResult = await ApiService.getAllSongs(this.buildQuery(this.currentPage, true));
      const artistResult = await ApiService.getAllSongs(this.buildQuery(this.currentPage, false));
      const merged: Song[] = [];
      const push = (list: Song[] | undefined) => {
        if (!list) {
          return;
        }
        list.forEach((song: Song) => {
          if (!merged.some((item: Song) => item.songId === song.songId)) {
            merged.push(song);
          }
        });
      };
      push(songResult.code === 0 && songResult.data ? songResult.data.items : undefined);
      push(artistResult.code === 0 && artistResult.data ? artistResult.data.items : undefined);

      if (reset) {
        this.songs = merged.slice(0, this.pageSize);
      } else {
        const all = this.songs.concat(merged);
        const unique: Song[] = [];
        all.forEach((song: Song) => {
          if (!unique.some((item: Song) => item.songId === song.songId)) {
            unique.push(song);
          }
        });
        this.songs = unique;
      }
      this.total = merged.length;
      if (merged.length === this.pageSize) {
        this.currentPage++;
      }
    } catch (error) {
      console.error('加载歌曲列表失败:', error);
    } finally {
      this.isLoading = false;
      this.loadingMore = false;
    }
  }

  /**
   * 歌手类型/地区筛选：先查对应歌手，再合并查询其歌曲
   */
  private async loadFilteredSongs(): Promise<void> {
    this.isLoading = true;
    this.songs = [];
    this.total = 0;
    try {
      const artistQuery: ArtistQuery = {
        pageNum: 1,
        pageSize: 5,
        name: undefined,
        gender: this.genderFilter === '-1' ? undefined : Number(this.genderFilter),
        area: this.areaFilter === '-1' ? undefined : this.areaFilter
      };
      const artistResult = await ApiService.getAllArtists(artistQuery);
      const merged: Song[] = [];
      if (artistResult.code === 0 && artistResult.data && artistResult.data.items) {
        const artists = artistResult.data.items;
        for (let i = 0; i < artists.length; i++) {
          const songQuery: SongQuery = {
            pageNum: 1,
            pageSize: 20,
            songName: undefined,
            artistName: artists[i].artistName,
            album: undefined
          };
          const songResult = await ApiService.getAllSongs(songQuery);
          if (songResult.code === 0 && songResult.data && songResult.data.items) {
            songResult.data.items.forEach((song: Song) => {
              if (!merged.some((item: Song) => item.songId === song.songId)) {
                merged.push(song);
              }
            });
          }
        }
      }
      this.songs = merged;
      this.total = merged.length;
    } catch (error) {
      console.error('筛选歌曲失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private onSearch(): void {
    if (this.hasFilter()) {
      this.loadFilteredSongs();
    } else {
      this.loadSongs(true);
    }
  }

  private onFilterChange(): void {
    if (this.hasFilter()) {
      this.loadFilteredSongs();
    } else {
      this.loadSongs(true);
    }
  }

  private hasFilter(): boolean {
    return this.genderFilter !== '-1' || this.areaFilter !== '-1';
  }

  private onReachEnd(): void {
    if (this.hasFilter()) {
      return;
    }
    if (!this.isLoading && !this.loadingMore && this.songs.length < this.total) {
      this.loadSongs(false);
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
    if (!this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    if (song.likeStatus === 1) {
      ApiService.cancelCollectSong(song.songId).then((result) => {
        if (result.code === 0) {
          song.likeStatus = 0;
          this.refreshSongs();
        }
      });
    } else {
      ApiService.collectSong(song.songId).then((result) => {
        if (result.code === 0) {
          song.likeStatus = 1;
          this.refreshSongs();
        }
      });
    }
  }

  private refreshSongs(): void {
    const snapshot = this.songs.slice();
    this.songs = [];
    this.songs = snapshot;
  }

  private goToRank(rankType: string): void {
    NavUtil.push('pages/Rank/RankPage', { rankType: rankType });
  }

  private getAvatar(): string | Resource {
    const userInfo = this.globalData.getUserInfo();
    if (userInfo && (userInfo.avatarUrl || userInfo.userAvatar)) {
      return userInfo.avatarUrl || userInfo.userAvatar;
    }
    return $r('app.media.default_avatar');
  }

  build() {
    Column() {
      // 标题栏：左侧搜索图标 + 收缩搜索框 + 右侧用户头像
      Row() {
        Image($r('app.media.search'))
          .width(22)
          .height(22)
          .margin({ right: ThemeUtil.getSpacing('sm') })
          .onClick(() => {
            this.searchFocused = true;
          })
        TextInput({ placeholder: '搜索歌曲、歌手', text: this.searchKeyword })
          .width(this.searchFocused ? '68%' : 110)
          .height(36)
          .backgroundColor(ThemeUtil.getColor('surface'))
          .borderRadius(18)
          .fontSize(ThemeUtil.getFontSize('sm'))
          .padding({ left: 14, right: 14 })
          .onFocus(() => {
            this.searchFocused = true;
          })
          .onBlur(() => {
            this.searchFocused = false;
          })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit(() => this.onSearch())

        if (this.searchKeyword.length > 0) {
          Image($r('app.media.clear'))
            .width(18)
            .height(18)
            .margin({ left: 6 })
            .onClick(() => {
              this.searchKeyword = '';
              this.onSearch();
            })
        }

        Blank()

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

      // 榜单入口
      Row() {
        this.buildRankCard('热门榜单', '今日热播', 'hot')
        this.buildRankCard('新歌榜单', '最新发布', 'new')
      }
      .width('100%')
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: 8, bottom: 4 })

      // 分类筛选（标签左对齐）
      this.buildFilterRow('歌手类型', this.genderOptions, 'gender', (value: string) => {
        this.genderFilter = value;
        this.onFilterChange();
      })
      this.buildFilterRow('地区类型', this.areaOptions, 'area', (value: string) => {
        this.areaFilter = value;
        this.onFilterChange();
      })

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.songs.length === 0) {
        EmptyView({ message: '暂无歌曲', subMessage: '换个筛选条件试试吧' })
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
        .onReachEnd(() => this.onReachEnd())
        .padding({ bottom: 8 })

        if (this.loadingMore) {
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
        }
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
  private buildRankCard(title: string, desc: string, rankType: string) {
    Column() {
      Text(title)
        .fontSize(ThemeUtil.getFontSize('md'))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .width('100%')
        .textAlign(TextAlign.Start)
      Text(desc)
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(64)
    .padding(ThemeUtil.getSpacing('md'))
    .backgroundColor(ThemeUtil.getColor('surface'))
    .borderRadius(ThemeUtil.getBorderRadius('lg'))
    .shadow({ radius: 6, color: 'rgba(0, 0, 0, 0.06)', offsetY: 2 })
    .margin({ right: ThemeUtil.getSpacing('md') })
    .onClick(() => this.goToRank(rankType))
  }

  @Builder
  private buildFilterRow(title: string, options: FilterOption[], filterType: string, onSelect: (value: string) => void) {
    Column() {
      Text(title)
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: ThemeUtil.getSpacing('md') })
        .margin({ top: 6, bottom: 4 })
      Scroll() {
        Row() {
          ForEach(options, (option: FilterOption) => {
            Text(option.label)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(filterType === 'gender' ?
                (this.genderFilter === option.value ? ThemeUtil.getColor('onPrimary') : ThemeUtil.getColor('textSecondary')) :
                (this.areaFilter === option.value ? ThemeUtil.getColor('onPrimary') : ThemeUtil.getColor('textSecondary')))
              .backgroundColor(filterType === 'gender' ?
                (this.genderFilter === option.value ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('surface')) :
                (this.areaFilter === option.value ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('surface')))
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: 6, bottom: 6 })
              .borderRadius(ThemeUtil.getBorderRadius('full'))
              .margin({ right: ThemeUtil.getSpacing('sm') })
              .onClick(() => onSelect(option.value))
          }, (option: FilterOption) => option.value)
        }
        .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      }
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 4 })
  }
}
