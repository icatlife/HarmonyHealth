import { AppColors } from '../common/Constants';

/**
 * 音乐控制面板组件
 * 包含歌曲信息、封面、进度条、控制按钮
 */
@Component
export struct MusicControlPanel {
  /**
   * 歌曲名
   */
  @Prop songTitle: string = '';
  
  /**
   * 歌手名
   */
  @Prop songArtist: string = '';
  
  /**
   * 封面占位色值
   */
  @Prop coverColor: string = AppColors.PRIMARY;
  
  /**
   * 是否正在播放
   */
  @Prop isPlaying: boolean = false;
  
  /**
   * 当前播放时间（秒）
   */
  @Prop currentTime: number = 0;
  
  /**
   * 总时长（秒）
   */
  @Prop totalDuration: number = 0;
  
  /**
   * 播放/暂停回调
   */
  onPlayPause: () => void = () => {};
  
  /**
   * 下一首回调
   */
  onNext: () => void = () => {};
  
  /**
   * 上一首回调
   */
  onPrevious: () => void = () => {};
  
  /**
   * 跳转回调
   */
  onSeek: (time: number) => void = (time: number) => {};
  
  /**
   * 组件构建
   */
  build() {
    Column({ space: 24 }) {
      // 歌曲信息区
      Column({ space: 8 }) {
        Text(this.songTitle || '未知歌曲')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(this.songArtist || '未知歌手')
          .fontSize(14)
          .fontColor(AppColors.TEXT_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      
      // 封面占位区
      Column() {
        Text('🎵')
          .fontSize(48)
      }
      .width(140)
      .height(140)
      .borderRadius(70)
      .backgroundColor(this.coverColor)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({
        radius: 16,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 8
      })
      
      // 进度条区
      Column({ space: 8 }) {
        // 进度条滑块
        Slider({
          value: this.currentTime,
          min: 0,
          max: Math.max(this.totalDuration, 1),
          step: 1
        })
          .width('100%')
          .height(6)
          .blockSize({ width: 16, height: 16 })
          .blockColor(AppColors.PRIMARY)
          .trackColor('#E8E8E8')
          .selectedColor(AppColors.PRIMARY)
          .showSteps(false)
          .showTips(false)
          .onChange((value: number) => {
            this.onSeek(Math.floor(value));
          })
        
        // 时间显示
        Row() {
          Text(this.formatTime(this.currentTime))
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
          
          Blank()
          
          Text(this.formatTime(this.totalDuration))
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
        }
        .width('100%')
      }
      .width('100%')
      
      // 控制按钮区
      Row({ space: 32 }) {
        // 上一首按钮
        Column() {
          Text('⏮️')
            .fontSize(24)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(AppColors.PRIMARY_LIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.onPrevious();
        })
        
        // 播放/暂停按钮
        Column() {
          Text(this.isPlaying ? '⏸️' : '▶️')
            .fontSize(24)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(AppColors.PRIMARY_LIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.onPlayPause();
        })
        
        // 下一首按钮
        Column() {
          Text('⏭️')
            .fontSize(24)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(AppColors.PRIMARY_LIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.onNext();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: 'rgba(126, 200, 160, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
  }
  
  /**
   * 格式化时间（秒转 mm:ss）
   */
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    const minsStr = mins.toString().padStart(2, '0');
    const secsStr = secs.toString().padStart(2, '0');
    return `${minsStr}:${secsStr}`;
  }
}
