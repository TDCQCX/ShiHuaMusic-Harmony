/**
 * API 服务层（对齐 music-client src/api/system.ts 全部接口）
 */
import { HttpUtil } from '../utils/HttpUtil';
import {
  ApiResult,
  Artist,
  ArtistDetail,
  ArtistQuery,
  Banner,
  FavoritePlaylist,
  PageData,
  PlaylistDetail,
  PlaylistQuery,
  RecommendedPlaylist,
  Song,
  SongDetail,
  SongQuery,
  SongUrlItem,
  UserInfo,
  LoginRequest,
  RegisterRequest,
  ResetPasswordRequest,
  UpdateUserInfoRequest,
  AddCommentRequest,
  FeedbackRequest
} from '../types/common';

export class ApiService {
  // ========== 用户 ==========
  static login(data: LoginRequest): Promise<ApiResult<string>> {
    return HttpUtil.post<string>('/user/login', data);
  }

  static logout(): Promise<ApiResult<object>> {
    return HttpUtil.post<object>('/user/logout');
  }

  static sendVerificationCode(email: string): Promise<ApiResult<object>> {
    return HttpUtil.get<object>('/user/sendVerificationCode?email=' + encodeURIComponent(email));
  }

  static register(data: RegisterRequest): Promise<ApiResult<object>> {
    return HttpUtil.post<object>('/user/register', data);
  }

  static resetPassword(data: ResetPasswordRequest): Promise<ApiResult<object>> {
    return HttpUtil.patch<object>('/user/resetUserPassword', data);
  }

  static getUserInfo(): Promise<ApiResult<UserInfo>> {
    return HttpUtil.get<UserInfo>('/user/getUserInfo');
  }

  static updateUserInfo(data: UpdateUserInfoRequest): Promise<ApiResult<object>> {
    return HttpUtil.put<object>('/user/updateUserInfo', data);
  }

  static deleteAccount(): Promise<ApiResult<object>> {
    return HttpUtil.delete<object>('/user/deleteAccount');
  }

  // ========== 内容 ==========
  static getBanner(): Promise<ApiResult<Banner[]>> {
    return HttpUtil.get<Banner[]>('/banner/getBannerList');
  }

  static getRecommendedPlaylists(): Promise<ApiResult<RecommendedPlaylist[]>> {
    return HttpUtil.get<RecommendedPlaylist[]>('/playlist/getRecommendedPlaylists');
  }

  static getRecommendedSongs(): Promise<ApiResult<Song[]>> {
    return HttpUtil.get<Song[]>('/song/getRecommendedSongs');
  }

  static getAllSongs(query: SongQuery): Promise<ApiResult<PageData<Song>>> {
    return HttpUtil.post<PageData<Song>>('/song/getAllSongs', query);
  }

  static getSongDetail(id: number): Promise<ApiResult<SongDetail>> {
    return HttpUtil.get<SongDetail>('/song/getSongDetail/' + id.toString());
  }

  static getAllArtists(query: ArtistQuery): Promise<ApiResult<PageData<Artist>>> {
    return HttpUtil.post<PageData<Artist>>('/artist/getAllArtists', query);
  }

  static getArtistDetail(id: number): Promise<ApiResult<ArtistDetail>> {
    return HttpUtil.get<ArtistDetail>('/artist/getArtistDetail/' + id.toString());
  }

  static getAllPlaylists(query: PlaylistQuery): Promise<ApiResult<PageData<RecommendedPlaylist>>> {
    return HttpUtil.post<PageData<RecommendedPlaylist>>('/playlist/getAllPlaylists', query);
  }

  static getPlaylistDetail(id: number): Promise<ApiResult<PlaylistDetail>> {
    return HttpUtil.get<PlaylistDetail>('/playlist/getPlaylistDetail/' + id.toString());
  }

  // ========== 收藏 ==========
  static getFavoriteSongs(query: SongQuery): Promise<ApiResult<PageData<Song>>> {
    return HttpUtil.post<PageData<Song>>('/favorite/getFavoriteSongs', query);
  }

  static collectSong(songId: number): Promise<ApiResult<object>> {
    return HttpUtil.post<object>('/favorite/collectSong?songId=' + songId.toString());
  }

  static cancelCollectSong(songId: number): Promise<ApiResult<object>> {
    return HttpUtil.delete<object>('/favorite/cancelCollectSong?songId=' + songId.toString());
  }

  static getFavoritePlaylists(): Promise<ApiResult<PageData<FavoritePlaylist>>> {
    const query = { pageNum: 1, pageSize: 50 } as PlaylistQuery;
    return HttpUtil.post<PageData<FavoritePlaylist>>('/favorite/getFavoritePlaylists', query);
  }

  static collectPlaylist(playlistId: number): Promise<ApiResult<object>> {
    return HttpUtil.post<object>('/favorite/collectPlaylist?playlistId=' + playlistId.toString());
  }

  static cancelCollectPlaylist(playlistId: number): Promise<ApiResult<object>> {
    return HttpUtil.delete<object>('/favorite/cancelCollectPlaylist?playlistId=' + playlistId.toString());
  }

  // ========== 评论 ==========
  static addSongComment(data: AddCommentRequest): Promise<ApiResult<object>> {
    return HttpUtil.post<object>('/comment/addSongComment', data);
  }

  static addPlaylistComment(data: AddCommentRequest): Promise<ApiResult<object>> {
    return HttpUtil.post<object>('/comment/addPlaylistComment', data);
  }

  static likeComment(commentId: number): Promise<ApiResult<object>> {
    return HttpUtil.patch<object>('/comment/likeComment/' + commentId.toString());
  }

  static cancelLikeComment(commentId: number): Promise<ApiResult<object>> {
    return HttpUtil.patch<object>('/comment/cancelLikeComment/' + commentId.toString());
  }

  static deleteComment(commentId: number): Promise<ApiResult<object>> {
    return HttpUtil.delete<object>('/comment/deleteComment/' + commentId.toString());
  }

  // ========== 反馈 ==========
  static addFeedback(data: FeedbackRequest): Promise<ApiResult<object>> {
    return HttpUtil.post<object>('/feedback/addFeedback?content=' + encodeURIComponent(data.content));
  }

  // ========== 播放 ==========
  static getSongUrl(id: string, quality: string): Promise<ApiResult<SongUrlItem[]>> {
    return HttpUtil.get<SongUrlItem[]>('song/url/v1?id=' + id + '&level=' + quality);
  }
}
