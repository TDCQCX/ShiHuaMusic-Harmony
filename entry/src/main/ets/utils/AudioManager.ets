/**
 * 音频播放引擎（单例，ArkTS 规范）
 * 基于 AVPlayer（@ohos.multimedia.media），对齐 music-client 播放行为
 */
import { media } from '@kit.MediaKit';
import { avSession } from '@kit.AVSessionKit';
import { ApiService } from '../api/ApiService';
import { MediaSessionManager } from './MediaSessionManager';
import { StorageUtil } from './StorageUtil';
import { PlayMode, PlayerState, TrackModel } from '../types/common';

export type PlayStatusListener = (isPlaying: boolean) => void;
export type ProgressListener = (currentTime: number, duration: number) => void;
export type TrackChangeListener = (track: TrackModel, index: number) => void;
export type StateListener = (state: PlayerState) => void;
export type PlayModeListener = (mode: PlayMode) => void;

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
  private lastSessionUpdateTime: number = 0;
  // 播放结束处理标记：防止 completed 事件与轮询兜底重复触发自动切歌
  private playEndHandled: boolean = false;
  // 已排定自动切歌（timeUpdate 每 100ms 触发，避免在等待窗口内重复排定）
  private playEndScheduled: boolean = false;

  private playListeners: PlayStatusListener[] = [];
  private progressListeners: ProgressListener[] = [];
  private trackListeners: TrackChangeListener[] = [];
  private stateListeners: StateListener[] = [];
  private playModeListeners: PlayModeListener[] = [];

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
        this.playFromSession();
      };
      this.mediaSession.onPauseCommand = () => {
        this.pauseFromSession();
      };
      this.mediaSession.onNextCommand = () => {
        this.next();
      };
      this.mediaSession.onPreviousCommand = () => {
        this.previous();
      };
      this.mediaSession.onSeekCommand = (positionMs: number) => {
        // 通知栏/播控中心拖动进度条：直接跳转并同步播放状态
        this.seekTo(positionMs);
      };
      this.mediaSession.onLoopModeCommand = (mode: avSession.LoopMode, isTarget: boolean) => {
        // setLoopMode：系统上报的是“当前”模式，由应用自行决定下一模式；
        // setTargetLoopMode：系统上报的是用户选定的“目标”模式，直接应用即可。
        const current = MediaSessionManager.mapToPlayMode(mode);
        const next = isTarget ? current : AudioManager.nextMode(current);
        console.info('通知栏循环模式命令：' + (isTarget ? '目标' : '切换') + '，' + current + ' -> ' + next);
        this.setPlayMode(next);
      };
      this.mediaSession.onToggleFavoriteCommand = () => {
        this.toggleFavoriteFromSession();
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
        this.schedulePlayEnd();
      } else if (state === 'error') {
        this.playerState = PlayerState.ERROR;
        this.notifyPlay(false);
      }
      this.notifyState(this.playerState);
    });
    player.on('timeUpdate', (time: number) => {
      this.currentTime = time;
      this.notifyProgress(this.currentTime, this.duration);
      // 节流：每秒向通知栏同步一次播放进度
      const now = Date.now();
      if (now - this.lastSessionUpdateTime > 1000) {
        this.lastSessionUpdateTime = now;
        this.mediaSession.updateState(PlayerState.PLAYING, this.currentTime);
      }
      // 兜底：部分设备/网络流不派发 completed 事件（日志可见
      // “OnEndOfStream is called / can not find EndOfStream callback”），
      // 依赖 timeUpdate（约每 100ms 上报一次）与 player.state 检测播完并自动切歌
      this.checkPlayEnd();
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

  /**
   * 统一更新歌曲收藏状态：同步播放列表、所有 UI 与通知栏
   */
  setLikeStatus(songId: number, status: number): void {
    let currentChanged: boolean = false;
    this.trackList.forEach((track: TrackModel) => {
      if (Number(track.id) === songId) {
        track.likeStatus = status;
        if (this.currentIndex >= 0 && this.trackList[this.currentIndex] === track) {
          currentChanged = true;
        }
      }
    });
    if (currentChanged) {
      const track = this.getCurrentTrack();
      if (track) {
        this.notifyTrack(track, this.currentIndex);
        this.mediaSession.updateSession(track, this.playerState, this.playMode);
      }
    }
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
      this.playEndHandled = false;
      this.playEndScheduled = false;
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
        // 手动跳转后重新允许播放结束检测
        this.playEndHandled = false;
        // 同步到通知栏/播控中心，保证拖动后进度不回弹
        this.mediaSession.updateState(this.playerState, this.currentTime);
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
    // 循环模式必须实时同步到通知栏（否则通知栏图标不更新、点击无效果）
    this.mediaSession.updateLoopMode(mode);
    this.notifyPlayMode(mode);
  }

  getPlayMode(): PlayMode {
    return this.playMode;
  }

  /**
   * 计算循环模式的下一个模式（与播放页/通知栏共用同一顺序）
   */
  static nextMode(mode: PlayMode): PlayMode {
    switch (mode) {
      case PlayMode.ORDER:
        return PlayMode.SHUFFLE;
      case PlayMode.SHUFFLE:
        return PlayMode.LOOP;
      case PlayMode.LOOP:
        return PlayMode.SINGLE;
      case PlayMode.SINGLE:
      default:
        return PlayMode.ORDER;
    }
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

  onPlayMode(listener: PlayModeListener): void {
    this.playModeListeners.push(listener);
  }

  offPlayMode(listener: PlayModeListener): void {
    this.removeListener(this.playModeListeners, listener);
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

  /**
   * 通知栏播放命令：直接驱动播放器并同步状态（不依赖内部状态机判断）
   */
  private async playFromSession(): Promise<void> {
    try {
      if (this.avPlayer !== null && (this.avPlayer.state === 'paused' || this.avPlayer.state === 'prepared' ||
        this.avPlayer.state === 'completed')) {
        await this.avPlayer.play();
      } else {
        await this.play();
      }
      this.playerState = PlayerState.PLAYING;
      this.notifyPlay(true);
      this.mediaSession.updateState(PlayerState.PLAYING, this.currentTime);
    } catch (error) {
      console.error('通知栏播放失败:', JSON.stringify(error));
    }
  }

  /**
   * 通知栏暂停命令：直接驱动播放器并同步状态
   */
  private async pauseFromSession(): Promise<void> {
    try {
      if (this.avPlayer !== null && this.avPlayer.state === 'playing') {
        await this.avPlayer.pause();
      }
      this.playerState = PlayerState.PAUSED;
      this.notifyPlay(false);
      this.mediaSession.updateState(PlayerState.PAUSED, this.currentTime);
    } catch (error) {
      console.error('通知栏暂停失败:', JSON.stringify(error));
    }
  }

  /**
   * 通知栏收藏命令：切换当前歌曲喜欢状态
   */
  private async toggleFavoriteFromSession(): Promise<void> {
    const track = this.getCurrentTrack();
    if (!track) {
      return;
    }
    const songId = Number(track.id);
    try {
      if (track.likeStatus === 1) {
        const result = await ApiService.cancelCollectSong(songId);
        if (result.code === 0) {
          this.setLikeStatus(songId, 0);
        }
      } else {
        const result = await ApiService.collectSong(songId);
        if (result.code === 0) {
          this.setLikeStatus(songId, 1);
        }
      }
    } catch (error) {
      console.error('通知栏收藏失败:', JSON.stringify(error));
    }
  }

  private handlePlayEnd(): void {
    if (this.playEndHandled) {
      return;
    }
    this.playEndHandled = true;
    console.info('handlePlayEnd 执行，当前播放模式: ' + this.playMode.toString());
    // 释放已完成的播放器，确保下一首以全新状态加载（参照 music-client ended → nextTrack）
    if (this.avPlayer !== null) {
      try {
        this.avPlayer.release();
      } catch (error) {
        console.warn('释放已完成播放器失败:', JSON.stringify(error));
      }
      this.avPlayer = null;
      this.prepared = false;
      this.pendingUrl = '';
    }
    if (this.playMode === PlayMode.SINGLE) {
      this.seekTo(0);
      this.play();
    } else {
      this.next();
    }
  }

  /**
   * 排定自动切歌：延迟 80ms 执行，避免与 stateChange(completed) 事件派发竞争；
   * completed 事件与 timeUpdate 兜底检测共用此入口，保证只切一次
   */
  private schedulePlayEnd(): void {
    if (this.playEndHandled || this.playEndScheduled) {
      return;
    }
    this.playEndScheduled = true;
    console.info('检测到播放结束，自动切歌');
    setTimeout(() => {
      this.playEndScheduled = false;
      this.handlePlayEnd();
    }, 80);
  }

  /**
   * 播放结束检测（timeUpdate 每 100ms 触发一次，播完自动切歌的可靠兜底）：
   * 1. player.state 已进入 completed（事件未派发时也能读到原生状态）；
   * 2. 播放进度已到达时长末尾（timeUpdate 最后一次上报通常距结尾不足 200ms）。
   */
  private checkPlayEnd(): void {
    if (this.playEndHandled || this.playEndScheduled || this.avPlayer === null) {
      return;
    }
    if (this.playerState !== PlayerState.PLAYING && this.playerState !== PlayerState.COMPLETED) {
      return;
    }
    let nativeState: media.AVPlayerState = 'idle';
    try {
      nativeState = this.avPlayer.state;
    } catch (error) {
      return;
    }
    // timeUpdate/duration 单位均为毫秒，距结尾 200ms 内视为播放结束
    const nearEnd: boolean = this.duration > 0 && this.currentTime >= this.duration - 200;
    if (nativeState === 'completed' || nearEnd) {
      console.info('检测到播放结束（state=' + nativeState + ', time=' + this.currentTime +
        '/' + this.duration + '）');
      this.schedulePlayEnd();
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

  private notifyPlayMode(mode: PlayMode): void {
    this.playModeListeners.forEach((listener: PlayModeListener) => {
      listener(mode);
    });
  }
}
