/**
 * 音乐数据模型
 * 
 * 注意：音频文件需用户手动放入 entry/src/main/resources/rawfile/ 目录
 * 支持格式：MP3、AAC、WAV、OGG 等 HarmonyOS 支持的音频格式
 * 
 * LRC 歌词文件也放在 rawfile 目录，与音频文件同级
 */

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

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
  
  /** 封面图片资源（可选） */
  coverImage?: ResourceStr;
  
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
 * LRC 解析结果接口
 */
export interface LrcParseResult {
  /** 歌词文本数组 */
  lyrics: string[];
  
  /** 时间戳数组（秒） */
  timestamps: number[];
}

/**
 * 解析后的歌词行接口
 */
interface ParsedLine {
  /** 时间戳（秒） */
  time: number;
  
  /** 歌词文本 */
  lyric: string;
}

/**
 * 模拟歌词项接口
 */
export interface MockLyricItem {
  lyrics: string[];
  timestamps: number[];
}

/**
 * 音乐数据源类
 * 提供本地预置歌曲数据
 */
export class MusicDataSource {
  // 预置的模拟歌词（用于降级） - 在 getLocalSongs 方法中内联定义

  /**
   * 解析 LRC 歌词文件
   * 
   * LRC 格式说明：
   * - 标准格式：[mm:ss.xx]歌词内容
   * - 示例：[00:15.30]这是一句歌词
   * - 支持多时间戳行：[00:15.30][00:45.60]重复歌词
   * 
   * @param context 应用上下文
   * @param lrcFileName LRC 文件名
   * @returns 解析结果，包含歌词数组和时间戳数组
   */
  static parseLrcFile(context: common.UIAbilityContext, lrcFileName: string): LrcParseResult {
    console.info(`MusicDataSource: parseLrcFile() 开始解析 LRC 文件: ${lrcFileName}`);
    const result: LrcParseResult = {
      lyrics: [],
      timestamps: []
    };
    
    try {
      // 读取 LRC 文件的字节内容
      const fileContent = context.resourceManager.getRawFileContentSync(lrcFileName);
      
      // 将字节数组转换为字符串
      const textDecoder = util.TextDecoder.create('utf-8');
      const lrcContent = textDecoder.decodeToString(fileContent);
      
      console.info(`MusicDataSource: LRC 文件读取成功 - ${lrcFileName}，文件大小: ${lrcContent.length} 字符`);
      
      // 按行分割
      const lines = lrcContent.split('\n');
      console.info(`MusicDataSource: LRC 文件共 ${lines.length} 行`);
      
      // 临时存储解析结果（用于排序）
      const parsedLines: ParsedLine[] = [];
      
      // 正则表达式匹配时间戳和歌词
      // 格式1: [mm:ss.xx] 或 [mm:ss:xx]（带毫秒）
      const lrcRegexWithMs = /\[(\d{1,2}):(\d{2})[.:](\d{2,3})\]/g;
      // 格式2: [mm:ss]（纯秒，不带毫秒） - 支持单数字分钟
      const lrcRegexWithoutMs = /\[(\d{1,2}):(\d{2})\]/g;
      
      let validLineCount = 0;
      let totalTimestamps = 0;
      
      for (const line of lines) {
        // 跳过空行
        const trimmedLine = line.trim();
        if (!trimmedLine) {
          continue;
        }
        
        // 跳过元数据行（如 [ti:歌名]、[ar:歌手] 等）
        if (trimmedLine.startsWith('[ti:') || 
            trimmedLine.startsWith('[ar:') || 
            trimmedLine.startsWith('[al:') || 
            trimmedLine.startsWith('[by:') ||
            trimmedLine.startsWith('[offset:')) {
          console.info(`MusicDataSource: 跳过元数据行: "${trimmedLine}"`);
          continue;
        }
        
        // 跳过歌曲信息行和元数据行（如 [0:00] 歌曲名 - 歌手、制作人、作词等）
        // 判断依据：时间戳为0开头，且包含特定关键词或格式
        const isMetadataLine = trimmedLine.match(/^\[(\d{1,2}):(\d{2})[.:]?\d{0,2}\]/) && (
          trimmedLine.includes('制作人') ||
          trimmedLine.includes('作词') ||
          trimmedLine.includes('作曲') ||
          trimmedLine.includes('编曲') ||
          trimmedLine.includes('演唱') ||
          trimmedLine.includes('吉他') ||
          trimmedLine.includes('合声') ||
          trimmedLine.includes('音频') ||
          trimmedLine.includes('混音') ||
          trimmedLine.includes('母带') ||
          trimmedLine.includes('TME享有') ||
          trimmedLine.includes('词：') ||
          trimmedLine.includes('曲：')
        );
        if (isMetadataLine) {
          console.info(`MusicDataSource: 跳过元数据行: "${trimmedLine}"`);
          continue;
        }
        
        // 跳过歌曲标题行（如 [0:00] 歌曲名 - 歌手）
        const isSongTitleLine = trimmedLine.match(/^\[(\d{1,2}):(\d{2})[.:]?\d{0,2}\]/) && 
                              (trimmedLine.includes(' - ') || trimmedLine.includes(' - ')) &&
                              parsedLines.length === 0;
        if (isSongTitleLine) {
          console.info(`MusicDataSource: 跳过歌曲标题行: "${trimmedLine}"`);
          continue;
        }
        
        // 提取所有时间戳
        const timestamps: number[] = [];
        
        // 先尝试匹配带毫秒的格式
        let match: RegExpExecArray | null = null;
        lrcRegexWithMs.lastIndex = 0;
        
        while ((match = lrcRegexWithMs.exec(trimmedLine)) !== null) {
          const minutes = parseInt(match[1]);
          const seconds = parseInt(match[2]);
          let milliseconds = 0;
          
          // 处理毫秒部分
          if (match[3]) {
            // 将毫秒字符串填充到3位（处理2位或3位毫秒）
            const msStr = match[3].padEnd(3, '0').substring(0, 3);
            milliseconds = parseInt(msStr);
          }
          
          // 转换为秒（保留小数）
          const totalSeconds = minutes * 60 + seconds + milliseconds / 1000;
          timestamps.push(totalSeconds);
          console.info(`MusicDataSource: 匹配到带毫秒时间戳: ${match[0]} -> ${totalSeconds}秒`);
        }
        
        // 如果没有匹配到带毫秒的格式，尝试匹配纯秒格式
        if (timestamps.length === 0) {
          lrcRegexWithoutMs.lastIndex = 0;
          while ((match = lrcRegexWithoutMs.exec(trimmedLine)) !== null) {
            const minutes = parseInt(match[1]);
            const seconds = parseInt(match[2]);
            // 转换为秒（没有毫秒）
            const totalSeconds = minutes * 60 + seconds;
            timestamps.push(totalSeconds);
            console.info(`MusicDataSource: 匹配到纯秒时间戳: ${match[0]} -> ${totalSeconds}秒`);
          }
        }
        
        // 提取歌词文本（移除时间戳部分）
        // 先移除带毫秒的时间戳
        let lyricText = trimmedLine.replace(lrcRegexWithMs, '').trim();
        // 再移除纯秒时间戳
        lyricText = lyricText.replace(lrcRegexWithoutMs, '').trim();
        
        // 如果没有时间戳或没有歌词文本，跳过
        if (timestamps.length === 0 || !lyricText) {
          console.info(`MusicDataSource: 跳过无效行 - 无时间戳或无歌词: "${trimmedLine}"`);
          continue;
        }
        
        // 为每个时间戳创建歌词条目
        for (const time of timestamps) {
          parsedLines.push({ time, lyric: lyricText });
        }
        validLineCount++;
        totalTimestamps += timestamps.length;
        
        // 调试日志：输出前几行的解析结果
        if (validLineCount <= 3) {
          console.info(`MusicDataSource: 第${validLineCount}行解析 - 原始行: "${trimmedLine}"`);
          console.info(`MusicDataSource:   歌词: "${lyricText}", 时间戳数量: ${timestamps.length}`);
          if (timestamps.length > 0) {
            console.info(`MusicDataSource:   第一个时间戳: ${timestamps[0]}秒`);
          }
        }
      }
      
      console.info(`MusicDataSource: LRC 文件有效歌词行数: ${validLineCount}, 总时间戳数量: ${totalTimestamps}`);
      
      // 按时间戳排序
      parsedLines.sort((a, b) => a.time - b.time);
      
      // 提取排序后的结果
      // 保留时间戳的小数精度（不向下取整），提高歌词同步准确性
      for (const item of parsedLines) {
        result.timestamps.push(item.time);
        result.lyrics.push(item.lyric);
      }
      
      console.info(`MusicDataSource: LRC 解析完成: ${lrcFileName}, 共 ${result.lyrics.length} 行歌词`);
      if (result.lyrics.length > 0) {
        console.info(`MusicDataSource: 第一行歌词: "${result.lyrics[0]}"`);
        if (result.lyrics.length > 1) {
          console.info(`MusicDataSource: 第二行歌词: "${result.lyrics[1]}"`);
        }
      } else {
        console.warn(`MusicDataSource: LRC 解析完成但未提取到歌词: ${lrcFileName}`);
      }
      
    } catch (error) {
      console.error(`MusicDataSource: LRC 解析失败: ${lrcFileName}, 错误: ${JSON.stringify(error)}`);
    }
    
    return result;
  }
  
  /**
   * 获取本地预置歌曲列表
   * @param context 应用上下文（用于读取 LRC 文件）
   * @returns 歌曲数组
   */
  static getLocalSongs(context?: common.UIAbilityContext): Song[] {
    // 预置的模拟歌词（用于降级）
    const mockLyricsSong1: MockLyricItem = {
      lyrics: ['晨光透过窗帘缝隙', '轻轻唤醒沉睡的梦', '新的一天悄然开始', '带着希望与期待'],
      timestamps: [0, 8, 16, 24]
    };
    const mockLyricsSong2: MockLyricItem = {
      lyrics: ['穿过茂密的树林', '脚踩松软的落叶', '鸟儿在枝头歌唱', '溪水潺潺流淌'],
      timestamps: [0, 8, 16, 24]
    };
    const mockLyricsSong3: MockLyricItem = {
      lyrics: ['系好鞋带准备出发', '心跳开始加速', '脚步踏在跑道上', '汗水慢慢渗出'],
      timestamps: [0, 8, 16, 24]
    };
    const mockLyricsSong4: MockLyricItem = {
      lyrics: ['仙歌音玉笛灵', '酒盏玉露清', '剑舞轻', '潇洒过白袍影'],
      timestamps: [0, 8, 16, 24]
    };
    const mockLyricsSong5: MockLyricItem = {
      lyrics: ['陽の満ちるこの部屋', '阳光即将洒满整个房间', 'そっとトキを待つよ', '悄悄的等待着那个时刻'],
      timestamps: [0, 8, 16, 24]
    };
    const mockLyricsSong6: MockLyricItem = {
      lyrics: ['楚河流沙几聚散', '日月沧桑尽变换', '乱世多少红颜换一声长叹', '谁曾巨鹿踏破了秦关'],
      timestamps: [0, 8, 16, 24]
    };
    
    // LRC 文件映射（文件名需与 rawfile 目录中的实际文件名完全一致）
    const lrcFileMap: Record<number, string> = {
      1: 'Recollect - 鈴木このみ&Ashnikko .lrc',
      2: 'DAMIDAMI - Sihan&三Z-STUDIO&HOYO-MiX .lrc',
      3: 'LOVE 2000 - 遠野ひかる .lrc',
      4: '谪仙-伊格赛听&amp;叶里-歌词.lrc',
      5: 'ユキトキ (雪融)(TV size)-二次元空间-歌词.lrc',
      6: '虞叹兮（甜美女声版） (cover_ 闻人听书)-昕儿-歌词.lrc'
    };
    
    // 歌曲名称映射（用于日志输出）
    const songNameMap: Record<number, string> = {
      1: 'Recollect',
      2: 'DAMIDAMI',
      3: 'LOVE 2000',
      4: '谪仙',
      5: '雪融',
      6: '虞叹兮'
    };
    
    // 解析 LRC 文件（如果有 context）
    const lrcData: Record<number, LrcParseResult> = {};
    
    if (context) {
      // 遍历 LRC 文件映射
      const ids = [1, 2, 3, 4, 5, 6];
      for (let i = 0; i < ids.length; i++) {
        const id = ids[i];
        const lrcFile = lrcFileMap[id];
        const songName = songNameMap[id];
        console.info(`MusicDataSource: getLocalSongs() - 开始解析歌曲 ${id} (${songName}) 的 LRC 文件: "${lrcFile}"`);
        const parsed = MusicDataSource.parseLrcFile(context, lrcFile);
        if (parsed.lyrics.length > 0) {
          lrcData[id] = parsed;
          console.info(`MusicDataSource: getLocalSongs() - LRC 解析完成 - 歌曲: ${songName}, 文件: ${lrcFile}, 歌词行数: ${parsed.lyrics.length}`);
          // 输出前3行歌词用于调试
          const previewCount = Math.min(3, parsed.lyrics.length);
          for (let j = 0; j < previewCount; j++) {
            console.info(`MusicDataSource:   [${j}] "${parsed.lyrics[j]}"`);
          }
        } else {
          console.warn(`MusicDataSource: getLocalSongs() - LRC 解析失败 - 歌曲: ${songName}, 文件: ${lrcFile}, 将使用模拟歌词`);
          // 使用对应歌曲的模拟歌词
          let mockLyrics: string[] = [];
          if (id === 1) {
            mockLyrics = mockLyricsSong1.lyrics;
          } else if (id === 2) {
            mockLyrics = mockLyricsSong2.lyrics;
          } else if (id === 3) {
            mockLyrics = mockLyricsSong3.lyrics;
          } else if (id === 4) {
            mockLyrics = mockLyricsSong4.lyrics;
          } else if (id === 5) {
            mockLyrics = mockLyricsSong5.lyrics;
          } else if (id === 6) {
            mockLyrics = mockLyricsSong6.lyrics;
          }
          console.info(`MusicDataSource: getLocalSongs() - 将使用模拟歌词: ${mockLyrics.slice(0, 3).join(', ')}...`);
        }
      }
    }
    
    return [
      {
        id: 1,
        title: 'Recollect',
        artist: '鈴木このみ & Ashnikko',
        duration: 245,
        coverColor: '#7EC8A0',
        coverImage: $r('app.media.Recollect'),
        fileName: 'Recollect_L.ogg',
        lyrics: lrcData[1]?.lyrics ?? mockLyricsSong1.lyrics,
        lyricTimestamps: lrcData[1]?.timestamps ?? mockLyricsSong1.timestamps
      } as Song,
      {
        id: 2,
        title: 'DAMIDAMI',
        artist: 'Sihan HOYO MiX 三Z-STUDIO',
        duration: 312,
        coverColor: '#A8D8B9',
        coverImage: $r('app.media.DAMIDAMI'),
        fileName: 'DAMIDAMI_L.ogg',
        lyrics: lrcData[2]?.lyrics ?? mockLyricsSong2.lyrics,
        lyricTimestamps: lrcData[2]?.timestamps ?? mockLyricsSong2.timestamps
      } as Song,
      {
        id: 3,
        title: 'LOVE 2000',
        artist: '遠野ひかる',
        duration: 198,
        coverColor: '#3CB371',
        coverImage: $r('app.media.love2000'),
        fileName: 'love2000.mp3',
        lyrics: lrcData[3]?.lyrics ?? mockLyricsSong3.lyrics,
        lyricTimestamps: lrcData[3]?.timestamps ?? mockLyricsSong3.timestamps
      } as Song,
      {
        id: 4,
        title: '谪仙',
        artist: '伊格赛听 / 叶里',
        duration: 160,
        coverColor: '#98C8A9',
        fileName: '谪仙.aac',
        lyrics: lrcData[4]?.lyrics ?? mockLyricsSong4.lyrics,
        lyricTimestamps: lrcData[4]?.timestamps ?? mockLyricsSong4.timestamps
      } as Song,
      {
        id: 5,
        title: '雪融',
        artist: '二次元空间',
        duration: 250,
        coverColor: '#5DB88A',
        fileName: '雪融.mp3',
        lyrics: lrcData[5]?.lyrics ?? mockLyricsSong5.lyrics,
        lyricTimestamps: lrcData[5]?.timestamps ?? mockLyricsSong5.timestamps
      } as Song,
      {
        id: 6,
        title: '虞叹兮',
        artist: '昕儿',
        duration: 190,
        coverColor: '#6BB896',
        fileName: '虞叹兮.mp3',
        lyrics: lrcData[6]?.lyrics ?? mockLyricsSong6.lyrics,
        lyricTimestamps: lrcData[6]?.timestamps ?? mockLyricsSong6.timestamps
      } as Song
    ];
  }
  
  /**
   * 根据ID获取歌曲
   * @param id 歌曲ID
   * @param context 应用上下文（可选，用于读取 LRC）
   * @returns 歌曲对象或undefined
   */
  static getSongById(id: number, context?: common.UIAbilityContext): Song | undefined {
    const songs = MusicDataSource.getLocalSongs(context);
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
    // 向下取整，确保显示格式为 MM:SS
    const totalSeconds = Math.floor(seconds);
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    const minsStr = mins.toString().padStart(2, '0');
    const secsStr = secs.toString().padStart(2, '0');
    return `${minsStr}:${secsStr}`;
  }
  
  /**
   * 根据当前播放时间获取当前歌词索引
   * @param currentTime 当前播放时间（秒，可以是浮点数）
   * @param timestamps 歌词时间戳数组（秒，可以是浮点数）
   * @returns 当前歌词索引（返回该时间戳组的第一个索引，用于双语歌词高亮）
   */
  static getCurrentLyricIndex(currentTime: number, timestamps: number[]): number {
    if (timestamps.length === 0) {
      return 0;
    }
    
    // 从后向前查找第一个时间戳小于等于当前时间的索引
    // 直接返回该索引，不区分歌词行还是翻译行
    for (let i = timestamps.length - 1; i >= 0; i--) {
      if (currentTime >= timestamps[i]) {
        return i;
      }
    }
    
    return 0;
  }
  
  /**
   * 获取应该高亮的歌词索引范围（用于双语歌词）
   * @param currentIndex 当前歌词索引
   * @param timestamps 歌词时间戳数组
   * @returns 包含所有应该高亮的索引的数组
   */
  static getHighlightedIndices(currentIndex: number, timestamps: number[]): number[] {
    if (timestamps.length === 0 || currentIndex < 0 || currentIndex >= timestamps.length) {
      return [];
    }
    
    const targetTimestamp = timestamps[currentIndex];
    const indices: number[] = [];
    
    // 向后查找相同时间戳的所有索引
    for (let i = currentIndex; i < timestamps.length; i++) {
      if (timestamps[i] === targetTimestamp) {
        indices.push(i);
      } else {
        break;
      }
    }
    
    return indices;
  }
}
