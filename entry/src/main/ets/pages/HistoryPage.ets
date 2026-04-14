import { DatabaseHelper } from '../model/DatabaseHelper';
import { BarChart } from '../components/BarChart';
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
  
  /**
   * 页面即将显示时的生命周期函数
   */
  async aboutToAppear() {
    await this.loadHistoryData();
  }
  
  /**
   * 加载历史数据
   */
  private async loadHistoryData(): Promise<void> {
    try {
      this.isLoading = true;
      
      const dbHelper = DatabaseHelper.getInstance();
      const context = getContext() as common.Context;
      
      // 确保数据库初始化完成
      await dbHelper.initDatabase(context);
      
      // 获取近7天历史记录
      const weekHistory: HistoryRecord[] = await dbHelper.getWeekHistory() as HistoryRecord[];
      
      // 处理数据用于图表展示
      this.processHistoryData(weekHistory);
      
      // 计算日均步数
      this.calculateAverageSteps(weekHistory);
      
    } catch (error) {
      console.error('加载历史数据失败:', error);
      
      // 显示模拟数据
      this.showSampleData();
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 处理历史数据用于图表展示
   */
  private processHistoryData(history: HistoryRecord[]): void {
    if (history.length === 0) {
      this.showSampleData();
      return;
    }
    
    // 提取步数数据和日期标签
    const steps: number[] = [];
    const labels: string[] = [];
    
    // 按照日期倒序排列（最新的在前面）
    const sortedHistory = [...history].sort((a: HistoryRecord, b: HistoryRecord) => {
      return new Date(b.date).getTime() - new Date(a.date).getTime();
    });
    
    // 只取最近7天的数据
    const recentHistory = sortedHistory.slice(0, 7);
    
    recentHistory.forEach((record: HistoryRecord) => {
      steps.push(record.steps);
      
      // 格式化日期标签
      const date = new Date(record.date);
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      labels.push(`${month}-${day}`);
    });
    
    // 如果数据不足7天，补充空数据
    while (steps.length < 7) {
      steps.unshift(0);
      
      // 计算缺失的日期
      const missingDays = 7 - labels.length;
      const date = new Date();
      date.setDate(date.getDate() - missingDays);
      
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      labels.unshift(`${month}-${day}`);
    }
    
    this.stepData = steps;
    this.dateLabels = labels;
  }
  
  /**
   * 计算日均步数
   */
  private calculateAverageSteps(history: HistoryRecord[]): void {
    if (history.length === 0) {
      this.averageSteps = 0;
      return;
    }
    
    const totalSteps = history.reduce((sum: number, record: HistoryRecord) => sum + record.steps, 0);
    this.averageSteps = Math.round(totalSteps / history.length);
  }
  
  /**
   * 显示示例数据（用于演示）
   */
  private showSampleData(): void {
    // 生成示例数据
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
    this.averageSteps = Math.round(sampleData.reduce((a: number, b: number) => a + b, 0) / sampleData.length);
  }
  
  /**
   * 返回主页
   */
  private goBack(): void {
    router.back();
  }
  
  build() {
    Column({ space: 0 }) {
      // 顶部导航栏
      Row() {
        Button('←')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#3B82F6')
          .backgroundColor(Color.Transparent)
          .width(40)
          .height(40)
          .onClick(() => {
            this.goBack();
          })
        
        Text('历史数据')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E293B')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        // 占位元素，保持布局平衡
        Blank()
          .width(40)
      }
      .width('100%')
      .padding({ top: 40, bottom: 20, left: 16, right: 16 })
      
      // 主要内容区域
      Scroll() {
        Column({ space: 24 }) {
          if (this.isLoading) {
            // 加载状态
            Column({ space: 16 }) {
              LoadingProgress()
                .width(40)
                .height(40)
                .color('#3B82F6')
              
              Text('正在加载历史数据...')
                .fontSize(16)
                .fontColor('#64748B')
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            // 图表区域
            Column({ space: 20 }) {
              Text('近7天步数趋势')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1E293B')
                .width('100%')
                .textAlign(TextAlign.Start)
              
              BarChart({
                data: this.stepData,
                labels: this.dateLabels
              })
              .width('100%')
            }
            .width('100%')
            .padding(24)
            .backgroundColor('#F8FAFC')
            .borderRadius(20)
            
            // 统计数据区域
            Column({ space: 16 }) {
              Text('运动统计')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1E293B')
                .width('100%')
                .textAlign(TextAlign.Start)
              
              Row() {
                Column({ space: 8 }) {
                  Text('日均步数')
                    .fontSize(14)
                    .fontColor('#64748B')
                  
                  Text(this.averageSteps.toLocaleString())
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#3B82F6')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                
                Column({ space: 8 }) {
                  Text('总步数')
                    .fontSize(14)
                    .fontColor('#64748B')
                  
                  Text(this.stepData.reduce((a: number, b: number) => a + b, 0).toLocaleString())
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#10B981')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              
              // 运动建议
              if (this.averageSteps >= 8000) {
                Text('🌟 优秀！继续保持活跃的生活方式')
                  .fontSize(14)
                  .fontColor('#10B981')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#10B98110')
                  .borderRadius(8)
              } else if (this.averageSteps >= 5000) {
                Text('💪 良好！每天多走几步效果更佳')
                  .fontSize(14)
                  .fontColor('#F59E0B')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#F59E0B10')
                  .borderRadius(8)
              } else {
                Text('👣 加油！增加日常活动量有益健康')
                  .fontSize(14)
                  .fontColor('#EF4444')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#EF444410')
                  .borderRadius(8)
              }
            }
            .width('100%')
            .padding(24)
            .backgroundColor(Color.White)
            .borderRadius(20)
            .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
          }
        }
        .width('100%')
        .padding(20)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}