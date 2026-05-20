import { DatabaseHelper } from '../model/DatabaseHelper';
import { CircularProgress } from '../components/CircularProgress';
import { AppColors, AppStyles, getProgressColor } from '../common/Constants';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State currentSteps: number = 0;
  @State goalSteps: number = 10000;
  @State todayDate: string = '';
  @State completionRate: number = 0;
  @State greeting: string = '';
  
  /**
   * 页面即将显示时的生命周期函数（首次加载时调用）
   */
  async aboutToAppear() {
    await this.loadTodayData();
    this.setTodayDate();
    this.setGreeting();
  }
  
  /**
   * 页面每次显示时的生命周期函数（包括从其他页面返回时）
   */
  async onPageShow() {
    await this.loadTodayData();
    this.setTodayDate();
    this.setGreeting();
  }
  
  /**
   * 设置今日日期
   */
  private setTodayDate(): void {
    const today = new Date();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    const weekDay = weekDays[today.getDay()];
    this.todayDate = `${month}月${day}日 星期${weekDay}`;
  }
  
  /**
   * 设置问候语
   */
  private setGreeting(): void {
    const hour = new Date().getHours();
    if (hour < 6) {
      this.greeting = '夜深了，注意休息';
    } else if (hour < 9) {
      this.greeting = '早上好，新的一天开始了';
    } else if (hour < 12) {
      this.greeting = '上午好，保持活力';
    } else if (hour < 14) {
      this.greeting = '中午好，记得活动';
    } else if (hour < 18) {
      this.greeting = '下午好，继续加油';
    } else if (hour < 22) {
      this.greeting = '晚上好，放松一下';
    } else {
      this.greeting = '夜深了，注意休息';
    }
  }
  
  /**
   * 加载今日数据
   */
  private async loadTodayData(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      const context = getContext() as common.Context;
      
      await dbHelper.initDatabase(context);
      
      const goal = await dbHelper.getTodayGoal();
      this.goalSteps = goal;
      
      const todaySteps = await this.getTodayStepsFromDatabase();
      this.currentSteps = todaySteps;
      
      this.completionRate = goal > 0 ? Math.min(100, (todaySteps / goal) * 100) : 0;
      
    } catch (error) {
      console.error('加载今日数据失败:', error);
    }
  }
  
  /**
   * 从数据库获取今日步数（模拟数据）
   */
  private async getTodayStepsFromDatabase(): Promise<number> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      const weekHistory = await dbHelper.getWeekHistory();
      
      if (weekHistory.length > 0) {
        return weekHistory[0].steps;
      }
      
      return Math.floor(Math.random() * 8000) + 2000;
      
    } catch (error) {
      console.error('获取今日步数失败:', error);
      return 3500;
    }
  }
  
  /**
   * 页面跳转
   */
  private navigateToPage(pageName: string): void {
    router.pushUrl({
      url: `pages/${pageName}`
    });
  }
  
  /**
   * 获取鼓励文案
   */
  private getEncouragementText(): string {
    if (this.completionRate >= 100) {
      return '🎉 恭喜！今日目标已达成！';
    } else if (this.completionRate >= 80) {
      return '💪 接近目标了，继续加油！';
    } else if (this.completionRate >= 50) {
      return '🌟 已完成一半，继续努力！';
    } else {
      return '👣 今天也要坚持运动哦！';
    }
  }

  build() {
    Column({ space: 0 }) {
      // 顶部欢迎区域
      Column({ space: 8 }) {
        Text(this.greeting)
          .fontSize(16)
          .fontColor(AppColors.TEXT_SECONDARY)
        
        Text(this.todayDate)
          .fontSize(14)
          .fontColor(AppColors.TEXT_TERTIARY)
      }
      .width('100%')
      .padding({ top: 32, bottom: 16 })
      .alignItems(HorizontalAlign.Center)
      
      // 主要内容区域
      Scroll() {
        Column({ space: AppStyles.SPACING_LG }) {
          // 环形进度条区域 - 视觉焦点
          Column({ space: AppStyles.SPACING_LG }) {
            // 环形进度条 - 放大居中
            Stack({ alignContent: Alignment.Center }) {
              CircularProgress({
                current: this.currentSteps,
                total: this.goalSteps,
                showCenterText: false
              })
              .width(220)
              .height(220)
              
              // 中央步数显示
              Column({ space: 8 }) {
                Text(this.currentSteps.toLocaleString())
                  .fontSize(42)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.PRIMARY)
                
                Text('步')
                  .fontSize(16)
                  .fontColor(AppColors.TEXT_SECONDARY)
                
                Text(`${Math.round(this.completionRate)}%`)
                  .fontSize(14)
                  .fontColor(AppColors.TEXT_TERTIARY)
                  .margin({ top: 4 })
              }
            }
            .width(220)
            .height(220)
            
            // 目标步数显示
            Row({ space: 8 }) {
              Text('目标')
                .fontSize(14)
                .fontColor(AppColors.TEXT_SECONDARY)
              
              Text(this.goalSteps.toLocaleString() + ' 步')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.PRIMARY)
            }
            
            // 完成率提示
            Text(this.getEncouragementText())
              .fontSize(14)
              .fontColor(getProgressColor(this.completionRate))
              .textAlign(TextAlign.Center)
              .padding({ top: 8, bottom: 8, left: 16, right: 16 })
              .backgroundColor(getProgressColor(this.completionRate) + '15')
              .borderRadius(20)
          }
          .width('100%')
          .padding(AppStyles.SPACING_LG)
          .backgroundColor(AppColors.CARD_BACKGROUND)
          .borderRadius(AppStyles.BORDER_RADIUS_LG)
          .shadow(AppStyles.CARD_SHADOW)
          
          // 功能导航卡片
          Column({ space: AppStyles.SPACING_MD }) {
            Text('功能导航')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')
              .margin({ bottom: 8 })
            
            // 卡片式按钮布局
            Column({ space: AppStyles.SPACING_MD }) {
              // 开始计步卡片
              this.buildNavCard(
                '🏃',
                '开始计步',
                '记录每一步，追踪运动数据',
                () => this.navigateToPage('StepCounterPage')
              )
              
              // 查看历史卡片
              this.buildNavCard(
                '📊',
                '查看历史',
                '追踪近7天运动趋势',
                () => this.navigateToPage('HistoryPage')
              )
              
              // 设置目标卡片
              this.buildNavCard(
                '⚙️',
                '设置目标',
                '自定义每日运动目标',
                () => this.navigateToPage('SettingPage')
              )
              
              // 运动音乐卡片
              this.buildNavCard(
                '🎵',
                '运动音乐',
                '运动时来点节奏',
                () => this.navigateToPage('MusicPlayerPage')
              )
            }
          }
          .width('100%')
          .padding(AppStyles.SPACING_LG)
          .backgroundColor(AppColors.CARD_BACKGROUND)
          .borderRadius(AppStyles.BORDER_RADIUS_LG)
          .shadow(AppStyles.CARD_SHADOW)
        }
        .width('100%')
        .padding(AppStyles.PAGE_PADDING)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      
      // 底部版权信息
      Text('FitPace © 2024')
        .fontSize(12)
        .fontColor(AppColors.TEXT_TERTIARY)
        .padding({ top: 12, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .padding({ left: 16, right: 16 })
  }
  
  /**
   * 构建导航卡片
   */
  @Builder
  buildNavCard(icon: string, title: string, subtitle: string, onClick: () => void) {
    Row({ space: AppStyles.SPACING_MD }) {
      // 图标区域
      Column() {
        Text(icon)
          .fontSize(28)
      }
      .width(56)
      .height(56)
      .backgroundColor(AppColors.PRIMARY + '20')
      .borderRadius(AppStyles.BORDER_RADIUS)
      .justifyContent(FlexAlign.Center)
      
      // 文字区域
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        
        Text(subtitle)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 箭头
      Text('›')
        .fontSize(24)
        .fontColor(AppColors.TEXT_TERTIARY)
    }
    .width('100%')
    .padding(AppStyles.SPACING_MD)
    .backgroundColor(AppColors.BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS)
    .onClick(() => {
      onClick();
    })
  }
}
