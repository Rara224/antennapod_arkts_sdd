import { PlaybackController } from '../../playback/PlaybackController';

@CustomDialog
export struct SpeedDialog {
  controller: CustomDialogController;
  onClose?: () => void;
  currentSpeed: number = 1.0;
  skipSilence: boolean = false;
  private playbackCtrl: PlaybackController = PlaybackController.getInstance();
  private validSpeeds: number[] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  build() {
    Column() {
      Text('Playback speed')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)

      // Speed buttons in a grid
      Row() {
        ForEach(this.validSpeeds, (speed: number) => {
          Text(speed.toFixed(2) + 'x')
            .fontSize(15)
            .fontWeight(Math.abs(speed - this.currentSpeed) < 0.01 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(Math.abs(speed - this.currentSpeed) < 0.01 ? Color.White : '#333333')
            .backgroundColor(Math.abs(speed - this.currentSpeed) < 0.01 ? '#1565C0' : '#F0F0F0')
            .borderRadius(20)
            .height(40)
            .padding({ left: 16, right: 16 })
            .textAlign(TextAlign.Center)
            .margin({ left: 4, right: 4 })
            .onClick(() => {
              this.playbackCtrl.setSpeed(speed);
              this.onClose?.();
            })
        }, (speed: number) => speed.toString())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 24 })

      // Skip silence toggle
      Row() {
        Text('Skip silence')
          .fontSize(17)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.skipSilence })
          .selectedColor('#1565C0')
          .onChange((isOn: boolean) => {
            AppStorage.setOrCreate<boolean>('skipSilence', isOn);
          })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ left: 20, right: 20, bottom: 34 })
  }
}
