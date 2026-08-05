/**
 * 格式化工具（ArkTS 规范）
 */
export class FormatUtil {
  /**
   * 秒 -> mm:ss
   */
  static formatDuration(seconds: number): string {
    if (seconds < 0 || isNaN(seconds)) {
      return '00:00';
    }
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return mins.toString().padStart(2, '0') + ':' + secs.toString().padStart(2, '0');
  }

  /**
   * 毫秒 -> mm:ss
   */
  static formatTime(ms: number): string {
    if (ms < 0 || isNaN(ms)) {
      return '00:00';
    }
    return FormatUtil.formatDuration(Math.floor(ms / 1000));
  }

  /**
   * 播放量格式化：1.2万 / 1.3亿
   */
  static formatPlayCount(count: number): string {
    if (count >= 100000000) {
      return (count / 100000000).toFixed(1) + '亿';
    }
    if (count >= 10000) {
      return (count / 10000).toFixed(1) + '万';
    }
    return count.toString();
  }

  /**
   * 时间戳 -> yyyy-MM-dd
   */
  static formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return year.toString() + '-' + month + '-' + day;
  }
}
