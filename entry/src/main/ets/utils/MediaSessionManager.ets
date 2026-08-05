/**
 * 媒体会话管理（avSession）：通知栏/锁屏媒体控制、后台播放
 */
import { avSession } from '@kit.AVSessionKit';
import { AppContext } from './AppContext';
import { PlayMode, PlayerState, TrackModel } from '../types/common';

export class MediaSessionManager {
  private static instance: MediaSessionManager | null = null;
  private session: avSession.AVSession | null = null;
  private currentTrack: TrackModel | null = null;
  private currentState: PlayerState = PlayerState.STOPPED;
  private currentMode: PlayMode = PlayMode.ORDER;

  // 命令回调（由 AudioManager 注册）
  onPlayCommand: (() => void) | null = null;
  onPauseCommand: (() => void) | null = null;
  onNextCommand: (() => void) | null = null;
  onPreviousCommand: (() => void) | null = null;

  private constructor() {
  }

  static getInstance(): MediaSessionManager {
    if (MediaSessionManager.instance === null) {
      MediaSessionManager.instance = new MediaSessionManager();
    }
    return MediaSessionManager.instance;
  }

  /**
   * 创建媒体会话（幂等）
   */
  async createSession(): Promise<void> {
    if (this.session !== null) {
      return;
    }
    const context = AppContext.getContext();
    if (context === null) {
      return;
    }
    try {
      const session = await avSession.createAVSession(context, 'ShiHuaMusic', 'audio');
      this.session = session;
      session.on('play', () => {
        if (this.onPlayCommand) {
          this.onPlayCommand();
        }
      });
      session.on('pause', () => {
        if (this.onPauseCommand) {
          this.onPauseCommand();
        }
      });
      session.on('playNext', () => {
        if (this.onNextCommand) {
          this.onNextCommand();
        }
      });
      session.on('playPrevious', () => {
        if (this.onPreviousCommand) {
          this.onPreviousCommand();
        }
      });
      await session.activate();
    } catch (error) {
      console.error('创建媒体会话失败:', JSON.stringify(error));
    }
  }

  /**
   * 更新媒体信息与播放状态（AudioManager 播放/切歌时调用）
   */
  async updateSession(track: TrackModel, state: PlayerState, mode: PlayMode): Promise<void> {
    await this.createSession();
    if (this.session === null) {
      return;
    }
    this.currentTrack = track;
    this.currentState = state;
    this.currentMode = mode;
    try {
      const metadata: avSession.AVMetadata = {
        assetId: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: track.duration
      };
      await this.session.setAVMetadata(metadata);
      await this.updatePlaybackState();
    } catch (error) {
      console.error('更新媒体会话失败:', JSON.stringify(error));
    }
  }

  /**
   * 仅更新播放状态（暂停/继续/进度时调用）
   */
  async updateState(state: PlayerState, positionMs: number = 0): Promise<void> {
    if (this.session === null) {
      return;
    }
    this.currentState = state;
    try {
      const playbackState: avSession.AVPlaybackState = {
        state: MediaSessionManager.mapState(state),
        position: {
          elapsedTime: positionMs,
          updateTime: Date.now()
        },
        loopMode: MediaSessionManager.mapLoopMode(this.currentMode)
      };
      await this.session.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error('更新播放状态失败:', JSON.stringify(error));
    }
  }

  async release(): Promise<void> {
    if (this.session !== null) {
      try {
        await this.session.destroy();
      } catch (error) {
        console.error('释放媒体会话失败:', JSON.stringify(error));
      }
      this.session = null;
    }
  }

  private async updatePlaybackState(): Promise<void> {
    if (this.session === null) {
      return;
    }
    try {
      const playbackState: avSession.AVPlaybackState = {
        state: MediaSessionManager.mapState(this.currentState),
        loopMode: MediaSessionManager.mapLoopMode(this.currentMode)
      };
      await this.session.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error('更新播放状态失败:', JSON.stringify(error));
    }
  }

  private static mapState(state: PlayerState): avSession.PlaybackState {
    switch (state) {
      case PlayerState.PLAYING:
        return avSession.PlaybackState.PLAYBACK_STATE_PLAY;
      case PlayerState.PAUSED:
        return avSession.PlaybackState.PLAYBACK_STATE_PAUSE;
      case PlayerState.COMPLETED:
        return avSession.PlaybackState.PLAYBACK_STATE_COMPLETED;
      case PlayerState.ERROR:
        return avSession.PlaybackState.PLAYBACK_STATE_ERROR;
      case PlayerState.STOPPED:
        return avSession.PlaybackState.PLAYBACK_STATE_STOP;
      default:
        return avSession.PlaybackState.PLAYBACK_STATE_INITIAL;
    }
  }

  private static mapLoopMode(mode: PlayMode): avSession.LoopMode {
    switch (mode) {
      case PlayMode.SINGLE:
        return avSession.LoopMode.LOOP_MODE_SINGLE;
      case PlayMode.LOOP:
        return avSession.LoopMode.LOOP_MODE_LIST;
      case PlayMode.SHUFFLE:
        return avSession.LoopMode.LOOP_MODE_SHUFFLE;
      case PlayMode.ORDER:
      default:
        return avSession.LoopMode.LOOP_MODE_SEQUENCE;
    }
  }
}
