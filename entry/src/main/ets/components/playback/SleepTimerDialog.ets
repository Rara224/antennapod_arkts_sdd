// 睡眠计时器弹窗：15/30/45/60分钟、集末暂停、取消，连接SleepTimer单例
import { SleepTimer } from '../../playback/SleepTimer';
import { EventBus, EVENT_SLEEP_TIMER } from '../../common/EventBus';
import { SleepTimerData } from '../../common/EventData';
import { PlaybackController } from '../../playback/PlaybackController';

@CustomDialog
export struct SleepTimerDialog {
  controller: CustomDialogController;
  onClose?: () => void;
  @State remainingText: string = '';
  @State isRunning: boolean = false;
  private sleepTimer: SleepTimer = SleepTimer.getInstance();
  private playbackCtrl: PlaybackController = PlaybackController.getInstance();
  private unsubscribeSleepTimer: (() => void) | undefined = undefined;

  aboutToAppear(): void {
    this.updateState();
    this.unsubscribeSleepTimer = EventBus.getInstance().subscribe(
      EVENT_SLEEP_TIMER,
      (data: Object): void => {
        const timerData = data as SleepTimerData;
        this.isRunning = timerData.isRunning;
        this.remainingText = this.formatTimeLeft(timerData.timeLeft);
      }
    );
  }

  aboutToDisappear(): void {
    if (this.unsubscribeSleepTimer !== undefined) {
      this.unsubscribeSleepTimer();
    }
  }

  private updateState(): void {
    const timeLeft = this.sleepTimer.getTimeLeft();
    this.isRunning = this.sleepTimer.isRunning();
    this.remainingText = this.formatTimeLeft(timeLeft);
  }

  private formatTimeLeft(ms: number): string {
    if (ms <= 0) {
      return '';
    }
    const totalSeconds = Math.floor(ms / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    if (hours > 0) {
      return pad(hours) + ':' + pad(minutes) + ':' + pad(seconds) + ' remaining';
    }
    return pad(minutes) + ':' + pad(seconds) + ' remaining';
  }

  private onSelectTime(minutes: number): void {
    if (this.isRunning) {
      this.sleepTimer.extend(minutes);
    } else {
      this.sleepTimer.start(minutes);
    }
    this.onClose?.();
  }

  private onEndOfEpisode(): void {
    this.sleepTimer.cancel();
    // Sleep at end of episode: the SleepTimer callback set in PlaybackController
    // already calls pause(). We start a timer with a very long duration as the
    // "end of episode" mechanism is handled by the onCompleted callback.
    const duration = AppStorage.get<number>('playbackDuration');
    const position = AppStorage.get<number>('playbackPosition');
    if (duration !== undefined && position !== undefined && duration > position) {
      const remainingMs = duration - position;
      const remainingMin = Math.ceil(remainingMs / 60000);
      this.sleepTimer.start(remainingMin > 0 ? remainingMin : 1);
    } else {
      this.sleepTimer.start(60);
    }
    this.onClose?.();
  }

  private onCancel(): void {
    this.sleepTimer.cancel();
    this.onClose?.();
  }

  build() {
    Column() {
      Text('Sleep timer')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 4 })
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.isRunning && this.remainingText.length > 0) {
        Text(this.remainingText)
          .fontSize(14)
          .fontColor('#1565C0')
          .margin({ bottom: 16 })
      }

      Divider().strokeWidth(0.5).color('#E0E0E0').margin({ bottom: 8 })

      // Time options
      Column() {
        Row() {
          Text('15 minutes')
            .fontSize(17)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor(['#CCCCCC'])
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => { this.onSelectTime(15); })

        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 20 })

        Row() {
          Text('30 minutes')
            .fontSize(17)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor(['#CCCCCC'])
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => { this.onSelectTime(30); })

        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 20 })

        Row() {
          Text('45 minutes')
            .fontSize(17)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor(['#CCCCCC'])
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => { this.onSelectTime(45); })

        Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 20 })

        Row() {
          Text('60 minutes')
            .fontSize(17)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor(['#CCCCCC'])
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => { this.onSelectTime(60); })
      }

      Divider().strokeWidth(0.5).color('#E0E0E0').margin({ top: 8, bottom: 8 })

      Column() {
        Row() {
          Text('End of episode')
            .fontSize(17)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor(['#CCCCCC'])
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => { this.onEndOfEpisode(); })
      }

      if (this.isRunning) {
        Divider().strokeWidth(0.5).color('#E0E0E0').margin({ top: 8, bottom: 8 })

        Row() {
          Text('Cancel timer')
            .fontSize(17)
            .fontColor('#D32F2F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => { this.onCancel(); })
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ bottom: 34 })
  }
}
