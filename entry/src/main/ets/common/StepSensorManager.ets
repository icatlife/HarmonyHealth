import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Constants } from './Constants';

/**
 * 模拟传感器数据结构
 */
interface MockSensorData {
    steps: number;
    timestamp: number;
}

/**
 * 计步传感器管理器
 * 用于封装计步传感器的订阅和管理逻辑
 * 包含模拟器降级逻辑，用于兼容模拟器和传感器异常情况
 */
export class StepSensorManager {
    /**
     * 传感器订阅ID
     */
    private subscriptionId: number | null = null;
    
    /**
     * 累计步数
     */
    private stepCount: number = 0;
    
    /**
     * 步数变化回调函数
     */
    private onStepChangeCallback: ((stepCount: number, increment: number) => void) | null = null;
    
    /**
     * 上次记录的步数值（用于计算增量）
     */
    private lastStepValue: number = 0;
    
    /**
     * 传感器是否正在运行
     */
    private isTracking: boolean = false;

    /**
     * 模拟步数定时器ID
     */
    private mockTimerId: number | null = null;

    /**
     * 传感器超时检测定时器ID
     */
    private sensorTimeoutId: number | null = null;

    /**
     * 是否正在使用模拟模式
     */
    private isMockMode: boolean = false;

    /**
     * 是否已收到第一个有效传感器数据
     */
    private hasReceivedFirstData: boolean = false;

    /**
     * 设置步数变化回调
     * @param callback 步数变化时的回调函数，参数为当前总步数和增量步数
     */
    public setOnStepChangeCallback(callback: (stepCount: number, increment: number) => void): void {
        this.onStepChangeCallback = callback;
    }

    /**
     * 开始步数追踪
     * @returns Promise<boolean> 启动是否成功
     */
    public async startTracking(): Promise<boolean> {
        try {
            // 检查是否已经在追踪
            if (this.isTracking) {
                console.info('StepSensorManager: Step tracking is already running');
                return true;
            }

            // 判断是否使用模拟模式
            if (Constants.USE_MOCK_STEPS) {
                console.info('StepSensorManager: Using mock step data (simulator mode)');
                this.startMockStepTracking();
                return true;
            }

            console.info('StepSensorManager: Attempting to use real sensor data');
            
            // 检查PEDOMETER传感器是否可用
            const sensorList = await sensor.getSensorList();
            const pedometerSensor = sensorList.find(s => s.sensorId === sensor.SensorId.PEDOMETER);
            
            if (!pedometerSensor) {
                console.warn('StepSensorManager: PEDOMETER sensor is not available, falling back to mock mode');
                this.startMockStepTracking();
                return false;
            }

            console.info('StepSensorManager: PEDOMETER sensor is available');

            // 订阅PEDOMETER传感器
            sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
                this.handleRealSensorData(data);
            }, { interval: 100000000 });

            this.isTracking = true;
            this.isMockMode = false;
            this.hasReceivedFirstData = false;
            
            // 启动传感器超时检测
            this.startSensorTimeoutDetection();
            
            console.info('StepSensorManager: Real sensor tracking started successfully');
            
            return true;
            
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepSensorManager: Failed to start step tracking. Code: ${e.code}, message: ${e.message}`);
            
            // 检查是否是权限错误或其他异常，降级到模拟模式
            console.warn('StepSensorManager: Falling back to mock mode due to error');
            this.startMockStepTracking();
            
            return false;
        }
    }

    /**
     * 启动模拟步数追踪
     * 在模拟器或传感器不可用时使用
     */
    private startMockStepTracking(): void {
        console.info('StepSensorManager: Starting mock step tracking');
        
        this.isTracking = true;
        this.isMockMode = true;
        
        // 清除之前的模拟定时器
        if (this.mockTimerId !== null) {
            clearInterval(this.mockTimerId);
        }
        
        // 启动模拟步数定时器
        this.mockTimerId = setInterval(() => {
            this.generateMockSteps();
        }, this.getRandomInterval(3000, 5000));
        
        console.info('StepSensorManager: Mock step tracking started');
    }

    /**
     * 生成模拟步数
     * 模拟真实步数增长模式
     */
    private generateMockSteps(): void {
        // 生成随机步数增量（5-15步）
        const increment = Math.floor(Math.random() * 11) + 5;
        
        // 模拟传感器数据格式
        const mockData: MockSensorData = {
            steps: this.lastStepValue + increment,
            timestamp: Date.now()
        };
        
        // 使用相同的处理逻辑
        this.handleMockSensorData(mockData);
        
        console.debug(`StepSensorManager: Generated mock steps - Increment: ${increment}, Total: ${this.stepCount}`);
    }

    /**
     * 启动传感器超时检测
     * 如果10秒内未收到有效数据，自动切换到模拟模式
     */
    private startSensorTimeoutDetection(): void {
        // 清除之前的超时定时器
        if (this.sensorTimeoutId !== null) {
            clearTimeout(this.sensorTimeoutId);
        }
        
        this.sensorTimeoutId = setTimeout(() => {
            if (!this.hasReceivedFirstData && !this.isMockMode) {
                console.warn('StepSensorManager: Sensor timeout - no data received in 10 seconds, switching to mock mode');
                this.stopRealSensorTracking();
                this.startMockStepTracking();
            }
        }, 10000); // 10秒超时
        
        console.info('StepSensorManager: Sensor timeout detection started (10 seconds)');
    }

    /**
     * 停止真实传感器追踪
     */
    private stopRealSensorTracking(): void {
        try {
            if (!this.isMockMode) {
                sensor.off(sensor.SensorId.PEDOMETER);
                console.info('StepSensorManager: Real sensor tracking stopped');
            }
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepSensorManager: Error stopping real sensor. Code: ${e.code}, message: ${e.message}`);
        }
    }

    /**
     * 停止步数追踪
     */
    public stopTracking(): void {
        try {
            if (this.isTracking) {
                // 停止真实传感器追踪
                if (!this.isMockMode) {
                    this.stopRealSensorTracking();
                }
                
                // 清除模拟定时器
                if (this.mockTimerId !== null) {
                    clearInterval(this.mockTimerId);
                    this.mockTimerId = null;
                    console.info('StepSensorManager: Mock timer cleared');
                }
                
                // 清除超时检测定时器
                if (this.sensorTimeoutId !== null) {
                    clearTimeout(this.sensorTimeoutId);
                    this.sensorTimeoutId = null;
                    console.info('StepSensorManager: Sensor timeout detection cleared');
                }
                
                this.isTracking = false;
                this.isMockMode = false;
                this.hasReceivedFirstData = false;
                
                console.info('StepSensorManager: All tracking stopped');
            } else {
                console.info('StepSensorManager: No active tracking to stop');
            }
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepSensorManager: Failed to stop step tracking. Code: ${e.code}, message: ${e.message}`);
        }
    }

    /**
     * 获取当前累计步数
     * @returns number 当前累计步数
     */
    public getCurrentSteps(): number {
        return this.stepCount;
    }

    /**
     * 重置步数计数器
     */
    public resetSteps(): void {
        this.stepCount = 0;
        this.lastStepValue = 0;
        console.info('StepSensorManager: Step count reset to 0');
    }

    /**
     * 设置初始步数
     * 用于从数据库加载已有步数后，设置到传感器管理器中
     * @param initialSteps 初始步数
     */
    public setInitialSteps(initialSteps: number): void {
        this.stepCount = initialSteps;
        this.lastStepValue = initialSteps;
        console.info(`StepSensorManager: Initial steps set to ${initialSteps}`);
    }

    /**
     * 检查是否正在追踪步数
     * @returns boolean 是否正在追踪
     */
    public isTrackingActive(): boolean {
        return this.isTracking;
    }

    /**
     * 检查是否处于模拟模式
     * @returns boolean 是否使用模拟数据
     */
    public isMockModeActive(): boolean {
        return this.isMockMode;
    }

    /**
     * 处理真实传感器数据
     * @param data 传感器数据
     */
    private handleRealSensorData(data: sensor.PedometerResponse): void {
        try {
            // 标记已收到第一个有效数据（清除超时检测）
            if (!this.hasReceivedFirstData) {
                this.hasReceivedFirstData = true;
                if (this.sensorTimeoutId !== null) {
                    clearTimeout(this.sensorTimeoutId);
                    this.sensorTimeoutId = null;
                    console.info('StepSensorManager: First sensor data received, timeout detection cleared');
                }
            }

            // 获取步数值
            const currentStepValue = data.steps;
            
            // 计算增量步数（首次运行时lastStepValue为0，增量就是当前值）
            const increment = this.lastStepValue === 0 ? currentStepValue : currentStepValue - this.lastStepValue;
            
            // 确保增量是正数（传感器重启时可能会重置）
            if (increment > 0) {
                this.stepCount += increment;
                this.lastStepValue = currentStepValue;
                
                console.debug(`StepSensorManager: Real step update - Current: ${currentStepValue}, Increment: ${increment}, Total: ${this.stepCount}`);
                
                // 通知回调函数
                if (this.onStepChangeCallback) {
                    this.onStepChangeCallback(this.stepCount, increment);
                }
            } else if (increment < 0) {
                // 传感器可能被重置，重新设置基准值
                console.warn('StepSensorManager: Sensor reset detected, resetting baseline');
                this.lastStepValue = currentStepValue;
            }
            
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepSensorManager: Error processing real sensor data. Code: ${e.code}, message: ${e.message}`);
        }
    }

    /**
     * 处理模拟传感器数据
     * @param data 模拟传感器数据
     */
    private handleMockSensorData(data: MockSensorData): void {
        try {
            // 获取步数值
            const currentStepValue = data.steps;
            
            // 计算增量步数（首次运行时lastStepValue为0，增量就是当前值）
            const increment = this.lastStepValue === 0 ? currentStepValue : currentStepValue - this.lastStepValue;
            
            // 确保增量是正数
            if (increment > 0) {
                this.stepCount += increment;
                this.lastStepValue = currentStepValue;
                
                console.debug(`StepSensorManager: Mock step update - Current: ${currentStepValue}, Increment: ${increment}, Total: ${this.stepCount}`);
                
                // 通知回调函数
                if (this.onStepChangeCallback) {
                    this.onStepChangeCallback(this.stepCount, increment);
                }
            }
            
        } catch (error) {
            const e: BusinessError = error as BusinessError;
            console.error(`StepSensorManager: Error processing mock sensor data. Code: ${e.code}, message: ${e.message}`);
        }
    }

    /**
     * 获取随机时间间隔（毫秒）
     * @param min 最小间隔
     * @param max 最大间隔
     * @returns 随机间隔
     */
    private getRandomInterval(min: number, max: number): number {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    /**
     * 销毁资源
     */
    public destroy(): void {
        this.stopTracking();
        this.onStepChangeCallback = null;
        console.info('StepSensorManager: Step sensor manager destroyed');
    }
}