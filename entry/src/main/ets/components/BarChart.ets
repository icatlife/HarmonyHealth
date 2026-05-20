import { AppColors, AppStyles } from '../common/Constants';

/**
 * 柱状图自定义组件
 * 用于展示近7天步数数据的柱状图表
 * 使用Canvas绘制，支持动画效果和薄荷绿渐变色
 */
@Component
export struct BarChart {
  /**
   * 步数数据数组（近7天）
   */
  @Prop data: number[] = [];
  
  /**
   * 横轴标签数组（日期）
   */
  @Prop labels: string[] = [];
  
  /**
   * 动画数据（用于柱子高度动画）
   */
  @State private animatedData: number[] = [];
  
  /**
   * Canvas 设置
   */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  
  /**
   * Canvas 上下文
   */
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  
  /**
   * 图表尺寸参数
   */
  private chartWidth: number = 320;
  private chartHeight: number = 220;
  private marginTop: number = 30;
  private marginRight: number = 20;
  private marginBottom: number = 40;
  private marginLeft: number = 45;
  
  /**
   * 绘制区域尺寸
   */
  private plotWidth: number = 0;
  private plotHeight: number = 0;
  
  /**
   * 组件构建
   */
  build() {
    Column({ space: AppStyles.SPACING_MD }) {
      // 图表标题
      Text('近7天步数趋势')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Start)
      
      // 图表容器
      Stack({ alignContent: Alignment.Center }) {
        // Canvas 柱状图
        Canvas(this.context)
          .width(this.chartWidth)
          .height(this.chartHeight)
          .backgroundColor(AppColors.CARD_BACKGROUND)
          .borderRadius(AppStyles.BORDER_RADIUS_SM)
          .shadow(AppStyles.CARD_SHADOW_LIGHT)
          .onReady(() => {
            this.initChartDimensions();
            this.drawChart();
          })
        
        // 暂无数据提示（条件显示）
        if (this.isDataEmpty()) {
          Column({ space: 8 }) {
            Text('📊')
              .fontSize(32)
              .fontWeight(FontWeight.Normal)
            
            Text('暂无数据')
              .fontSize(16)
              .fontColor(AppColors.TEXT_SECONDARY)
              .textAlign(TextAlign.Center)
            
            Text('开始运动后即可查看历史趋势')
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFFCC')
        }
      }
      .width(this.chartWidth)
      .height(this.chartHeight)
    }
    .width('100%')
    .padding(AppStyles.SPACING_MD)
    .backgroundColor(AppColors.BACKGROUND)
    .borderRadius(AppStyles.BORDER_RADIUS)
    .onAppear(() => {
      this.initializeAnimation();
    })
  }
  
  /**
   * 检查数据是否为空
   */
  private isDataEmpty(): boolean {
    return this.data.length === 0 || this.data.every(value => value === 0);
  }
  
  /**
   * 初始化图表尺寸
   */
  private initChartDimensions(): void {
    this.plotWidth = this.chartWidth - this.marginLeft - this.marginRight;
    this.plotHeight = this.chartHeight - this.marginTop - this.marginBottom;
  }
  
  /**
   * 初始化动画数据
   */
  private initializeAnimation(): void {
    this.animatedData = new Array(this.data.length).fill(0);
    
    if (!this.isDataEmpty()) {
      this.startAnimation();
    }
  }
  
  /**
   * 启动柱子高度动画
   */
  private startAnimation(): void {
    animateTo({
      duration: 1000,
      curve: Curve.EaseOut
    }, () => {
      this.animatedData = [...this.data];
      this.drawChart();
    });
  }
  
  /**
   * 绘制完整图表
   */
  private drawChart(): void {
    if (this.isDataEmpty()) {
      return;
    }
    
    this.context.clearRect(0, 0, this.chartWidth, this.chartHeight);
    this.drawBackground();
    this.drawAxes();
    this.drawBars();
    this.drawGridLines();
  }
  
  /**
   * 绘制图表背景
   */
  private drawBackground(): void {
    this.context.fillStyle = AppColors.CARD_BACKGROUND;
    this.context.beginPath();
    
    const radius = 12;
    this.context.moveTo(radius, 0);
    this.context.lineTo(this.chartWidth - radius, 0);
    this.context.arcTo(this.chartWidth, 0, this.chartWidth, radius, radius);
    this.context.lineTo(this.chartWidth, this.chartHeight - radius);
    this.context.arcTo(this.chartWidth, this.chartHeight, this.chartWidth - radius, this.chartHeight, radius);
    this.context.lineTo(radius, this.chartHeight);
    this.context.arcTo(0, this.chartHeight, 0, this.chartHeight - radius, radius);
    this.context.lineTo(0, radius);
    this.context.arcTo(0, 0, radius, 0, radius);
    this.context.closePath();
    
    this.context.fill();
  }
  
  /**
   * 绘制坐标轴
   */
  private drawAxes(): void {
    this.context.strokeStyle = AppColors.BORDER;
    this.context.lineWidth = 1;
    this.context.fillStyle = AppColors.TEXT_SECONDARY;
    this.context.font = '12px sans-serif';
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    
    // 绘制横轴（底部）
    this.context.beginPath();
    this.context.moveTo(this.marginLeft, this.marginTop + this.plotHeight);
    this.context.lineTo(this.marginLeft + this.plotWidth, this.marginTop + this.plotHeight);
    this.context.stroke();
    
    // 绘制纵轴（左侧）
    this.context.beginPath();
    this.context.moveTo(this.marginLeft, this.marginTop);
    this.context.lineTo(this.marginLeft, this.marginTop + this.plotHeight);
    this.context.stroke();
    
    this.drawXAxisLabels();
    this.drawYAxisTicks();
  }
  
  /**
   * 绘制横轴标签
   */
  private drawXAxisLabels(): void {
    const barWidth = this.plotWidth / this.data.length;
    
    this.data.forEach((_, index) => {
      const x = this.marginLeft + (index + 0.5) * barWidth;
      const y = this.marginTop + this.plotHeight + 20;
      
      const label = this.labels[index] || `${index + 1}`;
      
      this.context.fillText(label, x, y);
    });
  }
  
  /**
   * 绘制纵轴刻度
   */
  private drawYAxisTicks(): void {
    const maxValue = Math.max(...this.data);
    const tickCount = 5;
    
    for (let i = 0; i <= tickCount; i++) {
      const value = Math.round((maxValue * i) / tickCount);
      const y = this.marginTop + this.plotHeight - (this.plotHeight * i) / tickCount;
      
      this.context.beginPath();
      this.context.moveTo(this.marginLeft - 5, y);
      this.context.lineTo(this.marginLeft, y);
      this.context.stroke();
      
      this.context.textAlign = 'right';
      this.context.fillText(value.toLocaleString(), this.marginLeft - 8, y);
      this.context.textAlign = 'center';
    }
  }
  
  /**
   * 绘制网格线
   */
  private drawGridLines(): void {
    const tickCount = 5;
    
    this.context.strokeStyle = '#F5F5F5';
    this.context.lineWidth = 1;
    
    for (let i = 0; i <= tickCount; i++) {
      const y = this.marginTop + this.plotHeight - (this.plotHeight * i) / tickCount;
      
      this.context.beginPath();
      this.context.moveTo(this.marginLeft, y);
      this.context.lineTo(this.marginLeft + this.plotWidth, y);
      this.context.stroke();
    }
  }
  
  /**
   * 绘制柱子 - 使用薄荷绿渐变
   */
  private drawBars(): void {
    const maxValue = Math.max(...this.data);
    const barWidth = this.plotWidth / this.data.length * 0.6;
    const barSpacing = this.plotWidth / this.data.length * 0.2;
    
    this.data.forEach((value, index) => {
      const animatedValue = this.animatedData[index] || 0;
      const barHeight = maxValue > 0 ? (animatedValue / maxValue) * this.plotHeight : 0;
      const x = this.marginLeft + index * (barWidth + barSpacing) + barSpacing;
      const y = this.marginTop + this.plotHeight - barHeight;
      
      // 创建薄荷绿渐变色
      const gradient = this.context.createLinearGradient(x, y, x, y + barHeight);
      
      // 根据值大小选择薄荷绿深浅
      if (value >= 8000) {
        // 高活动量 - 翠绿色
        gradient.addColorStop(0, '#3CB371');
        gradient.addColorStop(1, '#2E8B57');
      } else if (value >= 5000) {
        // 中等活动量 - 薄荷绿
        gradient.addColorStop(0, '#7EC8A0');
        gradient.addColorStop(1, '#5DB88A');
      } else {
        // 低活动量 - 浅薄荷绿
        gradient.addColorStop(0, '#A8D8B9');
        gradient.addColorStop(1, '#98C8A9');
      }
      
      // 绘制柱子
      this.context.fillStyle = gradient;
      
      const radius = 4;
      this.context.beginPath();
      this.context.moveTo(x + radius, y);
      this.context.lineTo(x + barWidth - radius, y);
      this.context.arcTo(x + barWidth, y, x + barWidth, y + radius, radius);
      this.context.lineTo(x + barWidth, y + barHeight - radius);
      this.context.arcTo(x + barWidth, y + barHeight, x + barWidth - radius, y + barHeight, radius);
      this.context.lineTo(x + radius, y + barHeight);
      this.context.arcTo(x, y + barHeight, x, y + barHeight - radius, radius);
      this.context.lineTo(x, y + radius);
      this.context.arcTo(x, y, x + radius, y, radius);
      this.context.closePath();
      
      this.context.fill();
      
      // 在柱子顶部显示数值
      if (barHeight > 25) {
        this.context.fillStyle = '#FFFFFF';
        this.context.font = '10px sans-serif';
        this.context.textAlign = 'center';
        this.context.fillText(
          animatedValue.toLocaleString(),
          x + barWidth / 2,
          y + 12
        );
      }
    });
  }
  
  /**
   * 属性变化监听
   */
  aboutToUpdate(): void {
    if (!this.isDataEmpty()) {
      this.startAnimation();
    }
  }
}
