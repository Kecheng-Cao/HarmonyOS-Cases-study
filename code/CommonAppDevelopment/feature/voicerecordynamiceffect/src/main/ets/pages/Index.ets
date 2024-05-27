/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** 实现步骤
 1.利用AVrecord录制音频病获取音频振幅
 2.利用振幅的变化，换算出column的height并加上动画效果。
 3.使用AVplayer播放录制的音频文件。
 */
import media from '@ohos.multimedia.media';
import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { CommonConstants as Const } from '../common/CommonConstants';
import { AppRouter } from '@ohos/dynamicsrouter/Index';

// 音频录制
export class AudioRecorderDemo {
  private avRecorder: media.AVRecorder | undefined = undefined;
  public maxAmplitude: number = 0;
  public time: number = 0;
  private avProfile: media.AVRecorderProfile = {
    audioBitrate: Const.AUDIO_BITRATE, // 音频比特率
    audioChannels: Const.AUDIO_CHANNELS, // 音频声道数
    audioCodec: media.CodecMimeType.AUDIO_AAC, // 音频编码格式，当前只支持aac
    audioSampleRate: Const.AUDIO_SAMPLE_RATE, // 音频采样率
    fileFormat: media.ContainerFormatType.CFT_MPEG_4A, // 封装格式，当前只支持m4a
  };
  private avConfig: media.AVRecorderConfig = {
    audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC, // 音频输入源，这里设置为麦克风
    profile: this.avProfile,
    url: 'fd://35', // 参考应用文件访问与管理开发示例新建并读写一个文件
  };

  // 注册audioRecorder回调函数
  setAudioRecorderCallback(): void {
    if (this.avRecorder !== undefined) {
      // 状态机变化回调函数
      this.avRecorder.on('stateChange', (state: media.AVRecorderState, _: media.StateChangeReason) => {
        console.log(`AudioRecorder current state is ${state}`);
      })
      // 错误上报回调函数
      this.avRecorder.on('error', (err: BusinessError) => {
        console.error(`AudioRecorder failed, code is ${err.code}, message is ${err.message}`);
      })
    }
  }

  // 开始录制对应的流程
  async startRecordingProcess(): Promise<void> {
    if (this.avRecorder !== undefined) {
      await this.avRecorder.release();
      this.avRecorder = undefined;
    }
    // 1.创建录制实例
    this.avRecorder = await media.createAVRecorder();
    this.setAudioRecorderCallback();
    // 2.获取录制文件fd赋予avConfig里的url；参考FilePicker文档
    const context = getContext(this);
    const path = context.filesDir;
    const filepath = path + '/01.mp3';

    const file = fs.openSync(filepath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    const fdNumber = file.fd;
    this.avConfig.url = 'fd://' + fdNumber;
    // 3.配置录制参数完成准备工作
    await this.avRecorder.prepare(this.avConfig);
    // 4.开始录制
    await this.avRecorder.start();

    // TODO：知识点：通过getAudioCapturerMaxAmplitude接口获取声音振幅大小。
    this.time = setInterval(() => {
      this.avRecorder!.getAudioCapturerMaxAmplitude((_: BusinessError, amplitude: number) => {
        this.maxAmplitude = amplitude;
      });
    }, Const.COLUMN_HEIGHT);
  }

  // 暂停录制对应的流程
  async pauseRecordingProcess(): Promise<void> {
    if (this.avRecorder !== undefined && this.avRecorder.state === 'started') { // 仅在started状态下调用pause为合理状态切换
      await this.avRecorder.pause();
    }
  }

  // 恢复录制对应的流程
  async resumeRecordingProcess(): Promise<void> {
    if (this.avRecorder !== undefined && this.avRecorder.state === 'paused') { // 仅在paused状态下调用resume为合理状态切换
      await this.avRecorder.resume();
    }
  }

  // 停止录制对应的流程
  async stopRecordingProcess(): Promise<void> {
    if (this.avRecorder !== undefined) {
      // 1. 停止录制
      if (this.avRecorder.state === 'started'
        || this.avRecorder.state === 'paused') { // 仅在started或者paused状态下调用stop为合理状态切换
        await this.avRecorder.stop();
        clearInterval(this.time);
      }
      // 2.重置
      await this.avRecorder.reset();
      // 3.释放录制实例
      await this.avRecorder.release();
      this.avRecorder = undefined;
    }
  }
}

// 音频播放
export class AVPlayerDemo {
  private count: number = 0;
  private isSeek: boolean = true; // 用于区分模式是否支持seek操作
  private fileSize: number = -1;
  private fd: number = 0;

  // 注册avplayer回调函数
  setAVPlayerCallback(avPlayer: media.AVPlayer): void {
    // seek操作结果回调函数
    avPlayer.on('seekDone', (seekDoneTime: number) => {
      console.info(`AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    })
    // error回调监听函数,当avPlayer在操作过程中出现错误时调用 reset接口触发重置流程
    avPlayer.on('error', (err: BusinessError) => {
      console.error(`Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
      avPlayer.reset(); // 调用reset重置资源，触发idle状态
    })
    // 状态机变化回调函数
    avPlayer.on('stateChange', async (state: string, _: media.StateChangeReason) => {
      switch (state) {
        case 'idle': // 成功调用reset接口后触发该状态机上报
          console.info('AVPlayer state idle called.');
          avPlayer.release(); // 调用release接口销毁实例对象
          break;
        case 'initialized': // avplayer 设置播放源后触发该状态上报
          console.info('AVPlayer state initialized called.');
          avPlayer.prepare();
          break;
        case 'prepared': // prepare调用成功后上报该状态机
          console.info('AVPlayer state prepared called.');
          avPlayer.play(); // 调用播放接口开始播放
          break;
        case 'playing': // play成功调用后触发该状态机上报
          console.info('AVPlayer state playing called.');
          this.count++;
          break;
        case 'paused': // pause成功调用后触发该状态机上报
          console.info('AVPlayer state paused called.');
          avPlayer.play(); // 再次播放接口开始播放
          break;
        case 'completed': // 播放结束后触发该状态机上报
          console.info('AVPlayer state completed called.');
          avPlayer.stop(); //调用播放结束接口
          break;
        case 'stopped': // stop接口成功调用后触发该状态机上报
          console.info('AVPlayer state stopped called.');
          avPlayer.reset(); // 调用reset接口初始化avplayer状态
          break;
        case 'released':
          console.info('AVPlayer state released called.');
          break;
        default:
          console.info('AVPlayer state unknown called.');
          break;
      }
    })
  }

  // 以下demo为使用fs文件系统打开沙箱地址获取媒体文件地址并通过url属性进行播放示例
  async avPlayerUrlDemo(): Promise<void> {
    // 创建avPlayer实例对象
    const avPlayer: media.AVPlayer = await media.createAVPlayer();
    // 创建状态机变化回调函数
    this.setAVPlayerCallback(avPlayer);
    let fdPath = 'fd://';
    // 通过UIAbilityContext获取沙箱地址filesDir，以Stage模型为例
    const context = getContext(this) as common.UIAbilityContext;
    const pathDir = context.filesDir;
    const path = pathDir + '/01.mp3';
    // 打开相应的资源文件地址获取fd，并为url赋值触发initialized状态机上报
    const file = await fs.open(path);
    fdPath = fdPath + '' + file.fd;
    this.isSeek = true; // 支持seek操作
    avPlayer.url = fdPath;
  }
}

// 获取麦克风权限
const permissions: Array<Permissions> = ['ohos.permission.MICROPHONE'];

function reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): void {
  const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    const granStatus: Array<number> = data.authResults;
    const length: number = granStatus.length;
    for (let i = 0; i < length; i++) {
      if (granStatus[i] === 0) {

      } else {
        return;
      }
    }
  })
}

/*
* 使用Foreach渲染出20个宽度相等，高度随机的Column。
* 当音频振幅传过来的时候，column高度会随之随机变化
*/

@Component
struct ButtonWithWaterRipples {
  @Link columnX: number; // 矩形width
  @Link yMax: number; // 矩形height最大值
  @Link yMin: number; // 矩形height最小值
  @State arr: Array<number> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]

  build() {
    Row({ space: Const.COLUMN_WIDTH }) {
      ForEach(this.arr, (_: number) => {
        Column()
          .width(this.columnX)
          .height(Math.floor(Math.random() * (this.yMin - this.yMax + Const.OPACITY_TRUE) + this.yMax))
          .backgroundColor(Color.Gray)
          .borderRadius($r("app.integer.voice_record_dynamic_effect_radius_column"))
      }, (index: number) => index.toString())
    }
    .borderRadius(Const.BLANK_COLUMN)
    .backgroundColor($r("app.color.voice_record_dynamic_effect_color_message"))
    .width($r("app.string.voice_record_dynamic_effect_width_half"))
    .height(Const.COLUMN_HEIGHT)
    .justifyContent(FlexAlign.Center)
  }
}

@AppRouter({ name: "voicerecordynamiceffect/GestureGroupExample" })
@Component
export struct GestureGroupExample {
  @State columnX: number = Const.COLUMN_WIDTH; // Column宽度
  @State yMax: number = Const.OPACITY_FALSE; // Column高度最大值
  @State yMin: number = Const.OPACITY_FALSE; // Column高度最小值
  @State isListening: boolean = false;
  @State count: number = Const.OPACITY_FALSE;
  @State flagUpOpacity: number = Const.OPACITY_FALSE; // 上划取消字样透明度
  @State flagInfoOpacity: number = Const.OPACITY_FALSE; // 消息条透明度
  @State maxNumber: number = Const.OPACITY_FALSE; // Column最大高度
  @State minNumber: number = Const.OPACITY_FALSE; // Column最小高度
  @State timeStart: number = Const.OPACITY_FALSE; // 初始时间戳
  @State timeEnd: number = Const.OPACITY_FALSE; // 结束时间戳
  @State timeAv: number = Const.OPACITY_FALSE; // 首饰持续时间
  // 创建音频录制与播放实例
  AVrecord = new AudioRecorderDemo();
  AVplaer = new AVPlayerDemo();

  aboutToAppear() {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    reqPermissionsFromUser(permissions, context);
  }

  @Builder
  message(message: string | Resource) {

    Row({ space: Const.BLANK_row }) {
      Image($r("app.media.voice_record_dynamic_effect_avatar_friend"))
        .width($r("app.integer.voice_record_dynamic_effect_width_image"))
        .height($r("app.integer.voice_record_dynamic_effect_height_image"))

      Text(message)
        .fontSize($r("app.integer.voice_record_dynamic_effect_font_size_text"))
        .textAlign(TextAlign.Center)
        .margin(5)
        .backgroundColor(Color.White)
        .padding({
          left: $r('app.integer.voice_record_dynamic_effect_margin_left'),
          right: $r('app.integer.voice_record_dynamic_effect_margin_left'),
          top: $r('app.integer.voice_record_dynamic_effect_margin_left'),
          bottom: $r('app.integer.voice_record_dynamic_effect_margin_left')
        })
        .borderRadius(Const.COLUMN_WIDTH)
    }
    .justifyContent(FlexAlign.Start)
    .width($r('app.string.voice_record_dynamic_effect_width_full'))
    .margin({ top: $r('app.integer.voice_record_dynamic_effect_margin_top') })
    .padding({ left: $r('app.integer.voice_record_dynamic_effect_margin_left'), right: $r('app.integer.voice_record_dynamic_effect_margin_left') })
  }

  @Builder
  myMessage(message: string | Resource) {

    Row({ space: Const.BLANK_row }) {

      Text($r("app.string.voice_record_dynamic_effect_talk_message_thr"))
        .fontSize($r("app.integer.voice_record_dynamic_effect_font_size_text"))
        .textAlign(TextAlign.Center)
        .margin(5)
        .backgroundColor($r("app.color.voice_record_dynamic_effect_color_message"))
        .padding({
          left: $r('app.integer.voice_record_dynamic_effect_margin_left'),
          right: $r('app.integer.voice_record_dynamic_effect_margin_left'),
          top: $r('app.integer.voice_record_dynamic_effect_margin_left'),
          bottom: $r('app.integer.voice_record_dynamic_effect_margin_left')
        })
        .borderRadius(Const.COLUMN_WIDTH)

      Image($r("app.media.voice_record_dynamic_effect_avatar_own"))
        .width($r("app.integer.voice_record_dynamic_effect_width_image"))
        .height($r("app.integer.voice_record_dynamic_effect_height_image"))

    }
    .justifyContent(FlexAlign.End)
    .width($r('app.string.voice_record_dynamic_effect_width_full'))
    .margin({ top: $r('app.integer.voice_record_dynamic_effect_margin_top') })
    .padding({ left: $r('app.integer.voice_record_dynamic_effect_margin_left'), right: $r('app.integer.voice_record_dynamic_effect_margin_left') })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Image($r("app.media.voice_record_dynamic_effect_left")).width($r("app.integer.voice_record_dynamic_effect_width_image")).height($r("app.integer.voice_record_dynamic_effect_height_image"))
          Text($r("app.string.voice_record_dynamic_effect_friend")).fontSize($r("app.integer.voice_record_dynamic_effect_font_size_text")).textAlign(TextAlign.Center)
          Image($r("app.media.voice_record_dynamic_effect_qmz0nuwq")).width($r("app.integer.voice_record_dynamic_effect_width_image")).height($r("app.integer.voice_record_dynamic_effect_height_image"))
        }
        .backgroundColor($r("app.color.voice_record_dynamic_effect_color_all"))
        .justifyContent(FlexAlign.SpaceBetween)
        .width($r('app.string.voice_record_dynamic_effect_width_full'))
        .padding($r("app.integer.voice_record_dynamic_effect_padding_row"))

        Column() {

          this.message($r("app.string.voice_record_dynamic_effect_talk_info"))
          this.message($r("app.string.voice_record_dynamic_effect_talk_message"))
          this.message($r("app.string.voice_record_dynamic_effect_talk_message_one"))
          this.message($r("app.string.voice_record_dynamic_effect_talk_message_two"))
          this.myMessage($r("app.string.voice_record_dynamic_effect_talk_message_thr"))
          this.message($r("app.string.voice_record_dynamic_effect_talk_message_four"))


          Row({ space: Const.BLANK_row }) {
            Row() {
              Image($r("app.media.voice_record_dynamic_effect_volume"))
                .width($r("app.integer.voice_record_dynamic_effect_width_image"))
                .height($r("app.integer.voice_record_dynamic_effect_height_image"))
              Text(this.timeAv.toString()).fontSize($r("app.integer.voice_record_dynamic_effect_font_size_text")).margin(5)
            }
            .borderRadius(Const.COLUMN_WIDTH)
            .justifyContent(FlexAlign.SpaceAround)
            .width(this.timeAv * Const.COLUMN_WIDTH + Const.HEIGHT_MIN)
            .backgroundColor($r("app.color.voice_record_dynamic_effect_color_message"))
            .margin({ top: $r('app.integer.voice_record_dynamic_effect_margin_top') })
            .padding({ left: $r('app.integer.voice_record_dynamic_effect_margin_left'), right: $r('app.integer.voice_record_dynamic_effect_margin_left') })
            .onClick(() => {
              this.AVplaer.avPlayerUrlDemo();
            })

            Image($r("app.media.voice_record_dynamic_effect_avatar_own"))
              .width($r("app.integer.voice_record_dynamic_effect_width_image"))
              .height($r("app.integer.voice_record_dynamic_effect_height_image"))
          }
          .width($r('app.string.voice_record_dynamic_effect_width_full'))
          .justifyContent(FlexAlign.End)
          .opacity(this.flagInfoOpacity)
          .margin({ top: $r('app.integer.voice_record_dynamic_effect_margin_top') })
          .padding({ left: $r('app.integer.voice_record_dynamic_effect_margin_left'), right: $r('app.integer.voice_record_dynamic_effect_margin_left') })


          Blank(Const.BLANK_COLUMN)
          Row() {
            Image($r("app.media.voice_record_dynamic_effect_icon"))
              .width($r("app.integer.voice_record_dynamic_effect_width_image"))
              .height($r("app.integer.voice_record_dynamic_effect_height_image"))
            Button($r("app.string.voice_record_dynamic_effect_button"))
              .type(ButtonType.Normal)
              .borderRadius(5)
              .backgroundColor(Color.White)
              .width($r("app.integer.voice_record_dynamic_effect_width_button"))
              .height($r("app.integer.voice_record_dynamic_effect_height_button"))
              .fontColor(Color.Black)
              .gesture(
                GestureGroup(GestureMode.Sequence,
                  LongPressGesture()
                    .onAction(() => {
                      // 获取时间戳
                      this.timeStart = Math.floor(new Date().getTime() / Const.ANIMATION_DURATION);
                      this.flagInfoOpacity = Const.OPACITY_FALSE;
                      this.isListening = !this.isListening;
                      this.flagUpOpacity = Const.OPACITY_TRUE;
                      this.AVrecord.startRecordingProcess();
                      // 每隔100ms获取一次振幅
                      this.count = setInterval(() => {
                        if (this.AVrecord.maxAmplitude > Const.MIN_AMPLITUDE) {
                          this.maxNumber = (this.AVrecord.maxAmplitude) / Const.MAX_AMPLITUDE * Const.COLUMN_HEIGHT;
                          this.minNumber = (this.AVrecord.maxAmplitude) / Const.MAX_AMPLITUDE * Const.COLUMN_HEIGHT - Const.HEIGHT_MIN;
                        } else {
                          this.maxNumber = Const.OPACITY_FALSE;
                          this.minNumber = Const.OPACITY_FALSE;
                        }
                        if (this.isListening) {
                          animateTo({ duration: Const.ANIMATION_DURATION, curve: Curve.EaseInOut }, () => {
                            this.yMax = this.maxNumber;
                            this.yMin = this.minNumber;
                          })
                        }
                      }, Const.SET_INTERVAL_TIME);
                    })
                    .onActionEnd(() => {
                      clearInterval(this.count);
                      this.flagInfoOpacity = Const.OPACITY_TRUE;
                      this.yMax = Const.OPACITY_FALSE;
                      this.yMin = Const.OPACITY_FALSE;
                      this.AVrecord.stopRecordingProcess();
                    }),
                  // 上划取消
                  PanGesture()
                    .onActionStart(() => {
                      clearInterval(this.count);
                    })
                    .onActionEnd(() => {
                      this.isListening = false;
                      animateTo({ duration: Const.OPACITY_FALSE }, () => {
                        this.yMax = Const.OPACITY_FALSE;
                        this.yMin = Const.OPACITY_FALSE;
                      })
                      this.flagUpOpacity = Const.OPACITY_FALSE;
                      this.flagInfoOpacity = Const.OPACITY_FALSE;
                      this.AVrecord.stopRecordingProcess();
                    })
                )
                  .onCancel(() => {
                    // 获取结束时间戳并计算出手势持续时间
                    this.timeEnd = Math.floor(new Date().getTime() / Const.ANIMATION_DURATION);
                    this.timeAv = this.timeEnd - this.timeStart;
                    clearInterval(this.count);
                    this.isListening = false;
                    // TODO：知识点：当不需要动画时设置duration为0打断动画。
                    animateTo({ duration: Const.OPACITY_FALSE }, () => {
                      this.yMax = Const.OPACITY_FALSE;
                      this.yMin = Const.OPACITY_FALSE;
                    });
                    this.flagUpOpacity = Const.OPACITY_FALSE;
                    this.flagInfoOpacity = Const.OPACITY_TRUE;
                    this.AVrecord.stopRecordingProcess();
                  })
              )
            Image($r("app.media.voice_record_dynamic_effect_emoji")).width($r("app.integer.voice_record_dynamic_effect_width_image")).height($r("app.integer.voice_record_dynamic_effect_height_image"))
            Image($r("app.media.voice_record_dynamic_effect_add")).width($r("app.integer.voice_record_dynamic_effect_width_image")).height($r("app.integer.voice_record_dynamic_effect_height_image"))
          }
          .justifyContent(FlexAlign.SpaceAround)
          .width($r('app.string.voice_record_dynamic_effect_width_full'))
          .height($r("app.integer.voice_record_dynamic_effect_height_row"))
          .backgroundColor($r("app.color.voice_record_dynamic_effect_color_row"))

        }
        .backgroundColor($r("app.color.voice_record_dynamic_effect_color_all"))
        .justifyContent(FlexAlign.End)
        .width($r('app.string.voice_record_dynamic_effect_width_full'))
        .height($r("app.string.voice_record_dynamic_effect_width_nine"))
      }
      .width($r('app.string.voice_record_dynamic_effect_width_full'))
      .height($r("app.string.voice_record_dynamic_effect_height_full"))

      if (this.flagUpOpacity === 1) {
        Column() {
          Column() {
            ButtonWithWaterRipples({ columnX: this.columnX, yMax: this.yMax, yMin: this.yMin });
            Text($r("app.string.voice_record_dynamic_effect_top_fig"))
              .fontSize($r("app.integer.voice_record_dynamic_effect_font_size_text"))
              .height($r("app.integer.voice_record_dynamic_effect_height_text"))
          }
          .justifyContent(FlexAlign.Center)
          .width($r('app.string.voice_record_dynamic_effect_width_full'))
          .height($r("app.string.voice_record_dynamic_effect_width_nine"))

          Row() {
            Text($r("app.string.voice_record_dynamic_effect_send_message")).fontSize($r("app.integer.voice_record_dynamic_effect_font_size_text")).fontColor(Color.White)
          }
          .justifyContent(FlexAlign.Center)
          .height(Const.HEIGHT_ST)
          .width($r('app.string.voice_record_dynamic_effect_width_full'))
          .borderRadius($r("app.integer.voice_record_dynamic_effect_radius_row"))
          .backgroundColor(Color.Gray)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor($r("app.string.voice_record_dynamic_effect_color_stack"))
        .width($r('app.string.voice_record_dynamic_effect_width_full'))
        .height($r("app.string.voice_record_dynamic_effect_height_full"))
      }
    }
    .alignContent(Alignment.Bottom)
    .width($r('app.string.voice_record_dynamic_effect_width_full'))
    .height($r("app.string.voice_record_dynamic_effect_height_full"))
  }
}