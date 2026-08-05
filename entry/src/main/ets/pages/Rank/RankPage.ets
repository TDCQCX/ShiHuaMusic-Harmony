/**
 * 榜单页（热门榜单 / 新歌榜单）：序号 + 歌曲列表
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { NavParams, Song, TrackModel } from '../../types/common';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';

@Entry
@Component
struct RankPage {
  @State rankType: string = 'hot';
  @State title: string = '热门榜单';
  @State songs: Song[] = [];
  @State isLoading: boolean = true;

  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    const params = NavUtil.getParams() as NavParams;
    if (params && params.rankType) {
      this.rankType = params.rankType;
    }
    this.title = this.rankType === 'new' ? '新歌榜单' : '热门榜单';
    this.loadRank();
  }

  private async loadRank(): Promise<void> {
    try {
      if (this.rankType === 'new') {
        const result = await ApiService.getAllSongs({ pageNum: 1, pageSize: 20, songName: undefined, artistName: undefined, album: undefined });
        if (result.code === 0 && result.data && result.data.items) {
          this.songs = result.data.items;
        }
      } else {
        const result = await ApiService.getRecommendedSongs();
        if (result.code === 0 && result.data) {
          this.songs = result.data.slice(0, 20);
        }
      }
    } catch (error) {
      console.error('加载榜单失败:', error);
    } finally {
      this.isLoading = false;
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
        Text(this.title)
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Text('')
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.songs.length === 0) {
        EmptyView({ message: '暂无数据' })
          .layoutWeight(1)
      } else {
        List() {
          ForEach(this.songs, (song: Song, index: number) => {
            ListItem() {
              Row() {
                Text((index + 1).toString())
                  .fontSize(ThemeUtil.getFontSize('md'))
                  .fontColor(index < 3 ? '#E53935' : ThemeUtil.getColor('textHint'))
                  .fontWeight(FontWeight.Bold)
                  .width(36)
                  .textAlign(TextAlign.Center)
                Image(song.coverUrl ? song.coverUrl : $r('app.media.default_cover'))
                  .width(44)
                  .height(44)
                  .borderRadius(ThemeUtil.getBorderRadius('sm'))
                  .objectFit(ImageFit.Cover)
                  .margin({ right: ThemeUtil.getSpacing('md') })
                Column() {
                  Text(song.songName)
                    .fontSize(ThemeUtil.getFontSize('md'))
                    .fontColor(ThemeUtil.getColor('textPrimary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(song.artistName)
                    .fontSize(ThemeUtil.getFontSize('xs'))
                    .fontColor(ThemeUtil.getColor('textHint'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                SymbolGlyph($r('sys.symbol.play_fill'))
                  .fontSize(22)
                  .fontColor([ThemeUtil.getColor('primary')])
                  .onClick(() => this.playSong(song, index))
              }
              .width('100%')
              .height(64)
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
              .onClick(() => this.playSong(song, index))
            }
            .margin({ bottom: 1 })
          }, (song: Song) => song.songId.toString())
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
