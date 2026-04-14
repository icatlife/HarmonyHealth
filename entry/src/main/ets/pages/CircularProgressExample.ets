import { CircularProgress } from '../components/CircularProgress';
import router from '@ohos.router';

/**
 * 环形进度条组件示例页面
 * 用于演示 CircularProgress 组件的使用
 */
@Entry
@Component
struct CircularProgressExample {
  @State currentSteps: number = 3500;
  @State goalSteps: number = 10000;
  
  build() {
    Column({ space: 32 }) {
      // 页面标题
      Text('环形进度条示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1E293B')
      
      // 环形进度条组件
      CircularProgress({ 
        current: this.currentSteps, 
        total: this.goalSteps 
      })
      .width(200)
      .height(200)
      
      // 控制面板
      Column({ space: 16 }) {
        Text('步数控制')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1E293B')
        
        Row({ space: 12 }) {
          Button('-500')
            .width(80)
            .height(40)
            .fontColor(Color.White)
            .backgroundColor('#EF4444')
            .borderRadius(8)
            .onClick(() => {
              this.currentSteps = Math.max(0, this.currentSteps - 500);
            })
          
          Button('+500')
            .width(80)
            .height(40)
            .fontColor(Color.White)
            .backgroundColor('#10B981')
            .borderRadius(8)
            .onClick(() => {
              this.currentSteps = Math.min(this.goalSteps, this.currentSteps + 500);
            })
        }
        
        // 步数显示
        Text(`当前步数: ${this.currentSteps.toLocaleString()} / ${this.goalSteps.toLocaleString()}`)
          .fontSize(14)
          .fontColor('#64748B')
          .textAlign(TextAlign.Center)
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 })
      
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
    .height('100%')
    .padding(24)
    .backgroundColor('#F8FAFC')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}