import sys

file_path = r"D:\HarmonyHealth\entry\src\main\ets\viewmodel\MusicViewModel.ets"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_method = '''  /**
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
  }'''

new_method = '''  /**
   * 更新当前歌词索引（带节流和变化检测）
   */
  updateLyricIndex(): void {
    if (!this._currentSong || this._currentSong.lyricTimestamps.length === 0) {
      return;
    }

    // 节流：限制更新频率，避免过于频繁的计算
    const now = Date.now();
    if (now - this._lastLyricUpdateTime < MusicViewModel.LYRIC_UPDATE_INTERVAL) {
      return;
    }
    this._lastLyricUpdateTime = now;

    // 计算新的歌词索引
    const newIndex = MusicDataSource.getCurrentLyricIndex(
      this._currentTime,
      this._currentSong.lyricTimestamps
    );

    // 只有索引真正变化时才更新（避免不必要的UI刷新）
    if (newIndex !== this._currentLyricIndex) {
      this._currentLyricIndex = newIndex;
      // 索引变化时才触发UI更新
      this.notifyUpdate();
    }
  }'''

if old_method in content:
    content = content.replace(old_method, new_method)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("File updated successfully")
else:
    print("Old method not found in file")
    # 打印附近的内容帮助调试
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'updateLyricIndex' in line and 'void' in line:
            print(f"Found at line {i+1}:")
            for j in range(max(0, i-3), min(len(lines), i+15)):
                print(f"{j+1}: {lines[j]}")
