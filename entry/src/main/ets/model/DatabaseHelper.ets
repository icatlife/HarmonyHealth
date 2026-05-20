import relationalStore from '@ohos.data.relationalStore';
import { Constants } from '../common/Constants';
import { DateUtils } from '../common/DateUtils';
import { StepRecord } from './StepRecord';

/**
 * 数据库助手类
 * 用于管理关系型数据库的连接和初始化
 */
export class DatabaseHelper {
    /**
     * 数据库存储实例
     */
    private rdbStore: relationalStore.RdbStore | null = null;

    /**
     * 数据库上下文
     */
    private context: Context | null = null;

    /**
     * 单例实例
     */
    private static instance: DatabaseHelper | null = null;

    /**
     * 获取单例实例
     * @returns DatabaseHelper 实例
     */
    public static getInstance(): DatabaseHelper {
        if (!DatabaseHelper.instance) {
            DatabaseHelper.instance = new DatabaseHelper();
        }
        return DatabaseHelper.instance;
    }

    /**
     * 私有构造函数
     */
    private constructor() {}

    /**
     * 初始化数据库
     * @param context 应用上下文
     * @returns Promise<void>
     */
    public async initDatabase(context: Context): Promise<void> {
        // 如果已经初始化，直接返回
        if (this.rdbStore) {
            console.info('Database already initialized, skipping re-initialization');
            return;
        }

        this.context = context;

        try {
            // 数据库配置
            const config: relationalStore.StoreConfig = {
                name: Constants.DATABASE_NAME,
                securityLevel: relationalStore.SecurityLevel.S1
            };

            // 获取数据库实例
            this.rdbStore = await relationalStore.getRdbStore(context, config);
            console.info('Database initialized successfully');

            // 创建表
            await this.createTables();
        } catch (error) {
            console.error('Failed to initialize database:', JSON.stringify(error));
            throw new Error(`Failed to initialize database: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 创建数据库表
     * @returns Promise<void>
     */
    private async createTables(): Promise<void> {
        if (!this.rdbStore) {
            throw new Error('Database not initialized');
        }

        // 创建步数记录表的SQL语句
        const createTableSql = `
            CREATE TABLE IF NOT EXISTS ${Constants.TABLE_STEP_RECORD} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL UNIQUE,
                steps INTEGER NOT NULL DEFAULT 0,
                goal INTEGER NOT NULL DEFAULT ${Constants.DEFAULT_GOAL},
                created_time INTEGER,
                updated_time INTEGER
            )
        `;

        try {
            await this.rdbStore.executeSql(createTableSql);
            console.info('Table created successfully');
        } catch (error) {
            console.error('Failed to create table:', JSON.stringify(error));
            throw new Error(`Failed to initialize database: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 获取数据库存储实例
     * @returns RdbStore 实例
     */
    public getRdbStore(): relationalStore.RdbStore {
        if (!this.rdbStore) {
            throw new Error('Database not initialized. Call initDatabase() first.');
        }
        return this.rdbStore;
    }

    /**
     * 检查数据库是否已初始化
     * @returns boolean
     */
    public isInitialized(): boolean {
        return this.rdbStore !== null;
    }

    /**
     * 关闭数据库连接
     */
    public async close(): Promise<void> {
        if (this.rdbStore) {
            try {
                await this.rdbStore.close();
                this.rdbStore = null;
                this.context = null;
                console.info('Database closed successfully');
            } catch (error) {
                console.error('Failed to close database:', JSON.stringify(error));
            }
        }
    }

    /**
     * 保存今日步数
     * @param steps 今日步数
     * @returns Promise<void>
     */
    public async saveTodaySteps(steps: number): Promise<void> {
        if (!this.rdbStore) {
            throw new Error('Database not initialized. Call initDatabase() first.');
        }

        const today = DateUtils.formatDate(new Date());
        
        // 使用 INSERT OR REPLACE 语法，如果记录已存在则更新，不存在则插入
        const insertSql = `
            INSERT OR REPLACE INTO ${Constants.TABLE_STEP_RECORD} (date, steps, goal, updated_time)
            VALUES (?, ?, COALESCE((SELECT goal FROM ${Constants.TABLE_STEP_RECORD} WHERE date = ?), ?), ?)
        `;

        try {
            await this.rdbStore.executeSql(insertSql, [today, steps, today, Constants.DEFAULT_GOAL, Math.floor(Date.now() / 1000)]);
            console.info(`Steps saved for ${today}: ${steps}`);
        } catch (error) {
            console.error('❌ Failed to save steps - 详细错误:', error);
            console.error('❌ 错误类型:', typeof error);
            console.error('❌ 错误代码:', error.code);
            console.error('❌ 错误消息:', error.message);
            console.error('❌ 完整错误JSON:', JSON.stringify(error, null, 2));
            throw new Error(`Failed to save steps: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 获取最近7天的步数记录（包括今天）
     * @returns Promise<StepRecord[]> 步数记录数组
     */
    public async getWeekHistory(): Promise<StepRecord[]> {
        if (!this.rdbStore) {
            throw new Error('Database not initialized. Call initDatabase() first.');
        }

        const records: StepRecord[] = [];
        let resultSet: relationalStore.ResultSet | null = null;

        try {
            // 获取今天的日期
            const today = new Date();
            const todayStr = DateUtils.formatDate(today);
            
            // 计算6天前的日期（共7天：今天 + 过去6天）
            const sixDaysAgo = new Date(today);
            sixDaysAgo.setDate(today.getDate() - 6);
            const sixDaysAgoStr = DateUtils.formatDate(sixDaysAgo);

            // 使用 RdbPredicates 构造查询条件
            const predicates = new relationalStore.RdbPredicates(Constants.TABLE_STEP_RECORD);
            predicates.greaterThanOrEqualTo('date', sixDaysAgoStr);
            predicates.lessThanOrEqualTo('date', todayStr);
            predicates.orderByAsc('date'); // 按日期升序排列，便于后续处理

            resultSet = await this.rdbStore.query(predicates, ['id', 'date', 'steps', 'goal']);

            // 遍历结果集
            while (resultSet.goToNextRow()) {
                const id = resultSet.getLong(resultSet.getColumnIndex('id'));
                const date = resultSet.getString(resultSet.getColumnIndex('date'));
                const steps = resultSet.getLong(resultSet.getColumnIndex('steps'));
                const goal = resultSet.getLong(resultSet.getColumnIndex('goal'));

                records.push(new StepRecord(id, date, steps, goal));
            }

            console.info(`Retrieved ${records.length} records for week history (date range: ${sixDaysAgoStr} to ${todayStr})`);
            return records;
        } catch (error) {
            console.error('Failed to get week history:', JSON.stringify(error));
            throw new Error(`Failed to get week history: ${JSON.stringify(error)}`);
        } finally {
            // 确保关闭游标
            if (resultSet) {
                resultSet.close();
            }
        }
    }

    /**
     * 获取今日步数
     * @returns Promise<number> 今日步数
     */
    public async getTodaySteps(): Promise<number> {
        if (!this.rdbStore) {
            throw new Error('Database not initialized. Call initDatabase() first.');
        }

        const today = DateUtils.formatDate(new Date());
        let resultSet: relationalStore.ResultSet | null = null;

        try {
            const predicates = new relationalStore.RdbPredicates(Constants.TABLE_STEP_RECORD);
            predicates.equalTo('date', today);

            resultSet = await this.rdbStore.query(predicates, ['steps']);

            if (resultSet.goToNextRow()) {
                const steps = resultSet.getLong(resultSet.getColumnIndex('steps'));
                console.info(`Today's steps: ${steps}`);
                return steps;
            } else {
                // 如果今日记录不存在，返回0步
                console.info(`No record for today, returning 0 steps`);
                return 0;
            }
        } catch (error) {
            console.error('Failed to get today\'s steps:', JSON.stringify(error));
            throw new Error(`Failed to get today\'s steps: ${JSON.stringify(error)}`);
        } finally {
            if (resultSet) {
                resultSet.close();
            }
        }
    }

    /**
     * 获取今日目标步数
     * @returns Promise<number> 目标步数
     */
    public async getTodayGoal(): Promise<number> {
        if (!this.rdbStore) {
            throw new Error('Database not initialized. Call initDatabase() first.');
        }

        const today = DateUtils.formatDate(new Date());
        let resultSet: relationalStore.ResultSet | null = null;

        try {
            const predicates = new relationalStore.RdbPredicates(Constants.TABLE_STEP_RECORD);
            predicates.equalTo('date', today);

            resultSet = await this.rdbStore.query(predicates, ['goal']);

            if (resultSet.goToNextRow()) {
                const goal = resultSet.getLong(resultSet.getColumnIndex('goal'));
                console.info(`Today's goal: ${goal}`);
                return goal;
            } else {
                // 如果今日记录不存在，返回默认目标
                console.info(`No record for today, returning default goal: ${Constants.DEFAULT_GOAL}`);
                return Constants.DEFAULT_GOAL;
            }
        } catch (error) {
            console.error('Failed to get today\'s goal:', JSON.stringify(error));
            throw new Error(`Failed to get today\'s goal: ${JSON.stringify(error)}`);
        } finally {
            if (resultSet) {
                resultSet.close();
            }
        }
    }

    /**
     * 更新今日目标步数
     * @param goal 新的目标步数
     * @returns Promise<void>
     */
    public async updateGoal(goal: number): Promise<void> {
        if (!this.rdbStore) {
            throw new Error('Database not initialized. Call initDatabase() first.');
        }

        const today = DateUtils.formatDate(new Date());

        try {
            // 检查今日记录是否存在
            const checkPredicates = new relationalStore.RdbPredicates(Constants.TABLE_STEP_RECORD);
            checkPredicates.equalTo('date', today);

            const resultSet = await this.rdbStore.query(checkPredicates, ['id']);
            const recordExists = resultSet.goToNextRow();
            resultSet.close();

            if (recordExists) {
                // 更新现有记录
                const updatePredicates = new relationalStore.RdbPredicates(Constants.TABLE_STEP_RECORD);
                updatePredicates.equalTo('date', today);

                const valuesBucket: relationalStore.ValuesBucket = {
                    'goal': goal,
                    'updated_time': Math.floor(Date.now() / 1000)
                };

                await this.rdbStore.update(valuesBucket, updatePredicates);
                console.info(`Goal updated for ${today}: ${goal}`);
            } else {
                // 创建新记录
                const valuesBucket: relationalStore.ValuesBucket = {
                    'date': today,
                    'steps': 0,
                    'goal': goal,
                    'created_time': Math.floor(Date.now() / 1000),
                    'updated_time': Math.floor(Date.now() / 1000)
                };

                await this.rdbStore.insert(Constants.TABLE_STEP_RECORD, valuesBucket);
                console.info(`New record created for ${today} with goal: ${goal}`);
            }
        } catch (error) {
            console.error('Failed to update goal:', JSON.stringify(error));
            throw new Error(`Failed to update goal: ${JSON.stringify(error)}`);
        }
    }
}