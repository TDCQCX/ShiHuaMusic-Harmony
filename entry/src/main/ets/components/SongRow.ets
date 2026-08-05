/**
 * 歌曲行组件（封面/歌名/歌手/时长/喜欢/播放）
 */
import { ThemeUtil } from '../utils/ThemeUtil';
import { FormatUtil } from '../utils/FormatUtil';
import { Song } from '../types/common';

@Component
export struct SongRow {
  song: Song = {
    songId: 0,
    songName: '',
    artistName: '',
    album: '',
    duration: '0',
    coverUrl: '',
    audioUrl: '',
    likeStatus: 0,
    releaseTime: ''
  };
  index: number = 0;
  showCover: boolean = true;
  showLike: boolean = true;
  onPlay?: (song: Song, index: number) => void;
  onLike?: (song: Song) => void;

  build() {
    Row() {
      if (this.showCover) {
        Image(this.song.coverUrl ? this.song.coverUrl : $r('app.media.default_cover'))
          .width(44)
          .height(44)
          .borderRadius(ThemeUtil.getBorderRadius('sm'))
          .backgroundColor(ThemeUtil.getColor('surface'))
          .objectFit(ImageFit.Cover)
          .margin({ right: ThemeUtil.getSpacing('md') })
      } else {
        Text((this.index + 1).toString())
          .fontSize(ThemeUtil.getFontSize('sm'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .width(30)
          .textAlign(TextAlign.Center)
          .margin({ right: ThemeUtil.getSpacing('md') })
      }

      Column() {
        Text(this.song.songName)
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.song.album ? this.song.artistName + ' · ' + this.song.album : this.song.artistName)
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('textHint'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.showLike) {
        SymbolGlyph($r('sys.symbol.heart'))
          .fontSize(22)
          .fontColor([this.song.likeStatus === 1 ? '#E53935' : ThemeUtil.getColor('textHint')])
          .margin({ right: ThemeUtil.getSpacing('md') })
          .onClick(() => {
            if (this.onLike) {
              this.onLike(this.song);
            }
          })
      }

      Text(FormatUtil.formatDuration(Number(this.song.duration)))
        .fontSize(ThemeUtil.getFontSize('xs'))
        .fontColor(ThemeUtil.getColor('textHint'))
        .margin({ right: ThemeUtil.getSpacing('md') })

      Image($r('app.media.play'))
        .width(22)
        .height(22)
        .opacity(0.85)
        .onClick(() => {
          if (this.onPlay) {
            this.onPlay(this.song, this.index);
          }
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
    .onClick(() => {
      if (this.onPlay) {
        this.onPlay(this.song, this.index);
      }
    })
  }
}
