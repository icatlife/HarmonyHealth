import { StepViewModel } from '../viewmodel/StepViewModel';
import { AppColors, AppStyles, getProgressColor } from '../common/Constants';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

/**
 * 计步核心页面
 * 实时显示步数、目标进度和健康数据
 * 采用薄荷绿主题设计风格
 */
@Entry
@Component
struct StepCounterPage {
  private stepVM: StepViewModel = new StepViewModel();
  
  @State private currentSteps: number = 0;
  @State private goalSteps: number = 10000;
  @State private progressPercent: number = 0;
  @State private isTracking: boolean = false;
  @State private caloriesBurned: number = 0;
  @State private distanceWalked: number = 0;
  
  @State private animatedProgress: number = 0;
  @State private stepNumberAnimation: number = 0;
  
  aboutToAppear(): void {
    console.info('StepCounterPage: aboutToAppear - Initializing step counter');
    
    this.stepVM.setOnStepChangeCallback((steps: number, goal: number, percent: number) => {
      this.updateUI(steps, goal, percent);
    });
    
    this.stepVM.init(getContext() as common.Context).then(() => {
      this.stepVM.startTracking().then(() => {
        this.isTracking = true;
        console.info('StepCounterPage: Step tracking started');
      });
    }).catch((error: Error) => {
      console.error(`StepCounterPage: Failed to initialize. Error: ${JSON.stringify(error)}`);
    });
  }
  
  aboutToDisappear(): void {
    console.info('StepCounterPage: aboutToDisappear - Cleaning up resources');
    
    this.stepVM.stopTracking().then(() => {
      this.isTracking = false;
      console.info('StepCounterPage: Step tracking stopped');
    });
    
    this.stepVM.destroy();
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
  
  build() {
    Column({ space: 0 }) {
      this.buildHeader()
      
      Scroll() {
        Column({ space: AppStyles.SPACING_LG }) {
          this.buildStepCard()
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
      
      Row({ space: 8 }) {
        Circle({ width: 8, height: 8 })
          .fill(this.isTracking ? AppColors.SUCCESS : AppColors.ERROR)
        
        Text(this.isTracking ? '追踪中' : '已停止')
          .fontSize(12)
          .fontColor(this.isTracking ? AppColors.SUCCESS : AppColors.ERROR)
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
