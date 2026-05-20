import { DatabaseHelper } from '../model/DatabaseHelper';
import { CircularProgress } from '../components/CircularProgress';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State currentSteps: number = 0;
  @State goalSteps: number = 10000;
  @State todayDate: string = '';
  @State completionRate: number = 0;
  
  /**
   * 页面即将显示时的生命周期函数（首次加载时调用）
   */
  async aboutToAppear() {
    await this.loadTodayData();
    this.setTodayDate();
  }
  
  /**
   * 页面每次显示时的生命周期函数（包括从其他页面返回时）
   */
  async onPageShow() {
    await this.loadTodayData();
    this.setTodayDate();
  }
  
  /**
   * 设置今日日期
   */
  private setTodayDate(): void {
    const today = new Date();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    this.todayDate = `${month}月${day}日`;
  }
  
  /**
   * 加载今日数据
   */
  private async loadTodayData(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      const context = getContext() as common.Context;
      
      // 确保数据库初始化完成
      await dbHelper.initDatabase(context);
      
      // 获取今日目标步数
      const goal = await dbHelper.getTodayGoal();
      this.goalSteps = goal;
      
      // 获取今日步数（这里暂时使用模拟数据，后续集成计步器）
      // 在实际应用中，这里应该从计步器服务获取实时步数
      const todaySteps = await this.getTodayStepsFromDatabase();
      this.currentSteps = todaySteps;
      
      // 计算完成率
      this.completionRate = goal > 0 ? Math.min(100, (todaySteps / goal) * 100) : 0;
      
    } catch (error) {
      console.error('加载今日数据失败:', error);
      // 使用默认值继续显示
    }
  }
  
  /**
   * 从数据库获取今日步数（模拟数据）
   */
  private async getTodayStepsFromDatabase(): Promise<number> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      const weekHistory = await dbHelper.getWeekHistory();
      
      // 如果有今日数据，返回今日步数，否则返回模拟数据
      if (weekHistory.length > 0) {
        return weekHistory[0].steps; // 假设第一条是今日数据
      }
      
      // 返回模拟数据
      return Math.floor(Math.random() * 8000) + 2000;
      
    } catch (error) {
      console.error('获取今日步数失败:', error);
      return 3500; // 默认值
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

  build() {
    Column({ space: 0 }) {
      // 顶部标题区域
      Column({ space: 8 }) {
        Text('健康步数')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E293B')
        
        Text(this.todayDate)
          .fontSize(16)
          .fontColor('#64748B')
      }
      .width('100%')
      .padding({ top: 40, bottom: 20 })
      .alignItems(HorizontalAlign.Center)
      
      // 主要内容区域
      Scroll() {
        Column({ space: 32 }) {
          // 环形进度条区域
          Column({ space: 24 }) {
            // 环形进度条
            CircularProgress({
              current: this.currentSteps,
              total: this.goalSteps
            })
            .width(240)
            .height(240)
            
            // 步数统计信息
            Column({ space: 12 }) {
              Row() {
                Text('今日步数')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1E293B')
                
                Text(this.currentSteps.toLocaleString())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#3B82F6')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              
              Row() {
                Text('目标步数')
                  .fontSize(16)
                  .fontColor('#64748B')
                
                Text(this.goalSteps.toLocaleString())
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#64748B')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              
              // 完成率提示
              if (this.completionRate >= 100) {
                Text('🎉 恭喜！今日目标已达成！')
                  .fontSize(14)
                  .fontColor('#10B981')
                  .textAlign(TextAlign.Center)
                  .width('100%')
              } else if (this.completionRate >= 80) {
                Text('💪 接近目标了，继续加油！')
                  .fontSize(14)
                  .fontColor('#F59E0B')
                  .textAlign(TextAlign.Center)
                  .width('100%')
              } else {
                Text('👣 今天也要坚持运动哦！')
                  .fontSize(14)
                  .fontColor('#64748B')
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }
            }
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
            .width('100%')
          }
          .width('100%')
          .padding(24)
          .backgroundColor('#F8FAFC')
          .borderRadius(20)
          
          // 功能按钮区域
          Column({ space: 16 }) {
            Text('功能导航')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1E293B')
              .width('100%')
              .textAlign(TextAlign.Start)
            
            // 计步追踪按钮
            Button() {
              Column({ space: 8 }) {
                Text('🚶♂️ 计步追踪')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                
                Text('开始追踪你的运动数据')
                  .fontSize(12)
                  .fontColor('#FFFFFFA0')
              }
            }
            .width('100%')
            .height(80)
            .backgroundColor('#3B82F6')
            .borderRadius(12)
            .onClick(() => {
              this.navigateToPage('StepCounterPage');
            })
            
            // 历史数据按钮
            Button() {
              Column({ space: 8 }) {
                Text('📊 历史数据')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                
                Text('查看近7天运动趋势')
                  .fontSize(12)
                  .fontColor('#FFFFFFA0')
              }
            }
            .width('100%')
            .height(80)
            .backgroundColor('#10B981')
            .borderRadius(12)
            .onClick(() => {
              this.navigateToPage('HistoryPage');
            })
            
            // 设置按钮
            Button() {
              Column({ space: 8 }) {
                Text('⚙️ 设置')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                
                Text('个性化你的运动目标')
                  .fontSize(12)
                  .fontColor('#FFFFFFA0')
              }
            }
            .width('100%')
            .height(80)
            .backgroundColor('#64748B')
            .borderRadius(12)
            .onClick(() => {
              this.navigateToPage('SettingPage');
            })
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
        }
        .width('100%')
        .padding(20)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      
      // 底部版权信息
      Text('健康步数 © 2024')
        .fontSize(12)
        .fontColor('#94A3B8')
        .padding({ top: 16, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ left: 16, right: 16 })
  }
}