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