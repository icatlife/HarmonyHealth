import { DatabaseHelper } from '../model/DatabaseHelper';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  /**
   * 页面即将显示时的生命周期函数
   * 这里添加临时的数据库测试代码，后续会被正式UI替换
   */
  aboutToAppear() {
    this.testDatabaseOperations();
  }

  /**
   * 数据库操作测试方法
   * 临时测试代码，验证数据库CRUD功能是否正常工作
   */
  async testDatabaseOperations() {
    console.info('=== 开始数据库测试 ===');

    try {
      // 获取数据库实例
      const dbHelper = DatabaseHelper.getInstance();
      
      // 方案A：确保数据库初始化完成
      console.info('步骤0: 确保数据库初始化完成...');
      
      // 获取应用上下文
      const context = getContext() as common.Context;
      
      // 调用数据库初始化，如果已初始化会安全跳过
      await dbHelper.initDatabase(context);
      console.info('✅ 数据库初始化确认完成');

      // 测试1: 保存今日步数
      console.info('测试1: 保存今日步数');
      await dbHelper.saveTodaySteps(5000);
      console.info('✅ 今日步数保存成功: 5000步');

      // 测试2: 读取今日目标步数
      console.info('测试2: 读取今日目标步数');
      const todayGoal = await dbHelper.getTodayGoal();
      console.info(`✅ 今日目标步数: ${todayGoal}`);

      // 测试3: 更新目标步数
      console.info('测试3: 更新目标步数');
      await dbHelper.updateGoal(8000);
      console.info('✅ 目标步数更新成功: 8000步');

      // 测试4: 再次读取更新后的目标步数
      console.info('测试4: 验证更新后的目标步数');
      const updatedGoal = await dbHelper.getTodayGoal();
      console.info(`✅ 更新后的目标步数: ${updatedGoal}`);

      // 测试5: 查询近7天历史记录
      console.info('测试5: 查询近7天历史记录');
      const weekHistory = await dbHelper.getWeekHistory();
      console.info(`✅ 查询到 ${weekHistory.length} 条历史记录`);
      
      // 输出每条记录的详细信息
      weekHistory.forEach((record, index) => {
        console.info(`记录 ${index + 1}: 日期=${record.date}, 步数=${record.steps}, 目标=${record.goal}, 完成率=${(record.getCompletionRate() * 100).toFixed(1)}%`);
      });

      console.info('=== 数据库测试完成 ===');
      console.info('所有测试操作均成功执行！');

      // 更新页面消息显示测试结果
      this.message = `数据库测试完成 - 共${weekHistory.length}条记录`;

    } catch (error) {
      // 增强错误日志输出
      console.error('❌ 数据库测试失败 - 错误对象:', error);
      console.error('❌ 错误类型:', typeof error);
      console.error('❌ 错误属性:', Object.keys(error));
      console.error('❌ 错误消息:', error.message);
      console.error('❌ 错误代码:', error.code);
      console.error('❌ 完整错误JSON:', JSON.stringify(error, null, 2));
      
      // 尝试获取更详细的错误信息
      if (error instanceof Error) {
        console.error('❌ 错误堆栈:', error.stack);
      }
      
      this.message = '数据库测试失败，请检查控制台详细错误信息';
    }
  }

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
        })
    }
    .height('100%')
    .width('100%')
  }
}