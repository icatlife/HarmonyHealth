/**
 * 日期工具类
 */
export class DateUtils {
    /**
     * 格式化日期为 YYYY-MM-DD 格式
     * @param date 日期对象
     * @returns 格式化后的日期字符串
     */
    static formatDate(date: Date): string {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        
        return `${year}-${month}-${day}`;
    }

    /**
     * 获取最近7天的日期范围
     * @param date 基准日期
     * @returns 包含最近7天日期的数组，格式为 MM-DD
     */
    static getWeekRange(date: Date): string[] {
        const dates: string[] = [];
        
        // 从当前日期往前推6天，加上当天共7天
        for (let i = 6; i >= 0; i--) {
            const targetDate = new Date(date);
            targetDate.setDate(date.getDate() - i);
            
            const month = String(targetDate.getMonth() + 1).padStart(2, '0');
            const day = String(targetDate.getDate()).padStart(2, '0');
            
            dates.push(`${month}-${day}`);
        }
        
        return dates;
    }
}