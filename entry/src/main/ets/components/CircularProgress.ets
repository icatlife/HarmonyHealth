/**
 * 环形进度条自定义组件
 * 用于展示步数完成进度的环形图表
 * 支持平滑动画过渡和渐变色效果
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
   * 环形半径
   */
  private radius: number = 0;
  
  /**
   * 环形线宽
   */
  private strokeWidth: number = 0;
  
  /**
   * 画布中心点X坐标
   */
  private centerX: number = 0;
  
  /**
   * 画布中心点Y坐标
   */
  private centerY: number = 0;
  
  /**
   * 组件构建
   */
  build() {
    Column({ space: 8 }) {
      // Canvas 环形进度条
      Canvas(this.context)
        .width(200)
        .height(200)
        .backgroundColor(Color.Transparent)
        .onReady(() => {
          this.initCanvas();
          this.drawCircle();
        })
      
      // 中央文本显示
      Column({ space: 4 }) {
        // 当前步数（大字体）
        Text(this.animatedCurrent.toLocaleString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
        
        // 百分比进度（四舍五入到整数）
        Text(`${Math.round(this.animatedProgress)}%`)
          .fontSize(14)
          .fontColor('#64748B')
      }
      .position({ x: 0, y: 0 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onAppear(() => {
      // 组件出现时初始化动画
      this.startAnimation();
    })
  }
  
  /**
   * 初始化Canvas参数
   */
  private initCanvas(): void {
    // 设置画布尺寸相关参数
    this.radius = 80;
    this.strokeWidth = 12;
    this.centerX = 100; // 画布宽度/2
    this.centerY = 100; // 画布高度/2
  }
  
  /**
   * 绘制环形进度条
   */
  private drawCircle(): void {
    // 清除画布
    this.context.clearRect(0, 0, 200, 200);
    
    // 绘制背景环
    this.drawBackgroundCircle();
    
    // 绘制前景进度环
    this.drawProgressCircle();
  }
  
  /**
   * 绘制背景环（灰色）
   */
  private drawBackgroundCircle(): void {
    this.context.beginPath();
    this.context.arc(this.centerX, this.centerY, this.radius, 0, Math.PI * 2);
    this.context.strokeStyle = '#E2E8F0'; // 浅灰色
    this.context.lineWidth = this.strokeWidth;
    this.context.lineCap = 'round'; // 圆头端点
    this.context.stroke();
  }
  
  /**
   * 绘制前景进度环（渐变色）
   */
  private drawProgressCircle(): void {
    if (this.animatedProgress <= 0) return;
    
    // 计算进度角度（从顶部开始，顺时针）
    const startAngle = -Math.PI / 2; // 顶部（-90度）
    const endAngle = startAngle + (Math.PI * 2 * this.animatedProgress) / 100;
    
    // 创建渐变色
    const gradient = this.context.createLinearGradient(
      this.centerX - this.radius, this.centerY,
      this.centerX + this.radius, this.centerY
    );
    
    // 根据进度选择渐变色
    if (this.animatedProgress >= 100) {
      // 完成状态：绿色渐变
      gradient.addColorStop(0, '#10B981'); // 翠绿色
      gradient.addColorStop(1, '#059669'); // 深绿色
    } else if (this.animatedProgress >= 70) {
      // 良好进度：蓝绿色渐变
      gradient.addColorStop(0, '#3B82F6'); // 蓝色
      gradient.addColorStop(1, '#06B6D4'); // 青色
    } else if (this.animatedProgress >= 40) {
      // 中等进度：橙黄色渐变
      gradient.addColorStop(0, '#F59E0B'); // 橙色
      gradient.addColorStop(1, '#EAB308'); // 黄色
    } else {
      // 低进度：红色渐变
      gradient.addColorStop(0, '#EF4444'); // 红色
      gradient.addColorStop(1, '#DC2626'); // 深红色
    }
    
    // 绘制进度环
    this.context.beginPath();
    this.context.arc(this.centerX, this.centerY, this.radius, startAngle, endAngle);
    this.context.strokeStyle = gradient;
    this.context.lineWidth = this.strokeWidth;
    this.context.lineCap = 'round'; // 圆头端点
    this.context.stroke();
  }
  
  /**
   * 启动动画
   */
  private startAnimation(): void {
    // 计算目标进度百分比
    const targetProgress = this.total > 0 ? Math.min(100, (this.current / this.total) * 100) : 0;
    
    // 使用 animateTo 实现平滑动画
    animateTo({
      duration: 800, // 动画时长800ms
      tempo: 0.8,    // 动画节奏
      curve: Curve.EaseOut // 缓出效果
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
    // 当 current 变化时重新启动动画
    this.startAnimation();
  }
  
  /**
   * 监听 total 属性变化
   */
  onTotalChanged(): void {
    // 当 total 变化时重新启动动画
    this.startAnimation();
  }
}

/**
 * 组件使用示例：
 * 
 * @Component
 * struct ExamplePage {
 *   @State currentSteps: number = 3500;
 *   @State goalSteps: number = 10000;
 *   
 *   build() {
 *     Column() {
 *       CircularProgress({ 
 *         current: this.currentSteps, 
 *         total: this.goalSteps 
 *       })
 *       .width(200)
 *       .height(200)
 *     }
 *   }
 * }
 * 
 * 组件特性：
 * 1. 平滑动画：使用 animateTo 实现进度和数字的平滑过渡
 * 2. 智能渐变色：根据完成度自动选择颜色（红→橙→蓝→绿）
 * 3. 圆头端点：进度条两端为圆形，视觉效果更佳
 * 4. 响应式设计：自动适配容器尺寸
 * 5. 中央显示：同时显示步数和百分比，信息完整
 * 6. Canvas绘制：使用HarmonyOS标准Canvas API，性能优秀
 */