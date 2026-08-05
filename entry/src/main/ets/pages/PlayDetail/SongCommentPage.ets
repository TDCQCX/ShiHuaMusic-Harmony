/**
 * 歌曲评论（独立页面）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { GlobalDataManager } from '../../utils/GlobalDataManager';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { AddCommentRequest, Comment, NavParams } from '../../types/common';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';

@Entry
@Component
struct SongCommentPage {
  @State songId: number = 0;
  @State comments: Comment[] = [];
  @State commentContent: string = '';
  @State isLoading: boolean = true;

  private globalData: GlobalDataManager = GlobalDataManager.getInstance();

  aboutToAppear(): void {
    const params = NavUtil.getParams() as NavParams;
    if (params && params.songId !== undefined) {
      this.songId = params.songId;
    }
    this.loadComments();
  }

  private async loadComments(): Promise<void> {
    if (this.songId <= 0) {
      this.isLoading = false;
      return;
    }
    try {
      const result = await ApiService.getSongDetail(this.songId);
      if (result.code === 0 && result.data) {
        this.comments = result.data.comments;
      }
    } catch (error) {
      console.error('加载评论失败:', error);
    } finally {
      this.isLoading = false;
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
        songId: this.songId,
        content: content
      };
      const result = await ApiService.addSongComment(request);
      if (result.code === 0) {
        this.commentContent = '';
        await this.loadComments();
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
      if (result.code === 0) {
        this.loadComments();
      }
    });
  }

  private deleteComment(comment: Comment): void {
    ApiService.deleteComment(comment.commentId).then((result) => {
      if (result.code === 0) {
        this.loadComments();
      }
    });
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
        Text('歌曲评论')
          .fontSize(ThemeUtil.getFontSize('lg'))
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeUtil.getColor('textPrimary'))
        Blank()
        Text('')
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      .backgroundColor(ThemeUtil.getColor('surface'))

      Column() {
        TextArea({ placeholder: '说点什么吧', text: this.commentContent })
          .width('100%')
          .height(72)
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
      }
      .width('100%')
      .padding(ThemeUtil.getSpacing('md'))

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.comments.length === 0) {
        EmptyView({ message: '暂无评论', subMessage: '快来抢沙发吧~' })
          .layoutWeight(1)
      } else {
        List() {
          ForEach(this.comments, (comment: Comment) => {
            ListItem() {
              Row() {
                Image(comment.userAvatar ? comment.userAvatar : $r('app.media.default_avatar'))
                  .width(40)
                  .height(40)
                  .borderRadius(ThemeUtil.getBorderRadius('full'))
                  .objectFit(ImageFit.Cover)
                  .margin({ right: ThemeUtil.getSpacing('md') })
                Column() {
                  Row() {
                    Text(comment.username)
                      .fontSize(ThemeUtil.getFontSize('sm'))
                      .fontColor(ThemeUtil.getColor('primary'))
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
                  Text(comment.content)
                    .fontSize(ThemeUtil.getFontSize('sm'))
                    .fontColor(ThemeUtil.getColor('textPrimary'))
                    .margin({ top: 4 })
                  Text(comment.createTime)
                    .fontSize(ThemeUtil.getFontSize('xs'))
                    .fontColor(ThemeUtil.getColor('textHint'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(ThemeUtil.getSpacing('md'))
            }
          }, (comment: Comment) => comment.commentId.toString())
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 1, color: ThemeUtil.getColor('divider') })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }
}
