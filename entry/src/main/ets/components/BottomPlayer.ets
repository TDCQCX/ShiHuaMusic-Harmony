/**
 * 底部迷你播放器（全局常驻）
 * 同一卡片容器：上滑时卡片整体从左至右收缩为圆形（内容渐变），下滑恢复
 */
import { NavUtil } from '../utils/NavUtil';
import { ApiService } from '../api/ApiService';
import { AudioManager } from '../utils/AudioManager';
import { GlobalDataManager } from '../utils/GlobalDataManager';
import { ThemeUtil, ThemeType } from '../utils/ThemeUtil';
import { FormatUtil } from '../utils/FormatUtil';
import { PlayMode, PlayerState, TrackModel } from '../types/common';

@Component
export struct BottomPlayer {
  @StorageLink('themeVersion') themeVersion: number = 0;
  @StorageLink('playerCollapsed') isCollapsed: boolean = false;
  @State currentTrack: TrackModel | null = null;
  @State isPlaying: boolean = false;
  @State progress: number = 0;
  @State duration: number = 0;
  @State playMode: PlayMode = PlayMode.ORDER;
  @State likeStatus: number = 0;
  @State showPlaylist: boolean = false;
  @State themeRefresh: number = 0;
  @State progressRatio: number = 0;
  @State collapseAngle: number = 0;

  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private collapseTimer: number = -1;
  private themeListener: (theme: ThemeType) => void = (theme: ThemeType) => {
    this.themeRefresh++;
  };

  private playListener: (isPlaying: boolean) => void = (isPlaying: boolean) => {
    this.isPlaying = isPlaying;
    if (isPlaying) {
      this.startCollapseRotate();
    } else {
      this.stopCollapseRotate();
    }
  };
  private progressListener: (currentTime: number, duration: number) => void = (currentTime: number, duration: number) => {
    this.progress = currentTime;
    this.duration = duration;
    this.progressRatio = duration > 0 ? Math.min(1, currentTime / duration) : 0;
  };
  private trackListener: (track: TrackModel, index: number) => void = (track: TrackModel, index: number) => {
    this.currentTrack = track;
    this.likeStatus = track.likeStatus;
  };
  private stateListener: (state: PlayerState) => void = (state: PlayerState) => {
    if (state === PlayerState.COMPLETED) {
      this.audioManager.next();
    }
  };

  aboutToAppear(): void {
    ThemeUtil.addThemeChangeListener(this.themeListener);
    this.audioManager.onPlay(this.playListener);
    this.audioManager.onProgress(this.progressListener);
    this.audioManager.onTrackChange(this.trackListener);
    this.audioManager.onState(this.stateListener);
    const track = this.audioManager.getCurrentTrack();
    if (track) {
      this.currentTrack = track;
      this.likeStatus = track.likeStatus;
      this.playMode = this.audioManager.getPlayMode();
      this.isPlaying = this.audioManager.isPlaying();
      if (this.isPlaying) {
        this.startCollapseRotate();
      }
    }
  }

  aboutToDisappear(): void {
    ThemeUtil.removeThemeChangeListener(this.themeListener);
    this.audioManager.offPlay(this.playListener);
    this.audioManager.offProgress(this.progressListener);
    this.audioManager.offTrackChange(this.trackListener);
    this.audioManager.offState(this.stateListener);
    this.stopCollapseRotate();
  }

  private startCollapseRotate(): void {
    if (this.collapseTimer !== -1) {
      return;
    }
    this.collapseTimer = setInterval(() => {
      this.collapseAngle = (this.collapseAngle + 1) % 360;
    }, 40);
  }

  private stopCollapseRotate(): void {
    if (this.collapseTimer !== -1) {
      clearInterval(this.collapseTimer);
      this.collapseTimer = -1;
    }
  }

  private togglePlayPause(): void {
    this.audioManager.togglePlayPause();
  }

  private previous(): void {
    this.audioManager.previous();
  }

  private next(): void {
    this.audioManager.next();
  }

  private async toggleLike(): Promise<void> {
    const track = this.currentTrack;
    if (!track) {
      return;
    }
    if (!this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    const songId = Number(track.id);
    try {
      if (this.likeStatus === 1) {
        const result = await ApiService.cancelCollectSong(songId);
        if (result.code === 0) {
          track.likeStatus = 0;
          this.likeStatus = 0;
        }
      } else {
        const result = await ApiService.collectSong(songId);
        if (result.code === 0) {
          track.likeStatus = 1;
          this.likeStatus = 1;
        }
      }
    } catch (error) {
      console.error('收藏操作失败:', error);
    }
  }

  private onSliderChange(value: number, mode: SliderChangeMode): void {
    if (mode === SliderChangeMode.Moving) {
      this.progress = value;
    } else if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
      this.audioManager.seekTo(value);
    }
  }

  private openPlayDetail(): void {
    NavUtil.push('pages/PlayDetail/PlayDetailPage');
  }

  private playTrack(track: TrackModel, index: number): void {
    this.audioManager.play(index);
  }

  private removeTrack(track: TrackModel): void {
    this.audioManager.deleteTrack(track.id);
  }

  private clearAll(): void {
    this.audioManager.clearTrackList();
  }

  @Builder
  private buildPlaylistSheet() {
    Column() {
      Row() {
        Text('播放列表')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Text('清空')
          .fontSize(ThemeUtil.getFontSize('xs'))
          .fontColor(ThemeUtil.getColor('error'))
          .margin({ right: ThemeUtil.getSpacing('lg') })
          .onClick(() => this.clearAll())
        Image($r('app.media.close'))
          .width(22)
          .height(22)
          .onClick(() => {
            this.showPlaylist = false;
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('md') })

      List() {
        ForEach(this.audioManager.getTrackList(), (track: TrackModel, index: number) => {
          ListItem() {
            Row() {
              Image(track.cover ? track.cover : $r('app.media.default_cover'))
                .width(40)
                .height(40)
                .borderRadius(ThemeUtil.getBorderRadius('sm'))
                .objectFit(ImageFit.Cover)
                .margin({ right: ThemeUtil.getSpacing('md') })
              Column() {
                Text(track.title)
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(this.audioManager.getCurrentIndex() === index ?
                    ThemeUtil.getColor('primary') : ThemeUtil.getColor('textPrimary'))
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
              Text(FormatUtil.formatTime(track.duration))
                .fontSize(ThemeUtil.getFontSize('xs'))
                .fontColor(ThemeUtil.getColor('textHint'))
                .margin({ right: ThemeUtil.getSpacing('md') })
              Image($r('app.media.more'))
                .width(18)
                .height(18)
                .onClick(() => this.removeTrack(track))
            }
            .width('100%')
            .height(56)
            .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('md') })
            .onClick(() => this.playTrack(track, index))
          }
        }, (track: TrackModel) => track.id)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('surface'))
  }

  build() {
    // 同一卡片容器：白色卡片，收放时宽度/圆角/高度连续渐变
    Stack() {
      // 圆形内容：收起时放大淡入（与完整内容同容器过渡）
      if (this.currentTrack !== null) {
        Stack() {
          Progress({
            value: this.progressRatio * 100,
            total: 100,
            type: ProgressType.Ring
          })
            .width(72)
            .height(72)
            .color(ThemeUtil.getColor('primary'))
            .backgroundColor(ThemeUtil.getColor('divider'))
            .style({ strokeWidth: 4 })
          Image(this.currentTrack.cover ? this.currentTrack.cover : $r('app.media.default_cover'))
            .width(56)
            .height(56)
            .borderRadius(ThemeUtil.getBorderRadius('full'))
            .objectFit(ImageFit.Cover)
            .rotate({ angle: this.collapseAngle })
            .animation({ duration: 40, curve: Curve.Linear })
        }
        .width(72)
        .height(72)
        .opacity(this.isCollapsed ? 1 : 0)
        .scale({ x: this.isCollapsed ? 1 : 0.5, y: this.isCollapsed ? 1 : 0.5 })
        .animation({ duration: 320, curve: Curve.EaseInOut })
        .onClick(() => this.openPlayDetail())
      }

      // 完整内容：展开时显示，收起时缩小淡出
      Column() {
        if (this.currentTrack !== null) {
          Row() {
            Text(FormatUtil.formatTime(this.progress))
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('textHint'))
              .width(40)
            Slider({
              value: this.progress,
              min: 0,
              max: this.duration > 0 ? this.duration : 1,
              step: 1
            })
              .layoutWeight(1)
              .height(16)
              .selectedColor(ThemeUtil.getColor('primary'))
              .blockColor(ThemeUtil.getColor('primary'))
              .trackColor(ThemeUtil.getColor('divider'))
              .showSteps(false)
              .onChange((value: number, mode: SliderChangeMode) => this.onSliderChange(value, mode))
              .margin({ left: 4, right: 4 })
            Text(FormatUtil.formatTime(this.duration))
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('textHint'))
              .width(40)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: 12 })

          Row() {
            Row() {
              Image(this.currentTrack ? this.currentTrack.cover : '')
                .width(48)
                .height(48)
                .borderRadius(ThemeUtil.getBorderRadius('md'))
                .backgroundColor(ThemeUtil.getColor('background'))
                .objectFit(ImageFit.Cover)
                .margin({ right: ThemeUtil.getSpacing('sm') })
                .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.12)' })
              Column() {
                Text(this.currentTrack ? this.currentTrack.title : '未知歌曲')
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(ThemeUtil.getColor('textPrimary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.currentTrack ? this.currentTrack.artist : '未知歌手')
                  .fontSize(ThemeUtil.getFontSize('xs'))
                  .fontColor(ThemeUtil.getColor('textHint'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)
            .onClick(() => this.openPlayDetail())

            Row({ space: ThemeUtil.getSpacing('md') }) {
              SymbolGlyph($r('sys.symbol.backward_fill'))
                .fontSize(24)
                .fontColor([ThemeUtil.getColor('textPrimary')])
                .onClick(() => this.previous())

              SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_circle_fill') : $r('sys.symbol.play_circle_fill'))
                .fontSize(38)
                .fontColor([ThemeUtil.getColor('primary')])
                .onClick(() => this.togglePlayPause())

              SymbolGlyph($r('sys.symbol.fast_forward'))
                .fontSize(24)
                .fontColor([ThemeUtil.getColor('textPrimary')])
                .onClick(() => this.next())

              SymbolGlyph($r('sys.symbol.music_note_list'))
                .fontSize(22)
                .fontColor([ThemeUtil.getColor('textPrimary')])
                .onClick(() => {
                  this.showPlaylist = true;
                })

              SymbolGlyph(this.likeStatus === 1 ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
                .fontSize(24)
                .fontColor([this.likeStatus === 1 ? '#E53935' : ThemeUtil.getColor('textHint')])
                .onClick(() => this.toggleLike())
            }
          }
          .width('100%')
          .height(72)
          .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
        } else {
          Row() {
            Text('暂无播放')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('textHint'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.music_note_list'))
              .fontSize(20)
              .fontColor([ThemeUtil.getColor('textHint')])
              .onClick(() => {
                this.showPlaylist = true;
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
        }
      }
      .width('100%')
      .opacity(this.isCollapsed && this.currentTrack !== null ? 0 : 1)
      .scale({ x: this.isCollapsed && this.currentTrack !== null ? 0.5 : 1, y: this.isCollapsed && this.currentTrack !== null ? 0.5 : 1 })
      .animation({ duration: 320, curve: Curve.EaseInOut })
    }
    .alignSelf(ItemAlign.End)
    .width(this.isCollapsed && this.currentTrack !== null ? 72 : '100%')
    .height(this.isCollapsed && this.currentTrack !== null ? 72 : 'auto')
    .backgroundColor(ThemeUtil.getColor('surface'))
    .opacity(this.themeRefresh >= 0 ? 1 : 1)
    .borderRadius(this.isCollapsed ? 36 : 16)
    .shadow(this.isCollapsed ?
      { radius: 4, color: 'rgba(0, 0, 0, 0.08)' } :
      { radius: 8, color: 'rgba(0, 0, 0, 0.08)', offsetY: -2 })
    .animation({ duration: 320, curve: Curve.EaseInOut })
    .bindSheet($$this.showPlaylist, this.buildPlaylistSheet(), {
      height: 420,
      showClose: false,
      dragBar: true,
      backgroundColor: ThemeUtil.getColor('surface')
    })
  }
}
