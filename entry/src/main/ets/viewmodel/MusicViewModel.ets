import { Song, MusicDataSource } from '../model/MusicData';
import { notificationManager } from '@kit.NotificationKit';
import { Constants } from '../common/Constants';
import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

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
   * AVPlayer 实例（用于真实音频播放）
   */
  private avPlayer: media.AVPlayer | null = null;
  
  /**
   * 应用上下文（用于获取资源文件）
   */
  private context: common.UIAbilityContext | null = null;
  
  /**
   * AVPlayer 当前状态
   */
  private playerState: string = 'idle';
  
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
   * @param callback 回调函数，可传入 null 清除回调
   */
  setOnUpdateCallback(callback: MusicUpdateCallback | null): void {
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
   * 初始化 AVPlayer
   * @param context 应用上下文
   */
  async initAVPlayer(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    
    try {
      // 创建 AVPlayer 实例
      this.avPlayer = await media.createAVPlayer();
      console.info('MusicViewModel: AVPlayer 创建成功');
      
      // 设置状态变化监听
      this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
        this.playerState = state;
        console.info(`MusicViewModel: AVPlayer 状态变化 - ${state}, reason: ${reason}`);
        
        switch (state) {
          case 'initialized':
            // 设置音频源后触发该状态，需要调用 prepare()
            console.info('MusicViewModel: AVPlayer 已初始化，准备播放');
            if (this.avPlayer) {
              await this.avPlayer.prepare();
            }
            break;
          case 'prepared':
            // 准备完成，可以获取时长，自动开始播放
            if (this.avPlayer) {
              this._totalDuration = Math.floor(this.avPlayer.duration / 1000); // 转换为秒
              console.info(`MusicViewModel: 音频时长 - ${this._totalDuration}秒`);
              // 自动开始播放
              await this.avPlayer.play();
              this._isPlaying = true;
              this.updateNotification('正在后台播放');
              this.notifyUpdate();
            }
            break;
          case 'playing':
            this._isPlaying = true;
            this.updateNotification('正在后台播放');
            this.notifyUpdate();
            break;
          case 'paused':
          case 'stopped':
            this._isPlaying = false;
            this.updateNotification('已暂停');
            this.notifyUpdate();
            break;
          case 'completed':
            // 播放完成，自动播放下一首
            this._isPlaying = false;
            this.onSongComplete();
            break;
          case 'error':
            console.error('MusicViewModel: AVPlayer 进入错误状态');
            this._isPlaying = false;
            this.notifyUpdate();
            break;
        }
      });
      
      // 设置错误监听
      this.avPlayer.on('error', (err: BusinessError) => {
        console.error(`MusicViewModel: AVPlayer 错误 - code: ${err.code}, message: ${err.message}`);
        this._isPlaying = false;
        this.notifyUpdate();
      });
      
      // 设置时间更新监听（用于更新播放进度和歌词）
      this.avPlayer.on('timeUpdate', (time: number) => {
        // time 是毫秒，转换为秒
        this._currentTime = Math.floor(time / 1000);
        this.updateLyricIndex();
        this.notifyUpdate();
      });
      
    } catch (error) {
      console.error('MusicViewModel: AVPlayer 初始化失败', error);
    }
  }
  
  /**
   * 加载播放列表
   * @param context 应用上下文（用于读取 LRC 歌词文件）
   */
  loadPlaylist(context?: common.UIAbilityContext): void {
    this._playlist = MusicDataSource.getLocalSongs(context);
    console.info(`MusicViewModel: 加载播放列表，共 ${this._playlist.length} 首歌曲`);
    
    if (this._playlist.length > 0) {
      this._currentIndex = 0;
      this._currentSong = this._playlist[0];
      this._totalDuration = this._currentSong.duration;
      
      // 输出第一首歌的歌词信息用于调试
      if (this._currentSong.lyrics.length > 0) {
        console.info(`MusicViewModel: 第一首歌曲词行数: ${this._currentSong.lyrics.length}`);
        console.info(`MusicViewModel: 第一首歌曲词预览: "${this._currentSong.lyrics[0]}"`);
      }
    }
    
    // 初始化时检查通知权限
    this.checkNotificationPermission();
    
    this.notifyUpdate();
  }
  
  /**
   * 选择指定歌曲播放
   * @param song 歌曲对象
   */
  async selectSong(song: Song): Promise<void> {
    // 停止当前播放
    this.stopTimer();
    
    // 重置 AVPlayer 状态，以便加载新的音频源
    if (this.avPlayer) {
      try {
        console.info(`MusicViewModel: 重置 AVPlayer，当前状态: ${this.playerState}`);
        
        // 根据当前状态进行重置
        if (this.playerState === 'playing' || this.playerState === 'paused') {
          // playing/paused -> stop -> reset -> idle
          await this.avPlayer.stop();
          await this.avPlayer.reset();
          console.info('MusicViewModel: AVPlayer 已从 playing/paused 重置到 idle 状态');
        } else if (this.playerState === 'prepared' || this.playerState === 'completed' || 
                   this.playerState === 'stopped') {
          // prepared/completed/stopped -> reset -> idle
          await this.avPlayer.reset();
          console.info('MusicViewModel: AVPlayer 已从 prepared/completed/stopped 重置到 idle 状态');
        } else if (this.playerState === 'initialized') {
          // initialized 状态下，reset() 可能不可用，直接设置新的音频源即可
          console.info('MusicViewModel: AVPlayer 处于 initialized 状态，将直接设置新的音频源');
        }
        // idle 状态不需要重置
      } catch (error) {
        console.error('MusicViewModel: 重置 AVPlayer 失败', error);
      }
    }
    
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
   * 使用 AVPlayer 实现真实音频播放
   */
  async play(): Promise<void> {
    if (!this._currentSong) {
      console.warn('MusicViewModel: 没有可播放的歌曲');
      return;
    }
    
    if (this._isPlaying) {
      console.info('MusicViewModel: 已经在播放中');
      return;
    }
    
    // 如果 AVPlayer 未初始化或已释放，无法播放
    if (!this.avPlayer || !this.context) {
      console.error('MusicViewModel: AVPlayer 未初始化');
      return;
    }
    
    try {
      console.info(`MusicViewModel: 开始播放 - ${this._currentSong.title}, 当前状态: ${this.playerState}`);
      
      // 根据 AVPlayer 当前状态执行不同操作
      switch (this.playerState) {
        case 'idle':
        case 'stopped':
          // 需要加载新的音频资源
          await this.loadAudioSource();
          break;
        case 'initialized':
          // 已设置音频源，需要准备
          await this.avPlayer.prepare();
          break;
        case 'prepared':
        case 'paused':
        case 'completed':
          // 直接开始播放或继续播放
          await this.avPlayer.play();
          this._isPlaying = true;
          this.updateNotification('正在后台播放');
          this.notifyUpdate();
          break;
        default:
          console.warn(`MusicViewModel: 未处理的播放状态 - ${this.playerState}`);
          // 尝试根据状态重置后重新播放
          try {
            if (this.playerState === 'playing' || this.playerState === 'paused') {
              await this.avPlayer.stop();
              await this.avPlayer.reset();
            } else if (this.playerState === 'prepared' || this.playerState === 'completed' || 
                       this.playerState === 'stopped') {
              await this.avPlayer.reset();
            }
            // initialized 和 idle 状态不需要 reset
          } catch (resetError) {
            console.error('MusicViewModel: 重置失败', resetError);
          }
          await this.loadAudioSource();
          break;
      }
      
    } catch (error) {
      console.error('MusicViewModel: 播放失败', error);
      this._isPlaying = false;
      this.notifyUpdate();
    }
  }
  
  /**
   * 加载音频资源
   */
  private async loadAudioSource(): Promise<void> {
    if (!this.avPlayer || !this.context || !this._currentSong) {
      return;
    }
    
    try {
      const fileName = this._currentSong.fileName;
      console.info(`MusicViewModel: 加载音频文件 - ${fileName}`);
      
      // 使用 resourceManager 获取 rawfile 中的音频文件
      const fileDescriptor = await this.context.resourceManager.getRawFd(fileName);
      
      // 构造 AVFileDescriptor
      const avFileDescriptor: media.AVFileDescriptor = {
        fd: fileDescriptor.fd,
        offset: fileDescriptor.offset,
        length: fileDescriptor.length
      };
      
      // 设置音频源
      this.avPlayer.fdSrc = avFileDescriptor;
      
      console.info('MusicViewModel: 音频源设置成功，等待 prepared 状态');
      
    } catch (error) {
      console.error('MusicViewModel: 加载音频源失败', error);
      // 如果加载失败，回退到模拟播放
      this.startSimulatedPlayback();
    }
  }
  
  /**
   * 模拟播放（当真实音频播放失败时的降级方案）
   */
  private startSimulatedPlayback(): void {
    console.warn('MusicViewModel: 使用模拟播放模式');
    
    this._isPlaying = true;
    this.updateNotification('正在后台播放');
    
    // 使用 setInterval 模拟播放进度
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
  async pause(): Promise<void> {
    if (!this._isPlaying) {
      return;
    }
    
    // 停止定时器（如果在使用模拟播放）
    this.stopTimer();
    
    // 使用 AVPlayer 暂停
    if (this.avPlayer && this.playerState === 'playing') {
      try {
        await this.avPlayer.pause();
        console.info('MusicViewModel: AVPlayer 暂停成功');
      } catch (error) {
        console.error('MusicViewModel: AVPlayer 暂停失败', error);
      }
    }
    
    this._isPlaying = false;
    console.info(`MusicViewModel: 暂停播放 - 当前时间: ${this._currentTime}s`);
    
    // 更新通知 - 已暂停
    this.updateNotification('已暂停');
    
    this.notifyUpdate();
  }
  
  /**
   * 继续播放
   */
  async resume(): Promise<void> {
    if (this._isPlaying || !this._currentSong) {
      return;
    }
    
    // 使用 AVPlayer 继续播放
    if (this.avPlayer && (this.playerState === 'paused' || this.playerState === 'prepared')) {
      try {
        console.info(`MusicViewModel: 继续播放 - 从 ${this._currentTime}s 开始`);
        await this.avPlayer.play();
        this._isPlaying = true;
        this.updateNotification('正在后台播放');
        this.notifyUpdate();
      } catch (error) {
        console.error('MusicViewModel: AVPlayer 继续播放失败', error);
      }
    } else {
      // 如果 AVPlayer 状态不对，重新调用 play()
      await this.play();
    }
  }
  
  /**
   * 播放下一首
   */
  async next(): Promise<void> {
    if (this._playlist.length === 0) {
      return;
    }
    
    this.stopTimer();
    
    // 重置 AVPlayer 状态
    if (this.avPlayer) {
      try {
        console.info(`MusicViewModel: next() - 重置 AVPlayer，当前状态: ${this.playerState}`);
        
        if (this.playerState === 'playing' || this.playerState === 'paused') {
          // playing/paused -> stop -> reset -> idle
          await this.avPlayer.stop();
          await this.avPlayer.reset();
          console.info('MusicViewModel: AVPlayer 已从 playing/paused 重置到 idle 状态');
        } else if (this.playerState === 'prepared' || this.playerState === 'completed' || 
                   this.playerState === 'stopped') {
          // prepared/completed/stopped -> reset -> idle
          await this.avPlayer.reset();
          console.info('MusicViewModel: AVPlayer 已从 prepared/completed/stopped 重置到 idle 状态');
        } else if (this.playerState === 'initialized') {
          // initialized 状态下，reset() 可能不可用，直接设置新的音频源即可
          console.info('MusicViewModel: AVPlayer 处于 initialized 状态，将直接设置新的音频源');
        }
      } catch (error) {
        console.error('MusicViewModel: 重置 AVPlayer 失败', error);
      }
    }
    
    this._currentIndex = (this._currentIndex + 1) % this._playlist.length;
    const nextSong = this._playlist[this._currentIndex];
    
    this._currentSong = nextSong;
    this._totalDuration = nextSong.duration;
    this._currentTime = 0;
    this._currentLyricIndex = 0;
    this._isPlaying = false;
    
    console.info(`MusicViewModel: 下一首 - ${nextSong.title}`);
    
    // 更新通知显示新歌曲
    this.updateNotification('已选择');
    
    this.notifyUpdate();
  }
  
  /**
   * 播放上一首
   */
  async previous(): Promise<void> {
    if (this._playlist.length === 0) {
      return;
    }
    
    this.stopTimer();
    
    // 重置 AVPlayer 状态
    if (this.avPlayer) {
      try {
        console.info(`MusicViewModel: previous() - 重置 AVPlayer，当前状态: ${this.playerState}`);
        
        if (this.playerState === 'playing' || this.playerState === 'paused') {
          // playing/paused -> stop -> reset -> idle
          await this.avPlayer.stop();
          await this.avPlayer.reset();
          console.info('MusicViewModel: AVPlayer 已从 playing/paused 重置到 idle 状态');
        } else if (this.playerState === 'prepared' || this.playerState === 'completed' || 
                   this.playerState === 'stopped') {
          // prepared/completed/stopped -> reset -> idle
          await this.avPlayer.reset();
          console.info('MusicViewModel: AVPlayer 已从 prepared/completed/stopped 重置到 idle 状态');
        } else if (this.playerState === 'initialized') {
          // initialized 状态下，reset() 可能不可用，直接设置新的音频源即可
          console.info('MusicViewModel: AVPlayer 处于 initialized 状态，将直接设置新的音频源');
        }
      } catch (error) {
        console.error('MusicViewModel: 重置 AVPlayer 失败', error);
      }
    }
    
    this._currentIndex = (this._currentIndex - 1 + this._playlist.length) % this._playlist.length;
    const prevSong = this._playlist[this._currentIndex];
    
    this._currentSong = prevSong;
    this._totalDuration = prevSong.duration;
    this._currentTime = 0;
    this._currentLyricIndex = 0;
    this._isPlaying = false;
    
    console.info(`MusicViewModel: 上一首 - ${prevSong.title}`);
    
    // 更新通知显示新歌曲
    this.updateNotification('已选择');
    
    this.notifyUpdate();
  }
  
  /**
   * 跳转到指定时间
   * @param time 目标时间（秒）
   */
  async seekTo(time: number): Promise<void> {
    if (!this._currentSong) {
      return;
    }
    
    // 限制在有效范围内
    this._currentTime = Math.max(0, Math.min(time, this._totalDuration));
    
    // 使用 AVPlayer 跳转
    if (this.avPlayer && 
        (this.playerState === 'prepared' || this.playerState === 'playing' || 
         this.playerState === 'paused' || this.playerState === 'completed')) {
      try {
        // seekTo 接受毫秒作为参数
        await this.avPlayer.seek(this._currentTime * 1000);
        console.info(`MusicViewModel: AVPlayer 跳转到 ${this._currentTime}s`);
      } catch (error) {
        console.error('MusicViewModel: AVPlayer 跳转失败', error);
      }
    }
    
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
    
    // 使用 AVPlayer 停止
    if (this.avPlayer && this.playerState === 'playing') {
      try {
        await this.avPlayer.stop();
      } catch (error) {
        console.error('MusicViewModel: AVPlayer 停止失败', error);
      }
    }
    
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
    
    // 释放 AVPlayer 资源
    if (this.avPlayer) {
      try {
        // 先停止播放
        if (this.playerState === 'playing') {
          await this.avPlayer.stop();
        }
        // 释放资源
        await this.avPlayer.release();
        this.avPlayer = null;
        console.info('MusicViewModel: AVPlayer 资源已释放');
      } catch (error) {
        console.error('MusicViewModel: AVPlayer 资源释放失败', error);
      }
    }
    
    // 取消媒体通知
    await this.cancelNotification();
    
    console.info('MusicViewModel: 资源已释放');
  }
}
