import { router } from '@kit.ArkUI';
import { Song } from '../model/MusicData';
import { MusicViewModel } from '../viewmodel/MusicViewModel';
import { AppColors } from '../common/Constants';
import { MusicControlPanel } from '../components/MusicControlPanel';
import { MusicListPanel } from '../components/MusicListPanel';
import { LyricsDisplay } from '../components/LyricsDisplay';
import { common } from '@kit.AbilityKit';

/**
 * 音乐播放器页面
 * 包含播放控制和播放列表两个标签页
 */
@Entry
@Component
struct MusicPlayerPage {
  /**
   * 视图模型
   */
  private viewModel: MusicViewModel = new MusicViewModel();
  
  /**
   * 当前歌曲
   */
  @State private currentSong: Song | null = null;
  
  /**
   * 播放状态
   */
  @State private isPlaying: boolean = false;
  
  /**
   * 当前播放时间
   */
  @State private currentTime: number = 0;
  
  /**
   * 总时长
   */
  @State private totalDuration: number = 0;
  
  /**
   * 当前歌词索引
   */
  @State private currentLyricIndex: number = 0;
  
  /**
   * 播放列表
   */
  @State private playlist: Song[] = [];
  
  /**
   * 当前标签索引
   */
  @State private currentTabIndex: number = 0;
  
  /**
   * 页面即将显示
   */
  async aboutToAppear(): Promise<void> {
    // 获取应用上下文
    const context = getContext(this) as common.UIAbilityContext;
    
    // 设置状态更新回调
    this.viewModel.setOnUpdateCallback(() => {
      this.updateState();
    });
    
    // 加载播放列表（传入 context 以解析 LRC 歌词文件）
    this.viewModel.loadPlaylist(context);
    
    // 初始化 AVPlayer（用于真实音频播放）
    try {
      await this.viewModel.initAVPlayer(context);
      console.info('MusicPlayerPage: AVPlayer 初始化成功');
    } catch (error) {
      console.error('MusicPlayerPage: AVPlayer 初始化失败', error);
    }
    
    // 初始化状态
    this.updateState();
  }
  
  /**
   * 页面即将消失
   * 注意：不调用 pause()，保持后台播放
   * 只释放页面级资源，不停止播放
   */
  aboutToDisappear(): void {
    // 只清除回调，不停止播放
    this.viewModel.setOnUpdateCallback(null);
    // 注意：不调用 destroy()，保持后台播放能力
  }
  
  /**
   * 更新页面状态
   */
  private updateState(): void {
    this.currentSong = this.viewModel.currentSong;
    this.isPlaying = this.viewModel.isPlaying;
    this.currentTime = this.viewModel.currentTime;
    this.totalDuration = this.viewModel.totalDuration;
    this.currentLyricIndex = this.viewModel.currentLyricIndex;
    this.playlist = this.viewModel.playlist;
    
    // 调试日志：输出当前歌曲和歌词信息
    console.info(`MusicPlayerPage: updateState - 当前歌曲: ${this.currentSong?.title ?? '无'}`);
    if (this.currentSong?.lyrics) {
      const lyricCount = this.currentSong.lyrics.length;
      console.info(`MusicPlayerPage: updateState - 歌词行数: ${lyricCount}`);
      const previewLines = Math.min(3, lyricCount);
      for (let i = 0; i < previewLines; i++) {
        console.info(`MusicPlayerPage: updateState - 歌词[${i}]: "${this.currentSong.lyrics[i]}"`);
      }
    } else {
      console.info('MusicPlayerPage: updateState - 无歌词数据');
    }
  }
  
  /**
   * 播放/暂停切换
   */
  private handlePlayPause(): void {
    if (this.isPlaying) {
      this.viewModel.pause();
    } else {
      this.viewModel.play();
    }
  }
  
  /**
   * 下一首
   */
  private handleNext(): void {
    this.viewModel.next();
  }
  
  /**
   * 上一首
   */
  private handlePrevious(): void {
    this.viewModel.previous();
  }
  
  /**
   * 跳转
   */
  private handleSeek(time: number): void {
    this.viewModel.seekTo(time);
  }
  
  /**
   * 选择歌曲
   */
  private async handleSongSelect(song: Song): Promise<void> {
    console.info(`MusicPlayerPage: handleSongSelect - 选择歌曲: ${song.title}, 歌词行数: ${song.lyrics.length}`);
    if (song.lyrics.length > 0) {
      console.info(`MusicPlayerPage: handleSongSelect - 歌词预览: "${song.lyrics[0]}"`);
    }
    
    // 先切换歌曲
    await this.viewModel.selectSong(song);
    
    // 切换到播放标签
    this.currentTabIndex = 0;
    
    // 自动播放
    await this.viewModel.play();
  }
  
  /**
   * 页面构建
   */
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 返回按钮
        Column() {
          Text('←')
            .fontSize(24)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          router.back();
        })
        
        // 标题
        Text('🎵 运动音乐')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
          .layoutWeight(1)
        
        // 占位
        Column()
          .width(44)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      
      // Tabs 组件
      Tabs({ index: this.currentTabIndex }) {
        // 正在播放标签
        TabContent() {
          Column({ space: 20 }) {
            // 音乐控制面板
            MusicControlPanel({
              songTitle: this.currentSong?.title ?? '',
              songArtist: this.currentSong?.artist ?? '',
              coverColor: this.currentSong?.coverColor ?? AppColors.PRIMARY,
              coverImage: this.currentSong?.coverImage,
              isPlaying: this.isPlaying,
              currentTime: this.currentTime,
              totalDuration: this.totalDuration,
              onPlayPause: () => {
                this.handlePlayPause();
              },
              onNext: () => {
                this.handleNext();
              },
              onPrevious: () => {
                this.handlePrevious();
              },
              onSeek: (time: number) => {
                this.handleSeek(time);
              }
            })
            
            // 歌词显示
            LyricsDisplay({
              lyrics: this.currentSong?.lyrics ?? [],
              currentIndex: this.currentLyricIndex,
              timestamps: this.currentSong?.lyricTimestamps ?? []
            })
              .layoutWeight(1)
          }
          .width('100%')
          .height('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        }
        .tabBar('正在播放')
        
        // 音乐列表标签
        TabContent() {
          Column() {
            MusicListPanel({
              playlist: this.playlist,
              currentSongId: this.currentSong?.id ?? -1,
              onSongSelect: (song: Song) => {
                this.handleSongSelect(song);
              }
            })
          }
          .width('100%')
          .height('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        }
        .tabBar('音乐列表')
      }
      .width('100%')
      .layoutWeight(1)
      .barMode(BarMode.Fixed)
      .barPosition(BarPosition.Start)
      .animationDuration(300)
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
      .barBackgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}
