/**
 * 歌手详情（资料 + 歌曲列表）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { ArtistDetail, NavParams, Song, TrackModel } from '../../types/common';
import { SongRow } from '../../components/SongRow';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';

@Entry
@Component
struct ArtistDetailPage {
  @State artist: ArtistDetail | null = null;
  @State isLoading: boolean = true;

  private artistId: number = 0;
  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    const params = NavUtil.getParams() as NavParams;
    if (params && params.artistId !== undefined) {
      this.artistId = params.artistId;
    }
    this.loadDetail();
  }

  private async loadDetail(): Promise<void> {
    try {
      const result = await ApiService.getArtistDetail(this.artistId);
      if (result.code === 0 && result.data) {
        this.artist = result.data;
      }
    } catch (error) {
      console.error('加载歌手详情失败:', error);
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
    if (!this.artist) {
      return;
    }
    const tracks: TrackModel[] = [];
    this.artist.songs.forEach((item: Song) => {
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
        Text('歌手详情')
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
      } else if (!this.artist) {
        EmptyView({ message: '歌手信息加载失败' })
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            Row() {
              Image(this.artist ? this.artist.avatar : '')
                .width(90)
                .height(90)
                .borderRadius(ThemeUtil.getBorderRadius('full'))
                .objectFit(ImageFit.Cover)
                .backgroundColor(ThemeUtil.getColor('surface'))
              Column() {
                Text(this.artist ? this.artist.artistName : '')
                  .fontSize(ThemeUtil.getFontSize('xl'))
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ThemeUtil.getColor('textPrimary'))
                if (this.artist && this.artist.area.length > 0) {
                  Text('地区：' + this.artist.area)
                    .fontSize(ThemeUtil.getFontSize('sm'))
                    .fontColor(ThemeUtil.getColor('textSecondary'))
                    .margin({ top: ThemeUtil.getSpacing('xs') })
                }
                if (this.artist && this.artist.birth.length > 0) {
                  Text('生日：' + this.artist.birth)
                    .fontSize(ThemeUtil.getFontSize('sm'))
                    .fontColor(ThemeUtil.getColor('textSecondary'))
                    .margin({ top: ThemeUtil.getSpacing('xs') })
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: ThemeUtil.getSpacing('md') })
            }
            .width('100%')
            .padding(ThemeUtil.getSpacing('md'))

            if (this.artist && this.artist.introduction.length > 0) {
              Text(this.artist.introduction)
                .fontSize(ThemeUtil.getFontSize('sm'))
                .fontColor(ThemeUtil.getColor('textSecondary'))
                .maxLines(6)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('md') })
            }

            Row() {
              Text('所有歌曲')
                .fontSize(ThemeUtil.getFontSize('lg'))
                .fontWeight(FontWeight.Bold)
                .fontColor(ThemeUtil.getColor('textPrimary'))
              Blank()
            }
            .width('100%')
            .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
            .margin({ bottom: ThemeUtil.getSpacing('sm') })

            if (this.artist && this.artist.songs.length > 0) {
              ForEach(this.artist.songs, (song: Song, index: number) => {
                SongRow({
                  song: song,
                  index: index,
                  onPlay: (item: Song, itemIndex: number) => this.playSong(item, itemIndex)
                })
              }, (song: Song) => song.songId.toString())
            } else {
              EmptyView({ message: '暂无歌曲' })
                .height(200)
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
