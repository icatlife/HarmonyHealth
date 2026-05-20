import { DatabaseHelper } from '../model/DatabaseHelper';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { notificationManager } from '@kit.NotificationKit';

@Entry
@Component
struct SettingPage {
  @State goalSteps: number = 10000;
  @State isNotificationEnabled: boolean = false;
  @State appVersion: string = '1.0.0';
  @State appName: string = '健康步数';
  
  /**
   * 页面即将显示时的生命周期函数
   */
  async aboutToAppear() {
    await this.loadSettings();
    this.loadAppInfo();
  }
  
  /**
   * 加载设置数据
   */
  private async loadSettings(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      const context = getContext() as common.Context;
      
      // 确保数据库初始化完成
      await dbHelper.initDatabase(context);
      
      // 获取当前目标步数
      const goal = await dbHelper.getTodayGoal();
      this.goalSteps = goal;
      
    } catch (error) {
      console.error('加载设置失败:', error);
    }
  }
  
  /**
   * 加载应用信息
   */
  private loadAppInfo(): void {
    try {
      // 使用固定的应用信息（实际应该从应用配置中获取）
      this.appName = '健康步数';
      this.appVersion = '1.0.0';
      
    } catch (error) {
      console.error('加载应用信息失败:', error);
    }
  }
  
  /**
   * 更新目标步数
   */
  private async updateGoalSteps(newGoal: number): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      await dbHelper.updateGoal(newGoal);
      this.goalSteps = newGoal;
      
      // 显示成功提示
      promptAction.showToast({
        message: `目标步数已更新为 ${newGoal.toLocaleString()} 步`,
        duration: 2000
      });
      
    } catch (error) {
      console.error('更新目标步数失败:', error);
      promptAction.showToast({
        message: '更新失败，请重试',
        duration: 2000
      });
    }
  }
  
  /**
   * 请求通知权限
   */
  private async requestNotificationPermission(): Promise<void> {
    try {
      const context = getContext() as common.Context;
      
      console.info('开始请求通知权限...');
      
      // 调用真实的权限请求API - 使用正确的API签名
      await notificationManager.requestEnableNotification();
      
      console.info('通知权限请求成功，用户已授权');
      this.isNotificationEnabled = true;
      
      promptAction.showToast({
        message: '通知权限已开启',
        duration: 2000
      });
      
    } catch (error) {
      console.error('❌ 请求通知权限失败 - 详细错误信息:');
      console.error(`错误码: ${error.code}`);
      console.error(`错误消息: ${error.message}`);
      console.error(`完整错误对象:`, error);
      
      promptAction.showToast({
        message: `权限请求失败: ${error.message || '未知错误'}`,
        duration: 3000
      });
    }
  }
  
  /**
   * 发送测试通知
   */
  private async sendTestNotification(): Promise<void> {
    if (!this.isNotificationEnabled) {
      promptAction.showToast({
        message: '请先开启通知权限',
        duration: 2000
      });
      return;
    }
    
    try {
      console.info('开始发送测试通知...');
      
      // 创建通知请求
      const notificationRequest: notificationManager.NotificationRequest = {
        id: 1002, // 使用不同的ID避免与计步通知冲突
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '🔔 测试通知',
            text: '这是一个来自健康步数应用的测试通知',
            additionalText: '通知功能正常工作'
          }
        },
        deliveryTime: new Date().getTime(), // 立即发送
        showDeliveryTime: true
      };
      
      console.info('通知请求对象创建完成:', JSON.stringify(notificationRequest, null, 2));
      
      // 发送通知
      await notificationManager.publish(notificationRequest);
      
      console.info('✅ 测试通知发送成功！');
      
      promptAction.showToast({
        message: '测试通知已发送！请查看通知栏',
        duration: 3000
      });
      
    } catch (error) {
      console.error('❌ 发送测试通知失败 - 详细错误信息:');
      console.error(`错误码: ${error.code}`);
      console.error(`错误消息: ${error.message}`);
      console.error(`完整错误对象:`, error);
      
      promptAction.showToast({
        message: `通知发送失败: ${error.message || '未知错误'}`,
        duration: 3000
      });
    }
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
        
        Text('设置')
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
          // 目标步数设置
          Column({ space: 16 }) {
            Text('目标步数设置')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1E293B')
              .width('100%')
              .textAlign(TextAlign.Start)
            
            Column({ space: 12 }) {
              Row() {
                Text('每日目标')
                  .fontSize(16)
                  .fontColor('#64748B')
                
                Text(this.goalSteps.toLocaleString() + ' 步')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#3B82F6')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              
              Slider({
                value: this.goalSteps,
                min: 1000,
                max: 20000,
                step: 500,
                style: SliderStyle.OutSet
              })
              .width('100%')
              .trackColor('#E2E8F0')
              .selectedColor('#3B82F6')
              .blockColor('#3B82F6')
              .onChange((value: number) => {
                this.goalSteps = value;
              })
              
              Row({ space: 12 }) {
                Text('1000步')
                  .fontSize(12)
                  .fontColor('#64748B')
                
                Text('20000步')
                  .fontSize(12)
                  .fontColor('#64748B')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              
              Button('保存设置')
                .width('100%')
                .height(40)
                .fontColor(Color.White)
                .backgroundColor('#3B82F6')
                .borderRadius(8)
                .onClick(() => {
                  this.updateGoalSteps(this.goalSteps);
                })
            }
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
          
          // 通知设置
          Column({ space: 16 }) {
            Text('通知设置')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1E293B')
              .width('100%')
              .textAlign(TextAlign.Start)
            
            Column({ space: 12 }) {
              Row() {
                Column({ space: 4 }) {
                  Text('运动提醒')
                    .fontSize(16)
                    .fontColor('#1E293B')
                  
                  Text('目标达成和运动提醒')
                    .fontSize(12)
                    .fontColor('#64748B')
                }
                .layoutWeight(1)
                
                Toggle({ type: ToggleType.Switch, isOn: this.isNotificationEnabled })
                  .onChange((isOn: boolean) => {
                    if (isOn) {
                      this.requestNotificationPermission();
                    } else {
                      this.isNotificationEnabled = false;
                    }
                  })
              }
              .width('100%')
              
              if (this.isNotificationEnabled) {
                Button('发送测试通知')
                  .width('100%')
                  .height(36)
                  .fontColor('#3B82F6')
                  .backgroundColor('#3B82F610')
                  .borderRadius(6)
                  .onClick(() => {
                    this.sendTestNotification();
                  })
              }
            }
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
          
          // 应用信息
          Column({ space: 16 }) {
            Text('应用信息')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1E293B')
              .width('100%')
              .textAlign(TextAlign.Start)
            
            Column({ space: 12 }) {
              Row() {
                Text('应用名称')
                  .fontSize(14)
                  .fontColor('#64748B')
                
                Text(this.appName)
                  .fontSize(14)
                  .fontColor('#1E293B')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              
              Row() {
                Text('版本号')
                  .fontSize(14)
                  .fontColor('#64748B')
                
                Text(this.appVersion)
                  .fontSize(14)
                  .fontColor('#1E293B')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              
              Row() {
                Text('开发者')
                  .fontSize(14)
                  .fontColor('#64748B')
                
                Text('健康步数团队')
                  .fontSize(14)
                  .fontColor('#1E293B')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
          
          // 操作按钮
          Column({ space: 12 }) {
            Button('清除所有数据')
              .width('100%')
              .height(40)
              .fontColor('#EF4444')
              .backgroundColor('#EF444410')
              .borderRadius(8)
              .onClick(() => {
                promptAction.showToast({
                  message: '数据清除功能开发中',
                  duration: 2000
                });
              })
            
            Button('反馈建议')
              .width('100%')
              .height(40)
              .fontColor('#64748B')
              .backgroundColor('#64748B10')
              .borderRadius(8)
              .onClick(() => {
                promptAction.showToast({
                  message: '反馈功能开发中',
                  duration: 2000
                });
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}