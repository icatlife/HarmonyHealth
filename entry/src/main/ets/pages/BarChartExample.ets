import { BarChart } from '../components/BarChart';
import router from '@ohos.router';

/**
 * 柱状图组件示例页面
 * 用于演示 BarChart 组件的使用
 */
@Entry
@Component
struct BarChartExample {
  @State stepData: number[] = [4500, 6200, 3800, 7800, 9200, 8500, 6700];
  @State dateLabels: string[] = ['04-07', '04-08', '04-09', '04-10', '04-11', '04-12', '04-13'];
  @State emptyData: number[] = [];
  @State emptyLabels: string[] = [];
  
  build() {
    Scroll() {
      Column({ space: 24 }) {
        // 页面标题
        Text('步数趋势图表示例')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E293B')
        
        // 有数据的柱状图
        Column({ space: 16 }) {
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
          
          // 数据控制面板
          Column({ space: 12 }) {
            Text('数据控制')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1E293B')
            
            Row({ space: 12 }) {
              Button('随机数据')
                .width(100)
                .height(36)
                .fontColor(Color.White)
                .backgroundColor('#3B82F6')
                .borderRadius(8)
                .onClick(() => {
                  this.generateRandomData();
                })
              
              Button('清空数据')
                .width(100)
                .height(36)
                .fontColor(Color.White)
                .backgroundColor('#EF4444')
                .borderRadius(8)
                .onClick(() => {
                  this.stepData = [];
                  this.dateLabels = [];
                })
            }
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8FAFC')
        .borderRadius(16)
        
        // 空数据示例
        Column({ space: 16 }) {
          Text('空数据状态示例')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1E293B')
            .width('100%')
            .textAlign(TextAlign.Start)
          
          BarChart({
            data: this.emptyData,
            labels: this.emptyLabels
          })
          .width('100%')
          
          Button('添加示例数据')
            .width(120)
            .height(36)
            .fontColor(Color.White)
            .backgroundColor('#10B981')
            .borderRadius(8)
            .onClick(() => {
              this.emptyData = [2000, 3500, 1800, 4200, 3000, 2500, 3800];
              this.emptyLabels = ['今天', '昨天', '前天', '3天前', '4天前', '5天前', '6天前'];
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8FAFC')
        .borderRadius(16)
        
        // 返回按钮
        Button('返回主页')
          .width(120)
          .height(40)
          .fontColor(Color.White)
          .backgroundColor('#3B82F6')
          .borderRadius(8)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding(24)
    }
    .scrollBar(BarState.Off)
    .backgroundColor('#F8FAFC')
  }
  
  /**
   * 生成随机数据
   */
  private generateRandomData(): void {
    const newData: number[] = [];
    const newLabels: string[] = [];
    
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      
      newLabels.push(`${month}-${day}`);
      newData.push(Math.floor(Math.random() * 10000) + 1000); // 1000-11000之间的随机数
    }
    
    this.stepData = newData;
    this.dateLabels = newLabels;
  }
}