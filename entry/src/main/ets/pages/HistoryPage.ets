import { DatabaseHelper } from '../model/DatabaseHelper';
import { BarChart } from '../components/BarChart';
import { DateUtils } from '../common/DateUtils';
import { AppColors, AppStyles } from '../common/Constants';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

interface HistoryRecord {
  date: string;
  steps: number;
  goal: number;
  getCompletionRate: () => number;
}

@Entry
@Component
struct HistoryPage {
  @State stepData: number[] = [];
  @State dateLabels: string[] = [];
  @State averageSteps: number = 0;
  @State isLoading: boolean = true;
  @State totalSteps: number = 0;
  
  async aboutToAppear() {
    await this.loadHistoryData();
  }
  
  private async loadHistoryData(): Promise<void> {
    try {
      this.isLoading = true;
      
      const dbHelper = DatabaseHelper.getInstance();
      const context = getContext() as common.Context;
      
      await dbHelper.initDatabase(context);
      
      const weekHistory: HistoryRecord[] = await dbHelper.getWeekHistory() as HistoryRecord[];
      
      this.processHistoryData(weekHistory);
      this.calculateAverageSteps(weekHistory);
      
    } catch (error) {
      console.error('加载历史数据失败:', error);
      this.showSampleData();
    } finally {
      this.isLoading = false;
    }
  }
  
  private processHistoryData(history: HistoryRecord[]): void {
    if (history.length === 0) {
      this.showCompleteWeekData();
      return;
    }
    
    const today = new Date();
    const weekDates: string[] = [];
    const weekLabels: string[] = [];
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      
      const dateStr = DateUtils.formatDate(date);
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      
      weekDates.push(dateStr);
      weekLabels.push(`${month}-${day}`);
    }
    
    const steps: number[] = [];
    
    const dateToStepsMap: Map<string, number> = new Map();
    history.forEach((record: HistoryRecord) => {
      dateToStepsMap.set(record.date, record.steps);
    });
    
    weekDates.forEach((dateStr: string) => {
      const stepsForDate = dateToStepsMap.get(dateStr) || 0;
      steps.push(stepsForDate);
    });
    
    this.stepData = steps;
    this.dateLabels = weekLabels;
    
    console.info(`Processed ${steps.length} days of data: ${steps.join(', ')}`);
  }
  
  private calculateAverageSteps(history: HistoryRecord[]): void {
    let totalSteps = 0;
    
    if (history.length === 0) {
      this.averageSteps = 0;
      this.totalSteps = 0;
      return;
    }
    
    const today = new Date();
    const weekDates: string[] = [];
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      weekDates.push(DateUtils.formatDate(date));
    }
    
    const dateToStepsMap: Map<string, number> = new Map();
    history.forEach((record: HistoryRecord) => {
      dateToStepsMap.set(record.date, record.steps);
    });
    
    weekDates.forEach((dateStr: string) => {
      totalSteps += dateToStepsMap.get(dateStr) || 0;
    });
    
    this.totalSteps = totalSteps;
    this.averageSteps = Math.round(totalSteps / 7);
    
    console.info(`Calculated average steps: ${this.averageSteps} (total: ${totalSteps} over 7 days)`);
  }
  
  private showCompleteWeekData(): void {
    const weekData: number[] = [];
    const weekLabels: string[] = [];
    
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      
      weekLabels.push(`${month}-${day}`);
      weekData.push(0);
    }
    
    this.stepData = weekData;
    this.dateLabels = weekLabels;
    this.averageSteps = 0;
    this.totalSteps = 0;
    
    console.info('Displaying complete week data with zeros');
  }

  private showSampleData(): void {
    const sampleData: number[] = [];
    const sampleLabels: string[] = [];
    
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      
      sampleLabels.push(`${month}-${day}`);
      sampleData.push(Math.floor(Math.random() * 8000) + 2000);
    }
    
    this.stepData = sampleData;
    this.dateLabels = sampleLabels;
    this.totalSteps = sampleData.reduce((a: number, b: number) => a + b, 0);
    this.averageSteps = Math.round(this.totalSteps / sampleData.length);
  }
  
  private goBack(): void {
    router.back();
  }
  
  /**
   * 获取运动建议
   */
  private getAdviceText(): string {
    if (this.averageSteps >= 8000) {
      return '🌟 优秀！继续保持活跃的生活方式';
    } else if (this.averageSteps >= 5000) {
      return '💪 良好！每天多走几步效果更佳';
    } else {
      return '👣 加油！增加日常活动量有益健康';
    }
  }
  
  /**
   * 获取建议颜色
   */
  private getAdviceColor(): string {
    if (this.averageSteps >= 8000) {
      return AppColors.SUCCESS;
    } else if (this.averageSteps >= 5000) {
      return AppColors.WARNING;
    } else {
      return AppColors.PRIMARY;
    }
  }

  build() {
    Column({ space: 0 }) {
      // 顶部导航栏
      Row() {
        Button('←')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .width(40)
          .height(40)
          .onClick(() => {
            this.goBack();
          })
        
        Text('历史数据')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Blank()
          .width(40)
      }
      .width('100%')
      .padding({ top: 40, bottom: 20, left: AppStyles.SPACING_MD, right: AppStyles.SPACING_MD })
      
      // 主要内容区域
      Scroll() {
        Column({ space: AppStyles.SPACING_LG }) {
          if (this.isLoading) {
            Column({ space: AppStyles.SPACING_MD }) {
              LoadingProgress()
                .width(40)
                .height(40)
                .color(AppColors.PRIMARY)
              
              Text('正在加载历史数据...')
                .fontSize(16)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            // 图表区域
            Column({ space: AppStyles.SPACING_MD }) {
              BarChart({
                data: this.stepData,
                labels: this.dateLabels
              })
              .width('100%')
            }
            .width('100%')
            .padding(AppStyles.SPACING_MD)
            .backgroundColor(AppColors.CARD_BACKGROUND)
            .borderRadius(AppStyles.BORDER_RADIUS_LG)
            .shadow(AppStyles.CARD_SHADOW)
            
            // 统计数据卡片
            Column({ space: AppStyles.SPACING_MD }) {
              Text('运动统计')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
                .width('100%')
                .textAlign(TextAlign.Start)
              
              // 统计数据网格
              Row({ space: AppStyles.SPACING_MD }) {
                // 日均步数
                this.buildStatCard(
                  '📈',
                  '日均步数',
                  this.averageSteps.toLocaleString()
                )
                
                // 总步数
                this.buildStatCard(
                  '🎯',
                  '总步数',
                  this.totalSteps.toLocaleString()
                )
              }
              .width('100%')
              
              // 运动建议
              Column({ space: 8 }) {
                Text(this.getAdviceText())
                  .fontSize(14)
                  .fontColor(this.getAdviceColor())
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(AppStyles.SPACING_MD)
              .backgroundColor(this.getAdviceColor() + '15')
              .borderRadius(AppStyles.BORDER_RADIUS)
            }
            .width('100%')
            .padding(AppStyles.SPACING_LG)
            .backgroundColor(AppColors.CARD_BACKGROUND)
            .borderRadius(AppStyles.BORDER_RADIUS_LG)
            .shadow(AppStyles.CARD_SHADOW)
            
            // 本周亮点
            this.buildWeeklyHighlight()
          }
        }
        .width('100%')
        .padding(AppStyles.PAGE_PADDING)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
  
  /**
   * 构建统计卡片
   */
  @Builder
  buildStatCard(icon: string, label: string, value: string) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(24)
      
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
      
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .padding(AppStyles.SPACING_MD)
    .backgroundColor(AppColors.BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS)
  }
  
  /**
   * 构建本周亮点
   */
  @Builder
  buildWeeklyHighlight() {
    Column({ space: AppStyles.SPACING_MD }) {
      Text('本周亮点')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Start)
      
      Row({ space: AppStyles.SPACING_MD }) {
        // 最高步数
        Column({ space: 4 }) {
          Text('🏆')
            .fontSize(20)
          Text('最高')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
          Text(Math.max(...this.stepData).toLocaleString())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.SUCCESS)
        }
        .layoutWeight(1)
        .padding(AppStyles.SPACING_MD)
        .backgroundColor(AppColors.BACKGROUND)
        .borderRadius(AppStyles.BORDER_RADIUS)
        
        // 最低步数
        Column({ space: 4 }) {
          Text('📉')
            .fontSize(20)
          Text('最低')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
          Text(Math.min(...this.stepData.filter(v => v > 0)).toLocaleString() || '0')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WARNING)
        }
        .layoutWeight(1)
        .padding(AppStyles.SPACING_MD)
        .backgroundColor(AppColors.BACKGROUND)
        .borderRadius(AppStyles.BORDER_RADIUS)
        
        // 活跃天数
        Column({ space: 4 }) {
          Text('📅')
            .fontSize(20)
          Text('活跃')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
          Text(this.stepData.filter(v => v > 0).length + '天')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
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
}
