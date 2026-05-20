/**
 * 应用常量定义
 */
export class Constants {
    /** 数据库名称 */
    static readonly DATABASE_NAME: string = 'FitPaceDB';

    /** 步数记录表名 */
    static readonly TABLE_STEP_RECORD: string = 'step_records';

    /** 默认目标步数 */
    static readonly DEFAULT_GOAL: number = 6000;

    /** 是否使用模拟步数数据 */
    static readonly USE_MOCK_STEPS: boolean = true;

    /** 通知ID */
    static readonly NOTIFICATION_ID: number = 1001;

    /** 音乐通知ID */
    static readonly MUSIC_NOTIFICATION_ID: number = 1003;
}

/**
 * 全局颜色定义 - 薄荷绿主题
 */
export class AppColors {
    /** 主色调 - 柔和薄荷绿 */
    static readonly PRIMARY: string = '#7EC8A0';
    static readonly PRIMARY_LIGHT: string = '#A8D8B9';
    static readonly PRIMARY_DARK: string = '#5DB88A';
    
    /** 辅助色 - 浅灰背景 */
    static readonly BACKGROUND: string = '#F5F5F5';
    static readonly CARD_BACKGROUND: string = '#FFFFFF';
    
    /** 文字颜色 */
    static readonly TEXT_PRIMARY: string = '#333333';
    static readonly TEXT_SECONDARY: string = '#666666';
    static readonly TEXT_TERTIARY: string = '#999999';
    static readonly TEXT_WHITE: string = '#FFFFFF';
    
    /** 进度条颜色 - 根据完成度变化 */
    static readonly PROGRESS_LOW: string = '#A8D8B9';      // 低进度 - 浅薄荷绿
    static readonly PROGRESS_MEDIUM: string = '#7EC8A0';   // 中进度 - 薄荷绿
    static readonly PROGRESS_HIGH: string = '#5DB88A';     // 高进度 - 深薄荷绿
    static readonly PROGRESS_COMPLETE: string = '#3CB371'; // 达标 - 翠绿色
    
    /** 功能色 */
    static readonly SUCCESS: string = '#3CB371';
    static readonly WARNING: string = '#F5A623';
    static readonly ERROR: string = '#E57373';
    static readonly INFO: string = '#7EC8A0';
    
    /** 边框和分割线 */
    static readonly BORDER: string = '#E8E8E8';
    static readonly DIVIDER: string = '#F0F0F0';
    
    /** 阴影颜色 */
    static readonly SHADOW: string = '#0000001A';
    static readonly SHADOW_LIGHT: string = '#0000000D';
}

/**
 * 全局样式常量
 */
export class AppStyles {
    /** 统一圆角 */
    static readonly BORDER_RADIUS: number = 16;
    static readonly BORDER_RADIUS_SM: number = 12;
    static readonly BORDER_RADIUS_LG: number = 20;
    
    /** 卡片阴影 */
    static readonly CARD_SHADOW: ShadowOptions = {
        radius: 12,
        color: '#0000001A',
        offsetX: 0,
        offsetY: 4
    };
    
    static readonly CARD_SHADOW_LIGHT: ShadowOptions = {
        radius: 8,
        color: '#0000000D',
        offsetX: 0,
        offsetY: 2
    };
    
    /** 间距 */
    static readonly SPACING_XS: number = 8;
    static readonly SPACING_SM: number = 12;
    static readonly SPACING_MD: number = 16;
    static readonly SPACING_LG: number = 24;
    static readonly SPACING_XL: number = 32;
    
    /** 页面内边距 */
    static readonly PAGE_PADDING: number = 20;
}

/**
 * 获取进度条颜色
 */
export function getProgressColor(progress: number): string {
    if (progress >= 100) {
        return AppColors.PROGRESS_COMPLETE;
    } else if (progress >= 70) {
        return AppColors.PROGRESS_HIGH;
    } else if (progress >= 40) {
        return AppColors.PROGRESS_MEDIUM;
    } else {
        return AppColors.PROGRESS_LOW;
    }
}

/**
 * 获取进度条渐变色（用于 Canvas）
 */
export function getProgressGradient(progress: number): [string, string] {
    if (progress >= 100) {
        return ['#3CB371', '#2E8B57']; // 翠绿渐变
    } else if (progress >= 70) {
        return ['#5DB88A', '#4DA876']; // 深薄荷绿渐变
    } else if (progress >= 40) {
        return ['#7EC8A0', '#6DB890']; // 薄荷绿渐变
    } else {
        return ['#A8D8B9', '#98C8A9']; // 浅薄荷绿渐变
    }
}
