// 底部播放器组件 - 移植自微信小程序components/player/player.js
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { SongInfo, PlayerState, PlayMode } from '../../types/common';
import { ThemeUtil } from '../../utils/ThemeUtil';

@Component
export struct BottomPlayer {
  @State private currentSong: SongInfo | null = null;
  @State private isPlaying: boolean = false;
  @State private progress: number = 0;
  @State private duration: number = 0;
  @State private playMode: PlayMode = PlayMode.SEQUENCE;
  @State private showMiniPlayer: boolean = true; // 是否显示迷你播放器

  private globalDataManager: GlobalDataManager = GlobalDataManager.getInstance();
  private audioManager = this.globalDataManager.getAudioManager();

  /**
   * 组件即将显示
   */
  aboutToAppear(): void {
    this.initializePlayer();
    this.setupEventListeners();
  }

  /**
   * 初始化播放器
   */
  private initializePlayer(): void {
    // 获取当前播放状态
    this.currentSong = this.audioManager.getCurrentSong();
    this.isPlaying = this.audioManager.isPlaying();
    this.progress = this.audioManager.getProgress();
    this.duration = this.audioManager.getDuration();
    this.playMode = this.audioManager.getPlayMode();
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 播放状态变化监听
    this.audioManager.onPlay((isPlaying: boolean) => {
      this.isPlaying = isPlaying;
    });

    // 进度更新监听
    this.audioManager.onProgress((progress: number, duration: number) => {
      this.progress = progress;
      this.duration = duration;
    });

    // 歌曲切换监听
    this.audioManager.onSongChange((song: SongInfo, index: number) => {
      this.currentSong = song;
    });

    // 播放状态变化监听
    this.audioManager.onStateChange((state: PlayerState) => {
      switch (state) {
        case PlayerState.PLAYING:
          this.isPlaying = true;
          break;
        case PlayerState.PAUSED:
        case PlayerState.STOPPED:
          this.isPlaying = false;
          break;
        case PlayerState.COMPLETED:
          // 播放完成，自动播放下一首
          this.next();
          break;
      }
    });
  }

  /**
   * 切换播放/暂停
   */
  private async togglePlayPause(): Promise<void> {
    try {
      await this.audioManager.togglePlayPause();
    } catch (error) {
      console.error('切换播放状态失败:', error);
    }
  }

  /**
   * 播放上一首
   */
  private async previous(): Promise<void> {
    try {
      await this.audioManager.previous();
    } catch (error) {
      console.error('播放上一首失败:', error);
    }
  }

  /**
   * 播放下一首
   */
  private async next(): Promise<void> {
    try {
      await this.audioManager.next();
    } catch (error) {
      console.error('播放下一首失败:', error);
    }
  }

  /**
   * 切换播放模式
   */
  private togglePlayMode(): void {
    let newMode: PlayMode;
    switch (this.playMode) {
      case PlayMode.SEQUENCE:
        newMode = PlayMode.LOOP;
        break;
      case PlayMode.LOOP:
        newMode = PlayMode.SINGLE;
        break;
      case PlayMode.SINGLE:
        newMode = PlayMode.RANDOM;
        break;
      case PlayMode.RANDOM:
        newMode = PlayMode.SEQUENCE;
        break;
    }
    
    this.audioManager.setPlayMode(newMode);
    this.playMode = newMode;
  }

  /**
   * 获取播放模式图标
   */
  private getPlayModeIcon(): string | Resource {
    switch (this.playMode) {
      case PlayMode.SEQUENCE:
        return $r('app.media.顺序播放');
      case PlayMode.LOOP:
        return $r('app.media.列表循环');
      case PlayMode.SINGLE:
        return $r('app.media.单曲循环');
      case PlayMode.RANDOM:
        return $r('app.media.random');
      default:
        return $r('app.media.顺序播放');
    }
  }

  /**
   * 获取播放模式文本
   */
  private getPlayModeText(): string {
    switch (this.playMode) {
      case PlayMode.SEQUENCE:
        return '顺序播放';
      case PlayMode.LOOP:
        return '列表循环';
      case PlayMode.SINGLE:
        return '单曲循环';
      case PlayMode.RANDOM:
        return '随机播放';
      default:
        return '顺序播放';
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(time: number): string {
    if (!time || time < 0) return '00:00';
    
    const minutes = Math.floor(time / 60000);
    const seconds = Math.floor((time % 60000) / 1000);
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  /**
   * 处理进度条点击
   */
  private onProgressBarClick(event: ClickEvent): void {
    // TODO: 实现进度条拖拽功能
    console.log('进度条点击:', event.x);
  }

  /**
   * 组件构建
   */
  build() {
    if (!this.showMiniPlayer) {
      return;
    }

    Column() {
      // 进度条
      if (this.duration > 0) {
        Slider({
          value: this.progress,
          min: 0,
          max: this.duration,
          step: 1000 // 1秒步长
        })
          .width('100%')
          .height(4)
          .backgroundColor(ThemeUtil.getColor('divider'))
          .selectedColor(ThemeUtil.getColor('primary'))
          .blockColor(ThemeUtil.getColor('primary'))
          .onClick((event) => this.onProgressBarClick(event))
          .enabled(false) // 暂时禁用，后续实现拖拽
      }

      Row() {
        // 歌曲信息和播放按钮
        Row() {
          // 歌曲封面
          Image(this.currentSong?.picUrl || '')
            .width(48)
            .height(48)
            .borderRadius(ThemeUtil.getBorderRadius('lg'))
            .margin({ right: ThemeUtil.getSpacing('md') })
            .backgroundColor(ThemeUtil.getColor('surface'))

          // 歌曲信息
          Column() {
            Text(this.currentSong?.name || '暂无播放')
              .fontSize(ThemeUtil.getFontSize('sm'))
              .fontColor(ThemeUtil.getColor('textPrimary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            
            Text(this.currentSong?.artists?.map(artist => artist.name).join(' / ') || '未知艺术家')
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(ThemeUtil.getColor('textHint'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .onClick(() => {
          // TODO: 跳转到播放详情页面
          console.log('跳转到播放详情页面');
        })

        // 控制按钮
        Row({ space: ThemeUtil.getSpacing('md') }) {
          // 播放模式
          Image(this.getPlayModeIcon())
            .width(20)
            .height(20)
            .onClick(() => this.togglePlayMode())
            .bindPopup(this.popupConfiguration)

          // 上一首
          Image($r('app.media.prev'))
            .width(24)
            .height(24)
            .onClick(() => this.previous())

          // 播放/暂停
          Image(this.isPlaying ? $r('app.media.pause') : $r('app.media.play'))
            .width(32)
            .height(32)
            .onClick(() => this.togglePlayPause())

          // 下一首
          Image($r('app.media.next'))
            .width(24)
            .height(24)
            .onClick(() => this.next())

          // 播放列表
          Image($r('app.media.playlist'))
            .width(20)
            .height(20)
            .onClick(() => {
              // TODO: 显示播放列表
              console.log('显示播放列表');
            })
        }
      }
      .width('100%')
      .height(80)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))
      .border({
        width: { top: 0.5 },
        color: ThemeUtil.getColor('divider')
      })
    }
    .width('100%')
    .height(100)
    .padding({ top: ThemeUtil.getSpacing('md') })
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  /**
   * 播放模式提示配置
   */
  private get popupConfiguration(): PopupConfiguration {
    return {
      primaryValue: this.getPlayModeText(),
      placement: Placement.Top,
      enableArrow: true
    };
  }
}