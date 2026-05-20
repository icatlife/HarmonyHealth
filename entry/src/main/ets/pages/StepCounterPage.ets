import { StepViewModel } from '../viewmodel/StepViewModel';
import { AppColors, AppStyles, getProgressColor } from '../common/Constants';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

/**
 * 计步核心页面
 * 实时显示步数、目标进度和健康数据
 * 采用薄荷绿主题设计风格
 * 支持手动开始/暂停计步
 */
@Entry
@Component
struct StepCounterPage {
  private stepVM: StepViewModel = StepViewModel.getInstance();
  
  @State private currentSteps: number = 0;
  @State private goalSteps: number = 10000;
  @State private progressPercent: number = 0;
  @State private isTracking: boolean = false;
  @State private isPaused: boolean = false;
  @State private caloriesBurned: number = 0;
  @State private distanceWalked: number = 0;
  
  @State private animatedProgress: number = 0;
  @State private stepNumberAnimation: number = 0;
  
  aboutToAppear(): void {
    console.info('StepCounterPage: aboutToAppear - Initializing step counter');
    
    // 设置步数变化回调
    this.stepVM.setOnStepChangeCallback((steps: number, goal: number, percent: number) => {
      this.updateUI(steps, goal, percent);
    });
    
    // 初始化 ViewModel，但不自动开始计步
    this.stepVM.init(getContext() as common.Context).then(() => {
      // 从 ViewModel 获取当前状态
      this.isTracking = this.stepVM.tracking;
      this.isPaused = this.stepVM.paused;
      
      // 更新UI显示当前步数
      this.updateUI(this.stepVM.todaySteps, this.stepVM.todayGoal, this.stepVM.progressPercent);
      
      console.info(`StepCounterPage: Initialized - Steps: ${this.stepVM.todaySteps}, Tracking: ${this.isTracking}, Paused: ${this.isPaused}`);
    }).catch((error: Error) => {
      console.error(`StepCounterPage: Failed to initialize. Error: ${JSON.stringify(error)}`);
    });
  }
  
  /**
   * 页面即将消失
   * 只清除回调，不停止追踪
   */
  aboutToDisappear(): void {
    console.info('StepCounterPage: aboutToDisappear - Clearing callbacks only');
    this.stepVM.setOnStepChangeCallback(null);
  }
  
  /**
   * 开始计步
   */
  private async handleStartTracking(): Promise<void> {
    try {
      console.info('StepCounterPage: Starting tracking');
      await this.stepVM.startTracking();
      this.isTracking = this.stepVM.tracking;
      this.isPaused = this.stepVM.paused;
      console.info(`StepCounterPage: Tracking started - isTracking: ${this.isTracking}, isPaused: ${this.isPaused}`);
    } catch (error) {
      console.error(`StepCounterPage: Failed to start tracking. Error: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 暂停计步
   */
  private async handlePauseTracking(): Promise<void> {
    try {
      console.info('StepCounterPage: Pausing tracking');
      await this.stepVM.pauseTracking();
      this.isTracking = this.stepVM.tracking;
      this.isPaused = this.stepVM.paused;
      console.info(`StepCounterPage: Tracking paused - isTracking: ${this.isTracking}, isPaused: ${this.isPaused}`);
    } catch (error) {
      console.error(`StepCounterPage: Failed to pause tracking. Error: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 恢复计步
   */
  private async handleResumeTracking(): Promise<void> {
    try {
      console.info('StepCounterPage: Resuming tracking');
      await this.stepVM.startTracking(); // startTracking 会自动处理恢复逻辑
      this.isTracking = this.stepVM.tracking;
      this.isPaused = this.stepVM.paused;
      console.info(`StepCounterPage: Tracking resumed - isTracking: ${this.isTracking}, isPaused: ${this.isPaused}`);
    } catch (error) {
      console.error(`StepCounterPage: Failed to resume tracking. Error: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 停止计步
   */
  private async handleStopTracking(): Promise<void> {
    try {
      console.info('StepCounterPage: Stopping tracking');
      await this.stepVM.stopTracking();
      this.isTracking = this.stepVM.tracking;
      this.isPaused = this.stepVM.paused;
      console.info(`StepCounterPage: Tracking stopped - isTracking: ${this.isTracking}, isPaused: ${this.isPaused}`);
    } catch (error) {
      console.error(`StepCounterPage: Failed to stop tracking. Error: ${JSON.stringify(error)}`);
    }
  }
  
  private updateUI(steps: number, goal: number, percent: number): void {
    this.animateNumber(this.stepNumberAnimation, steps, 1000, (value: number) => {
      this.stepNumberAnimation = value;
    });
    
    this.animateNumber(this.animatedProgress, percent, 800, (value: number) => {
      this.animatedProgress = value;
    });
    
    this.currentSteps = steps;
    this.goalSteps = goal;
    this.progressPercent = percent;
    
    this.caloriesBurned = Math.round(steps * 0.04);
    this.distanceWalked = Math.round(steps * 0.7) / 1000;
  }
  
  private animateNumber(start: number, end: number, duration: number, callback: (value: number) => void): void {
    const startTime = Date.now();
    const animate = () => {
      const currentTime = Date.now();
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      const easeOutQuart = 1 - Math.pow(1 - progress, 4);
      const currentValue = start + (end - start) * easeOutQuart;
      
      callback(Math.round(currentValue));
      
      if (progress < 1) {
        setTimeout(animate, 16);
      }
    };
    animate();
  }
  
  private getEncouragementText(): string {
    if (this.progressPercent >= 100) {
      return '🎉 恭喜！今日目标已达成！';
    } else if (this.progressPercent >= 80) {
      return '💪 接近目标了，继续加油！';
    } else if (this.progressPercent >= 50) {
      return '🌟 已经完成一半了，真棒！';
    } else if (this.progressPercent >= 25) {
      return '🚶 良好的开始，继续保持！';
    } else {
      return '👣 迈出第一步，开始今天的运动吧！';
    }
  }
  
  /**
   * 获取状态文本
   */
  private getStatusText(): string {
    if (!this.isTracking) {
      return '未开始';
    } else if (this.isPaused) {
      return '已暂停';
    } else {
      return '计步中';
    }
  }
  
  /**
   * 获取状态颜色
   */
  private getStatusColor(): string {
    if (!this.isTracking) {
      return AppColors.TEXT_TERTIARY;
    } else if (this.isPaused) {
      return AppColors.WARNING;
    } else {
      return AppColors.SUCCESS;
    }
  }
  
  build() {
    Column({ space: 0 }) {
      this.buildHeader()
      
      Scroll() {
        Column({ space: AppStyles.SPACING_LG }) {
          this.buildStepCard()
          this.buildControlButtons()
          this.buildProgressSection()
          this.buildHealthStats()
          this.buildEncouragement()
        }
        .padding(AppStyles.SPACING_LG)
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
  
  @Builder
  buildHeader() {
    Row({ space: AppStyles.SPACING_MD }) {
      Button('←', { type: ButtonType.Normal, stateEffect: true })
        .width(40)
        .height(40)
        .backgroundColor(AppColors.CARD_BACKGROUND)
        .fontColor(AppColors.PRIMARY)
        .borderRadius(20)
        .shadow(AppStyles.CARD_SHADOW_LIGHT)
        .onClick(() => {
          router.back();
        })
      
      Text('步数追踪')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
      
      // 状态指示器
      Row({ space: 8 }) {
        Circle({ width: 8, height: 8 })
          .fill(this.getStatusColor())
        
        Text(this.getStatusText())
          .fontSize(12)
          .fontColor(this.getStatusColor())
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(AppColors.CARD_BACKGROUND)
      .borderRadius(12)
      .shadow(AppStyles.CARD_SHADOW_LIGHT)
    }
    .width('100%')
    .padding({ left: AppStyles.SPACING_LG, right: AppStyles.SPACING_LG, top: 12, bottom: 12 })
    .backgroundColor(AppColors.BACKGROUND)
  }
  
  @Builder
  buildStepCard() {
    Column({ space: AppStyles.SPACING_MD }) {
      Row({ space: AppStyles.SPACING_MD }) {
        Text('👣')
          .fontSize(24)
        
        Text('今日步数')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      
      Text(this.stepNumberAnimation.toLocaleString())
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
        .textAlign(TextAlign.Center)
      
      Text(`目标: ${this.goalSteps.toLocaleString()} 步`)
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
  
  /**
   * 控制按钮区域
   */
  @Builder
  buildControlButtons() {
    Column({ space: AppStyles.SPACING_MD }) {
      // 状态提示
      if (!this.isTracking) {
        Text('点击"开始计步"开始记录您的运动数据')
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
      } else if (this.isPaused) {
        Text('计步已暂停，点击"继续计步"恢复记录')
          .fontSize(14)
          .fontColor(AppColors.WARNING)
          .textAlign(TextAlign.Center)
      } else {
        Text('正在记录您的步数...')
          .fontSize(14)
          .fontColor(AppColors.SUCCESS)
          .textAlign(TextAlign.Center)
      }
      
      // 按钮区域
      Row({ space: AppStyles.SPACING_MD }) {
        if (!this.isTracking) {
          // 未开始状态：显示"开始计步"按钮
          Button('开始计步', { type: ButtonType.Normal, stateEffect: true })
            .width('100%')
            .height(48)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(AppStyles.BORDER_RADIUS)
            .onClick(() => {
              this.handleStartTracking();
            })
        } else if (this.isPaused) {
          // 暂停状态：显示"继续计步"和"停止计步"按钮
          Button('继续计步', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(48)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(AppStyles.BORDER_RADIUS)
            .onClick(() => {
              this.handleResumeTracking();
            })
          
          Button('停止计步', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(48)
            .backgroundColor(AppColors.ERROR)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(AppStyles.BORDER_RADIUS)
            .onClick(() => {
              this.handleStopTracking();
            })
        } else {
          // 计步中状态：显示"暂停计步"和"停止计步"按钮
          Button('暂停计步', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(48)
            .backgroundColor(AppColors.WARNING)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(AppStyles.BORDER_RADIUS)
            .onClick(() => {
              this.handlePauseTracking();
            })
          
          Button('停止计步', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(48)
            .backgroundColor(AppColors.ERROR)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(AppStyles.BORDER_RADIUS)
            .onClick(() => {
              this.handleStopTracking();
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
  
  @Builder
  buildProgressSection() {
    Column({ space: AppStyles.SPACING_MD }) {
      Row({ space: 8 }) {
        Text('完成进度')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        
        Text(`${this.animatedProgress}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(getProgressColor(this.animatedProgress))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      
      Column({ space: AppStyles.SPACING_MD }) {
        Row() {
          Row()
            .width(`${this.animatedProgress}%`)
            .height(12)
            .backgroundColor(getProgressColor(this.animatedProgress))
            .borderRadius(6)
        }
        .width('100%')
        .height(12)
        .backgroundColor(AppColors.BORDER)
        .borderRadius(6)
        
        Text(`${this.currentSteps} / ${this.goalSteps} 步`)
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
  
  @Builder
  buildHealthStats() {
    Column({ space: AppStyles.SPACING_MD }) {
      Text('运动数据')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Start)
      
      Row({ space: AppStyles.SPACING_MD }) {
        // 卡路里消耗
        Column({ space: 8 }) {
          Text('🔥')
            .fontSize(24)
          
          Text(this.caloriesBurned.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WARNING)
          
          Text('卡路里')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .padding(AppStyles.SPACING_MD)
        .backgroundColor(AppColors.BACKGROUND)
        .borderRadius(AppStyles.BORDER_RADIUS)
        
        // 行走距离
        Column({ space: 8 }) {
          Text('📍')
            .fontSize(24)
          
          Text(this.distanceWalked.toFixed(1))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
          
          Text('公里')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .padding(AppStyles.SPACING_MD)
        .backgroundColor(AppColors.BACKGROUND)
        .borderRadius(AppStyles.BORDER_RADIUS)
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
  
  @Builder
  buildEncouragement() {
    Column({ space: AppStyles.SPACING_MD }) {
      Text('💪')
        .fontSize(36)
      
      Text(this.getEncouragementText())
        .fontSize(16)
        .fontColor(AppColors.TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      Text('每一步都在让身体更健康！')
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.PRIMARY_LIGHT + '30')
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .border({ width: 2, color: AppColors.PRIMARY + '30' })
  }
}
