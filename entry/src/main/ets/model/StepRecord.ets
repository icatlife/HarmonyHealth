/**
 * 步数记录数据模型
 * 用于表示单条步数记录的数据结构
 */
export class StepRecord {
    /**
     * 自增主键，唯一标识每条记录
     */
    id: number;

    /**
     * 日期，格式为 YYYY-MM-DD
     */
    date: string;

    /**
     * 当日步数
     */
    steps: number;

    /**
     * 当日目标步数
     */
    goal: number;

    /**
     * 构造函数
     * @param id 自增主键
     * @param date 日期
     * @param steps 步数
     * @param goal 目标步数
     */
    constructor(id: number, date: string, steps: number, goal: number) {
        this.id = id;
        this.date = date;
        this.steps = steps;
        this.goal = goal;
    }

    /**
     * 计算步数完成率
     * @returns 完成率（0-1之间的数值）
     */
    getCompletionRate(): number {
        if (this.goal <= 0) {
            return 0;
        }
        return Math.min(this.steps / this.goal, 1);
    }

    /**
     * 检查是否完成目标
     * @returns 如果步数达到或超过目标，返回true
     */
    isGoalAchieved(): boolean {
        return this.steps >= this.goal;
    }

    /**
     * 获取剩余步数
     * @returns 距离目标还差多少步
     */
    getRemainingSteps(): number {
        return Math.max(this.goal - this.steps, 0);
    }
}