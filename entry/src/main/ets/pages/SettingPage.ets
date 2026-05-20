import { DatabaseHelper } from '../model/DatabaseHelper';
import { AppColors, AppStyles } from '../common/Constants';
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
  @State appName: string = 'FitPace';
  
  async aboutToAppear() {
    await this.loadSettings();
    this.loadAppInfo();
  }
  
  private async loadSettings(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      const context = getContext() as common.Context;
      
      await dbHelper.initDatabase(context);
      
      const goal = await dbHelper.getTodayGoal();
      this.goalSteps = goal;
      
    } catch (error) {
      console.error('加载设置失败:', error);
    }
  }
  
  private loadAppInfo(): void {
    try {
      this.appName = 'FitPace';
      this.appVersion = '1.0.0';
      
    } catch (error) {
      console.error('加载应用信息失败:', error);
    }
  }
  
  private async updateGoalSteps(newGoal: number): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      await dbHelper.updateGoal(newGoal);
      this.goalSteps = newGoal;
      
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
  
  private async requestNotificationPermission(): Promise<void> {
    try {
      const context = getContext() as common.Context;
      
      console.info('开始请求通知权限...');
      
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
      
      const notificationRequest: notificationManager.NotificationRequest = {
        id: 1002,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '🔔 测试通知',
            text: '这是一个来自 FitPace 应用的测试通知',
            additionalText: '通知功能正常工作'
          }
        },
        deliveryTime: new Date().getTime(),
        showDeliveryTime: true
      };
      
      console.info('通知请求对象创建完成:', JSON.stringify(notificationRequest, null, 2));
      
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
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .width(40)
          .height(40)
          .onClick(() => {
            this.goBack();
          })
        
        Text('设置')
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
          // 目标步数设置卡片
          this.buildGoalSettingCard()
          
          // 通知设置卡片
          this.buildNotificationCard()
          
          // 应用信息卡片
          this.buildAppInfoCard()
          
          // 操作按钮卡片
          this.buildActionsCard()
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
   * 构建目标步数设置卡片
   */
  @Builder
  buildGoalSettingCard() {
    Column({ space: AppStyles.SPACING_MD }) {
      Row({ space: 8 }) {
        Text('🎯')
          .fontSize(20)
        
        Text('目标步数设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      
      Column({ space: AppStyles.SPACING_MD }) {
        Row() {
          Text('每日目标')
            .fontSize(16)
            .fontColor(AppColors.TEXT_SECONDARY)
          
          Text(this.goalSteps.toLocaleString() + ' 步')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        
        // Slider 使用薄荷绿色
        Slider({
          value: this.goalSteps,
          min: 1000,
          max: 20000,
          step: 500,
          style: SliderStyle.OutSet
        })
          .width('100%')
          .trackColor(AppColors.BORDER)
          .selectedColor(AppColors.PRIMARY)
          .blockColor(AppColors.PRIMARY_DARK)
          .onChange((value: number) => {
            this.goalSteps = value;
          })
        
        Row({ space: AppStyles.SPACING_MD }) {
          Text('1000步')
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
          
          Text('20000步')
            .fontSize(12)
            .fontColor(AppColors.TEXT_TERTIARY)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        
        Button('保存设置')
          .width('100%')
          .height(44)
          .fontColor(AppColors.TEXT_WHITE)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(AppStyles.BORDER_RADIUS)
          .onClick(() => {
            this.updateGoalSteps(this.goalSteps);
          })
      }
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
  
  /**
   * 构建通知设置卡片
   */
  @Builder
  buildNotificationCard() {
    Column({ space: AppStyles.SPACING_MD }) {
      Row({ space: 8 }) {
        Text('🔔')
          .fontSize(20)
        
        Text('通知设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      
      Column({ space: AppStyles.SPACING_MD }) {
        Row() {
          Column({ space: 4 }) {
            Text('运动提醒')
              .fontSize(16)
              .fontColor(AppColors.TEXT_PRIMARY)
            
            Text('目标达成和运动提醒')
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .layoutWeight(1)
          
          Toggle({ type: ToggleType.Switch, isOn: this.isNotificationEnabled })
            .selectedColor(AppColors.PRIMARY)
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
            .height(40)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.PRIMARY + '20')
            .borderRadius(AppStyles.BORDER_RADIUS_SM)
            .onClick(() => {
              this.sendTestNotification();
            })
        }
      }
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
  
  /**
   * 构建应用信息卡片
   */
  @Builder
  buildAppInfoCard() {
    Column({ space: AppStyles.SPACING_MD }) {
      Row({ space: 8 }) {
        Text('ℹ️')
          .fontSize(20)
        
        Text('应用信息')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      
      Column({ space: AppStyles.SPACING_MD }) {
        this.buildInfoRow('应用名称', this.appName)
        this.buildInfoRow('版本号', this.appVersion)
        this.buildInfoRow('开发者', 'FitPace 团队')
      }
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
  
  /**
   * 构建信息行
   */
  @Builder
  buildInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
      
      Text(value)
        .fontSize(14)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }
  
  /**
   * 构建操作按钮卡片
   */
  @Builder
  buildActionsCard() {
    Column({ space: AppStyles.SPACING_MD }) {
      Button('清除所有数据')
        .width('100%')
        .height(44)
        .fontColor(AppColors.ERROR)
        .backgroundColor(AppColors.ERROR + '15')
        .borderRadius(AppStyles.BORDER_RADIUS)
        .onClick(() => {
          promptAction.showToast({
            message: '数据清除功能开发中',
            duration: 2000
          });
        })
      
      Button('反馈建议')
        .width('100%')
        .height(44)
        .fontColor(AppColors.TEXT_SECONDARY)
        .backgroundColor(AppColors.BORDER)
        .borderRadius(AppStyles.BORDER_RADIUS)
        .onClick(() => {
          promptAction.showToast({
            message: '反馈功能开发中',
            duration: 2000
          });
        })
    }
    .width('100%')
    .padding(AppStyles.SPACING_LG)
    .backgroundColor(AppColors.CARD_BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS_LG)
    .shadow(AppStyles.CARD_SHADOW)
  }
}
