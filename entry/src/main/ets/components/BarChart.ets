/**
 * 柱状图自定义组件
 * 用于展示近7天步数数据的柱状图表
 * 使用Canvas绘制，支持动画效果和渐变色
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
  private chartWidth: number = 300;
  private chartHeight: number = 200;
  private marginTop: number = 30;
  private marginRight: number = 20;
  private marginBottom: number = 40;
  private marginLeft: number = 40;
  
  /**
   * 绘制区域尺寸
   */
  private plotWidth: number = 0;
  private plotHeight: number = 0;
  
  /**
   * 组件构建
   */
  build() {
    Column({ space: 16 }) {
      // 图表标题
      Text('近7天步数趋势')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1E293B')
        .width('100%')
        .textAlign(TextAlign.Start)
      
      // 图表容器
      Stack({ alignContent: Alignment.Center }) {
        // Canvas 柱状图
        Canvas(this.context)
          .width(this.chartWidth)
          .height(this.chartHeight)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 })
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
              .fontColor('#64748B')
              .textAlign(TextAlign.Center)
            
            Text('开始运动后即可查看历史趋势')
              .fontSize(12)
              .fontColor('#94A3B8')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF80')
        }
      }
      .width(this.chartWidth)
      .height(this.chartHeight)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F8FAFC')
    .borderRadius(16)
    .onAppear(() => {
      // 组件出现时初始化动画数据
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
    // 初始化动画数据为0
    this.animatedData = new Array(this.data.length).fill(0);
    
    // 如果数据不为空，启动动画
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
      
      // 动画完成后重绘图表
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
    
    // 清除画布
    this.context.clearRect(0, 0, this.chartWidth, this.chartHeight);
    
    // 绘制背景
    this.drawBackground();
    
    // 绘制坐标轴
    this.drawAxes();
    
    // 绘制柱子
    this.drawBars();
    
    // 绘制网格线
    this.drawGridLines();
  }
  
  /**
   * 绘制图表背景
   */
  private drawBackground(): void {
    // 绘制白色圆角背景
    this.context.fillStyle = '#FFFFFF';
    this.context.beginPath();
    
    // 手动绘制圆角矩形（兼容性更好）
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
    // 设置坐标轴样式
    this.context.strokeStyle = '#E2E8F0';
    this.context.lineWidth = 1;
    this.context.fillStyle = '#64748B';
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
    
    // 绘制横轴标签
    this.drawXAxisLabels();
    
    // 绘制纵轴刻度
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
      
      // 绘制刻度线
      this.context.beginPath();
      this.context.moveTo(this.marginLeft - 5, y);
      this.context.lineTo(this.marginLeft, y);
      this.context.stroke();
      
      // 绘制刻度值
      this.context.textAlign = 'right';
      this.context.fillText(value.toLocaleString(), this.marginLeft - 8, y);
      this.context.textAlign = 'center';
    }
  }
  
  /**
   * 绘制网格线
   */
  private drawGridLines(): void {
    const maxValue = Math.max(...this.data);
    const tickCount = 5;
    
    this.context.strokeStyle = '#F1F5F9';
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
   * 绘制柱子
   */
  private drawBars(): void {
    const maxValue = Math.max(...this.data);
    const barWidth = this.plotWidth / this.data.length * 0.6; // 柱子宽度为间隔的60%
    const barSpacing = this.plotWidth / this.data.length * 0.2; // 间距为间隔的20%
    
    this.data.forEach((value, index) => {
      const animatedValue = this.animatedData[index] || 0;
      const barHeight = maxValue > 0 ? (animatedValue / maxValue) * this.plotHeight : 0;
      const x = this.marginLeft + index * (barWidth + barSpacing) + barSpacing;
      const y = this.marginTop + this.plotHeight - barHeight;
      
      // 创建柱子渐变色
      const gradient = this.context.createLinearGradient(x, y, x, y + barHeight);
      
      // 根据值大小选择颜色
      if (value >= 8000) {
        gradient.addColorStop(0, '#10B981'); // 绿色（高活动量）
        gradient.addColorStop(1, '#059669');
      } else if (value >= 5000) {
        gradient.addColorStop(0, '#3B82F6'); // 蓝色（中等活动量）
        gradient.addColorStop(1, '#2563EB');
      } else {
        gradient.addColorStop(0, '#F59E0B'); // 橙色（低活动量）
        gradient.addColorStop(1, '#D97706');
      }
      
      // 绘制柱子
      this.context.fillStyle = gradient;
      
      // 手动绘制圆角矩形
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
      
      // 绘制柱子顶部阴影效果
      const topGradient = this.context.createLinearGradient(x, y, x, y + 10);
      topGradient.addColorStop(0, '#FFFFFF40');
      topGradient.addColorStop(1, '#FFFFFF00');
      
      this.context.fillStyle = topGradient;
      this.context.beginPath();
      this.context.moveTo(x + radius, y);
      this.context.lineTo(x + barWidth - radius, y);
      this.context.arcTo(x + barWidth, y, x + barWidth, y + radius, radius);
      this.context.lineTo(x + barWidth, y + Math.min(10, barHeight) - radius);
      this.context.arcTo(x + barWidth, y + Math.min(10, barHeight), x + barWidth - radius, y + Math.min(10, barHeight), radius);
      this.context.lineTo(x + radius, y + Math.min(10, barHeight));
      this.context.arcTo(x, y + Math.min(10, barHeight), x, y + Math.min(10, barHeight) - radius, radius);
      this.context.lineTo(x, y + radius);
      this.context.arcTo(x, y, x + radius, y, radius);
      this.context.closePath();
      
      this.context.fill();
      
      // 在柱子顶部显示数值（如果柱子足够高）
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
    // 当数据变化时重新启动动画
    if (!this.isDataEmpty()) {
      this.startAnimation();
    }
  }
}

/**
 * 组件使用示例：
 * 
 * @Component
 * struct HistoryPage {
 *   @State stepData: number[] = [4500, 6200, 3800, 7800, 9200, 8500, 6700];
 *   @State dateLabels: string[] = ['04-07', '04-08', '04-09', '04-10', '04-11', '04-12', '04-13'];
 *   
 *   build() {
 *     Column() {
 *       BarChart({
 *         data: this.stepData,
 *         labels: this.dateLabels
 *       })
 *       .width('100%')
 *     }
 *   }
 * }
 * 
 * 组件特性：
 * 1. 动画效果：柱子高度平滑增长的动画
 * 2. 智能配色：根据步数大小自动选择颜色（橙→蓝→绿）
 * 3. 完整坐标：包含横轴标签和纵轴刻度
 * 4. 网格背景：浅色网格线增强可读性
 * 5. 数据提示：柱子顶部显示具体数值
 * 6. 空状态：数据为空时显示友好的占位提示
 * 7. 圆角设计：现代圆角卡片式设计
 */