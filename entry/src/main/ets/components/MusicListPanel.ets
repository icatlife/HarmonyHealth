import { Song } from '../model/MusicData';
import { AppColors } from '../common/Constants';

/**
 * 音乐列表面板组件
 * 展示播放列表，支持选择歌曲
 */
@Component
export struct MusicListPanel {
  /**
   * 歌曲列表
   */
  @Prop playlist: Song[] = [];
  
  /**
   * 当前播放歌曲的ID
   */
  @Prop currentSongId: number = -1;
  
  /**
   * 歌曲选择回调
   */
  onSongSelect: (song: Song) => void = (song: Song) => {};
  
  /**
   * 组件构建
   */
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('播放列表')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        
        Blank()
        
        Text(`${this.playlist.length} 首`)
          .fontSize(14)
          .fontColor(AppColors.TEXT_TERTIARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      
      // 列表内容
      if (this.playlist.length === 0) {
        // 空状态
        Column({ space: 12 }) {
          Text('🎵')
            .fontSize(40)
            .opacity(0.5)
          
          Text('暂无音乐')
            .fontSize(16)
            .fontColor(AppColors.TEXT_TERTIARY)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        // 歌曲列表
        List({ space: 0 }) {
          ForEach(this.playlist, (song: Song, index: number) => {
            ListItem() {
              Row() {
                // 左侧：序号或播放图标
                if (song.id === this.currentSongId) {
                  Text('🔊')
                    .fontSize(18)
                    .width(44)
                    .textAlign(TextAlign.Center)
                } else {
                  Text(`${index + 1}`)
                    .fontSize(14)
                    .fontColor(AppColors.TEXT_TERTIARY)
                    .width(44)
                    .textAlign(TextAlign.Center)
                }
                
                // 中间：歌曲信息
                Column({ space: 4 }) {
                  Text(song.title)
                    .fontSize(16)
                    .fontWeight(song.id === this.currentSongId ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(song.id === this.currentSongId ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  
                  Text(song.artist)
                    .fontSize(12)
                    .fontColor(AppColors.TEXT_TERTIARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                
                // 右侧：时长
                Text(this.formatDuration(song.duration))
                  .fontSize(12)
                  .fontColor(AppColors.TEXT_TERTIARY)
                  .margin({ left: 12 })
              }
              .width('100%')
              .height(64)
              .padding({ left: 16, right: 16 })
              .backgroundColor(song.id === this.currentSongId ? '#E8F5EE' : 'transparent')
            }
            .onClick(() => {
              this.onSongSelect(song);
            })
          }, (song: Song) => `song_${song.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Auto)
        .divider({
          strokeWidth: 1,
          color: '#F0F0F0',
          startMargin: 60,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: 'rgba(126, 200, 160, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }
  
  /**
   * 格式化时长（秒转 mm:ss）
   */
  private formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    const minsStr = mins.toString().padStart(2, '0');
    const secsStr = secs.toString().padStart(2, '0');
    return `${minsStr}:${secsStr}`;
  }
}
