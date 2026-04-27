export class TranscriptEntry {
  startTimeMs: number = 0;
  endTimeMs: number = 0;
  text: string = '';
  speaker: string = '';

  constructor(startTimeMs: number, endTimeMs: number, text: string, speaker: string) {
    this.startTimeMs = startTimeMs;
    this.endTimeMs = endTimeMs;
    this.text = text;
    this.speaker = speaker;
  }
}
