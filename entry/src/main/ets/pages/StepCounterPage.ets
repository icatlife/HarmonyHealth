import { StepViewModel } from '../viewmodel/StepViewModel';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

/**
 * 计步核心页面
 * 实时显示步数、目标进度和健康数据
 * 采用现代健康应用设计风格
 */
@Entry
@Component
struct StepCounterPage {
  // 视图模型实例
  private stepVM: StepViewModel = new StepViewModel();
  
  // 页面状态
  @State private currentSteps: number = 0;
  @State private goalSteps: number = 10000;
  @State private progressPercent: number = 0;
  @State private isTracking: boolean = false;
  @State private caloriesBurned: number = 0;
  @State private distanceWalked: number = 0;
  
  // 动画状态
  @State private animatedProgress: number = 0;
  @State private stepNumberAnimation: number = 0;
  
  /**
   * 页面显示时初始化
   */
  aboutToAppear(): void {
    console.info('StepCounterPage: aboutToAppear - Initializing step counter');
    
    // 初始化视图模型
    this.stepVM.init(getContext() as common.Context).then(() => {
      // 设置步数变化回调
      this.stepVM.setOnStepChangeCallback((steps: number, goal: number, percent: number) => {
        this.updateUI(steps, goal, percent);
      });
      
      // 开始步数追踪
      this.stepVM.startTracking().then(() => {
        this.isTracking = true;
        console.info('StepCounterPage: Step tracking started');
      });
    }).catch((error: Error) => {
      console.error(`StepCounterPage: Failed to initialize. Error: ${JSON.stringify(error)}`);
    });
  }
  
  /**
   * 页面消失时清理资源
   */
  aboutToDisappear(): void {
    console.info('StepCounterPage: aboutToDisappear - Cleaning up resources');
    
    // 停止步数追踪
    this.stepVM.stopTracking().then(() => {
      this.isTracking = false;
      console.info('StepCounterPage: Step tracking stopped');
    });
    
    // 释放资源
    this.stepVM.destroy();
  }
  
  /**
   * 更新UI数据
   */
  private updateUI(steps: number, goal: number, percent: number): void {
    // 步数数字动画效果
    this.animateNumber(this.stepNumberAnimation, steps, 1000, (value: number) => {
      this.stepNumberAnimation = value;
    });
    
    // 进度条动画效果
    this.animateNumber(this.animatedProgress, percent, 800, (value: number) => {
      this.animatedProgress = value;
    });
    
    this.currentSteps = steps;
    this.goalSteps = goal;
    this.progressPercent = percent;
    
    // 计算额外数据（每步约0.04卡路里，每步约0.7米）
    this.caloriesBurned = Math.round(steps * 0.04);
    this.distanceWalked = Math.round(steps * 0.7) / 1000; // 转换为公里
  }
  
  /**
   * 数字动画效果
   */
  private animateNumber(start: number, end: number, duration: number, callback: (value: number) => void): void {
    const startTime = Date.now();
    const animate = () => {
      const currentTime = Date.now();
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      // 使用缓动函数让动画更自然
      const easeOutQuart = 1 - Math.pow(1 - progress, 4);
      const currentValue = start + (end - start) * easeOutQuart;
      
      callback(Math.round(currentValue));
      
      if (progress < 1) {
        setTimeout(animate, 16); // 约60fps
      }
    };
    animate();
  }
  
  /**
   * 获取鼓励文案
   */
  private getEncouragementText(): string {
    if (this.progressPercent >= 100) {
      return '🎉 恭喜！今日目标已达成！';
    } else if (this.progressPercent >= 80) {
      return '💪 接近目标了，继续加油！';
    } else if (this.progressPercent >= 50) {
      return '🌟 已经完成一半了，真棒！';
    } else if (this.progressPercent >= 25) {
      return '🚶♂️ 良好的开始，继续保持！';
    } else {
      return '👣 迈出第一步，开始今天的运动吧！';
    }
  }
  
  /**
   * 获取进度条颜色
   */
  private getProgressColor(): ResourceColor {
    if (this.progressPercent >= 100) {
      return '#10B981'; // 成功绿色
    } else if (this.progressPercent >= 70) {
      return '#3B82F6'; // 积极蓝色
    } else if (this.progressPercent >= 40) {
      return '#F59E0B'; // 警告橙色
    } else {
      return '#EF4444'; // 需要努力红色
    }
  }
  
  build() {
    Column({ space: 0 }) {
      // 顶部导航栏
      this.buildHeader()
      
      // 主要内容区域
      Scroll() {
        Column({ space: 32 }) {
          // 步数展示卡片
          this.buildStepCard()
          
          // 进度展示
          this.buildProgressSection()
          
          // 健康数据统计
          this.buildHealthStats()
          
          // 鼓励文案
          this.buildEncouragement()
        }
        .padding(24)
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFC')
  }
  
  /**
   * 构建顶部导航栏
   */
  @Builder
  buildHeader() {
    Row({ space: 12 }) {
      // 返回按钮
      Button('←', { type: ButtonType.Normal, stateEffect: true })
        .width(40)
        .height(40)
        .backgroundColor(Color.White)
        .borderRadius(20)
        .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 })
        .onClick(() => {
          router.back();
        })
      
      Text('步数追踪')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1E293B')
        .layoutWeight(1)
      
      // 追踪状态指示器
      Row({ space: 8 }) {
        Circle({ width: 8, height: 8 })
          .fill(this.isTracking ? '#10B981' : '#EF4444')
        
        Text(this.isTracking ? '追踪中' : '已停止')
          .fontSize(12)
          .fontColor(this.isTracking ? '#10B981' : '#EF4444')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 12, bottom: 12 })
    .backgroundColor('#F8FAFC')
  }
  
  /**
   * 构建步数展示卡片
   */
  @Builder
  buildStepCard() {
    Column({ space: 16 }) {
      // 步数图标和标题
      Row({ space: 12 }) {
        // 使用文本图标替代图片资源
        Text('👣')
          .fontSize(24)
          .fontWeight(FontWeight.Normal)
        
        Text('今日步数')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1E293B')
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      
      // 大数字显示
      Text(this.stepNumberAnimation.toLocaleString())
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')
        .textAlign(TextAlign.Center)
      
      // 目标步数
      Text(`目标: ${this.goalSteps.toLocaleString()} 步`)
        .fontSize(14)
        .fontColor('#64748B')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 16, color: '#00000010', offsetX: 0, offsetY: 4 })
  }
  
  /**
   * 构建进度展示区域
   */
  @Builder
  buildProgressSection() {
    Column({ space: 20 }) {
      // 进度百分比
      Row({ space: 8 }) {
        Text('完成进度')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1E293B')
        
        Text(`${this.animatedProgress}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getProgressColor())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      
      // 简化版进度条（避免复杂的Circle参数问题）
      Column({ space: 12 }) {
        // 线性进度条背景
        Row() {
          // 进度条填充
          Row()
            .width(`${this.animatedProgress}%`)
            .height(12)
            .backgroundColor(this.getProgressColor())
            .borderRadius(6)
        }
        .width('100%')
        .height(12)
        .backgroundColor('#E2E8F0')
        .borderRadius(6)
        
        // 进度文本
        Text(`${this.currentSteps} / ${this.goalSteps} 步`)
          .fontSize(14)
          .fontColor('#64748B')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 16, color: '#00000010', offsetX: 0, offsetY: 4 })
  }
  
  /**
   * 构建健康数据统计
   */
  @Builder
  buildHealthStats() {
    Column({ space: 16 }) {
      Text('运动数据')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1E293B')
        .width('100%')
        .textAlign(TextAlign.Start)
      
      Row({ space: 16 }) {
        // 卡路里消耗
        Column({ space: 8 }) {
          Text('🔥')
            .fontSize(24)
            .fontWeight(FontWeight.Normal)
          
          Text(this.caloriesBurned.toString())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#EF4444')
          
          Text('卡路里')
            .fontSize(12)
            .fontColor('#64748B')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
        
        // 行走距离
        Column({ space: 8 }) {
          Text('📍')
            .fontSize(24)
            .fontWeight(FontWeight.Normal)
          
          Text(this.distanceWalked.toFixed(1))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#3B82F6')
          
          Text('公里')
            .fontSize(12)
            .fontColor('#64748B')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 16, color: '#00000010', offsetX: 0, offsetY: 4 })
  }
  
  /**
   * 构建鼓励文案区域
   */
  @Builder
  buildEncouragement() {
    Column({ space: 12 }) {
      Text('💪')
        .fontSize(36)
        .fontWeight(FontWeight.Normal)
      
      Text(this.getEncouragementText())
        .fontSize(16)
        .fontColor('#1E293B')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      Text('每一步都在让身体更健康！')
        .fontSize(12)
        .fontColor('#64748B')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#F0FDF4')
    .borderRadius(24)
    .border({ width: 2, color: '#10B98120' })
  }
}

/**
 * 设计思路说明：
 * 
 * 1. 视觉设计：
 *    - 采用现代健康应用设计风格，以白色为主色调，搭配清新的绿色和蓝色
 *    - 使用大圆角、阴影效果和适当的留白，营造清爽舒适的视觉体验
 *    - 响应式颜色系统：进度条颜色根据完成度动态变化（红→橙→蓝→绿）
 * 
 * 2. 布局结构：
 *    - 顶部导航栏：包含返回按钮和追踪状态指示
 *    - 主要内容区域：采用卡片式布局，层次分明
 *    - 步数展示：大数字突出显示，增强视觉冲击力
 *    - 进度展示：线性进度条，直观展示完成度
 *    - 健康数据：卡路里和距离的双卡片设计
 *    - 鼓励文案：根据进度动态变化的激励文字
 * 
 * 3. 动画效果：
 *    - 步数数字滚动动画：平滑的数字变化效果
 *    - 进度条动画：线性进度条的渐变填充
 *    - 缓动函数：使用自然缓动效果，提升用户体验
 * 
 * 4. 交互体验：
 *    - 清晰的视觉反馈：追踪状态实时显示
 *    - 智能文案系统：根据完成度提供不同的鼓励文案
 *    - 完整的数据展示：步数、进度、卡路里、距离全方位展示
 * 
 * 5. 技术实现：
 *    - 完整的生命周期管理：aboutToAppear/Disappear中管理资源
 *    - 响应式状态管理：使用@State装饰器实现数据绑定
 *    - 模块化构建：使用@Builder分离不同UI组件
 *    - 错误处理：完整的异常捕获和日志记录
 *    - 使用emoji图标替代图片资源，确保跨平台兼容性
 */