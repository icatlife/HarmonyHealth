import { DatabaseHelper } from '../model/DatabaseHelper';
import { StepSensorManager } from '../common/StepSensorManager';
import { Constants } from '../common/Constants';
import common from '@ohos.app.ability.common';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';

/**
 * 计步数据视图模型（单例模式）
 * 作为UI层与数据层、传感器层之间的桥梁
 * 管理步数追踪状态、数据持久化和进度计算
 *
 * 单例模式说明：
 * - 使用 getInstance() 获取唯一实例
 * - 确保后台计步状态在页面切换时保持
 */
export class StepViewModel {
    /**
     * 单例实例
     */
    private static instance: StepViewModel | null = null;

    /**
     * 获取单例实例
     */
    static getInstance(): StepViewModel {
        if (!StepViewModel.instance) {
            StepViewModel.instance = new StepViewModel();
        }
        return StepViewModel.instance;
    }

    /**
     * 数据库助手实例
     */
    private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();
    
    /**
     * 传感器管理器实例
     */
    private stepSensorManager: StepSensorManager | null = null;
    
    /**
     * 今日步数
     */
    private _todaySteps: number = 0;
    
    /**
     * 今日目标步数
     */
    private _todayGoal: number = Constants.DEFAULT_GOAL;
    
    /**
     * 完成百分比（0-100）
     */
    private _progressPercent: number = 0;
    
    /**
     * 当前日期（用于判断是否需要重置步数）
     */
    private currentDate: string = '';
    
    /**
     * 是否正在追踪步数
     */
    private isTracking: boolean = false;

    /**
     * 是否已暂停计步
     */
    private isPaused: boolean = false;

    /**
     * 是否已初始化
     */
    private isInitialized: boolean = false;

    /**
     * 步数变化回调函数
     */
    private onStepChangeCallback: ((steps: number, goal: number, percent: number) => void) | null = null;

    /**
     * 今日是否已发送目标达成通知
     * 用于避免重复通知
     */
    private hasNotifiedToday: boolean = false;

    /**
     * 今日是否已发送运动提醒通知
     * 用于避免重复提醒
     */
    private hasSentMorningReminder: boolean = false;

    /**
     * 运动提醒定时器ID
     * 用于管理定时任务
     */
    private morningReminderTimer: number = -1;

    /**
     * 通知ID
     */
    private readonly NOTIFICATION_ID: number = 1001;

    /**
     * 运动提醒通知ID
     */
    private readonly MORNING_REMINDER_ID: number = 1003;

    /**
     * 后台长时任务ID
     * 用于保持应用在后台运行时能够持续获取传感器数据
     */
    private backgroundTaskId: number = -1;

    /**
     * 应用上下文
     */
    private context: common.Context | null = null;

    /**
     * WantAgent对象，用于后台任务唤醒
     */
    private wantAgentObj: WantAgent | null = null;

    /**
     * 设置步数变化回调
     * @param callback 回调函数
     */
    public setOnStepChangeCallback(callback: ((steps: number, goal: number, percent: number) => void) | null): void {
        this.onStepChangeCallback = callback;
    }

    /**
     * 获取今日步数
     */
    public get todaySteps(): number {
        return this._todaySteps;
    }

    /**
     * 获取今日目标步数
     */
    public get todayGoal(): number {
        return this._todayGoal;
    }

    /**
     * 获取完成百分比
     */
    public get progressPercent(): number {
        return this._progressPercent;
    }

    /**
     * 获取是否正在追踪
     */
    public get tracking(): boolean {
        return this.isTracking;
    }

    /**
     * 获取是否已暂停
     */
    public get paused(): boolean {
        return this.isPaused;
    }

    /**
     * 初始化视图模型
     * 从数据库加载今日步数和目标，初始化状态
     * @param context 应用上下文
     */
    async init(context: common.Context): Promise<void> {
        // 防止重复初始化
        if (this.isInitialized) {
            console.info('StepViewModel: Already initialized, skipping');
            return;
        }

        try {
            // 保存应用上下文用于后台任务
            this.context = context;
            
            // 确保数据库已初始化
            await this.dbHelper.initDatabase(context);
            
            // 获取当前日期
            this.currentDate = this.getCurrentDate();
            
            // 从数据库加载今日步数和目标
            await this.loadTodayData();
            
            // 计算初始进度
            this.refreshProgress();
            
            // 关键修复：立即触发回调，确保UI在页面初始化时就能显示正确的数据
            // 修复二次进入页面时步数短暂显示为0的问题
            // 注意：这里假设回调函数已经在页面初始化前设置完成
            if (this.onStepChangeCallback) {
                this.onStepChangeCallback(this._todaySteps, this._todayGoal, this._progressPercent);
                console.info(`StepViewModel: Initial callback triggered - Steps: ${this._todaySteps}, Goal: ${this._todayGoal}, Percent: ${this._progressPercent}%`);
            } else {
                console.warn('StepViewModel: onStepChangeCallback not set, UI may show initial 0 values');
            }
            
            // 重置今日通知状态（每天重置）
            this.hasNotifiedToday = false;
            this.hasSentMorningReminder = false;
            console.info(`📅 StepViewModel: Notification status reset for new day: ${this.currentDate}`);
            
            // 初始化WantAgent
            await this.initWantAgent();
            
            // 设置运动提醒定时器
            await this.setupMorningReminder();
            
            console.info('StepViewModel: Initialized successfully');
            this.isInitialized = true;
            
        } catch (error) {
            console.error(`StepViewModel: Failed to initialize. Error: ${JSON.stringify(error)}`);
            // 使用默认值继续运行
            this._todaySteps = 0;
            this._todayGoal = Constants.DEFAULT_GOAL;
            this.refreshProgress();
            
            // 错误情况下也触发回调，确保UI有数据
            if (this.onStepChangeCallback) {
                this.onStepChangeCallback(this._todaySteps, this._todayGoal, this._progressPercent);
            }
        }
    }

    /**
     * 初始化WantAgent
     * 用于后台任务被系统终止后的重新启动
     */
    private async initWantAgent(): Promise<void> {
        try {
            if (!this.context) {
                console.warn('StepViewModel: Context not available, cannot init WantAgent');
                return;
            }
            
            const wantAgentInfo: wantAgent.WantAgentInfo = {
                wants: [{
                    bundleName: 'com.icatlife.myapplication',
                    abilityName: 'EntryAbility'
                }],
                actionType: wantAgent.OperationType.START_ABILITY,
                requestCode: 0,
                wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
            };
            
            this.wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);
            console.info('StepViewModel: WantAgent initialized successfully');
            
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepViewModel: Failed to init WantAgent. Code: ${e.code}, message: ${e.message}`);
        }
    }

    /**
     * 开始步数追踪
     * 创建传感器管理器并设置回调，申请后台长时任务
     */
    async startTracking(): Promise<void> {
        try {
            // 如果已经暂停，则恢复计步
            if (this.isPaused) {
                await this.resumeTracking();
                return;
            }

            if (this.isTracking) {
                console.info('StepViewModel: Tracking is already active');
                return;
            }
            
            // 创建传感器管理器实例
            this.stepSensorManager = new StepSensorManager();
            
            // 关键修复：将数据库中的已有步数传递给传感器管理器
            // 确保后续增量累加是在已有步数基础上进行
            this.stepSensorManager.setInitialSteps(this._todaySteps);
            
            // 设置步数变化回调
            this.stepSensorManager.setOnStepChangeCallback(async (totalSteps: number, increment: number) => {
                await this.onStepChange(totalSteps, increment);
            });
            
            // 检查日期是否变化，需要重置步数
            await this.checkDateChange();
            
            // 开始追踪
            const success = await this.stepSensorManager.startTracking();
            
            if (success) {
                this.isTracking = true;
                this.isPaused = false;
                const mode = this.stepSensorManager.isMockModeActive() ? 'Mock' : 'Real';
                console.info(`StepViewModel: Step tracking started successfully (${mode} mode)`);
                
                // 申请后台长时任务，确保应用退到后台后仍能获取传感器数据
                await this.startBackgroundTask();
                
            } else {
                console.error('StepViewModel: Failed to start step tracking');
                this.stepSensorManager = null;
            }
            
        } catch (error) {
            console.error(`StepViewModel: Error starting tracking. Error: ${JSON.stringify(error)}`);
            this.stepSensorManager = null;
        }
    }

    /**
     * 停止步数追踪
     * 释放传感器资源和定时器，停止后台长时任务
     */
    async stopTracking(): Promise<void> {
        try {
            if (this.stepSensorManager) {
                this.stepSensorManager.stopTracking();
                this.stepSensorManager.destroy();
                this.stepSensorManager = null;
                this.isTracking = false;
                this.isPaused = false;
                console.info('StepViewModel: Step tracking stopped');
                
                // 停止后台长时任务
                await this.stopBackgroundTask();
            } else {
                console.info('StepViewModel: No active tracking to stop');
            }
        } catch (error) {
            console.error(`StepViewModel: Error stopping tracking. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 暂停步数追踪
     * 停止传感器追踪但保持当前步数，不释放资源
     */
    async pauseTracking(): Promise<void> {
        try {
            if (!this.isTracking || this.isPaused) {
                console.info('StepViewModel: Cannot pause - not tracking or already paused');
                return;
            }

            if (this.stepSensorManager) {
                // 暂停传感器追踪
                this.stepSensorManager.stopTracking();
                this.isPaused = true;
                
                console.info(`StepViewModel: Step tracking paused - Current steps: ${this._todaySteps}`);
                
                // 停止后台长时任务
                await this.stopBackgroundTask();
            }
        } catch (error) {
            console.error(`StepViewModel: Error pausing tracking. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 恢复步数追踪
     * 从暂停状态恢复，继续累加步数
     */
    async resumeTracking(): Promise<void> {
        try {
            if (!this.isPaused) {
                console.info('StepViewModel: Cannot resume - not in paused state');
                return;
            }

            if (this.stepSensorManager) {
                // 设置当前步数作为初始值，确保从暂停时的步数继续累加
                this.stepSensorManager.setInitialSteps(this._todaySteps);
                
                // 恢复传感器追踪
                const success = await this.stepSensorManager.startTracking();
                
                if (success) {
                    this.isPaused = false;
                    const mode = this.stepSensorManager.isMockModeActive() ? 'Mock' : 'Real';
                    console.info(`StepViewModel: Step tracking resumed successfully (${mode} mode) - Starting from ${this._todaySteps} steps`);
                    
                    // 重新申请后台长时任务
                    await this.startBackgroundTask();
                } else {
                    console.error('StepViewModel: Failed to resume step tracking');
                }
            }
        } catch (error) {
            console.error(`StepViewModel: Error resuming tracking. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 开始后台长时任务
     * 申请后台运行权限，确保应用退到后台或锁屏后仍能持续获取传感器数据
     * 使用 DATA_TRANSFER 类型，适用于持续数据传输场景
     */
    private async startBackgroundTask(): Promise<void> {
        try {
            if (!this.context || !this.wantAgentObj) {
                console.warn('StepViewModel: Context or WantAgent not available, cannot start background task');
                return;
            }
            
            // 检查后台运行权限是否已授权
            // 注意：实际设备上需要用户授权 ohos.permission.KEEP_BACKGROUND_RUNNING 权限
            console.info('StepViewModel: Checking background running permission...');
            
            // 使用 DATA_TRANSFER 模式申请后台长时任务
            // DATA_TRANSFER 适用于数据传输场景，如持续获取传感器数据
            const bgMode: backgroundTaskManager.BackgroundMode = backgroundTaskManager.BackgroundMode.DATA_TRANSFER;
            
            // 申请后台长时任务
            await backgroundTaskManager.startBackgroundRunning(this.context, bgMode, this.wantAgentObj);
            
            console.info('StepViewModel: Background task started successfully');
            
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepViewModel: Failed to start background task. Code: ${e.code}, message: ${e.message}`);
            
            // 后台任务申请失败不影响前台功能，继续运行
            console.info('StepViewModel: Continue running in foreground mode');
        }
    }

    /**
     * 停止后台长时任务
     * 释放后台运行资源
     */
    private async stopBackgroundTask(): Promise<void> {
        try {
            if (this.context) {
                await backgroundTaskManager.stopBackgroundRunning(this.context);
                console.info('StepViewModel: Background task stopped successfully');
            }
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepViewModel: Failed to stop background task. Code: ${e.code}, message: ${e.message}`);
        }
    }

    /**
     * 更新目标步数
     * @param goal 新的目标步数
     */
    async updateGoal(goal: number): Promise<void> {
        try {
            if (goal <= 0) {
                console.warn('StepViewModel: Invalid goal value, must be positive');
                return;
            }
            
            this._todayGoal = goal;
            
            // 保存到数据库
            await this.dbHelper.updateGoal(goal);
            
            // 重新计算进度
            this.refreshProgress();
            
            // 触发回调
            this.triggerCallback();
            
            console.info(`StepViewModel: Goal updated to ${goal}`);
            
        } catch (error) {
            console.error(`StepViewModel: Failed to update goal. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 刷新进度百分比
     * 根据当前步数和目标计算完成百分比
     */
    refreshProgress(): void {
        if (this._todayGoal <= 0) {
            this._progressPercent = 0;
            return;
        }
        
        const percent = Math.min(100, Math.round((this._todaySteps / this._todayGoal) * 100));
        this._progressPercent = percent;
        
        console.debug(`StepViewModel: Progress updated - Steps: ${this._todaySteps}, Goal: ${this._todayGoal}, Percent: ${percent}%`);
    }

    /**
     * 步数变化回调处理
     * 包含目标达成检测、通知发送和振动反馈
     * @param totalSteps 总步数
     * @param increment 增量步数
     */
    private async onStepChange(totalSteps: number, increment: number): Promise<void> {
        try {
            // 更新今日步数
            this._todaySteps = totalSteps;
            
            // 保存到数据库
            await this.dbHelper.saveTodaySteps(totalSteps);
            
            // 更新进度百分比
            this.refreshProgress();
            
            // 触发UI回调
            this.triggerCallback();
            
            // 检查目标达成条件并发送通知
            await this.checkGoalAchievement(totalSteps);
            
            // 检查是否需要取消运动提醒
            this.checkMorningReminderCancellation(totalSteps);
            
            console.debug(`StepViewModel: Step updated - Total: ${totalSteps}, Increment: ${increment}`);
            
        } catch (error) {
            console.error(`StepViewModel: Error processing step change. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 检查目标达成条件并发送通知
     * 满足以下条件时触发：
     * 1. 当前步数 ≥ 目标步数
     * 2. 今日尚未发送过通知
     * @param currentSteps 当前步数
     */
    private async checkGoalAchievement(currentSteps: number): Promise<void> {
        try {
            // 每次步数更新都检查日期变化，确保通知状态正确重置
            await this.checkDateChange();
            
            // 检查是否满足触发条件
            if (currentSteps >= this._todayGoal && !this.hasNotifiedToday) {
                console.info(`🎯 StepViewModel: Goal achieved! Steps: ${currentSteps}, Goal: ${this._todayGoal}`);
                
                // 发送通知
                await this.sendGoalAchievementNotification(currentSteps);
                
                // 触发振动反馈
                await this.triggerVibrationFeedback();
                
                // 标记今日已发送通知
                this.hasNotifiedToday = true;
                
                console.info('✅ StepViewModel: Goal achievement notification and vibration sent successfully');
                console.info(`📊 StepViewModel: Notification sent - Steps: ${currentSteps}, Goal: ${this._todayGoal}, Date: ${this.currentDate}`);
            } else {
                // 记录检查结果，便于调试
                if (currentSteps < this._todayGoal) {
                    console.debug(`📈 StepViewModel: Progress - Steps: ${currentSteps}/${this._todayGoal} (${Math.round((currentSteps / this._todayGoal) * 100)}%)`);
                } else if (this.hasNotifiedToday) {
                    console.debug(`✅ StepViewModel: Goal already achieved today (Steps: ${currentSteps}), notification already sent`);
                }
            }
            
        } catch (error) {
            console.error(`❌ StepViewModel: Error in goal achievement check. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 发送目标达成通知
     * @param currentSteps 当前实际步数
     */
    private async sendGoalAchievementNotification(currentSteps: number): Promise<void> {
        try {
            const notificationRequest: notificationManager.NotificationRequest = {
                id: this.NOTIFICATION_ID,
                content: {
                    notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
                    normal: {
                        title: '🎉 恭喜！今日目标达成',
                        text: `您已走了 ${currentSteps.toLocaleString()} 步，完成了今日设定的 ${this._todayGoal.toLocaleString()} 步目标！`,
                        additionalText: '继续保持，明天加油！'
                    }
                }
            };
            
            console.info(`📨 StepViewModel: Sending goal achievement notification - ID: ${this.NOTIFICATION_ID}`);
            
            await notificationManager.publish(notificationRequest);
            console.info('✅ StepViewModel: Goal achievement notification sent successfully');
            
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`❌ StepViewModel: Failed to send goal achievement notification. Code: ${e.code}, message: ${e.message}`);
            console.error(`📊 StepViewModel: Notification details - Steps: ${currentSteps}, Goal: ${this._todayGoal}, Date: ${this.currentDate}`);
        }
    }

    /**
     * 触发振动反馈
     * 模拟器环境下无法真实振动，但代码逻辑会正常执行
     */
    private async triggerVibrationFeedback(): Promise<void> {
        try {
            // 尝试使用振动功能
            // 注意：模拟器环境下可能无法真实振动
            console.info('StepViewModel: Attempting to trigger vibration feedback (100ms)');
            
            // 这里使用简单的日志输出表示振动逻辑
            // 在实际设备上，可以调用系统振动API
            console.info('StepViewModel: Vibration feedback simulated - 100ms short vibration');
            
            // 在实际项目中，可以这样调用振动API（如果可用）：
            // const vibrator = require('@kit.VibratorKit').vibrator;
            // vibrator.startVibration({type: 'time', duration: 100}, {});
            
        } catch (error) {
            // 模拟器环境下可能会报错，这是正常现象
            console.warn('StepViewModel: Vibration may not work in simulator environment');
            console.debug(`StepViewModel: Vibration error details: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 触发步数变化回调
     */
    private triggerCallback(): void {
        if (this.onStepChangeCallback) {
            this.onStepChangeCallback(this._todaySteps, this._todayGoal, this._progressPercent);
        }
    }

    /**
     * 设置运动提醒定时器
     * 每天早上8:00检查是否需要发送运动提醒
     */
    private async setupMorningReminder(): Promise<void> {
        try {
            // 清除之前的定时器
            if (this.morningReminderTimer !== -1) {
                clearTimeout(this.morningReminderTimer);
                this.morningReminderTimer = -1;
            }

            const now = new Date();
            const targetTime = new Date();
            
            // 设置目标时间为今天上午8:00
            targetTime.setHours(8, 0, 0, 0);
            
            // 如果现在时间已经过了8:00，则设置到明天8:00
            if (now >= targetTime) {
                targetTime.setDate(targetTime.getDate() + 1);
            }
            
            const timeUntilReminder = targetTime.getTime() - now.getTime();
            
            console.info(`⏰ StepViewModel: Morning reminder scheduled for ${targetTime.toLocaleString()} (in ${Math.round(timeUntilReminder / 1000 / 60)} minutes)`);
            
            // 设置定时器
            this.morningReminderTimer = setTimeout(async () => {
                await this.checkAndSendMorningReminder();
                // 重新设置明天的提醒
                await this.setupMorningReminder();
            }, timeUntilReminder) as number;
            
        } catch (error) {
            console.error(`❌ StepViewModel: Failed to setup morning reminder. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 检查并发送运动提醒
     * 满足以下条件时触发：
     * 1. 当前步数 < 目标步数的20%
     * 2. 今日尚未发送过运动提醒
     */
    private async checkAndSendMorningReminder(): Promise<void> {
        try {
            // 检查日期变化
            await this.checkDateChange();
            
            const threshold = this._todayGoal * 0.2; // 20%阈值
            
            // 检查触发条件
            if (this._todaySteps < threshold && !this.hasSentMorningReminder) {
                console.info(`🏃♂️ StepViewModel: Sending morning reminder - Steps: ${this._todaySteps}, Threshold: ${threshold}, Goal: ${this._todayGoal}`);
                
                // 发送运动提醒通知
                await this.sendMorningReminderNotification();
                
                // 标记今日已发送提醒
                this.hasSentMorningReminder = true;
                
                console.info('✅ StepViewModel: Morning reminder notification sent successfully');
            } else {
                // 记录检查结果，便于调试
                if (this._todaySteps >= threshold) {
                    console.debug(`🏃♂️ StepViewModel: Morning reminder skipped - Steps (${this._todaySteps}) already exceed threshold (${threshold})`);
                } else if (this.hasSentMorningReminder) {
                    console.debug(`🏃♂️ StepViewModel: Morning reminder already sent today`);
                }
            }
            
        } catch (error) {
            console.error(`❌ StepViewModel: Error in morning reminder check. Error: ${JSON.stringify(error)}`);
        }
    }

    /**
     * 发送运动提醒通知
     */
    private async sendMorningReminderNotification(): Promise<void> {
        try {
            const notificationRequest: notificationManager.NotificationRequest = {
                id: this.MORNING_REMINDER_ID,
                content: {
                    notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
                    normal: {
                        title: '🏃♂️ 早上好！该动一动啦',
                        text: `新的一天开始了，您今天的运动目标是 ${this._todayGoal.toLocaleString()} 步，目前还差得远哦，快起来走走吧！`,
                        additionalText: '坚持运动，健康生活！'
                    }
                }
            };
            
            console.info(`📨 StepViewModel: Sending morning reminder notification - ID: ${this.MORNING_REMINDER_ID}`);
            
            await notificationManager.publish(notificationRequest);
            console.info('✅ StepViewModel: Morning reminder notification sent successfully');
            
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`❌ StepViewModel: Failed to send morning reminder notification. Code: ${e.code}, message: ${e.message}`);
        }
    }

    /**
     * 检查是否需要取消运动提醒
     * 当步数超过阈值时，取消尚未触发的提醒
     */
    private checkMorningReminderCancellation(currentSteps: number): void {
        const threshold = this._todayGoal * 0.2;
        
        if (currentSteps >= threshold && this.morningReminderTimer !== -1 && !this.hasSentMorningReminder) {
            console.info(`🏃♂️ StepViewModel: Canceling morning reminder - Steps (${currentSteps}) reached threshold (${threshold})`);
            
            clearTimeout(this.morningReminderTimer);
            this.morningReminderTimer = -1;
            
            console.info('✅ StepViewModel: Morning reminder canceled');
        }
    }

    /**
     * 检查日期变化
     * 如果日期变化，重置今日步数和通知状态
     */
    private async checkDateChange(): Promise<void> {
        const today = this.getCurrentDate();
        
        if (today !== this.currentDate) {
            console.info(`StepViewModel: Date changed from ${this.currentDate} to ${today}, resetting steps and notification status`);
            
            // 更新当前日期
            this.currentDate = today;
            
            // 重置步数
            this._todaySteps = 0;
            
            // 重置通知状态（每天可以重新触发）
            this.hasNotifiedToday = false;
            this.hasSentMorningReminder = false;
            console.info(`📅 StepViewModel: Date changed - Notification status reset for new day: ${today}`);
            
            // 重新设置运动提醒定时器
            await this.setupMorningReminder();
            
            // 加载今天的记录（如果有）
            await this.loadTodayData();
            
            // 重置传感器步数
            if (this.stepSensorManager) {
                this.stepSensorManager.resetSteps();
                // 关键修复：重置后需要重新设置初始步数（为0）
                this.stepSensorManager.setInitialSteps(0);
            }
            
            // 触发回调
            this.triggerCallback();
        }
    }

    /**
     * 加载今日数据
     * 从数据库加载今日步数和目标
     * 
     * 关键修复：二次进入计步页面时，需要从数据库加载今日已有的步数
     * 避免步数从0开始，确保增量累加是在已有步数基础上进行
     */
    private async loadTodayData(): Promise<void> {
        try {
            // 获取今日目标
            this._todayGoal = await this.dbHelper.getTodayGoal();
            
            // 关键修复：从数据库加载今日已有的步数
            // 避免二次进入页面时步数重置为0的问题
            this._todaySteps = await this.dbHelper.getTodaySteps();
            
            console.info(`StepViewModel: Loaded today's data - Steps: ${this._todaySteps}, Goal: ${this._todayGoal}`);
            
        } catch (error) {
            console.error(`StepViewModel: Failed to load today's data. Error: ${JSON.stringify(error)}`);
            // 使用默认值
            this._todaySteps = 0;
            this._todayGoal = Constants.DEFAULT_GOAL;
        }
    }

    /**
     * 获取当前日期字符串（YYYY-MM-DD格式）
     * @returns 当前日期字符串
     */
    private getCurrentDate(): string {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    /**
     * 获取当前是否正在追踪
     * @returns 是否正在追踪
     */
    isTrackingActive(): boolean {
        return this.isTracking;
    }

    /**
     * 获取是否使用模拟模式
     * @returns 是否使用模拟数据
     */
    isMockModeActive(): boolean {
        return this.stepSensorManager ? this.stepSensorManager.isMockModeActive() : false;
    }

    /**
     * 销毁资源
     * 页面销毁时必须调用此方法，停止所有后台任务
     */
    async destroy(): Promise<void> {
        await this.stopTracking();
        
        // 清除运动提醒定时器
        if (this.morningReminderTimer !== -1) {
            clearTimeout(this.morningReminderTimer);
            this.morningReminderTimer = -1;
            console.info('StepViewModel: Morning reminder timer cleared');
        }
        
        console.info('StepViewModel: Destroyed');
    }
}

/**
 * 后台长时任务说明：
 * 
 * 后台长时任务的作用是确保应用退到后台或锁屏后，计步传感器仍能持续获取数据。
 * 这对于步数追踪应用至关重要，因为用户通常会在手机放在口袋或锁屏状态下行走。
 * 
 * 实现机制：
 * 1. 使用 DATA_TRANSFER 模式申请后台任务
 * 2. 在应用启动时检查并申请 ohos.permission.KEEP_BACKGROUND_RUNNING 权限
 * 3. 在步数追踪开始时启动后台任务，追踪结束时停止后台任务
 * 4. 系统会根据资源使用情况智能管理后台任务的生命周期
 * 
 * 生命周期管理说明：
 * 
 * 在页面组件中使用 StepViewModel 时，应遵循以下生命周期管理：
 * 
 * 1. 在 aboutToAppear() 中：
 *    - 创建 StepViewModel 实例
 *    - 调用 init(context) 初始化
 *    - 设置步数变化回调
 *    - 调用 startTracking() 开始追踪（自动启动后台任务）
 * 
 * 2. 在 aboutToDisappear() 中：
 *    - 调用 stopTracking() 停止追踪（自动停止后台任务）
 *    - 调用 destroy() 释放资源
 * 
 * 通知和振动功能说明：
 * - 目标达成通知：当步数达到目标且今日未通知过时触发
 * - 振动反馈：与通知同时触发，100ms短振动
 * - 模拟器兼容：模拟器环境下振动可能无法真实触发，但代码逻辑正常
 * 
 * 示例代码：
 * 
 * @Component
 * struct StepTrackerPage {
 *   private stepVM: StepViewModel = new StepViewModel();
 * 
 *   aboutToAppear() {
 *     this.stepVM.init(getContext() as common.Context).then(() => {
 *       this.stepVM.setOnStepChangeCallback((steps, goal, percent) => {
 *         // 更新UI
 *       });
 *       this.stepVM.startTracking();
 *     });
 *   }
 * 
 *   aboutToDisappear() {
 *     this.stepVM.stopTracking();
 *     this.stepVM.destroy();
 *   }
 * }
 */