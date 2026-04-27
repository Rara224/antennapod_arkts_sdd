export class ChartSegment {
  color: string = '';
  percentage: number = 0;
  label: string = '';
}

@Component
export struct HalfCircleChart {
  @Prop segments: ChartSegment[] = [];
  @Prop centerText: string = '';
  @Prop subtitleText: string = '';
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column() {
      Canvas(this.context)
        .width(240)
        .height(140)
        .onReady(() => {
          this.drawChart();
        })

      if (this.centerText.length > 0) {
        Text(this.centerText)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: -20 })
          .textAlign(TextAlign.Center)
        if (this.subtitleText.length > 0) {
          Text(this.subtitleText)
            .fontSize(12)
            .fontColor('#99000000')
            .margin({ top: 4 })
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })
        }
      }
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: 16, bottom: 16 })
  }

  private drawChart(): void {
    const ctx = this.context;
    const centerX = 120;
    const centerY = 130;
    const radius = 100;
    const lineWidth = 24;

    ctx.lineWidth = lineWidth;
    ctx.lineCap = 'round';

    if (this.segments.length === 0) {
      // Draw empty arc in blue (matching Android)
      ctx.strokeStyle = '#1565C0';
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, Math.PI, 2 * Math.PI);
      ctx.stroke();
      return;
    }

    // Draw segments
    let currentAngle = Math.PI;
    const totalAngle = Math.PI;

    for (let i = 0; i < this.segments.length; i++) {
      const segment = this.segments[i];
      const segmentAngle = totalAngle * segment.percentage / 100;

      if (segmentAngle > 0.01) {
        ctx.strokeStyle = segment.color;
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + segmentAngle);
        ctx.stroke();
        currentAngle += segmentAngle;
      }
    }

    if (currentAngle < 2 * Math.PI) {
      ctx.strokeStyle = '#E0E0E0';
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, currentAngle, 2 * Math.PI);
      ctx.stroke();
    }
  }
}
