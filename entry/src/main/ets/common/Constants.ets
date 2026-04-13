/**
 * 应用常量定义
 */
export class Constants {
    /** 数据库名称 */
    static readonly DATABASE_NAME: string = 'FitPaceDB';

    /** 步数记录表名 */
    static readonly TABLE_STEP_RECORD: string = 'step_records';

    /** 默认目标步数 */
    static readonly DEFAULT_GOAL: number = 6000;

    /** 是否使用模拟步数数据 */
    static readonly USE_MOCK_STEPS: boolean = true;

    /** 通知ID */
    static readonly NOTIFICATION_ID: number = 1001;
}