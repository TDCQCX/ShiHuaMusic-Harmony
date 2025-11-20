// 通用类型定义

// 艺术家信息接口
export interface Artist {
  id: number;
  name: string;
  picUrl?: string;
}

// 专辑信息接口
export interface Album {
  id: number;
  name: string;
  picUrl: string;
}

// 歌曲信息接口（完整格式）
export interface SongInfo {
  id: number;
  name: string;
  artists: Artist[];
  album: Album;
  duration: number;
  url: string;
  picUrl: string;
}

// 歌曲列表项接口（简化格式，用于列表展示）
export interface SongListItem {
  id: number;
  name: string;
  artists?: Artist[];
  album?: Album;
  duration?: number;
  url?: string;
  picUrl?: string;
  playCount?: number;
}

// 歌单信息接口
export interface PlaylistInfo {
  id: number;
  name: string;
  coverUrl?: string;
  picUrl?: string;
  description?: string;
  creator?: {
    nickname: string;
  };
  trackCount?: number;
  playCount?: number;
  subscribedCount?: number;
  commentCount?: number;
}

// 轮播图信息接口
export interface BannerInfo {
  id: number;
  title?: string;
  picUrl: string;
  url?: string;
}

// 用户信息接口
export interface UserInfo {
  userId: string;
  username: string;
  userAvatar?: string;
  avatarUrl?: string;
  email?: string;
}

// API响应基础接口
export interface ApiResponse<T> {
  code: number;
  message?: string;
  data?: T;
  success?: boolean;
}

// 网络请求配置
export interface RequestConfig {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  data?: Object;
  params?: Record<string, string | number>;
  showLoading?: boolean;
  headers?: Record<string, string>;
  timeout?: number; // 超时时间（毫秒）
  useCache?: boolean; // 是否使用缓存
  retryCount?: number; // 重试次数
}

// 播放器状态接口
export interface PlayerState {
  currentSong: SongInfo | null;
  isPlaying: boolean;
  progress: number;
  currentTime: number;
  duration: number;
  loopMode: PlayMode; // 播放模式
  playingList: SongInfo[];
  currentIndex: number;
}

// 播放模式枚举
export enum PlayMode {
  SEQUENCE = 0,
  LOOP = 1,
  SINGLE = 2,
  RANDOM = 3
}