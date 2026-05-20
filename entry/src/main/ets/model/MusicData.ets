/**
 * 音乐数据模型
 * 
 * 注意：音频文件需用户手动放入 entry/src/main/resources/rawfile/ 目录
 * 支持格式：MP3、AAC、WAV 等 HarmonyOS 支持的音频格式
 */

/**
 * 歌曲数据接口
 */
export interface Song {
  /** 歌曲唯一标识 */
  id: number;
  
  /** 歌曲名 */
  title: string;
  
  /** 歌手名 */
  artist: string;
  
  /** 时长（秒） */
  duration: number;
  
  /** 封面占位色值（如 '#A8D8B9'），暂无专辑封面图片 */
  coverColor: string;
  
  /** 对应的音频文件名（如 'song1.mp3'），存放在 rawfile 目录 */
  fileName: string;
  
  /** 歌词数组，每行一句 */
  lyrics: string[];
  
  /** 每句歌词对应的时间戳（秒） */
  lyricTimestamps: number[];
}

/**
 * 播放历史接口（用于后续存储扩展）
 */
export interface PlayHistory {
  /** 歌曲ID */
  songId: number;
  
  /** 播放次数 */
  playCount: number;
  
  /** 最后播放时间（时间戳） */
  lastPlayTime: number;
}

/**
 * 音乐数据源类
 * 提供本地预置歌曲数据
 */
export class MusicDataSource {
  /**
   * 获取本地预置歌曲列表
   * @returns 歌曲数组
   */
  static getLocalSongs(): Song[] {
    return [
      {
        id: 1,
        title: '晨光微曦',
        artist: '薄荷绿乐队',
        duration: 245,
        coverColor: '#7EC8A0',
        fileName: 'song1.mp3',
        lyrics: [
          '晨光透过窗帘缝隙',
          '轻轻唤醒沉睡的梦',
          '新的一天悄然开始',
          '带着希望与期待',
          '微风拂过脸庞',
          '带走昨夜的疲惫',
          '阳光洒满房间',
          '温暖了整个心房',
          '让我们迎接这美好',
          '用微笑开启新旅程'
        ],
        lyricTimestamps: [0, 8, 16, 24, 32, 40, 48, 56, 64, 72]
      },
      {
        id: 2,
        title: '林间漫步',
        artist: '自然之声',
        duration: 312,
        coverColor: '#A8D8B9',
        fileName: 'song2.mp3',
        lyrics: [
          '穿过茂密的树林',
          '脚踩松软的落叶',
          '鸟儿在枝头歌唱',
          '溪水潺潺流淌',
          '阳光透过树叶',
          '洒下斑驳的光影',
          '空气中弥漫着',
          '泥土和花草的芬芳',
          '远离城市的喧嚣',
          '在这里找到宁静',
          '每一步都是放松',
          '每一刻都是享受'
        ],
        lyricTimestamps: [0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88]
      },
      {
        id: 3,
        title: '跑步日记',
        artist: '活力少年',
        duration: 198,
        coverColor: '#3CB371',
        fileName: 'song3.mp3',
        lyrics: [
          '系好鞋带准备出发',
          '心跳开始加速',
          '脚步踏在跑道上',
          '汗水慢慢渗出',
          '呼吸变得急促',
          '但内心充满力量',
          '每一步都在前进',
          '每一秒都在超越',
          '终点就在前方',
          '坚持就是胜利'
        ],
        lyricTimestamps: [0, 8, 16, 24, 32, 40, 48, 56, 64, 72]
      },
      {
        id: 4,
        title: '瑜伽时光',
        artist: '心灵瑜伽',
        duration: 420,
        coverColor: '#98C8A9',
        fileName: 'song4.mp3',
        lyrics: [
          '闭上双眼深呼吸',
          '感受身体的每一处',
          '让紧张慢慢释放',
          '让心灵回归平静',
          '伸展双臂向上',
          '感受指尖的延伸',
          '弯曲身体向前',
          '感受背部的舒展',
          '保持呼吸的节奏',
          '让身心合二为一',
          '在这宁静时刻',
          '找到内心的平衡',
          '瑜伽不仅是运动',
          '更是生活的艺术'
        ],
        lyricTimestamps: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130]
      },
      {
        id: 5,
        title: '夜跑星空',
        artist: '城市夜行者',
        duration: 267,
        coverColor: '#5DB88A',
        fileName: 'song5.mp3',
        lyrics: [
          '夜幕降临城市',
          '霓虹灯闪烁不息',
          '换上运动装备',
          '踏上熟悉的街道',
          '抬头仰望星空',
          '繁星点点闪耀',
          '微风轻抚脸庞',
          '带走一天的疲惫',
          '脚步声回荡在夜空',
          '心跳与节奏共鸣',
          '这是属于我的时光',
          '在奔跑中找到自由'
        ],
        lyricTimestamps: [0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88]
      },
      {
        id: 6,
        title: '骑行风景',
        artist: '自由车轮',
        duration: 356,
        coverColor: '#6BB896',
        fileName: 'song6.mp3',
        lyrics: [
          '跨上单车准备出发',
          '链条转动发出声响',
          '风吹过耳边',
          '带来远方的气息',
          '穿过繁华的街道',
          '驶向宁静的郊外',
          '田野一望无际',
          '金黄的麦浪翻滚',
          '蝴蝶在花丛飞舞',
          '蜜蜂忙碌采蜜',
          '车轮不停转动',
          '风景不断变换',
          '这就是骑行的魅力',
          '自由自在无拘无束'
        ],
        lyricTimestamps: [0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104]
      }
    ];
  }
  
  /**
   * 根据ID获取歌曲
   * @param id 歌曲ID
   * @returns 歌曲对象或undefined
   */
  static getSongById(id: number): Song | undefined {
    const songs = MusicDataSource.getLocalSongs();
    return songs.find((song: Song) => song.id === id);
  }
  
  /**
   * 获取随机封面颜色（用于动态生成）
   * @returns 十六进制颜色值
   */
  static getRandomCoverColor(): string {
    const colors: string[] = [
      '#7EC8A0',
      '#A8D8B9',
      '#3CB371',
      '#98C8A9',
      '#5DB88A',
      '#6BB896',
      '#8FD4B8',
      '#4ECDC4'
    ];
    const index = Math.floor(Math.random() * colors.length);
    return colors[index];
  }
  
  /**
   * 格式化时长显示（秒转为 mm:ss 格式）
   * @param seconds 秒数
   * @returns 格式化后的时间字符串
   */
  static formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    const minsStr = mins.toString().padStart(2, '0');
    const secsStr = secs.toString().padStart(2, '0');
    return `${minsStr}:${secsStr}`;
  }
  
  /**
   * 根据当前播放时间获取当前歌词索引
   * @param currentTime 当前播放时间（秒）
   * @param timestamps 歌词时间戳数组
   * @returns 当前歌词索引
   */
  static getCurrentLyricIndex(currentTime: number, timestamps: number[]): number {
    for (let i = timestamps.length - 1; i >= 0; i--) {
      if (currentTime >= timestamps[i]) {
        return i;
      }
    }
    return 0;
  }
}
