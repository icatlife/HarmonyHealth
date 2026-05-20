import { AppColors, getProgressGradient } from '../common/Constants';

/**
 * 环形进度条自定义组件
 * 用于展示步数完成进度的环形图表
 * 支持平滑动画过渡和薄荷绿渐变色效果
 * 中央文字使用 Canvas 绘制，确保精确居中
 */
@Component
export struct CircularProgress {
  /**
   * 当前步数
   */
  @Prop @Watch('onCurrentChanged') current: number = 0;
  
  /**
   * 目标步数
   */
  @Prop @Watch('onTotalChanged') total: number = 10000;
  
  /**
   * 是否显示中央文字（用于主页大尺寸显示）
   */
  @Prop showCenterText: boolean = true;
  
  /**
   * 动画进度值（0-100）
   */
  @State private animatedProgress: number = 0;
  
  /**
   * 动画步数值
   */
  @State private animatedCurrent: number = 0;
  
  /**
   * Canvas 设置
   */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  
  /**
   * Canvas 上下文
   */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  
  /**
   * 画布宽度（动态获取）
   */
  private canvasWidth: number = 200;
  
  /**
   * 画布高度（动态获取）
   */
  private canvasHeight: number = 200;
  
  /**
   * 环形半径
   */
  private radius: number = 85;
  
  /**
   * 环形线宽
   */
  private strokeWidth: number = 14;
  
  /**
   * 画布中心点X坐标
   */
  private centerX: number = 100;
  
  /**
   * 画布中心点Y坐标
   */
  private centerY: number = 100;
  
  /**
   * 组件构建
   */
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Canvas 环形进度条（包含中央文字）
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .onReady(() => {
          this.initCanvas();
          this.drawCircle();
        })
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      // 组件出现时初始化动画
      this.startAnimation();
    })
  }
  
  /**
   * 初始化Canvas参数（基于实际尺寸动态计算）
   */
  private initCanvas(): void {
    // 获取 Canvas 实际绘制尺寸
    const canvasSize = this.context.width;
    this.canvasWidth = canvasSize;
    this.canvasHeight = canvasSize;
    
    // 动态计算圆心坐标（Canvas 的正中央）
    this.centerX = this.canvasWidth / 2;
    this.centerY = this.canvasHeight / 2;
    
    // 动态计算环形半径（留出边距）
    const padding = 15; // 边距
    this.radius = (Math.min(this.canvasWidth, this.canvasHeight) / 2) - padding;
    
    // 动态计算线宽（根据尺寸比例）
    this.strokeWidth = Math.max(10, this.radius * 0.12);
  }
  
  /**
   * 绘制环形进度条
   */
  private drawCircle(): void {
    // 清除画布
    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    
    // 绘制背景环
    this.drawBackgroundCircle();
    
    // 绘制前景进度环
    this.drawProgressCircle();
    
    // 绘制中央文字
    if (this.showCenterText) {
      this.drawCenterText();
    }
  }
  
  /**
   * 绘制背景环（浅灰色）
   */
  private drawBackgroundCircle(): void {
    this.context.beginPath();
    this.context.arc(this.centerX, this.centerY, this.radius, 0, Math.PI * 2);
    this.context.strokeStyle = '#E8E8E8';
    this.context.lineWidth = this.strokeWidth;
    this.context.lineCap = 'round';
    this.context.stroke();
  }
  
  /**
   * 绘制前景进度环（薄荷绿渐变色）
   */
  private drawProgressCircle(): void {
    if (this.animatedProgress <= 0) return;
    
    // 计算进度角度（从顶部开始，顺时针）
    const startAngle = -Math.PI / 2;
    const endAngle = startAngle + (Math.PI * 2 * this.animatedProgress) / 100;
    
    // 获取薄荷绿渐变色
    const gradientColors = getProgressGradient(this.animatedProgress);
    const colorStart = gradientColors[0];
    const colorEnd = gradientColors[1];
    
    // 创建渐变色
    const gradient = this.context.createLinearGradient(
      this.centerX - this.radius, this.centerY,
      this.centerX + this.radius, this.centerY
    );
    gradient.addColorStop(0, colorStart);
    gradient.addColorStop(1, colorEnd);
    
    // 绘制进度环
    this.context.beginPath();
    this.context.arc(this.centerX, this.centerY, this.radius, startAngle, endAngle);
    this.context.strokeStyle = gradient;
    this.context.lineWidth = this.strokeWidth;
    this.context.lineCap = 'round';
    this.context.stroke();
  }
  
  /**
   * 绘制中央文字（以圆心为中心精确居中）
   */
  private drawCenterText(): void {
    // 设置文字对齐方式（确保文字以指定坐标为中心）
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    
    // 计算字体大小（根据半径动态调整）
    const stepFontSize = Math.max(24, this.radius * 0.35);
    const percentFontSize = Math.max(12, this.radius * 0.18);
    
    // 步数文字的 Y 坐标（圆心稍微上移，为百分比留出空间）
    const stepY = this.centerY - this.radius * 0.08;
    
    // 百分比文字的 Y 坐标（步数下方）
    const percentY = this.centerY + this.radius * 0.22;
    
    // 绘制步数数字
    this.context.font = `bold ${stepFontSize}px sans-serif`;
    this.context.fillStyle = AppColors.PRIMARY;
    this.context.fillText(
      this.animatedCurrent.toLocaleString(),
      this.centerX,
      stepY
    );
    
    // 绘制百分比进度
    this.context.font = `${percentFontSize}px sans-serif`;
    this.context.fillStyle = AppColors.TEXT_SECONDARY;
    this.context.fillText(
      `${Math.round(this.animatedProgress)}%`,
      this.centerX,
      percentY
    );
  }
  
  /**
   * 启动动画
   */
  private startAnimation(): void {
    // 计算目标进度百分比
    const targetProgress = this.total > 0 ? Math.min(100, (this.current / this.total) * 100) : 0;
    
    // 使用 animateTo 实现平滑动画
    animateTo({
      duration: 800,
      tempo: 0.8,
      curve: Curve.EaseOut
    }, () => {
      this.animatedProgress = targetProgress;
      this.animatedCurrent = this.current;
      
      // 动画完成后重绘Canvas
      this.drawCircle();
    });
  }
  
  /**
   * 监听 current 属性变化
   */
  onCurrentChanged(): void {
    this.startAnimation();
  }
  
  /**
   * 监听 total 属性变化
   */
  onTotalChanged(): void {
    this.startAnimation();
  }
}
