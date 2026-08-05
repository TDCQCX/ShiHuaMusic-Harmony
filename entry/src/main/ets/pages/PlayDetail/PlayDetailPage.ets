/**
 * 全屏播放页（黑胶唱片 + 歌曲信息 + 底部固定控制区）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { FormatUtil } from '../../utils/FormatUtil';
import { PlayMode, PlayerState, SongDetail, TrackModel } from '../../types/common';
import { LoadingView } from '../../components/common/LoadingView';

@Entry
@Component
struct PlayDetailPage {
  @State currentTrack: TrackModel | null = null;
  @State isPlaying: boolean = false;
  @State progress: number = 0;
  @State duration: number = 0;
  @State playMode: PlayMode = PlayMode.ORDER;
  @State songDetail: SongDetail | null = null;
  @State rotateAngle: number = 0;
  @State likeStatus: number = 0;
  @State barHeights: number[] = [];
  @State spectrumTick: number = 0;

  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();
  private rotationTimer: number = -1;
  private spectrumTimer: number = -1;

  private playListener: (isPlaying: boolean) => void = (isPlaying: boolean) => {
    this.isPlaying = isPlaying;
    if (isPlaying) {
      this.startRotation();
      this.startSpectrum();
    } else {
      this.stopRotation();
      this.stopSpectrum();
    }
  };
  private progressListener: (currentTime: number, duration: number) => void = (currentTime: number, duration: number) => {
    this.progress = currentTime;
    this.duration = duration;
  };
  private trackListener: (track: TrackModel, index: number) => void = (track: TrackModel, index: number) => {
    this.currentTrack = track;
    this.likeStatus = track.likeStatus;
    // 每首歌生成不同的频谱基线
    this.barSeed = this.getSeed(track.id);
    this.barHeights = this.generateBars(this.barSeed);
    this.loadSongDetail(track.id);
  };
  private stateListener: (state: PlayerState) => void = (state: PlayerState) => {
    if (state === PlayerState.COMPLETED) {
      this.audioManager.next();
    }
  };

  aboutToAppear(): void {
    this.audioManager.onPlay(this.playListener);
    this.audioManager.onProgress(this.progressListener);
    this.audioManager.onTrackChange(this.trackListener);
    this.audioManager.onState(this.stateListener);
    const track = this.audioManager.getCurrentTrack();
    if (track) {
      this.currentTrack = track;
      this.likeStatus = track.likeStatus;
      this.isPlaying = this.audioManager.isPlaying();
      this.playMode = this.audioManager.getPlayMode();
      // 生成当前歌曲的频谱基线（避免进入页面时频谱为空）
      this.barSeed = this.getSeed(track.id);
      this.barHeights = this.generateBars(this.barSeed);
      // 进入时若已在播放，立即开始旋转
      if (this.isPlaying) {
        this.startRotation();
        this.startSpectrum();
      }
      this.loadSongDetail(track.id);
    }
  }

  aboutToDisappear(): void {
    this.audioManager.offPlay(this.playListener);
    this.audioManager.offProgress(this.progressListener);
    this.audioManager.offTrackChange(this.trackListener);
    this.audioManager.offState(this.stateListener);
    this.stopRotation();
    this.stopSpectrum();
  }

  @State barSeed: number = 0;

  private startRotation(): void {
    if (this.rotationTimer !== -1) {
      return;
    }
    this.rotationTimer = setInterval(() => {
      this.rotateAngle = (this.rotateAngle + 0.3) % 360;
    }, 30);
  }

  private stopRotation(): void {
    if (this.rotationTimer !== -1) {
      clearInterval(this.rotationTimer);
      this.rotationTimer = -1;
    }
  }

  /**
   * 根据歌曲 id 生成频谱种子（每首歌不同）
   */
  private getSeed(id: string): number {
    let hash: number = 0;
    for (let i = 0; i < id.length; i++) {
      hash = (hash * 31 + id.charCodeAt(i)) % 100000;
    }
    return hash > 0 ? hash : 7;
  }

  /**
   * 生成频谱基线：钟形分布（中间高、两侧低），每首歌种子不同
   */
  private generateBars(seed: number): number[] {
    const count: number = 26;
    const bars: number[] = [];
    let s: number = seed;
    for (let i = 0; i < count; i++) {
      s = (s * 9301 + 49297) % 233280;
      // 钟形形状（两端 0.25、中间 0.95）+ 每首歌的种子扰动
      const bell: number = 0.25 + 0.70 * Math.sin(Math.PI * i / (count - 1));
      const jitter: number = 0.75 + 0.50 * (s / 233280);
      bars.push(Math.max(0.12, Math.min(1, bell * jitter)));
    }
    return bars;
  }

  private startSpectrum(): void {
    if (this.spectrumTimer !== -1) {
      return;
    }
    this.spectrumTimer = setInterval(() => {
      // @State 数字驱动 build 重跑，逐条重新计算高度（绕开 ForEach 复用不更新的问题）
      this.spectrumTick++;
    }, 80);
  }

  private stopSpectrum(): void {
    if (this.spectrumTimer !== -1) {
      clearInterval(this.spectrumTimer);
      this.spectrumTimer = -1;
    }
  }

  private async loadSongDetail(id: string): Promise<void> {
    try {
      const result = await ApiService.getSongDetail(Number(id));
      if (result.code === 0 && result.data) {
        this.songDetail = result.data;
      }
    } catch (error) {
      console.error('加载歌曲详情失败:', error);
    }
  }

  private onSliderChange(value: number, mode: SliderChangeMode): void {
    if (mode === SliderChangeMode.Moving) {
      this.progress = value;
    } else if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
      this.audioManager.seekTo(value);
    }
  }

  private togglePlayMode(): void {
    let newMode: PlayMode = PlayMode.ORDER;
    switch (this.playMode) {
      case PlayMode.ORDER:
        newMode = PlayMode.SHUFFLE;
        break;
      case PlayMode.SHUFFLE:
        newMode = PlayMode.LOOP;
        break;
      case PlayMode.LOOP:
        newMode = PlayMode.SINGLE;
        break;
      case PlayMode.SINGLE:
        newMode = PlayMode.ORDER;
        break;
      default:
        newMode = PlayMode.ORDER;
        break;
    }
    this.playMode = newMode;
    this.audioManager.setPlayMode(newMode);
  }

  private getPlayModeIcon(): Resource {
    switch (this.playMode) {
      case PlayMode.SHUFFLE:
        return $r('sys.symbol.shuffle');
      case PlayMode.LOOP:
        return $r('sys.symbol.repeat');
      case PlayMode.SINGLE:
        return $r('sys.symbol.repeat_1');
      case PlayMode.ORDER:
      default:
        return $r('sys.symbol.line_3_horizontal');
    }
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

  private goToComments(): void {
    if (this.currentTrack) {
      NavUtil.push('pages/PlayDetail/SongCommentPage', { songId: Number(this.currentTrack.id) });
    }
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
      // 顶部：返回 + 居中歌名
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => NavUtil.back())
        Blank()
        Text(this.currentTrack ? this.currentTrack.title : '')
          .fontSize(ThemeUtil.getFontSize('md'))
          .fontColor(ThemeUtil.getColor('textPrimary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Text('')
          .width(24)
      }
      .width('100%')
      .height(52)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })

      if (!this.currentTrack) {
        LoadingView()
          .layoutWeight(1)
      } else {
        // 中间内容区（固定，不滚动）
        Column() {
          Stack() {
            Circle()
              .width(220)
              .height(220)
              .fill(ThemeUtil.getColor('surface'))
              .stroke(ThemeUtil.getColor('textHint'))
              .strokeWidth(3)
            Circle()
              .width(14)
              .height(14)
              .fill(ThemeUtil.getColor('primary'))
            Image(this.currentTrack ? this.currentTrack.cover : '')
              .width(172)
              .height(172)
              .borderRadius(ThemeUtil.getBorderRadius('full'))
              .objectFit(ImageFit.Cover)
              .backgroundColor(ThemeUtil.getColor('background'))
          }
          .rotate({ angle: this.rotateAngle })
          .animation({ duration: 30, curve: Curve.Linear })
          .width('100%')
          .alignContent(Alignment.Center)
          .margin({ top: 32, bottom: 16 })

          Text(this.currentTrack ? this.currentTrack.title : '')
            .fontSize(ThemeUtil.getFontSize('xl'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.getColor('textPrimary'))
          Text(this.currentTrack ? this.currentTrack.artist : '')
            .fontSize(ThemeUtil.getFontSize('md'))
            .fontColor(ThemeUtil.getColor('textSecondary'))
            .margin({ top: ThemeUtil.getSpacing('xs') })

          if (this.songDetail) {
            Column() {
              Text('专辑：' + this.songDetail.album)
                .fontSize(ThemeUtil.getFontSize('sm'))
                .fontColor(ThemeUtil.getColor('textSecondary'))
              Text('发行时间：' + this.songDetail.releaseTime)
                .fontSize(ThemeUtil.getFontSize('sm'))
                .fontColor(ThemeUtil.getColor('textSecondary'))
                .margin({ top: 4 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ top: ThemeUtil.getSpacing('sm') })
          }

          // 查看评论：跳转独立评论页（进度条上方、右侧）
          Row() {
            Blank()
            Text('查看评论')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('primary'))
              .onClick(() => this.goToComments())
          }
          .width('100%')
          .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })
          .margin({ top: ThemeUtil.getSpacing('sm') })

          // 动态频谱：位于进度条上方，底部对齐向上长，铺满与进度条行同宽
          Column() {
            Row() {
              this.buildBar(0)
              this.buildBar(1)
              this.buildBar(2)
              this.buildBar(3)
              this.buildBar(4)
              this.buildBar(5)
              this.buildBar(6)
              this.buildBar(7)
              this.buildBar(8)
              this.buildBar(9)
              this.buildBar(10)
              this.buildBar(11)
              this.buildBar(12)
              this.buildBar(13)
              this.buildBar(14)
              this.buildBar(15)
              this.buildBar(16)
              this.buildBar(17)
              this.buildBar(18)
              this.buildBar(19)
              this.buildBar(20)
              this.buildBar(21)
              this.buildBar(22)
              this.buildBar(23)
              this.buildBar(24)
              this.buildBar(25)
            }
            .alignItems(VerticalAlign.Bottom)
            .width('100%')
            .height(56)
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }

        .layoutWeight(1)
        .width('100%')

        // 底部固定：进度条 + 控制区
        Column() {
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
              .selectedColor(ThemeUtil.getColor('primary'))
              .blockColor(ThemeUtil.getColor('primary'))
              .trackColor(ThemeUtil.getColor('divider'))
              .onChange((value: number, mode: SliderChangeMode) => this.onSliderChange(value, mode))
              .margin({ left: 4, right: 4 })
            Text(FormatUtil.formatTime(this.duration))
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('textHint'))
              .width(40)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: ThemeUtil.getSpacing('lg'), right: ThemeUtil.getSpacing('lg') })

          Row({ space: 32 }) {
            SymbolGlyph(this.getPlayModeIcon())
              .fontSize(26)
              .fontColor([ThemeUtil.getColor('primary')])
              .onClick(() => this.togglePlayMode())
            SymbolGlyph($r('sys.symbol.backward_fill'))
              .fontSize(32)
              .fontColor([ThemeUtil.getColor('textPrimary')])
              .onClick(() => this.audioManager.previous())
            SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_circle_fill') : $r('sys.symbol.play_circle_fill'))
              .fontSize(56)
              .fontColor([ThemeUtil.getColor('primary')])
              .onClick(() => this.audioManager.togglePlayPause())
            SymbolGlyph($r('sys.symbol.fast_forward'))
              .fontSize(32)
              .fontColor([ThemeUtil.getColor('textPrimary')])
              .onClick(() => this.audioManager.next())
            SymbolGlyph(this.likeStatus === 1 ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
              .fontSize(30)
              .fontColor([this.likeStatus === 1 ? '#E53935' : ThemeUtil.getColor('textHint')])
              .onClick(() => this.toggleLike())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: ThemeUtil.getSpacing('md'), bottom: 24 })
        }
        .width('100%')
        .backgroundColor(ThemeUtil.getColor('background'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 频谱条透明度：两侧向中间渐变（中间亮、两侧淡）
   */
  private getBarOpacity(index: number): number {
    const count: number = Math.max(1, this.barHeights.length);
    const center: number = (count - 1) / 2;
    const dist: number = Math.abs(index - center) / center;
    return 0.95 - 0.55 * dist;
  }

  /**
   * 频谱条当前高度：基线 × 随 tick 波动的系数（播放时跳动，暂停时静止）
   */
  private getBarHeight(index: number): number {
    const base: number = index < this.barHeights.length ? this.barHeights[index] : 0.2;
    const wave: number = 0.6 + 0.4 * Math.abs(Math.sin(this.spectrumTick * 0.1 + index * 1.5 + this.barSeed * 0.01));
    return 56 * Math.max(0.1, Math.min(1, base * wave));
  }

  @Builder
  private buildBar(index: number) {
    Column()
      .width(4)
      .height(this.getBarHeight(index))
      .borderRadius(2)
      .backgroundColor(ThemeUtil.getColor('primary'))
      .opacity(this.getBarOpacity(index))
  }
}
