/**
 * 歌单详情（收藏 / 歌曲 / 评论）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { AudioManager } from '../../utils/AudioManager';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { FormatUtil } from '../../utils/FormatUtil';
import { AddCommentRequest, Comment, NavParams, PlaylistDetail, Song, TrackModel } from '../../types/common';
import { SongRow } from '../../components/SongRow';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';

@Entry
@Component
struct PlaylistDetailPage {
  @State playlist: PlaylistDetail | null = null;
  @State isLoading: boolean = true;
  @State activeTab: number = 0;
  @State isCollected: boolean = false;
  @State commentContent: string = '';
  @State errorMessage: string = '';

  private playlistId: number = 0;
  private audioManager: AudioManager = AudioManager.getInstance();
  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    const params = NavUtil.getParams() as NavParams;
    if (params && params.playlistId !== undefined) {
      this.playlistId = params.playlistId;
    }
    this.loadDetail();
  }

  private async loadDetail(): Promise<void> {
    if (this.playlistId <= 0) {
      this.isLoading = false;
      return;
    }
    try {
      const result = await ApiService.getPlaylistDetail(this.playlistId);
      if (result.code === 0 && result.data) {
        this.playlist = result.data;
        this.isCollected = result.data.isCollected;
      } else {
        this.errorMessage = result.message || '获取歌单详情失败';
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private toTrackModel(song: Song): TrackModel {
    const track: TrackModel = {
      id: song.songId.toString(),
      title: song.songName,
      artist: song.artistName,
      album: song.album,
      cover: song.coverUrl,
      url: song.audioUrl,
      duration: Number(song.duration) * 1000,
      likeStatus: song.likeStatus
    };
    return track;
  }

  private playAll(): void {
    if (!this.playlist || this.playlist.songs.length === 0) {
      return;
    }
    const tracks: TrackModel[] = [];
    this.playlist.songs.forEach((song: Song) => {
      tracks.push(this.toTrackModel(song));
    });
    this.audioManager.setTrackList(tracks, 0);
    this.audioManager.play(0);
    this.globalData.addRecentPlay(tracks[0]);
  }

  private playSong(song: Song, index: number): void {
    if (!this.playlist) {
      return;
    }
    const tracks: TrackModel[] = [];
    this.playlist.songs.forEach((item: Song) => {
      tracks.push(this.toTrackModel(item));
    });
    this.audioManager.setTrackList(tracks, index);
    this.audioManager.play(index);
    this.globalData.addRecentPlay(tracks[index]);
  }

  private toggleCollect(): void {
    if (!this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    if (this.isCollected) {
      ApiService.cancelCollectPlaylist(this.playlistId).then((result) => {
        if (result.code === 0) {
          this.isCollected = false;
        }
      });
    } else {
      ApiService.collectPlaylist(this.playlistId).then((result) => {
        if (result.code === 0) {
          this.isCollected = true;
        }
      });
    }
  }

  private async submitComment(): Promise<void> {
    if (!this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    const content = this.commentContent.trim();
    if (!content) {
      return;
    }
    try {
      const request: AddCommentRequest = {
        playlistId: this.playlistId,
        content: content
      };
      const result = await ApiService.addPlaylistComment(request);
      if (result.code === 0) {
        this.commentContent = '';
        await this.loadDetail();
      }
    } catch (error) {
      console.error('发布评论失败:', error);
    }
  }

  private likeComment(comment: Comment): void {
    if (!this.globalData.getIsLoggedIn()) {
      NavUtil.push('pages/Login/LoginPage');
      return;
    }
    ApiService.likeComment(comment.commentId).then((result) => {
      if (result.code === 0 && this.playlist) {
        const comments = this.playlist.comments;
        comments.forEach((item: Comment) => {
          if (item.commentId === comment.commentId) {
            item.likeCount++;
          }
        });
        this.refreshPlaylist();
      }
    });
  }

  private deleteComment(comment: Comment): void {
    ApiService.deleteComment(comment.commentId).then((result) => {
      if (result.code === 0) {
        this.loadDetail();
      }
    });
  }

  private refreshPlaylist(): void {
    const snapshot = this.playlist;
    this.playlist = null;
    this.playlist = snapshot;
  }

  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut })
      .opacity(0)
      .translate({ y: 24 })
    PageTransitionExit({ duration: 200, curve: Curve.EaseIn })
      .opacity(0)
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => NavUtil.back())
        Blank()
        Text('歌单详情')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Image($r('app.media.share'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (!this.playlist) {
        EmptyView({ message: '歌单加载失败', subMessage: this.errorMessage })
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            Row() {
              Image(this.playlist ? this.playlist.coverUrl : '')
                .width(120)
                .height(120)
                .borderRadius(ThemeUtil.getBorderRadius('lg'))
                .objectFit(ImageFit.Cover)
                .backgroundColor(ThemeUtil.getColor('surface'))
              Column() {
                Text(this.playlist ? this.playlist.title : '')
                  .fontSize(ThemeUtil.getFontSize('lg'))
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ThemeUtil.getColor('textPrimary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('by ShiHua Music')
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(ThemeUtil.getColor('textHint'))
                  .margin({ top: ThemeUtil.getSpacing('sm') })
                Text((this.playlist ? this.playlist.songs.length : 0).toString() + ' 首歌曲')
                  .fontSize(ThemeUtil.getFontSize('xs'))
                  .fontColor(ThemeUtil.getColor('textHint'))
                  .margin({ top: ThemeUtil.getSpacing('sm') })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: ThemeUtil.getSpacing('md') })
            }
            .width('100%')
            .padding(ThemeUtil.getSpacing('md'))

            if (this.playlist && this.playlist.introduction.length > 0) {
              Text(this.playlist.introduction)
                .fontSize(ThemeUtil.getFontSize('sm'))
                .fontColor(ThemeUtil.getColor('textSecondary'))
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), bottom: ThemeUtil.getSpacing('sm') })
            }

            Row() {
              Row() {
                Image($r('app.media.play'))
                  .width(18)
                  .height(18)
                  .margin({ right: 6 })
                Text('播放全部')
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(ThemeUtil.getColor('textPrimary'))
              }
              .height(40)
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
              .backgroundColor(ThemeUtil.getColor('surface'))
              .borderRadius(ThemeUtil.getBorderRadius('full'))
              .onClick(() => this.playAll())

              Row() {
                Image(this.isCollected ? $r('app.media.like_active') : $r('app.media.like'))
                  .width(18)
                  .height(18)
                  .margin({ right: 6 })
                Text(this.isCollected ? '已收藏' : '收藏')
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(this.isCollected ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textPrimary'))
              }
              .height(40)
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
              .backgroundColor(ThemeUtil.getColor('surface'))
              .borderRadius(ThemeUtil.getBorderRadius('full'))
              .margin({ left: ThemeUtil.getSpacing('md') })
              .onClick(() => this.toggleCollect())
            }
            .width('100%')
            .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
            .margin({ bottom: ThemeUtil.getSpacing('sm') })

            Row() {
              Text('歌曲 (' + (this.playlist ? this.playlist.songs.length : 0).toString() + ')')
                .fontSize(ThemeUtil.getFontSize('md'))
                .fontColor(this.activeTab === 0 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
                .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .onClick(() => this.activeTab = 0)
              Text('评论 (' + (this.playlist ? this.playlist.comments.length : 0).toString() + ')')
                .fontSize(ThemeUtil.getFontSize('md'))
                .fontColor(this.activeTab === 1 ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('textHint'))
                .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .onClick(() => this.activeTab = 1)
            }
            .width('100%')
            .height(48)
            .backgroundColor(ThemeUtil.getColor('surface'))

            if (this.activeTab === 0 && this.playlist) {
              ForEach(this.playlist.songs, (song: Song, index: number) => {
                SongRow({
                  song: song,
                  index: index,
                  onPlay: (item: Song, itemIndex: number) => this.playSong(item, itemIndex)
                })
              }, (song: Song) => song.songId.toString())
            }

            if (this.activeTab === 1 && this.playlist) {
              Column() {
                TextArea({ placeholder: '说点什么吧', text: this.commentContent })
                  .width('100%')
                  .height(80)
                  .backgroundColor(ThemeUtil.getColor('surface'))
                  .borderRadius(ThemeUtil.getBorderRadius('sm'))
                  .onChange((value: string) => {
                    this.commentContent = value;
                  })
                Button('发布')
                  .width(100)
                  .height(36)
                  .fontSize(ThemeUtil.getFontSize('sm'))
                  .fontColor(ThemeUtil.getColor('onPrimary'))
                  .backgroundColor(ThemeUtil.getColor('primary'))
                  .borderRadius(ThemeUtil.getBorderRadius('full'))
                  .margin({ top: ThemeUtil.getSpacing('sm') })
                  .enabled(this.commentContent.trim().length > 0)
                  .onClick(() => this.submitComment())

                ForEach(this.playlist.comments, (comment: Comment) => {
                  Row() {
                    Image(comment.userAvatar ? comment.userAvatar : $r('app.media.default_avatar'))
                      .width(36)
                      .height(36)
                      .borderRadius(ThemeUtil.getBorderRadius('full'))
                      .objectFit(ImageFit.Cover)
                      .margin({ right: ThemeUtil.getSpacing('sm') })
                    Column() {
                      Text(comment.username)
                        .fontSize(ThemeUtil.getFontSize('sm'))
                        .fontColor(ThemeUtil.getColor('primary'))
                      Text(comment.content)
                        .fontSize(ThemeUtil.getFontSize('sm'))
                        .fontColor(ThemeUtil.getColor('textPrimary'))
                        .margin({ top: 4 })
                      Row() {
                        Text(comment.createTime)
                          .fontSize(ThemeUtil.getFontSize('xs'))
                          .fontColor(ThemeUtil.getColor('textHint'))
                        Blank()
                        Text(comment.likeCount.toString())
                          .fontSize(ThemeUtil.getFontSize('xs'))
                          .fontColor(ThemeUtil.getColor('textHint'))
                          .onClick(() => this.likeComment(comment))
                        Text('删除')
                          .fontSize(ThemeUtil.getFontSize('xs'))
                          .fontColor(ThemeUtil.getColor('error'))
                          .margin({ left: ThemeUtil.getSpacing('md') })
                          .onClick(() => this.deleteComment(comment))
                      }
                      .width('100%')
                      .margin({ top: 4 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .padding(ThemeUtil.getSpacing('md'))
                }, (comment: Comment) => comment.commentId.toString())
              }
              .width('100%')
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
