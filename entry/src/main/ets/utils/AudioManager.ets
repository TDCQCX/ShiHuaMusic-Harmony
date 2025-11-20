// 音频管理器 - 移植自微信小程序的AudioManager
import media from '@ohos.multimedia.media';
import { SongInfo, PlayMode, PlayerState } from '../types/common';

export class AudioManager {
  private static instance: AudioManager | null = null;
  private audioPlayer: media.AudioPlayer | null = null;
  private currentSong: SongInfo | null = null;
  private currentIndex: number = 0;
  private playlist: SongInfo[] = [];
  private playerState: PlayerState = PlayerState.STOPPED;
  private playMode: PlayMode = PlayMode.SEQUENCE;
  private progress: number = 0;
  private duration: number = 0;
  private volume: number = 1.0;
  private isLoop: boolean = false;
  private isRandom: boolean = false;
  
  // 事件监听器
  private playListeners: Array<(isPlaying: boolean) => void> = [];
  private progressListeners: Array<(progress: number, duration: number) => void> = [];
  private songChangeListeners: Array<(song: SongInfo, index: number) => void> = [];
  private stateChangeListeners: Array<(state: PlayerState) => void> = [];

  private constructor() {
    this.initAudioPlayer();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): AudioManager {
    if (!AudioManager.instance) {
      AudioManager.instance = new AudioManager();
    }
    return AudioManager.instance;
  }

  /**
   * 初始化音频播放器
   */
  private async initAudioPlayer(): Promise<void> {
    try {
      this.audioPlayer = await media.createAudioPlayer();
      this.setupEventListeners();
    } catch (error) {
      console.error('初始化音频播放器失败:', error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    if (!this.audioPlayer) return;

    // 播放状态变化
    this.audioPlayer.on('play', () => {
      this.playerState = PlayerState.PLAYING;
      this.notifyPlayListeners(true);
      this.notifyStateChangeListeners(this.playerState);
    });

    this.audioPlayer.on('pause', () => {
      this.playerState = PlayerState.PAUSED;
      this.notifyPlayListeners(false);
      this.notifyStateChangeListeners(this.playerState);
    });

    this.audioPlayer.on('finish', () => {
      this.playerState = PlayerState.COMPLETED;
      this.notifyStateChangeListeners(this.playerState);
      // 自动播放下一首
      if (this.playMode !== PlayMode.SINGLE) {
        this.next();
      }
    });

    this.audioPlayer.on('error', (error) => {
      console.error('音频播放错误:', error);
      this.playerState = PlayerState.ERROR;
      this.notifyStateChangeListeners(this.playerState);
    });

    // 进度更新
    this.audioPlayer.on('timeUpdate', (currentTime: number) => {
      this.progress = currentTime;
      this.notifyProgressListeners(this.progress, this.duration);
    });

    // 音频信息更新
    this.audioPlayer.on('loadedData', () => {
      const duration = this.audioPlayer?.duration || 0;
      this.duration = duration;
      this.notifyProgressListeners(this.progress, this.duration);
    });
  }

  /**
   * 播放音乐
   * @param song 歌曲信息
   * @param playlist 播放列表
   * @param index 播放索引
   */
  async play(song?: SongInfo, playlist?: SongInfo[], index: number = 0): Promise<void> {
    try {
      // 如果指定了歌曲、播放列表和索引，更新当前播放状态
      if (song && playlist) {
        this.currentSong = song;
        this.playlist = [...playlist];
        this.currentIndex = index;
      }

      // 如果没有当前歌曲，使用默认
      if (!this.currentSong && this.playlist.length > 0) {
        this.currentSong = this.playlist[this.currentIndex];
      }

      if (!this.currentSong) {
        console.warn('没有可播放的歌曲');
        return;
      }

      if (!this.audioPlayer) {
        await this.initAudioPlayer();
      }

      // 设置音频源
      await this.audioPlayer!.src = this.currentSong.url;
      await this.audioPlayer!.play();

      // 通知歌曲变化
      if (song) {
        this.notifySongChangeListeners(this.currentSong, this.currentIndex);
      }

    } catch (error) {
      console.error('播放音乐失败:', error);
      this.playerState = PlayerState.ERROR;
      this.notifyStateChangeListeners(this.playerState);
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    try {
      if (this.audioPlayer && this.playerState === PlayerState.PLAYING) {
        await this.audioPlayer.pause();
      }
    } catch (error) {
      console.error('暂停播放失败:', error);
    }
  }

  /**
   * 恢复播放
   */
  async resume(): Promise<void> {
    try {
      if (this.audioPlayer && this.playerState === PlayerState.PAUSED) {
        await this.audioPlayer.play();
      }
    } catch (error) {
      console.error('恢复播放失败:', error);
    }
  }

  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    try {
      if (this.audioPlayer) {
        await this.audioPlayer.stop();
        this.playerState = PlayerState.STOPPED;
        this.progress = 0;
        this.notifyPlayListeners(false);
        this.notifyStateChangeListeners(this.playerState);
      }
    } catch (error) {
      console.error('停止播放失败:', error);
    }
  }

  /**
   * 切换播放/暂停状态
   */
  async togglePlayPause(): Promise<void> {
    if (this.playerState === PlayerState.PLAYING) {
      await this.pause();
    } else if (this.playerState === PlayerState.PAUSED) {
      await this.resume();
    } else {
      // 如果是停止状态，重新播放
      await this.play();
    }
  }

  /**
   * 播放上一首
   */
  async previous(): Promise<void> {
    if (this.playlist.length === 0) return;

    if (this.isRandom) {
      // 随机播放模式
      this.currentIndex = Math.floor(Math.random() * this.playlist.length);
    } else {
      // 顺序播放或列表循环
      this.currentIndex = this.currentIndex > 0 ? 
        this.currentIndex - 1 : 
        (this.playMode === PlayMode.LOOP ? this.playlist.length - 1 : 0);
    }

    this.currentSong = this.playlist[this.currentIndex];
    await this.play();
  }

  /**
   * 播放下一首
   */
  async next(): Promise<void> {
    if (this.playlist.length === 0) return;

    if (this.isRandom) {
      // 随机播放模式
      this.currentIndex = Math.floor(Math.random() * this.playlist.length);
    } else {
      // 顺序播放或列表循环
      this.currentIndex = this.currentIndex < this.playlist.length - 1 ? 
        this.currentIndex + 1 : 
        (this.playMode === PlayMode.LOOP ? 0 : this.playlist.length - 1);
    }

    this.currentSong = this.playlist[this.currentIndex];
    await this.play();
  }

  /**
   * 设置播放进度
   * @param progress 进度（毫秒）
   */
  async seekTo(progress: number): Promise<void> {
    try {
      if (this.audioPlayer) {
        await this.audioPlayer.seek(progress);
        this.progress = progress;
      }
    } catch (error) {
      console.error('设置播放进度失败:', error);
    }
  }

  /**
   * 设置音量
   * @param volume 音量（0.0-1.0）
   */
  async setVolume(volume: number): Promise<void> {
    try {
      this.volume = Math.max(0, Math.min(1, volume));
      if (this.audioPlayer) {
        await this.audioPlayer.setVolume(this.volume);
      }
    } catch (error) {
      console.error('设置音量失败:', error);
    }
  }

  /**
   * 设置播放模式
   * @param mode 播放模式
   */
  setPlayMode(mode: PlayMode): void {
    this.playMode = mode;
    this.isLoop = mode === PlayMode.SINGLE || mode === PlayMode.LOOP;
    this.isRandom = mode === PlayMode.RANDOM;
  }

  /**
   * 设置播放列表
   * @param playlist 播放列表
   * @param index 起始索引
   */
  setPlaylist(playlist: SongInfo[], index: number = 0): void {
    this.playlist = [...playlist];
    this.currentIndex = index;
    this.currentSong = playlist[index] || null;
  }

  /**
   * 添加到播放列表
   * @param song 歌曲
   */
  addToPlaylist(song: SongInfo): void {
    this.playlist.push(song);
  }

  /**
   * 从播放列表移除
   * @param index 索引
   */
  removeFromPlaylist(index: number): void {
    if (index >= 0 && index < this.playlist.length) {
      this.playlist.splice(index, 1);
      // 如果移除的是当前播放歌曲，调整当前索引
      if (index <= this.currentIndex) {
        this.currentIndex = Math.max(0, this.currentIndex - 1);
      }
    }
  }

  // Getter方法
  getCurrentSong(): SongInfo | null {
    return this.currentSong;
  }

  getCurrentIndex(): number {
    return this.currentIndex;
  }

  getPlaylist(): SongInfo[] {
    return [...this.playlist];
  }

  getPlayerState(): PlayerState {
    return this.playerState;
  }

  getProgress(): number {
    return this.progress;
  }

  getDuration(): number {
    return this.duration;
  }

  getVolume(): number {
    return this.volume;
  }

  getPlayMode(): PlayMode {
    return this.playMode;
  }

  isPlaying(): boolean {
    return this.playerState === PlayerState.PLAYING;
  }

  // 事件监听器管理
  onPlay(listener: (isPlaying: boolean) => void): void {
    this.playListeners.push(listener);
  }

  onProgress(listener: (progress: number, duration: number) => void): void {
    this.progressListeners.push(listener);
  }

  onSongChange(listener: (song: SongInfo, index: number) => void): void {
    this.songChangeListeners.push(listener);
  }

  onStateChange(listener: (state: PlayerState) => void): void {
    this.stateChangeListeners.push(listener);
  }

  // 移除事件监听器
  removePlayListener(listener: (isPlaying: boolean) => void): void {
    const index = this.playListeners.indexOf(listener);
    if (index > -1) {
      this.playListeners.splice(index, 1);
    }
  }

  removeProgressListener(listener: (progress: number, duration: number) => void): void {
    const index = this.progressListeners.indexOf(listener);
    if (index > -1) {
      this.progressListeners.splice(index, 1);
    }
  }

  removeSongChangeListener(listener: (song: SongInfo, index: number) => void): void {
    const index = this.songChangeListeners.indexOf(listener);
    if (index > -1) {
      this.songChangeListeners.splice(index, 1);
    }
  }

  removeStateChangeListener(listener: (state: PlayerState) => void): void {
    const index = this.stateChangeListeners.indexOf(listener);
    if (index > -1) {
      this.stateChangeListeners.splice(index, 1);
    }
  }

  // 通知方法
  private notifyPlayListeners(isPlaying: boolean): void {
    this.playListeners.forEach(listener => listener(isPlaying));
  }

  private notifyProgressListeners(progress: number, duration: number): void {
    this.progressListeners.forEach(listener => listener(progress, duration));
  }

  private notifySongChangeListeners(song: SongInfo, index: number): void {
    this.songChangeListeners.forEach(listener => listener(song, index));
  }

  private notifyStateChangeListeners(state: PlayerState): void {
    this.stateChangeListeners.forEach(listener => listener(state));
  }

  /**
   * 清理资源
   */
  async cleanup(): Promise<void> {
    try {
      await this.stop();
      if (this.audioPlayer) {
        this.audioPlayer.release();
        this.audioPlayer = null;
      }
      
      // 清空所有监听器
      this.playListeners = [];
      this.progressListeners = [];
      this.songChangeListeners = [];
      this.stateChangeListeners = [];
      
      // 重置状态
      this.currentSong = null;
      this.playlist = [];
      this.currentIndex = 0;
      this.playerState = PlayerState.STOPPED;
      this.progress = 0;
      this.duration = 0;
      
    } catch (error) {
      console.error('清理音频管理器资源失败:', error);
    }
  }
}