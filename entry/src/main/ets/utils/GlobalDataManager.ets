/**
 * 全局数据管理器（单例，ArkTS 规范）
 * 对齐 music-client Pinia stores：用户、Token、最近播放
 */
import { ApiService } from '../api/ApiService';
import { AudioManager } from './AudioManager';
import { HttpUtil } from './HttpUtil';
import { StorageUtil } from './StorageUtil';
import { TrackModel, UserInfo } from '../types/common';

export class GlobalDataManager {
  private static instance: GlobalDataManager | null = null;
  private userInfo: UserInfo | null = null;
  private isLoggedIn: boolean = false;
  private recentPlayHistory: TrackModel[] = [];
  private audioManager: AudioManager;

  private constructor() {
    this.audioManager = AudioManager.getInstance();
  }

  static getInstance(): GlobalDataManager {
    if (GlobalDataManager.instance === null) {
      GlobalDataManager.instance = new GlobalDataManager();
    }
    return GlobalDataManager.instance;
  }

  /**
   * 应用启动时恢复本地会话
   */
  async initialize(): Promise<void> {
    const token = await StorageUtil.getString('token', '');
    if (token) {
      HttpUtil.setToken(token);
    }
    const savedUser = await StorageUtil.getObject<UserInfo>('user_info', null);
    if (savedUser) {
      this.userInfo = savedUser;
      this.isLoggedIn = true;
    }
    const history = await StorageUtil.getObject<TrackModel[]>('recent_history', null);
    if (history) {
      this.recentPlayHistory = history;
    }
  }

  getAudioManager(): AudioManager {
    return this.audioManager;
  }

  getUserInfo(): UserInfo | null {
    return this.userInfo;
  }

  getIsLoggedIn(): boolean {
    return this.isLoggedIn;
  }

  getToken(): string {
    return HttpUtil.getToken();
  }

  /**
   * 登录成功后写入会话
   */
  async setLoginStatus(userInfo: UserInfo, token: string): Promise<void> {
    this.userInfo = userInfo;
    this.isLoggedIn = true;
    HttpUtil.setToken(token);
    await StorageUtil.putString('token', token);
    await StorageUtil.putObject<UserInfo>('user_info', userInfo);
  }

  /**
   * 仅更新用户资料（保留会话）
   */
  async updateUserInfo(userInfo: UserInfo): Promise<void> {
    this.userInfo = userInfo;
    if (this.isLoggedIn) {
      await StorageUtil.putObject<UserInfo>('user_info', userInfo);
    }
  }

  /**
   * 退出/注销：清理会话
   */
  async clearLoginStatus(): Promise<void> {
    this.userInfo = null;
    this.isLoggedIn = false;
    HttpUtil.clearToken();
    await StorageUtil.remove('token');
    await StorageUtil.remove('user_info');
  }

  /**
   * 校验登录状态（网络失败时保留本地会话，避免误登出）
   */
  async checkLoginStatus(): Promise<boolean> {
    if (!this.isLoggedIn) {
      return false;
    }
    try {
      const result = await ApiService.getUserInfo();
      if (result.code === 0 && result.data) {
        this.userInfo = result.data;
        await StorageUtil.putObject<UserInfo>('user_info', result.data);
        return true;
      }
      await this.clearLoginStatus();
      return false;
    } catch (error) {
      console.warn('登录状态校验网络异常，保留本地会话');
      return this.isLoggedIn;
    }
  }

  // ========== 最近播放 ==========
  getRecentPlayHistory(): TrackModel[] {
    return this.recentPlayHistory;
  }

  async addRecentPlay(track: TrackModel): Promise<void> {
    this.recentPlayHistory = this.recentPlayHistory.filter((item: TrackModel) => item.id !== track.id);
    this.recentPlayHistory.unshift(track);
    if (this.recentPlayHistory.length > 100) {
      this.recentPlayHistory = this.recentPlayHistory.slice(0, 100);
    }
    await StorageUtil.putObject<TrackModel[]>('recent_history', this.recentPlayHistory);
  }

  async removeRecentPlay(id: string): Promise<void> {
    this.recentPlayHistory = this.recentPlayHistory.filter((item: TrackModel) => item.id !== id);
    await StorageUtil.putObject<TrackModel[]>('recent_history', this.recentPlayHistory);
  }

  async clearRecentPlay(): Promise<void> {
    this.recentPlayHistory = [];
    await StorageUtil.remove('recent_history');
  }
}
