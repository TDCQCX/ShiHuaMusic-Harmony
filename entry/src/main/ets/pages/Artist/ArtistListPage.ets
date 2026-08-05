/**
 * 歌手列表（性别/地区筛选 + 搜索 + 网格）
 */
import { NavUtil } from '../../utils/NavUtil';
import { ApiService } from '../../api/ApiService';
import { ThemeUtil } from '../../utils/ThemeUtil';
import { Artist, ArtistQuery } from '../../types/common';
import { BottomPlayer } from '../../components/BottomPlayer';
import { LoadingView } from '../../components/common/LoadingView';
import { EmptyView } from '../../components/common/EmptyView';

interface FilterOption {
  label: string;
  value: string;
}

@Entry
@Component
struct ArtistListPage {
  @State artists: Artist[] = [];
  @State searchKeyword: string = '';
  @State selectedGender: string = '-1';
  @State selectedArea: string = '-1';
  @State isLoading: boolean = true;
  @State loadingMore: boolean = false;
  @State total: number = 0;

  private currentPage: number = 1;
  private readonly pageSize: number = 20;
  private genderOptions: FilterOption[] = [
    { label: '全部', value: '-1' },
    { label: '男歌手', value: '0' },
    { label: '女歌手', value: '1' },
    { label: '组合/乐队', value: '2' }
  ];
  private areaOptions: FilterOption[] = [
    { label: '全部', value: '-1' },
    { label: '中国', value: '中国' },
    { label: '美国', value: '美国' },
    { label: '韩国', value: '韩国' },
    { label: '日本', value: '日本' }
  ];

  aboutToAppear(): void {
    this.loadArtists(true);
  }

  private buildQuery(pageNum: number): ArtistQuery {
    const query: ArtistQuery = {
      pageNum: pageNum,
      pageSize: this.pageSize,
      name: this.searchKeyword ? this.searchKeyword : undefined,
      gender: this.selectedGender === '-1' ? undefined : Number(this.selectedGender),
      area: this.selectedArea === '-1' ? undefined : this.selectedArea
    };
    return query;
  }

  private async loadArtists(reset: boolean): Promise<void> {
    if (reset) {
      this.isLoading = true;
      this.currentPage = 1;
    } else {
      this.loadingMore = true;
    }
    try {
      const result = await ApiService.getAllArtists(this.buildQuery(this.currentPage));
      if (result.code === 0 && result.data) {
        this.total = result.data.total;
        if (reset) {
          this.artists = result.data.items;
        } else {
          const merged = this.artists.concat(result.data.items);
          this.artists = merged;
        }
        if (result.data.items.length === this.pageSize) {
          this.currentPage++;
        }
      }
    } catch (error) {
      console.error('加载歌手列表失败:', error);
    } finally {
      this.isLoading = false;
      this.loadingMore = false;
    }
  }

  private onFilterChange(): void {
    this.loadArtists(true);
  }

  private goToDetail(artist: Artist): void {
    NavUtil.push('pages/Artist/ArtistDetailPage', { artistId: artist.artistId });
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
        Text('歌手')
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

      Row() {
        Image($r('app.media.search'))
          .width(16)
          .height(16)
          .margin({ left: 12 })
        TextInput({ placeholder: '搜索歌手', text: this.searchKeyword })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontSize(ThemeUtil.getFontSize('sm'))
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit(() => this.onFilterChange())
        if (this.searchKeyword.length > 0) {
          Image($r('app.media.clear'))
            .width(16)
            .height(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.searchKeyword = '';
              this.onFilterChange();
            })
        }
      }
      .width('100%')
      .height(44)
      .backgroundColor(ThemeUtil.getColor('surface'))

      Scroll() {
        Column() {
          this.buildFilterRow('歌手类型', this.genderOptions, this.selectedGender, (value: string) => {
            this.selectedGender = value;
            this.onFilterChange();
          })
          this.buildFilterRow('地区类型', this.areaOptions, this.selectedArea, (value: string) => {
            this.selectedArea = value;
            this.onFilterChange();
          })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .height(140)
      .backgroundColor(ThemeUtil.getColor('surface'))
      .margin({ bottom: ThemeUtil.getSpacing('sm') })

      if (this.isLoading) {
        LoadingView()
          .layoutWeight(1)
      } else if (this.artists.length === 0) {
        EmptyView({ message: '暂无歌手', subMessage: '试试其他筛选条件' })
          .layoutWeight(1)
      } else {
        Grid() {
          ForEach(this.artists, (artist: Artist) => {
            GridItem() {
              Column() {
                Image(artist.avatar ? artist.avatar : $r('app.media.default_avatar'))
                  .width(80)
                  .height(80)
                  .borderRadius(ThemeUtil.getBorderRadius('full'))
                  .objectFit(ImageFit.Cover)
                  .backgroundColor(ThemeUtil.getColor('surface'))
                Text(artist.artistName)
                  .fontSize(ThemeUtil.getFontSize('xs'))
                  .fontColor(ThemeUtil.getColor('textPrimary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: ThemeUtil.getSpacing('xs') })
              }
              .width('100%')
              .onClick(() => this.goToDetail(artist))
            }
          }, (artist: Artist) => artist.artistId.toString())
        }
        .layoutWeight(1)
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(ThemeUtil.getSpacing('md'))
        .rowsGap(ThemeUtil.getSpacing('lg'))
        .padding(ThemeUtil.getSpacing('md'))
        .scrollBar(BarState.Off)
        .onReachEnd(() => {
          if (!this.isLoading && !this.loadingMore && this.artists.length < this.total) {
            this.loadArtists(false);
          }
        })
        .padding({ bottom: 80 })
      }

      if (this.loadingMore) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color(ThemeUtil.getColor('primary'))
          .margin({ top: 8, bottom: 8 })
      }

      BottomPlayer()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.getColor('background'))
  }

  @Builder
  private buildFilterRow(title: string, options: FilterOption[], selected: string, onSelect: (value: string) => void) {
    Column() {
      Text(title)
        .fontSize(ThemeUtil.getFontSize('sm'))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.getColor('textPrimary'))
        .width('100%')
        .padding({ left: ThemeUtil.getSpacing('md') })
        .margin({ bottom: ThemeUtil.getSpacing('xs') })
      Scroll() {
        Row() {
          ForEach(options, (option: FilterOption) => {
            Text(option.label)
              .fontSize(ThemeUtil.getFontSize('xs'))
              .fontColor(selected === option.value ? ThemeUtil.getColor('onPrimary') : ThemeUtil.getColor('textSecondary'))
              .backgroundColor(selected === option.value ? ThemeUtil.getColor('primary') : ThemeUtil.getColor('background'))
              .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md'), top: 6, bottom: 6 })
              .borderRadius(ThemeUtil.getBorderRadius('full'))
              .margin({ right: ThemeUtil.getSpacing('sm') })
              .onClick(() => onSelect(option.value))
          }, (option: FilterOption) => option.value)
        }
        .padding({ left: ThemeUtil.getSpacing('md'), right: ThemeUtil.getSpacing('md') })
      }
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: ThemeUtil.getSpacing('sm') })
  }
}
