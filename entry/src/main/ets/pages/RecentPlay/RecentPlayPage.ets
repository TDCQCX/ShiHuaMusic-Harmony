/**
 * 最近播放（本地历史）
 */
import { NavUtil } from '../../utils/NavUtil';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { TrackModel } from '../../types/common';
import { EmptyView } from '../../components/common/EmptyView';

@Entry
@Component
struct RecentPlayPage {
  @State recentSongs: TrackModel[] = [];

  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    this.recentSongs = this.globalData.getRecentPlayHistory();
  }

  private playSong(track: TrackModel, index: number): void {
    const tracks = this.recentSongs.slice();
    this.audioManager.setTrackList(tracks, index);
    this.audioManager.play(index);
  }

  private removeSong(track: TrackModel): void {
    this.globalData.removeRecentPlay(track.id);
    this.recentSongs = this.globalData.getRecentPlayHistory();
  }

  private clearHistory(): void {
    this.getUIContext().showAlertDialog({
      title: '清空历史',
      message: '确定要清空所有播放记录吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: ThemeUtil.getColor('error'),
        action: () => {
          this.globalData.clearRecentPlay();
          this.recentSongs = [];
        }
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
        Text('最近播放')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        if (this.recentSongs.length > 0) {
          Text('清空')
            .fontSize(ThemeUtil.getFontSize('sm'))
            .fontColor(ThemeUtil.getColor('error'))
            .onClick(() => this.clearHistory())
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      if (this.recentSongs.length === 0) {
        EmptyView({ message: '暂无播放记录', subMessage: '开始听歌，记录你的音乐历程' })
          .layoutWeight(1)
      } else {
        List() {
          ForEach(this.recentSongs, (track: TrackModel, index: number) => {
            ListItem() {
              Row() {
                Image(track.cover ? track.cover : $r('app.media.default_cover'))
                  .width(44)
                  .height(44)
                  .borderRadius(ThemeUtil.getBorderRadius('sm'))
                  .objectFit(ImageFit.Cover)
                  .margin({ right: ThemeUtil.getSpacing('md') })
                Column() {
                  Text(track.title)
                    .fontSize(ThemeUtil.getFontSize('md'))
                    .fontColor(ThemeUtil.getColor('textPrimary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(track.artist)
                    .fontSize(ThemeUtil.getFontSize('xs'))
                    .fontColor(ThemeUtil.getColor('textHint'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Image($r('app.media.play'))
                  .width(22)
                  .height(22)
                  .onClick(() => this.playSong(track, index))
                Image($r('app.media.more'))
                  .width(20)
                  .height(20)
                  .margin({ left: ThemeUtil.getSpacing('md') })
                  .onClick(() => this.removeSong(track))
              }
              .width('100%')
              .height(64)
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
              .onClick(() => this.playSong(track, index))
            }
            .margin({ bottom: 1 })
          }, (track: TrackModel) => track.id)
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
