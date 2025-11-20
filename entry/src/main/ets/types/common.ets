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

// 路由配置接口
export interface RouteConfig {
  name: string;
  page: string;
}

// 位置接口
export interface Position {
  x: string | number;
  y: string | number;
}

// 边框配置接口
export interface BorderConfig {
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
}

// 文本溢出配置接口
export interface TextOverflowConfig {
  overflow: TextOverflow;
}

// 分隔线配置接口
export interface DividerConfig {
  strokeWidth: number;
  color: string | Resource;
}

// 弹性布局配置接口
export interface FlexConfig {
  space: string | number;
}

// 文本输入配置接口
export interface TextInputConfig {
  placeholder: string;
}

// Swiper指示器配置接口
export interface IndicatorConfig {
  color: string | Resource;
}

// 搜索推荐项接口
export interface SearchSuggestion {
  first: string;
  second: string;
}

// 弹性项目配置接口
export interface FlexItemConfig {
  space: string | number;
}

// 边距配置接口
export interface MarginConfig {
  left?: string | number;
  right?: string | number;
  top?: string | number;
  bottom?: string | number;
}

// 内边距配置接口
export interface PaddingConfig {
  left?: string | number;
  right?: string | number;
  top?: string | number;
  bottom?: string | number;
}

// 统一边距内边距接口
export interface SpacingConfig extends MarginConfig, PaddingConfig {}

// 请求统计数据接口
export interface RequestStats {
  success: number;
  failed: number;
  total: number;
}

// 登录响应接口
export interface LoginResponse {
  token: string;
  userInfo: UserInfo;
}

// 注册数据接口
export interface RegisterData {
  phone?: string;
  email?: string;
  password: string;
  nickname: string;
  captcha?: string;
}