import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseHelper } from '../model/DatabaseHelper';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 初始化数据库
    this.initDatabase();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    
    // 关闭数据库连接
    this.closeDatabase();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    
    // 应用进入后台时，后台长时任务会自动保持运行
    // 确保步数传感器能够持续获取数据
    hilog.info(DOMAIN, 'testTag', 'Application moved to background, background task will keep running');
  }

  /**
   * 初始化数据库
   */
  private async initDatabase(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      await dbHelper.initDatabase(this.context);
      hilog.info(DOMAIN, 'testTag', 'Database initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize database: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 关闭数据库连接
   */
  private async closeDatabase(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance();
      await dbHelper.close();
      hilog.info(DOMAIN, 'testTag', 'Database closed successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to close database: %{public}s', JSON.stringify(error));
    }
  }
}

/**
 * EntryAbility 后台长时任务支持说明：
 * 
 * 1. 权限配置：
 *    - 已在 module.json5 中声明 ohos.permission.KEEP_BACKGROUND_RUNNING 权限
 *    - 用户需要授权该权限才能启用后台长时任务
 * 
 * 2. 后台任务生命周期：
 *    - 在 StepViewModel.startTracking() 中启动后台任务
 *    - 在 StepViewModel.stopTracking() 中停止后台任务
 *    - EntryAbility 负责提供应用上下文，无需直接管理后台任务
 * 
 * 3. 后台状态处理：
 *    - onBackground(): 应用进入后台，后台任务继续运行
 *    - onForeground(): 应用回到前台，后台任务状态不变
 *    - onDestroy(): 应用销毁，所有后台任务自动停止
 * 
 * 4. 注意事项：
 *    - 后台长时任务由系统智能管理，可能会根据资源使用情况被限制
 *    - DATA_TRANSFER 模式适用于持续数据传输场景
 *    - 实际设备上需要用户明确授权后台运行权限
 */