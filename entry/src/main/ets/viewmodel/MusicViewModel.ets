import { Song, MusicDataSource } from '../model/MusicData';
import { notificationManager } from '@kit.NotificationKit';
import { Constants } from '../common/Constants';

/**
 * 音乐播放状态更新回调类型
 */
export type MusicUpdateCallback = () => void;

/**
 * 音乐播放器视图模型
 * 管理播放状态、播放列表、歌词同步等
 * 
 * 注意：当前使用 setInterval 模拟播放
 * 真机可切换为 AVPlayer 实现真实音频播放
 * 
 * AVPlayer 使用示例：
 * import { media } from '@kit.MediaKit';
 * let avPlayer = await media.createAVPlayer();
 * await avPlayer.setSource('resource://RAWFILE/song1.mp3');
 * await avPlayer.prepare();
 * await avPlayer.play();
 * 
 * 媒体通知功能说明：
 * - 在后台播放时显示通知，锁屏状态下可见
 * - 提升用户体验，让用户知道当前播放状态
 * - 通知显示歌曲名、歌手名和播放状态
 */
export class MusicViewModel {
  /**
   * 当前播放歌曲
   */
  private _currentSong: Song | null = null;
  
  /**
   * 是否正在播放
   */
  private _isPlaying: boolean = false;
  
  /**
   * 当前播放时间（秒）
   */
  private _currentTime: number = 0;
  
  /**
   * 总时长（秒）
   */
  private _totalDuration: number = 0;
  
  /**
   * 当前歌词索引
   */
  private _currentLyricIndex: number = 0;
  
  /**
   * 播放列表
   */
  private _playlist: Song[] = [];
  
  /**
   * 当前播放索引
   */
  private _currentIndex: number = -1;
  
  /**
   * 播放定时器ID
   */
  private _playTimer: number = -1;
  
  /**
   * 状态更新回调
   */
  private _onUpdateCallback: MusicUpdateCallback | null = null;
  
  /**
   * 通知是否已启用
   */
  private _notificationEnabled: boolean = false;
  
  /**
   * 获取当前歌曲
   */
  get currentSong(): Song | null {
    return this._currentSong;
  }
  
  /**
   * 获取播放状态
   */
  get isPlaying(): boolean {
    return this._isPlaying;
  }
  
  /**
   * 获取当前播放时间
   */
  get currentTime(): number {
    return this._currentTime;
  }
  
  /**
   * 获取总时长
   */
  get totalDuration(): number {
    return this._totalDuration;
  }
  
  /**
   * 获取当前歌词索引
   */
  get currentLyricIndex(): number {
    return this._currentLyricIndex;
  }
  
  /**
   * 获取播放列表
   */
  get playlist(): Song[] {
    return this._playlist;
  }
  
  /**
   * 设置状态更新回调
   * @param callback 回调函数
   */
  setOnUpdateCallback(callback: MusicUpdateCallback): void {
    this._onUpdateCallback = callback;
  }
  
  /**
   * 触发状态更新回调
   */
  private notifyUpdate(): void {
    if (this._onUpdateCallback) {
      this._onUpdateCallback();
    }
  }
  
  /**
   * 检查并请求通知权限
   * 发送媒体通知前需要确保应用具有通知权限
   */
  private async checkNotificationPermission(): Promise<boolean> {
    try {
      // 检查通知是否已启用
      const isEnabled = await notificationManager.isNotificationEnabled();
      this._notificationEnabled = isEnabled;
      return isEnabled;
    } catch (error) {
      console.error('MusicViewModel: 检查通知权限失败', error);
      this._notificationEnabled = false;
      return false;
    }
  }
  
  /**
   * 发送或更新媒体通知
   * 媒体通知在锁屏时可见，提升用户体验
   * @param statusText 状态文本（如"正在后台播放"、"已暂停"）
   */
  private async updateNotification(statusText: string): Promise<void> {
    // 检查通知权限
    if (!this._notificationEnabled) {
      const hasPermission = await this.checkNotificationPermission();
      if (!hasPermission) {
        console.warn('MusicViewModel: 通知权限未开启，无法显示媒体通知');
        return;
      }
    }
    
    // 没有当前歌曲时不发送通知
    if (!this._currentSong) {
      return;
    }
    
    try {
      // 构建通知内容
      const notificationRequest: notificationManager.NotificationRequest = {
        id: Constants.MUSIC_NOTIFICATION_ID,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: this._currentSong.title,
            text: this._currentSong.artist,
            additionalText: statusText
          }
        },
        // 设置为持续通知，不会被自动清除
        isUnremovable: false,
        // 设置通知时间
        deliveryTime: new Date().getTime()
      };
      
      // 发布通知
      await notificationManager.publish(notificationRequest);
      console.info(`MusicViewModel: 媒体通知已更新 - ${this._currentSong.title} (${statusText})`);
    } catch (error) {
      console.error('MusicViewModel: 发送媒体通知失败', error);
    }
  }
  
  /**
   * 取消媒体通知
   * 在停止播放或销毁时调用
   */
  private async cancelNotification(): Promise<void> {
    try {
      await notificationManager.cancel(Constants.MUSIC_NOTIFICATION_ID);
      console.info('MusicViewModel: 媒体通知已取消');
    } catch (error) {
      console.error('MusicViewModel: 取消媒体通知失败', error);
    }
  }
  
  /**
   * 加载播放列表
   */
  loadPlaylist(): void {
    this._playlist = MusicDataSource.getLocalSongs();
    console.info(`MusicViewModel: 加载播放列表，共 ${this._playlist.length} 首歌曲`);
    
    if (this._playlist.length > 0) {
      this._currentIndex = 0;
      this._currentSong = this._playlist[0];
      this._totalDuration = this._currentSong.duration;
    }
    
    // 初始化时检查通知权限
    this.checkNotificationPermission();
    
    this.notifyUpdate();
  }
  
  /**
   * 选择指定歌曲播放
   * @param song 歌曲对象
   */
  selectSong(song: Song): void {
    // 停止当前播放
    this.stopTimer();
    
    // 设置新歌曲
    this._currentSong = song;
    this._currentIndex = this._playlist.findIndex((s: Song) => s.id === song.id);
    this._totalDuration = song.duration;
    this._currentTime = 0;
    this._currentLyricIndex = 0;
    this._isPlaying = false;
    
    console.info(`MusicViewModel: 选择歌曲 - ${song.title} (${song.artist})`);
    
    // 更新通知显示新歌曲
    this.updateNotification('已选择');
    
    this.notifyUpdate();
  }
  
  /**
   * 开始播放
   * 使用 setInterval 模拟播放进度
   * 真机可切换为 AVPlayer 实现
   */
  play(): void {
    if (!this._currentSong) {
      console.warn('MusicViewModel: 没有可播放的歌曲');
      return;
    }
    
    if (this._isPlaying) {
      console.info('MusicViewModel: 已经在播放中');
      return;
    }
    
    this._isPlaying = true;
    console.info(`MusicViewModel: 开始播放 - ${this._currentSong.title}`);
    
    // 发送媒体通知 - 正在后台播放
    this.updateNotification('正在后台播放');
    
    // 使用 setInterval 模拟播放进度
    // 真机可替换为 AVPlayer 的播放逻辑
    this._playTimer = setInterval(() => {
      this._currentTime += 1;
      
      // 更新歌词索引
      this.updateLyricIndex();
      
      // 检查是否播放完成
      if (this._currentTime >= this._totalDuration) {
        this.onSongComplete();
      }
      
      this.notifyUpdate();
    }, 1000);
    
    this.notifyUpdate();
  }
  
  /**
   * 暂停播放
   */
  pause(): void {
    if (!this._isPlaying) {
      return;
    }
    
    this.stopTimer();
    this._isPlaying = false;
    console.info(`MusicViewModel: 暂停播放 - 当前时间: ${this._currentTime}s`);
    
    // 更新通知 - 已暂停
    this.updateNotification('已暂停');
    
    this.notifyUpdate();
  }
  
  /**
   * 继续播放
   */
  resume(): void {
    if (this._isPlaying || !this._currentSong) {
      return;
    }
    
    console.info(`MusicViewModel: 继续播放 - 从 ${this._currentTime}s 开始`);
    this.play();
  }
  
  /**
   * 播放下一首
   */
  next(): void {
    if (this._playlist.length === 0) {
      return;
    }
    
    this.stopTimer();
    
    this._currentIndex = (this._currentIndex + 1) % this._playlist.length;
    const nextSong = this._playlist[this._currentIndex];
    
    this._currentSong = nextSong;
    this._totalDuration = nextSong.duration;
    this._currentTime = 0;
    this._currentLyricIndex = 0;
    this._isPlaying = false;
    
    console.info(`MusicViewModel: 下一首 - ${nextSong.title}`);
    
    // 更新通知显示新歌曲
    this.updateNotification('正在后台播放');
    
    this.notifyUpdate();
    
    // 自动开始播放
    this.play();
  }
  
  /**
   * 播放上一首
   */
  previous(): void {
    if (this._playlist.length === 0) {
      return;
    }
    
    this.stopTimer();
    
    this._currentIndex = (this._currentIndex - 1 + this._playlist.length) % this._playlist.length;
    const prevSong = this._playlist[this._currentIndex];
    
    this._currentSong = prevSong;
    this._totalDuration = prevSong.duration;
    this._currentTime = 0;
    this._currentLyricIndex = 0;
    this._isPlaying = false;
    
    console.info(`MusicViewModel: 上一首 - ${prevSong.title}`);
    
    // 更新通知显示新歌曲
    this.updateNotification('正在后台播放');
    
    this.notifyUpdate();
    
    // 自动开始播放
    this.play();
  }
  
  /**
   * 跳转到指定时间
   * @param time 目标时间（秒）
   */
  seekTo(time: number): void {
    if (!this._currentSong) {
      return;
    }
    
    // 限制在有效范围内
    this._currentTime = Math.max(0, Math.min(time, this._totalDuration));
    
    // 更新歌词索引
    this.updateLyricIndex();
    
    console.info(`MusicViewModel: 跳转到 ${this._currentTime}s`);
    this.notifyUpdate();
  }
  
  /**
   * 更新当前歌词索引
   */
  updateLyricIndex(): void {
    if (!this._currentSong || this._currentSong.lyricTimestamps.length === 0) {
      return;
    }
    
    this._currentLyricIndex = MusicDataSource.getCurrentLyricIndex(
      this._currentTime,
      this._currentSong.lyricTimestamps
    );
  }
  
  /**
   * 格式化时间显示（秒转为 mm:ss 格式）
   * @param seconds 秒数
   * @returns 格式化后的时间字符串
   */
  formatTime(seconds: number): string {
    return MusicDataSource.formatDuration(seconds);
  }
  
  /**
   * 获取格式化的当前时间
   */
  getFormattedCurrentTime(): string {
    return this.formatTime(this._currentTime);
  }
  
  /**
   * 获取格式化的总时长
   */
  getFormattedTotalDuration(): string {
    return this.formatTime(this._totalDuration);
  }
  
  /**
   * 获取当前歌词
   */
  getCurrentLyric(): string {
    if (!this._currentSong || this._currentSong.lyrics.length === 0) {
      return '';
    }
    
    const index = Math.min(this._currentLyricIndex, this._currentSong.lyrics.length - 1);
    return this._currentSong.lyrics[index];
  }
  
  /**
   * 获取播放进度百分比
   */
  getProgressPercent(): number {
    if (this._totalDuration === 0) {
      return 0;
    }
    return Math.min(100, (this._currentTime / this._totalDuration) * 100);
  }
  
  /**
   * 歌曲播放完成处理
   */
  private onSongComplete(): void {
    console.info(`MusicViewModel: 歌曲播放完成 - ${this._currentSong?.title}`);
    
    // 停止定时器
    this.stopTimer();
    this._isPlaying = false;
    
    // 自动播放下一首
    this.next();
  }
  
  /**
   * 停止播放定时器
   */
  private stopTimer(): void {
    if (this._playTimer !== -1) {
      clearInterval(this._playTimer);
      this._playTimer = -1;
    }
  }
  
  /**
   * 停止播放并取消通知
   */
  async stop(): Promise<void> {
    this.stopTimer();
    this._isPlaying = false;
    this._currentTime = 0;
    
    // 取消媒体通知
    await this.cancelNotification();
    
    console.info('MusicViewModel: 播放已停止');
    this.notifyUpdate();
  }
  
  /**
   * 销毁视图模型（释放资源）
   */
  async destroy(): Promise<void> {
    this.stopTimer();
    this._onUpdateCallback = null;
    
    // 取消媒体通知
    await this.cancelNotification();
    
    console.info('MusicViewModel: 资源已释放');
  }
}
