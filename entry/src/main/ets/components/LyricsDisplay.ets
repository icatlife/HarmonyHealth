import { AppColors } from '../common/Constants';

/**
 * 歌词显示组件
 * 用于展示歌词列表，当前行高亮并自动滚动到中央
 * 支持平滑动画过渡效果
 */
@Component
export struct LyricsDisplay {
  /**
   * 歌词行数组
   */
  @Prop lyrics: string[] = [];
  
  /**
   * 当前高亮的歌词行索引（使用 @Watch 监听变化）
   */
  @Prop @Watch('onCurrentIndexChanged') currentIndex: number = 0;
  
  /**
   * 列表滚动控制器
   */
  private scroller: Scroller = new Scroller();
  
  /**
   * 组件构建
   */
  build() {
    Column() {
      if (this.lyrics.length === 0) {
        // 空歌词提示
        Column({ space: 12 }) {
          Text('🎵')
            .fontSize(48)
            .opacity(0.5)
          
          Text('暂无歌词')
            .fontSize(16)
            .fontColor(AppColors.TEXT_TERTIARY)
        }
      } else {
        // 歌词列表
        List({ scroller: this.scroller, space: 16 }) {
          ForEach(this.lyrics, (lyric: string, index: number) => {
            ListItem() {
              Text(lyric)
                .fontSize(index === this.currentIndex ? 18 : 14)
                .fontWeight(index === this.currentIndex ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(index === this.currentIndex ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
                .opacity(this.getLineOpacity(index))
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .animation({
                  duration: 300,
                  curve: Curve.EaseOut
                })
            }
            .height(40)
          }, (lyric: string, index: number) => `lyric_${index}`)
        }
        .width('100%')
        .height('100%')
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Off)
        .alignListItem(ListItemAlign.Center)
        .onAppear(() => {
          // 组件出现时滚动到当前行
          this.scrollToCurrentIndex();
        })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  /**
   * 监听 currentIndex 变化
   */
  onCurrentIndexChanged(): void {
    this.scrollToCurrentIndex();
  }
  
  /**
   * 获取行透明度（当前行及附近行较亮，远处较暗）
   */
  private getLineOpacity(index: number): number {
    const distance = Math.abs(index - this.currentIndex);
    
    if (distance === 0) {
      return 1.0; // 当前行完全不透明
    } else if (distance === 1) {
      return 0.7; // 相邻行
    } else if (distance === 2) {
      return 0.5; // 次相邻行
    } else {
      return 0.3; // 远处行
    }
  }
  
  /**
   * 滚动到当前索引（居中显示）
   */
  private scrollToCurrentIndex(): void {
    if (this.lyrics.length === 0 || this.currentIndex < 0) {
      return;
    }
    
    // 确保索引在有效范围内
    const safeIndex = Math.min(this.currentIndex, this.lyrics.length - 1);
    
    // 使用 animateTo 实现平滑滚动
    animateTo({
      duration: 400,
      curve: Curve.EaseOut
    }, () => {
      this.scroller.scrollToIndex(safeIndex, true, ScrollAlign.CENTER);
    });
  }
}
