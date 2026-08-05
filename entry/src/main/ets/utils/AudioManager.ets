/**
 * 音频播放引擎（单例，ArkTS 规范）
 * 基于 AVPlayer（@ohos.multimedia.media），对齐 music-client 播放行为
 */
import { media } from '@kit.MediaKit';
import { ApiService } from '../api/ApiService';
import { MediaSessionManager } from './MediaSessionManager';
import { StorageUtil } from './StorageUtil';
import { PlayMode, PlayerState, TrackModel } from '../types/common';

export type PlayStatusListener = (isPlaying: boolean) => void;
export type ProgressListener = (currentTime: number, duration: number) => void;
export type TrackChangeListener = (track: TrackModel, index: number) => void;
export type StateListener = (state: PlayerState) => void;

export class AudioManager {
  private static instance: AudioManager | null = null;
  private avPlayer: media.AVPlayer | null = null;
  private trackList: TrackModel[] = [];
  private currentIndex: number = -1;
  private playerState: PlayerState = PlayerState.STOPPED;
  private playMode: PlayMode = PlayMode.ORDER;
  private currentTime: number = 0;
  private duration: number = 0;
  private volume: number = 50;
  private quality: string = 'exhigh';
  private pendingUrl: string = '';
  private prepared: boolean = false;
  private mediaSession: MediaSessionManager = MediaSessionManager.getInstance();

  private playListeners: PlayStatusListener[] = [];
  private progressListeners: ProgressListener[] = [];
  private trackListeners: TrackChangeListener[] = [];
  private stateListeners: StateListener[] = [];

  private constructor() {
  }

  static getInstance(): AudioManager {
    if (AudioManager.instance === null) {
      AudioManager.instance = new AudioManager();
    }
    return AudioManager.instance;
  }

  /**
   * 恢复上次播放状态（应用启动时调用）
   */
  async restore(): Promise<void> {
    const volume = await StorageUtil.getNumber('audio_volume', 50);
    this.volume = Math.max(0, Math.min(100, volume));
    const quality = await StorageUtil.getString('audio_quality', 'exhigh');
    this.quality = quality;
    const mode = await StorageUtil.getNumber('audio_play_mode', PlayMode.ORDER);
    this.playMode = mode as PlayMode;
    const trackList = await StorageUtil.getObject<TrackModel[]>('audio_track_list', null);
    const currentIndex = await StorageUtil.getNumber('audio_current_index', 0);
    if (trackList && trackList.length > 0) {
      this.trackList = trackList;
      if (currentIndex >= 0 && currentIndex < trackList.length) {
        this.currentIndex = currentIndex;
      }
    }
  }

  /**
   * 创建 AVPlayer（惰性初始化）
   */
  private async ensurePlayer(): Promise<void> {
    if (this.avPlayer !== null) {
      return;
    }
    try {
      this.avPlayer = await this.createPlayer();
    } catch (error) {
      console.error('初始化播放器失败:', JSON.stringify(error));
    }
  }

  /**
   * 创建全新 AVPlayer 并绑定事件与媒体会话命令
   */
  private async createPlayer(): Promise<media.AVPlayer> {
    try {
      const player = await media.createAVPlayer();
      this.setupEvents(player);
      this.mediaSession.onPlayCommand = () => {
        this.resume();
      };
      this.mediaSession.onPauseCommand = () => {
        this.pause();
      };
      this.mediaSession.onNextCommand = () => {
        this.next();
      };
      this.mediaSession.onPreviousCommand = () => {
        this.previous();
      };
      return player;
    } catch (error) {
      console.error('创建播放器失败:', JSON.stringify(error));
      throw error as Error;
    }
  }

  private setupEvents(player: media.AVPlayer): void {
    if (player === null) {
      return;
    }
    player.on('stateChange', (state: media.AVPlayerState) => {
      if (state === 'playing') {
        this.playerState = PlayerState.PLAYING;
        this.notifyPlay(true);
        this.mediaSession.updateState(PlayerState.PLAYING, this.currentTime);
      } else if (state === 'paused') {
        this.playerState = PlayerState.PAUSED;
        this.notifyPlay(false);
        this.mediaSession.updateState(PlayerState.PAUSED, this.currentTime);
      } else if (state === 'stopped') {
        this.playerState = PlayerState.STOPPED;
        this.notifyPlay(false);
        this.mediaSession.updateState(PlayerState.STOPPED, 0);
      } else if (state === 'completed') {
        this.playerState = PlayerState.COMPLETED;
        this.notifyPlay(false);
        this.mediaSession.updateState(PlayerState.COMPLETED, this.duration);
        this.handlePlayEnd();
      } else if (state === 'error') {
        this.playerState = PlayerState.ERROR;
        this.notifyPlay(false);
      }
      this.notifyState(this.playerState);
    });
    player.on('timeUpdate', (time: number) => {
      this.currentTime = time;
      this.notifyProgress(this.currentTime, this.duration);
    });
    player.on('durationUpdate', (duration: number) => {
      this.duration = duration;
      this.notifyProgress(this.currentTime, this.duration);
    });
    player.on('error', (error: Error) => {
      console.error('播放错误:', JSON.stringify(error));
      this.playerState = PlayerState.ERROR;
      this.notifyState(this.playerState);
    });
  }

  // ========== 播放列表管理 ==========
  setTrackList(list: TrackModel[], index: number = 0): void {
    this.trackList = list;
    if (index >= 0 && index < list.length) {
      this.currentIndex = index;
    } else if (list.length > 0) {
      this.currentIndex = 0;
    } else {
      this.currentIndex = -1;
    }
    this.persistTrackList();
  }

  getTrackList(): TrackModel[] {
    return this.trackList;
  }

  addTrack(track: TrackModel): void {
    const existingIndex = this.findTrackIndex(track.id);
    if (existingIndex > -1) {
      this.currentIndex = existingIndex;
      return;
    }
    this.trackList.push(track);
    this.currentIndex = this.trackList.length - 1;
  }

  deleteTrack(id: string): void {
    const index = this.findTrackIndex(id);
    if (index > -1) {
      this.trackList.splice(index, 1);
      if (this.currentIndex > index) {
        this.currentIndex--;
      } else if (this.currentIndex === index) {
        this.currentIndex = this.trackList.length > 0 ? Math.min(index, this.trackList.length - 1) : -1;
      }
    }
    this.persistTrackList();
  }

  clearTrackList(): void {
    this.trackList = [];
    this.currentIndex = -1;
    this.stop();
    this.persistTrackList();
  }

  private findTrackIndex(id: string): number {
    return this.trackList.findIndex((track: TrackModel) => track.id === id);
  }

  private updateTrackInList(track: TrackModel): void {
    const index = this.findTrackIndex(track.id);
    if (index > -1) {
      this.trackList[index] = track;
    }
  }

  // ========== 播放控制 ==========
  async play(index?: number): Promise<void> {
    if (index !== undefined && index >= 0 && index < this.trackList.length) {
      this.currentIndex = index;
    }
    if (this.trackList.length === 0 || this.currentIndex < 0) {
      return;
    }
    const track = this.trackList[this.currentIndex];
    await this.ensurePlayer();
    if (this.avPlayer === null) {
      return;
    }
    await this.resolveTrackUrl(track);
    if (!track.url) {
      this.playerState = PlayerState.ERROR;
      this.notifyState(this.playerState);
      return;
    }
    try {
      // 参照小程序 audioManager：每次播放都重新设置音频源后再 play
      await this.switchTrack(track.url);
      await this.avPlayer.play();
      // 确认真正进入播放状态（避免状态属性滞后误判）
      await this.waitForState(this.avPlayer, 'playing', 3000);
      // 主动同步播放状态，确保 UI 立即切换（不依赖事件时序）
      this.playerState = PlayerState.PLAYING;
      this.notifyPlay(true);
      this.pendingUrl = track.url;
      this.notifyTrack(track, this.currentIndex);
      this.mediaSession.updateSession(track, PlayerState.PLAYING, this.playMode);
      this.persistTrackList();
    } catch (error) {
      console.error('播放失败:', JSON.stringify(error));
      this.playerState = PlayerState.ERROR;
      this.notifyState(this.playerState);
    }
  }

  /**
   * 切换歌曲：参照小程序 audioManager（src = 新地址; play()）
   * AVPlayer 对应：reset → setMediaSource → prepare → play
   */
  private async switchTrack(url: string): Promise<void> {
    try {
      if (this.avPlayer === null) {
        this.avPlayer = await this.createPlayer();
      } else if (this.avPlayer.state !== 'idle') {
        // reset 仅在非 idle 状态可用（idle 为刚创建状态，直接 setMediaSource）
        // reset 后回到 idle，可重新设置媒体源
        await this.avPlayer.reset();
      }
      this.prepared = false;
      const player = this.avPlayer;
      const source = media.createMediaSourceWithUrl(url);
      await player.setMediaSource(source);
      // setMediaSource 的 Promise 返回时状态可能尚未更新为 initialized，必须等待状态事件
      const initReady: boolean = await this.waitForState(player, 'initialized', 3000);
      if (!initReady) {
        throw new Error('音频源初始化超时');
      }
      await player.prepare();
      const prepared: boolean = await this.waitForState(player, 'prepared', 5000);
      if (!prepared) {
        throw new Error('音频准备超时');
      }
      this.prepared = true;
    } catch (error) {
      console.error('加载音频源失败:', JSON.stringify(error));
      throw error as Error;
    }
  }

  /**
   * 等待 AVPlayer 进入指定状态（基于 stateChange 事件）
   */
  private waitForState(player: media.AVPlayer, target: media.AVPlayerState, timeoutMs: number): Promise<boolean> {
    return new Promise((resolve: (result: boolean) => void) => {
      if (player.state === target) {
        resolve(true);
        return;
      }
      const handler = (state: media.AVPlayerState) => {
        if (state === target) {
          player.off('stateChange', handler);
          clearTimeout(timer);
          resolve(true);
        }
      };
      const timer = setTimeout(() => {
        player.off('stateChange', handler);
        resolve(false);
      }, timeoutMs);
      player.on('stateChange', handler);
    });
  }

  async pause(): Promise<void> {
    try {
      if (this.avPlayer !== null && this.playerState === PlayerState.PLAYING) {
        await this.avPlayer.pause();
        this.playerState = PlayerState.PAUSED;
        this.notifyPlay(false);
      }
    } catch (error) {
      console.error('暂停播放失败:', JSON.stringify(error));
    }
  }

  async resume(): Promise<void> {
    try {
      if (this.avPlayer !== null && this.playerState === PlayerState.PAUSED) {
        await this.avPlayer.play();
        this.playerState = PlayerState.PLAYING;
        this.notifyPlay(true);
      }
    } catch (error) {
      console.error('恢复播放失败:', JSON.stringify(error));
    }
  }

  async stop(): Promise<void> {
    if (this.avPlayer !== null) {
      try {
        if (this.avPlayer.state === 'playing' || this.avPlayer.state === 'paused' ||
          this.avPlayer.state === 'prepared' || this.avPlayer.state === 'completed') {
          await this.avPlayer.stop();
        }
        this.prepared = false;
      } catch (error) {
        console.error('停止播放失败:', JSON.stringify(error));
      }
    }
  }

  async togglePlayPause(): Promise<void> {
    if (this.playerState === PlayerState.PLAYING) {
      await this.pause();
    } else if (this.playerState === PlayerState.PAUSED) {
      await this.resume();
    } else {
      await this.play();
    }
  }

  async next(): Promise<void> {
    if (this.trackList.length === 0) {
      return;
    }
    if (this.playMode === PlayMode.SHUFFLE) {
      this.currentIndex = Math.floor(Math.random() * this.trackList.length);
    } else if (this.playMode === PlayMode.SINGLE) {
      await this.seekTo(0);
      await this.play();
      return;
    } else {
      if (this.currentIndex < this.trackList.length - 1) {
        this.currentIndex++;
      } else {
        this.currentIndex = 0;
      }
    }
    await this.play();
  }

  async previous(): Promise<void> {
    if (this.trackList.length === 0) {
      return;
    }
    if (this.playMode === PlayMode.SHUFFLE) {
      this.currentIndex = Math.floor(Math.random() * this.trackList.length);
    } else if (this.playMode === PlayMode.SINGLE) {
      await this.seekTo(0);
      await this.play();
      return;
    } else {
      if (this.currentIndex > 0) {
        this.currentIndex--;
      } else {
        this.currentIndex = this.trackList.length - 1;
      }
    }
    await this.play();
  }

  async seekTo(progress: number): Promise<void> {
    if (this.avPlayer !== null && this.prepared) {
      try {
        this.avPlayer.seek(progress);
        this.currentTime = progress;
        this.notifyProgress(this.currentTime, this.duration);
      } catch (error) {
        console.error('设置播放进度失败:', JSON.stringify(error));
      }
    }
  }

  setVolume(volume: number): void {
    const clamped = Math.max(0, Math.min(100, volume));
    this.volume = clamped;
    if (this.avPlayer !== null && this.prepared) {
      this.avPlayer.setVolume(clamped / 100);
    }
    StorageUtil.putNumber('audio_volume', clamped);
  }

  getVolume(): number {
    return this.volume;
  }

  setQuality(quality: string): void {
    this.quality = quality;
    StorageUtil.putString('audio_quality', quality);
  }

  getQuality(): string {
    return this.quality;
  }

  setPlayMode(mode: PlayMode): void {
    this.playMode = mode;
    StorageUtil.putNumber('audio_play_mode', mode);
    if (this.playerState === PlayerState.PLAYING || this.playerState === PlayerState.PAUSED) {
      this.mediaSession.updateState(this.playerState, this.currentTime);
    }
  }

  getPlayMode(): PlayMode {
    return this.playMode;
  }

  // ========== 状态读取 ==========
  getCurrentTrack(): TrackModel | null {
    if (this.currentIndex < 0 || this.currentIndex >= this.trackList.length) {
      return null;
    }
    return this.trackList[this.currentIndex];
  }

  getCurrentIndex(): number {
    return this.currentIndex;
  }

  setCurrentIndex(index: number): void {
    if (index >= 0 && index < this.trackList.length) {
      this.currentIndex = index;
    }
  }

  getPlayerState(): PlayerState {
    return this.playerState;
  }

  isPlaying(): boolean {
    return this.playerState === PlayerState.PLAYING;
  }

  getCurrentTime(): number {
    return this.currentTime;
  }

  getDuration(): number {
    return this.duration;
  }

  // ========== 事件订阅 ==========
  onPlay(listener: PlayStatusListener): void {
    this.playListeners.push(listener);
  }

  offPlay(listener: PlayStatusListener): void {
    this.removeListener(this.playListeners, listener);
  }

  onProgress(listener: ProgressListener): void {
    this.progressListeners.push(listener);
  }

  offProgress(listener: ProgressListener): void {
    this.removeListener(this.progressListeners, listener);
  }

  onTrackChange(listener: TrackChangeListener): void {
    this.trackListeners.push(listener);
  }

  offTrackChange(listener: TrackChangeListener): void {
    this.removeListener(this.trackListeners, listener);
  }

  onState(listener: StateListener): void {
    this.stateListeners.push(listener);
  }

  offState(listener: StateListener): void {
    this.removeListener(this.stateListeners, listener);
  }

  private removeListener<T>(listeners: T[], listener: T): void {
    const index = listeners.indexOf(listener);
    if (index > -1) {
      listeners.splice(index, 1);
    }
  }

  // ========== 内部逻辑 ==========
  private async resolveTrackUrl(track: TrackModel): Promise<void> {
    if (track.url && track.url.length > 0) {
      return;
    }
    try {
      const result = await ApiService.getSongUrl(track.id, this.quality);
      const data = result.data;
      if (data && data.length > 0) {
        const url = data[0].url;
        if (url) {
          track.url = url;
          this.updateTrackInList(track);
        }
      }
    } catch (error) {
      console.error('获取播放地址失败:', JSON.stringify(error));
    }
  }

  private handlePlayEnd(): void {
    if (this.playMode === PlayMode.SINGLE) {
      this.seekTo(0);
      this.play();
    } else {
      this.next();
    }
  }

  private persistTrackList(): void {
    StorageUtil.putObject<TrackModel[]>('audio_track_list', this.trackList);
    StorageUtil.putNumber('audio_current_index', this.currentIndex);
  }

  private notifyPlay(isPlaying: boolean): void {
    this.playListeners.forEach((listener: PlayStatusListener) => {
      listener(isPlaying);
    });
  }

  private notifyProgress(currentTime: number, duration: number): void {
    this.progressListeners.forEach((listener: ProgressListener) => {
      listener(currentTime, duration);
    });
  }

  private notifyTrack(track: TrackModel, index: number): void {
    this.trackListeners.forEach((listener: TrackChangeListener) => {
      listener(track, index);
    });
  }

  private notifyState(state: PlayerState): void {
    this.stateListeners.forEach((listener: StateListener) => {
      listener(state);
    });
  }
}
