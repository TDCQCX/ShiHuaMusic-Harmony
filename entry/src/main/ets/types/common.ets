/**
 * 数据模型定义（对齐 music-client 后端契约）
 */

// 通用响应结构（对应 client Result / ResultTable）
export interface ApiResult<T> {
  code: number;
  message: string;
  data?: T;
}

// 分页数据结构（对应 client ResultTable.data）
export interface PageData<T> {
  items: T[];
  total: number;
  pageSize: number;
  currentPage: number;
}

// 用户信息（对应 client UserInfo）
export interface UserInfo {
  userId: number;
  username: string;
  phone: string;
  email: string;
  avatarUrl: string;
  userAvatar: string;
  introduction: string;
  token: string;
}

// 歌曲（对应 client Song）
export interface Song {
  songId: number;
  songName: string;
  artistName: string;
  album: string;
  duration: string;
  coverUrl: string;
  audioUrl: string;
  likeStatus: number;
  releaseTime: string;
}

// 歌曲详情（对应 client SongDetail）
export interface SongDetail {
  songId: number;
  songName: string;
  artistName: string;
  album: string;
  lyric: string;
  duration: string;
  coverUrl: string;
  audioUrl: string;
  releaseTime: string;
  likeStatus: number;
  comments: Comment[];
}

// 评论（对应 client Comment）
export interface Comment {
  commentId: number;
  username: string;
  userAvatar: string;
  content: string;
  createTime: string;
  likeCount: number;
}

// 歌单详情（对应 client PlaylistDetail）
export interface PlaylistDetail {
  playlistId: number;
  title: string;
  coverUrl: string;
  introduction: string;
  songs: Song[];
  likeStatus: number;
  comments: Comment[];
  isCollected: boolean;
}

// 歌手（列表项，对应 client 歌手列表条目）
export interface Artist {
  artistId: number;
  artistName: string;
  avatar: string;
}

// 歌手详情（对应 client ArtistDetail）
export interface ArtistDetail {
  artistId: number;
  artistName: string;
  avatar: string;
  birth: string;
  area: string;
  introduction: string;
  songs: Song[];
}

// 轮播图（对应 client banner 数据）
export interface Banner {
  bannerId: number;
  bannerUrl: string;
}

// 推荐歌单（首页/歌单页条目）
export interface RecommendedPlaylist {
  playlistId: number;
  title: string;
  coverUrl: string;
}

// 收藏的歌单（对应 client favoriteStore）
export interface FavoritePlaylist {
  id: number;
  name: string;
  coverImgUrl: string;
}

// 播放器内部歌曲模型（对应 client trackModel）
export interface TrackModel {
  id: string;
  title: string;
  artist: string;
  album: string;
  cover: string;
  url: string;
  duration: number;
  likeStatus: number;
}

// 播放地址项（song/url/v1 返回）
export interface SongUrlItem {
  url: string;
}

// ========== 请求体 ==========
export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  verificationCode: string;
}

export interface ResetPasswordRequest {
  email: string;
  verificationCode: string;
  newPassword: string;
  repeatPassword: string;
}

export interface UpdateUserInfoRequest {
  userId: number;
  username: string;
  phone: string;
  email: string;
  introduction: string;
}

export interface AddCommentRequest {
  playlistId?: number;
  songId?: number;
  content: string;
}

export interface FeedbackRequest {
  content: string;
}

// ========== 查询条件 ==========
export interface PageQuery {
  pageNum: number;
  pageSize: number;
}

export interface SongQuery extends PageQuery {
  songName?: string;
  artistName?: string;
  album?: string;
}

export interface ArtistQuery extends PageQuery {
  name?: string;
  gender?: number;
  area?: string;
}

export interface PlaylistQuery extends PageQuery {
  title?: string;
  style?: string;
}

// ========== 网络请求配置 ==========
export interface RequestConfig {
  url: string;
  method: string;
  params?: Record<string, string>;
  data?: object;
  headers?: Record<string, string>;
  timeout?: number;
}

// 页面导航参数
export interface NavParams {
  playlistId?: number;
  artistId?: number;
  songId?: number;
  playlistName?: string;
  rankType?: string;
}

// ========== 播放器状态 ==========
export enum PlayMode {
  ORDER = 0,
  SHUFFLE = 1,
  LOOP = 2,
  SINGLE = 3
}

export enum PlayerState {
  IDLE = 0,
  PLAYING = 1,
  PAUSED = 2,
  STOPPED = 3,
  COMPLETED = 4,
  ERROR = 5
}

// 通用工具：判断是否成功响应
export function isSuccess(code: number): boolean {
  return code === 0;
}
