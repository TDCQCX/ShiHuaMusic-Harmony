// 全局数据管理类
import { UserInfo, SongInfo } from '../types/common';
import { StorageUtil } from './StorageUtil';
import { AudioManager } from './AudioManager';
import { HttpUtil } from './HttpUtil';

export class GlobalDataManager {
  private static instance: GlobalDataManager | null = null;
  private userInfo: UserInfo | null = null;
  private token: string | null = null;
  private isLoggedIn: boolean = false;
  private showWelcomeModal: boolean = false;
  private audioManager: AudioManager;
  private httpUtil: HttpUtil;

  // 全局配置
  private baseUrl: string = 'http://192.168.66.241:8080'; // 后端服务器API
  private imageBaseUrl: string = 'http://192.168.66.241:9000'; // 图片服务器API

  private constructor() {
    this.audioManager = AudioManager.getInstance();
    this.httpUtil = new HttpUtil();
    this.initializeApp();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): GlobalDataManager {
    if (!GlobalDataManager.instance) {
      GlobalDataManager.instance = new GlobalDataManager();
    }
    return GlobalDataManager.instance;
  }

  /**
   * 初始化应用
   */
  private async initializeApp(): Promise<void> {
    // 检查是否首次启动
    const hasShownWelcome: boolean = await StorageUtil.getHasShownWelcome();
    this.showWelcomeModal = !hasShownWelcome;

    // 从本地存储恢复用户信息和token
    const savedUserInfo: UserInfo | null = await StorageUtil.getUserInfo();
    const savedToken: string = await StorageUtil.getToken();
    
    if (savedUserInfo && savedToken) {
      this.userInfo = savedUserInfo;
      this.token = savedToken;
      this.isLoggedIn = true;
      
      // 设置token到HTTP工具
      this.httpUtil.setToken(savedToken);
    }
  }

  /**
   * 获取用户信息
   */
  getUserInfo(): UserInfo | null {
    return this.userInfo;
  }

  /**
   * 设置用户信息
   * @param userInfo 用户信息
   */
  async setUserInfo(userInfo: UserInfo): Promise<void> {
    this.userInfo = userInfo;
    this.isLoggedIn = true;
    await StorageUtil.saveUserInfo(userInfo);
  }

  /**
   * 获取token
   */
  getToken(): string | null {
    return this.token;
  }

  /**
   * 设置token
   * @param token 认证令牌
   */
  async setToken(token: string): Promise<void> {
    this.token = token;
    await StorageUtil.saveToken(token);
    this.httpUtil.setToken(token);
  }

  /**
   * 清除token
   */
  async clearToken(): Promise<void> {
    this.token = null;
    await StorageUtil.removeToken();
  }

  /**
   * 获取登录状态
   */
  getIsLoggedIn(): boolean {
    return this.isLoggedIn;
  }

  /**
   * 清除用户信息
   */
  async clearUserInfo(): Promise<void> {
    this.userInfo = null;
    this.isLoggedIn = false;
    await StorageUtil.removeUserInfo();
    await this.clearToken();
  }

  /**
   * 获取欢迎弹窗显示状态
   */
  getShowWelcomeModal(): boolean {
    return this.showWelcomeModal;
  }

  /**
   * 关闭欢迎弹窗
   */
  async closeWelcomeModal(): Promise<void> {
    this.showWelcomeModal = false;
    await StorageUtil.setHasShownWelcome(true);
  }

  /**
   * 获取音频管理器实例
   */
  getAudioManager(): AudioManager {
    return this.audioManager;
  }

  /**
   * 获取HTTP工具实例
   */
  getHttpUtil(): HttpUtil {
    return this.httpUtil;
  }

  /**
   * 获取基础URL
   */
  getBaseUrl(): string {
    return this.baseUrl;
  }

  /**
   * 获取图片基础URL
   */
  getImageBaseUrl(): string {
    return this.imageBaseUrl;
  }

  /**
   * 检查登录状态并验证token有效性
   */
  async checkLoginStatus(): Promise<boolean> {
    if (!this.isLoggedIn || !this.token) {
      return false;
    }

    try {
      const result = await this.request({
        url: '/user/getUserInfo',
        method: 'GET'
      });

      if (result.success || result.code === 0) {
        this.userInfo = result.data || result;
        this.isLoggedIn = true;
        await StorageUtil.saveUserInfo(result.data || result);
        return true;
      } else {
        await this.clearUserInfo();
        return false;
      }
    } catch (error) {
      console.error('登录状态验证失败:', error);
      await this.clearUserInfo();
      return false;
    }
  }

  /**
   * 设置登录状态
   * @param isLoggedIn 是否登录
   * @param userInfo 用户信息
   * @param token 认证令牌
   */
  async setLoginStatus(isLoggedIn: boolean, userInfo?: UserInfo, token?: string): Promise<void> {
    this.isLoggedIn = isLoggedIn;
    
    if (userInfo && token) {
      this.userInfo = userInfo;
      this.token = token;
      await StorageUtil.saveUserInfo(userInfo);
      await StorageUtil.saveToken(token);
      this.httpUtil.setToken(token);
    } else if (!isLoggedIn) {
      await this.clearUserInfo();
    }
  }

  /**
   * 设置用户信息（小程序版本兼容）
   * @param userInfo 用户信息
   */
  async setUserInfoCompat(userInfo: UserInfo): Promise<void> {
    this.userInfo = userInfo;
    this.isLoggedIn = true;
    await StorageUtil.saveUserInfo(userInfo);
    await StorageUtil.saveToken(this.token || '');
  }

  /**
   * 清除用户信息（小程序版本兼容）
   */
  async clearUserInfoCompat(): Promise<void> {
    this.userInfo = null;
    this.isLoggedIn = false;
    await StorageUtil.removeUserInfo();
    await StorageUtil.removeToken();
    this.token = null;
  }

  /**
   * 处理图片URL，确保在鸿蒙应用中正常显示
   * @param url 图片URL
   */
  processImageUrl(url: string): string {
    if (!url) return '';
    
    // 如果URL已经是完整URL，只提取路径部分，保留完整路径信息
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        // 提取完整路径部分（从第一个/开始的所有内容）
        const pathStartIndex = url.indexOf('/', url.indexOf('://') + 3);
        const path = pathStartIndex !== -1 ? url.substring(pathStartIndex) : '/';
        // 使用全局配置的图片服务器地址拼接完整路径
        return `${this.imageBaseUrl}${path}`;
      } catch (e) {
        console.warn('Failed to process URL:', url, e);
        return url;
      }
    }
    
    // 否则拼接图片服务器地址，确保路径正确
    const cleanPath = url.startsWith('/') ? url : '/' + url;
    return `${this.imageBaseUrl}${cleanPath}`;
  }

  /**
   * 批量处理数据中的图片URL
   * @param data 数据对象或数组
   * @param fields 图片字段名数组
   */
  processImageUrlsInData(data: ProcessedData[] | ProcessedData, fields: string[]): ProcessedData[] | ProcessedData {
    if (!Array.isArray(data)) return data;
    
    return data.map(item => {
      const processedItem: ProcessedData = { ...item };
      fields.forEach(field => {
        if (processedItem[field]) {
          processedItem[field] = this.processImageUrl(processedItem[field] as string);
        }
      });
      return processedItem;
    });
  }

  /**
   * 封装网络请求
   * @param options 请求选项
   */
  async request(options: RequestOptions): Promise<ApiResponse> {
    const { url, method = 'GET', data, params, showLoading = true } = options;
    
    // 构建完整URL
    const fullUrl = `${this.baseUrl}${url}`;
    
    try {
      // TODO: 实现鸿蒙原生网络请求
      // 这里应该使用鸿蒙的网络请求API
      
      console.log('发送请求:', url, data);
      
      // 模拟请求逻辑
      const result = await this.httpUtil.request({
        url,
        method,
        data,
        params,
        showLoading
      });
      
      // 处理401错误
      if (result.code === 401 || result.statusCode === 401) {
        await this.clearUserInfo();
        throw new Error('登录已过期，请重新登录');
      }
      
      return result as ApiResponse;
    } catch (error) {
      console.error('网络请求失败:', error);
      throw error;
    }
  }

  /**
   * 获取当前播放歌曲
   */
  getCurrentSong(): SongInfo | null {
    return this.audioManager.getCurrentSong();
  }

  /**
   * 设置当前播放歌曲
   */
  setCurrentSong(song: SongInfo): void {
    this.audioManager.setCurrentSong(song);
  }

  /**
   * 获取播放列表
   */
  getSongList(): SongInfo[] {
    return this.audioManager.getSongList();
  }

  /**
   * 设置播放列表
   */
  setSongList(songList: SongInfo[]): void {
    this.audioManager.setSongList(songList);
  }

  /**
   * 获取当前播放索引
   */
  getCurrentIndex(): number {
    return this.audioManager.getCurrentIndex();
  }

  /**
   * 设置当前播放索引
   */
  setCurrentIndex(index: number): void {
    this.audioManager.setCurrentIndex(index);
  }
}

/**
 * 图片数据处理接口
 */
interface ImageData {
  [key: string]: string | undefined;
}

/**
 * 网络请求响应接口
 */
interface ApiResponse {
  success?: boolean;
  code?: number;
  statusCode?: number;
  data?: Record<string, any> | any[] | string | number | boolean | null;
  message?: string;
  error?: string;
}

/**
 * 网络请求选项接口
 */
interface RequestOptions {
  url: string;
  method?: string;
  data?: Record<string, any> | any[] | string | number | boolean | null;
  params?: Record<string, string | number | boolean>;
  success?: (res: ApiResponse) => void;
  fail?: (err: Error) => void;
  complete?: (res: ApiResponse) => void;
  showLoading?: boolean;
}

/**
 * 通用数据处理接口
 */
interface ProcessedData extends ImageData {
  [key: string]: string | number | boolean | undefined;
}