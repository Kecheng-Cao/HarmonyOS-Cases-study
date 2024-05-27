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

import display from '@ohos.display';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { AvVideoPlayer, GlobalContext, IVideoPlayer, PlayerType, PlayStatus, StandardGSYVideoModel } from '@ohos/gsyvideoplayer';
import audio from '@ohos.multimedia.audio';
import emitter from '@ohos.events.emitter';
import settings from '@ohos.settings';
import { BaseDanmaku, BaseDanmakuParser, Callback, DANMAKU_STYLE_STROKEN, DanmakuContext, DanmakuTimer, DanmakuView, IDanmakus, IDanmakuView, JSONSource, OnDanmakuClickListener, Proxy, SpannedCacheStuffer, SystemClock } from '@ohos/danmakuflamemaster';
import { DanmakuParser } from './DanmakuParser';
import { sourceData } from './DanmakuData';
import { logger } from '@ohos/common';


let updateProgressTimer: number = 0;
let changeWidth: number = 0;
let changeHeight: number = 0;
let screenWidth: number = 0;
let screenHeight: number = 0;
let uiTime: number = 0;
let uiLockTime: number = 0;
let windowClass: window.Window | undefined = undefined;
const videoPlayEvent: emitter.InnerEvent = {
  eventId: 1
};
const videoInitEvent: emitter.InnerEvent = {
  eventId: 2
};
const videoPauseEvent: emitter.InnerEvent = {
  eventId: 3
};

let touchStartX: number = 0;
let touchStartY: number = 0;

@Component
export struct DanmakuVideoPlayer {
  iVideoPlayer: IVideoPlayer | undefined = undefined;
  @Provide currentTime: string = "00:00";
  @Provide totalTime: string = "00:00";
  @State progressValue: number = 0;
  @State slideEnable: boolean = false;
  @State eventType: string = '';
  @State showBottomUi: boolean = false;
  @State fullShowTop: boolean = false;
  @State fullShowLock: boolean = false;
  @State lock: boolean = false;
  // 播放按钮显示
  @State showPlay: boolean = true;
  // 暂停按钮显示
  @State showPause: boolean = false;
  // 是否销毁页面
  @State destroyPage: boolean = false;
  // 是否加载中
  @State loadingVisible: Visibility = Visibility.None;
  // 当前视频方向
  @State curDirection: number = 0;
  // 是否全屏
  @State screenIsFull: boolean = false;
  // 弹幕开关文本
  @State danmakuText: string = "弹幕开";
  // 是否显示音量数值的布局
  @State showVolumeUi: boolean = false;
  // 是否显示亮度数值的布局
  @State showBrightnessUi: boolean = false;
  // 是否显示横向滑动的进度布局
  @State showSeekProgressUi: boolean = false;
  // 当前音量 [0-20]
  @State currentVolumeValue: number = 0;
  // 系统最大音量
  @State maxVolumeValue: number = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_volume_value"));
  // 当前亮度 [0-255]
  @State currentBrightness: number = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_current_brightness"));
  // 拖拽的时间
  @State seekCurrentTime: string = this.currentTime;
  // 当前进度
  @State seekTimePosition: number = 0;
  // 是否拖动进度条
  private isSeek: boolean = false;
  // 是否正在加载手势滑动禁止
  private isLoadNotSeek: boolean = false;
  // 当前拖拽进度的方向资源
  @State seekDirectionRes: Resource = $r("app.media.danmaku_player_video_forward_icon");
  private audioManager: audio.AudioManager | null = null;
  private isVerticalDrag: boolean = false;
  private isHorizontalDrag: boolean = false;
  @State coverVisible: Visibility = Visibility.Visible;
  private panOptionBrightAndVolume: PanGestureOptions = new PanGestureOptions({
    direction: PanDirection.Vertical
  });
  private panOptionSeek: PanGestureOptions = new PanGestureOptions({
    direction: PanDirection.Horizontal
  });
  public title: string = "";
  private xComponentId: string = 'xid';
  @State ijkComponentVisible: Visibility = Visibility.Hidden;
  private danmakuShow: boolean = true;
  second: number = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_second"));
  PROGRESS_MAX_VALUE: number = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_process_maxvalue"));
  // 构建StandardGSYVideoModel对象
  public videoModel: StandardGSYVideoModel = new StandardGSYVideoModel();
  @State model: DanmakuView.Model = new DanmakuView.Model();
  private context: DanmakuContext | undefined = undefined;
  private parser: BaseDanmakuParser | undefined = undefined;
  private cacheStufferAdapter: Proxy = new Pro();
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X;
  controller: VideoController = new VideoController();

  /*
   * TODO: 知识点：解析弹幕
   */
  private createParser(): BaseDanmakuParser {
    const parser: BaseDanmakuParser = new DanmakuParser();
    const jsonSource = new JSONSource(sourceData);
    parser.load(jsonSource);
    return parser;
  }
  /*
   * 初始化播放器
   */
  videoInit: (iVideoPlayer: IVideoPlayer, xid: string) => void = (iVideoPlayer: IVideoPlayer, xid: string) => {
    logger.info('VideoInit');
    this.iVideoPlayer = iVideoPlayer;
    this.xComponentId = xid;
    this.iVideoPlayer.setUp(this.videoModel.getUrl(), this.videoModel.getCacheWithPlay());
  }
  /*
   * TODO: 知识点：添加弹幕，设置该条弹幕的相关参数，示例中为定值
   */
  private addDanmaku(isLive: Boolean) {
    if (! this.context) {
      return;
    }
    let danmaku: BaseDanmaku = this.context.mDanmakuFactory.createDanmaku(BaseDanmaku.TYPE_SCROLL_RL);
    danmaku.text = "这是一条弹幕" + SystemClock.uptimeMillis();
    danmaku.padding = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_danmaku_padding"));
    danmaku.priority = 0; // 可能会被各种过滤器过滤并隐藏显示
    danmaku.isLive = isLive.valueOf();
    danmaku.setTime(this.model.getCurrentTime() + getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_range")));
    if (this.parser) {
      danmaku.textSize = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_new_danmaku_fontsize")) * (this.parser.getDisplayer().getDensity() * 0.5);
    }
    danmaku.textColor = 0xffff0000;
    danmaku.textShadowColor = 0xffffffff;
    danmaku.borderColor = 0xff00ff00;
    this.model.addDanmaku(danmaku);
  }
  /*
   * 上侧返回装饰器
   */
  @Builder topTitle() {
    Row() {
      Image($r("app.media.danmaku_player_video_back"))
        .width(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_back_icon_width")))
        .height(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_back_icon_height")))
        .margin({
          top: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_back_icon_margin_top")),
          left: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_back_icon_margin_left"))
        })
        .onClick( () => {
          this.videoModel.ExecuteBackClickListener();
        })
      Text(this.videoModel.getTitle())
        .fontSize(getContext(this)
          .resourceManager
          .getStringSync($r("app.string.danmaku_player_video_title_fontsize")))
        .margin({
          top: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_title_margin_top")),
          left: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_title_margin_left"))
        })
        .fontColor($r("app.color.danmaku_player_title_color"))
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .backgroundColor($r("app.color.danmaku_player_bottom_controls_color"))
    .position({
      x: 0,
      y: 0
    })
    .padding(getContext(this)
      .resourceManager
      .getNumber($r("app.integer.danmaku_player_top_title_padding")))
  }
  /*
   * 播放暂停控制装饰器
   */
  @Builder middleControls() {
    Row() {
      Row() {
        if (this.showPlay) {
          Image($r("app.media.danmaku_player_video_play_pressed"))
            .width(getContext(this)
              .resourceManager
              .getNumber($r("app.integer.danmaku_player_play_icon_width")))
            .height(getContext(this)
              .resourceManager
              .getNumber($r("app.integer.danmaku_player_play_icon_width")))
            .onClick( () => {
              this.videoToPlay();
            })
        }

        Image($r("app.media.danmaku_player_icon_load"))
          .objectFit(ImageFit.Auto)
          .width(getContext(this)
            .resourceManager
            .getNumber($r("app.integer.danmaku_player_play_icon_width")))
          .height(getContext(this)
            .resourceManager
            .getNumber($r("app.integer.danmaku_player_play_icon_width")))
          .visibility(this.loadingVisible)
          .border({
            width: 0
          })
          .borderStyle(BorderStyle.Dashed)
        Stack() {
          if (this.showPause) {
            Image($r("app.media.danmaku_player_video_pause_normal"))
              .width(getContext(this)
                .resourceManager
                .getNumber($r("app.integer.danmaku_player_play_icon_width")))
              .height(getContext(this)
                .resourceManager
                .getNumber($r("app.integer.danmaku_player_play_icon_width")))
              .onClick( () => {
                logger.info('click pause');
                this.videoToPause();
              })
          }
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .align(Alignment.BottomEnd)
      .width(getContext(this)
        .resourceManager
        .getStringSync($r("app.string.danmaku_player_empty_width")))
      .height('100%')

      Row() {
        if (this.curDirection === 1 && this.fullShowLock) {
          Image(this.lock ? $r("app.media.danmaku_player_lock") : $r("app.media.danmaku_player_unlock"))
            .width(getContext(this)
              .resourceManager
              .getNumber($r("app.integer.danmaku_player_lock_icon_width")))
            .height(getContext(this)
              .resourceManager
              .getNumber($r("app.integer.danmaku_player_lock_icon_width")))
            .objectFit(ImageFit.Contain)
            .margin({
              right: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_lock_margin"))
            })
            .onClick( () => {
              this.lock = ! this.lock;
              if (this.lock) {
                this.showBottomUi = false;
                this.fullShowTop = false;
                this.showPlay = false;
                this.showPause = false;
              }
            })
        }
      }
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Center)
      .width(getContext(this)
        .resourceManager
        .getStringSync($r("app.string.danmaku_player_empty_width")))
      .height('100%')
    }
    .width("100%")
    .height('100%')
    .justifyContent(FlexAlign.End)
  }
  /*
   * 暂停播放
   */
  private videoToPause() {
    if (! this.iVideoPlayer) {
      return;
    }
    logger.info('standardGSYVideoPlayer onPause1 click');
    this.iVideoPlayer.pause();
  }
  /*
   * 开始播放
   */
  private videoToPlay() {
    if (! this.iVideoPlayer) {
      return;
    }
    logger.info('standardGSYVideoPlayer onPlay click');
    this.timeCountdown();
    this.loadingVisible = Visibility.Visible;
    this.showPause = false;
    this.showPlay = false;
    this.videoJudgeToPlay();
  }
  /*
   * 判断是否播放逻辑
   */
  private videoJudgeToPlay() {
    logger.info('videoJudgeToPlay');
    if (! this.iVideoPlayer) {
      return;
    }
    if (GlobalContext.getContext().getObject('xid') !== this.iVideoPlayer.xComponentId) {
      logger.info('videoJudgeToPlay1');
      this.iVideoPlayer.play();
      this.iVideoPlayer.firstOrSeek = true;
    } else {
      logger.info('videoJudgeToPlay2');
      if (this.iVideoPlayer.playStatus === PlayStatus.PAUSE) {
        logger.info('standardGSYVideoPlayer videoJudgeToPlay ResumePlay');
        this.iVideoPlayer.resumePlay();
      } else {
        logger.info('standardGSYVideoPlayer videoJudgeToPlay play: ' + this.iVideoPlayer.videoUrl);
        this.iVideoPlayer.play();
      }
    }
  }
  /*
   * 底部装饰器：包括进度条、全屏按钮、发送弹幕按钮、弹幕开关
   */
  @Builder bottomControls() {
    Column() {
      Row() {
        Text(this.currentTime)
          .fontSize('35px')
          .margin({
            left: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_margin"))
          })
          .fontColor($r('app.color.danmaku_player_time_color'))

        Slider({
          value: this.progressValue,
          min: 0,
          max: this.PROGRESS_MAX_VALUE,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width(this.screenIsFull ? getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_slider_length_horizontal")) : getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_slider_length_vertical")) )
          .blockColor(Color.Blue)
          .trackColor(Color.White)
          .selectedColor(Color.Blue)
          .showSteps(true)
          .showTips(true)
          .onChange( (value: number, mode: SliderChangeMode) => {
            clearTimeout(uiTime);
            if (! this.iVideoPlayer) {
              return;
            }
            switch (mode) {case SliderChangeMode.Begin:
              // 通知的回调会到的慢一点，导致下面设置的showPause = true无效
              // 使用isSeek参数去控制pause通知里面的状态操作
                this.iVideoPlayer.pause();
                this.isSeek = true;
                this.stopProgressTask();
                this.showPlay = false;
                this.showPause = true;
                break;
              case SliderChangeMode.End:
                this.showPause = false;
                this.loadingVisible = Visibility.Visible;
                const seekValue = value * (this.iVideoPlayer.getDuration() / 100);
                this.iVideoPlayer.seekTo(seekValue);
                this.model.seekTo(seekValue);
                this.iVideoPlayer.firstOrSeek = true;
                logger.info('slider-->seekValue end: ' + seekValue);
                break;
            }
          })
        Text(this.totalTime)
          .fontSize(getContext(this)
            .resourceManager
            .getStringSync($r("app.string.danmaku_player_total_time_fontsize")))
          .margin({
            right: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_total_time_right_margin"))
          })
          .fontColor($r('app.color.danmaku_player_time_color'))

        Image(this.screenIsFull ? $r("app.media.danmaku_player_video_shrink") : $r("app.media.danmaku_player_video_enlarge"))
          .width(getContext(this)
            .resourceManager
            .getNumber($r("app.integer.danmaku_player_enlarge_icon_width")))
          .height(getContext(this)
            .resourceManager
            .getNumber($r("app.integer.danmaku_player_enlarge_icon_width")))
          .margin({
            right: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_enlarge_icon_margin"))
          })
          .onClick( () => {
            if (this.screenIsFull) {
              this.videoModel.ExecuteBackClickListener();
            } else {
              this.videoModel.ExecuteFullClickListener();
            }
          })
      }
      .width("100%")
      .backgroundColor($r("app.color.danmaku_player_bottom_controls_color"))

      Row() {
        Text("点击发送一条弹幕")
          .backgroundColor($r("app.color.danmaku_player_color_add_danmaku"))
          .width(getContext(this)
            .resourceManager
            .getStringSync($r("app.string.danmaku_player_send_danmaku_width")))
          .textAlign(TextAlign.Center)
          .fontColor($r("app.color.danmaku_player_color_add_text_danmaku"))
          .borderRadius(getContext(this)
            .resourceManager
            .getStringSync($r("app.string.danmaku_player_send_danmaku_border_radius")))
          .onClick( () => {
            this.addDanmaku(false);
          })
          .layoutWeight(1)
          .fontSize(getContext(this)
            .resourceManager
            .getStringSync($r("app.string.danmaku_player_send_danmaku_fontsize")))
          .margin(getContext(this)
            .resourceManager
            .getStringSync($r("app.string.danmaku_player_send_danmaku_margin")))

        Text(this.danmakuText)
          .textAlign(TextAlign.Center)
          .fontColor($r("app.color.danmaku_player_color_show_danmaku"))
          .fontSize(getContext(this)
            .resourceManager
            .getStringSync($r("app.string.danmaku_player_send_danmaku_fontsize")))
        Toggle({
          type: ToggleType.Switch,
          isOn: this.danmakuShow
        })
          .size({
            width: getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_toggle_width")),
            height: getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_toggle_height"))
          })
          .selectedColor($r("app.color.danmaku_player_toggle_color"))
          .switchPointColor($r("app.color.danmaku_player_switchPoint_color"))
          .onChange( (isOn: boolean) => {
            logger.info('Component status:' + isOn)
            if (! isOn) {
              this.model.hide();
              this.danmakuText = '弹幕关';
            } else {
              this.model.setWidth(vp2px(changeWidth));
              this.model.setHeight(vp2px(changeHeight - 1));
              this.model.hide();
              this.model.show();
              this.danmakuText = '弹幕开';
            }
            this.danmakuShow = ! this.danmakuShow;
          })
      }
      .backgroundColor($r("app.color.danmaku_player_bottom_controls_color"))
      .margin({
        bottom: (this.screenIsFull ? 10 : 0)
      })
    }
  }
  /*
   * 声音调节控件
   */
  @Builder volumeUI() {
    Column() {
      Image($r("app.media.danmaku_player_video_volume_icon"))
        .objectFit(ImageFit.Auto)
        .width(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_volume_icon_width")))
        .height(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_volume_icon_height")))
        .alignSelf(ItemAlign.Center)
        .borderStyle(BorderStyle.Dashed)

      Text((this.currentVolumeValue / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_volume_value")) * 100).toFixed(0) + '%')
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_brightness_text_width")))
    }
    .height("80%")
    .visibility(this.showVolumeUi ? Visibility.Visible : Visibility.Hidden)
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
  /*
   * 亮度调节控件
   */
  @Builder brightnessUI() {
    Column() {
      Image($r("app.media.danmaku_player_video_brightness_6_white_36dp"))
        .objectFit(ImageFit.Auto)
        .width(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_volume_icon_width")))
        .height(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_volume_icon_height")))
        .border({
          width: 0
        })
        .alignSelf(ItemAlign.Center)

      Text((this.currentBrightness / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_brightness")) * 100).toFixed(0) + '%')
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_brightness_text_width")))
    }
    .visibility(this.showBrightnessUi ? Visibility.Visible : Visibility.Hidden)
    .width(getContext(this)
      .resourceManager
      .getNumber($r("app.integer.danmaku_player_brightness_UI_width")))
    .alignSelf(ItemAlign.Center)
  }
  /*
   * 进度条控件
   */
  @Builder seekProgressUI() {
    Column() {
      Image(this.seekDirectionRes)
        .objectFit(ImageFit.Auto)
        .width(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_volume_icon_height")))
        .height(getContext(this)
          .resourceManager
          .getNumber($r("app.integer.danmaku_player_volume_icon_height")))
        .border({
          width: 0
        })
        .margin({
          top: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_seek_progress_margin_top"))
        })
        .alignSelf(ItemAlign.Center)

      Row() {
        Text(`${this.seekCurrentTime}/${this.totalTime}`)
      }
      .margin({
        top: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_seek_progress_margin_top"))
      })

      Progress({
        value: this.seekTimePosition,
        total: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_progress_total")),
        type: ProgressType.Linear
      })
        .style({
          strokeWidth: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_progress_stroke_width")),
          enableSmoothEffect: false
        })
        .padding({
          left: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_seek_padding_Left")),
          right: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_seek_padding_right"))
        })
        .margin({
          top: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_seek_margin_top")),
          bottom: getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_seek_margin_bottom"))
        })
        .backgroundColor(Color.White);
    }
    .visibility(this.showSeekProgressUi ? Visibility.Visible : Visibility.Hidden)
    .width(getContext(this)
      .resourceManager
      .getNumber($r("app.integer.danmaku_player_seek_progress_width")))
    .backgroundColor('#55bcbcbc')
    .alignItems(HorizontalAlign.Center)
    .alignSelf(ItemAlign.Center)
  }

  build() {
    Stack({
      alignContent: Alignment.Bottom
    }) {

      // 使用gsyvideoplayer库中的AvVideoPlayer播放器
      AvVideoPlayer({
        videoInit: this.videoInit
      })
      Stack() {
        if (this.videoModel.getCoverImage()) {
          Image(this.videoModel.getCoverImage())
            .width('100%')
            .height('100%')
            .visibility(this.coverVisible)
        }
      }

      Row() {
        this.volumeUI()
        this.seekProgressUI()
        this.brightnessUI()
      }
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .height('100%')

      this.middleControls();
      DanmakuView({
        model: $model
      })
        .backgroundColor(Color.Transparent)
        .position({
          x: 0,
          y: 0
        })
        .enabled(false);
      Stack() {
        if (this.showBottomUi) {
          if (this.curDirection === 1 && this.fullShowTop) {
            this.topTitle();
          }
          this.bottomControls();
        }
      }
    }
    .gesture(GestureGroup(GestureMode.Parallel, TapGesture()
        .onAction( (event: GestureEvent | undefined) => {
          if (event) {
            if (this.lock) {
              this.timeLockCountdown();
              return;
            }
            if (this.loadingVisible === Visibility.Visible) {
              return;
            }
            if (! this.showPlay) {
              this.timeCountdown();
            }
            if (event && event.fingerList && event.fingerList[0]) {
              logger.info('TapGesture event.onActionStart start x: ' + event.fingerList[0].localX +
                " ---event.onActionStart start y: " + event.fingerList[0].localY);
            }
          }
        }),
      /*
       * 绑定声音屏幕亮度拖动手势
       */
      PanGesture(this.panOptionBrightAndVolume)
        .onActionStart( (event: GestureEvent | undefined) => {
          logger.info('Vertical Pan Start');
          if (this.lock || this.isHorizontalDrag) {
            return;
          }
          if (event && event.fingerList && event.fingerList[0]) {
            touchStartX = event.fingerList[0].localX;
            touchStartY = event.fingerList[0].localY;
            logger.info('VerticalPanBrightAndVolume event.onActionStart start x: ' + touchStartX + ' event.onActionStart start y: ' + touchStartY);
          }
        })
        .onActionUpdate( (event: GestureEvent | undefined) => {
          if (this.lock || this.isHorizontalDrag) {
            return;
          }
          this.isVerticalDrag = true;
          if (event && event.fingerList && event.fingerList[0]) {
            const touchY = event.fingerList[0].localY;
            const deltaY = touchY - touchStartY;
            // 移动距离占播放器高度的比例(deltaY取反是因为值的正负与滑动方向相反)
            const percent = (- deltaY / changeHeight);
            const width = changeWidth as number;
            if (touchStartX >= (width / 2)) {
              this.showVolumeUi = true;
              let playerVolumeValue = this.currentVolumeValue;
              playerVolumeValue += this.maxVolumeValue * percent;
              if (playerVolumeValue < 0) {
                playerVolumeValue = 0;
              }
              if (playerVolumeValue > this.maxVolumeValue) {
                playerVolumeValue = this.maxVolumeValue;
              }
              this.currentVolumeValue = playerVolumeValue;
              if (this.audioManager) {
                this.audioManager.setVolume(audio.AudioVolumeType.MEDIA, playerVolumeValue, (err: BusinessError) => {
                  if (err) {
                    logger.info(`Failed to set the volume. ${err}`);
                    return;
                  }
                })
              }
            } else {
              this.showBrightnessUi = true;
              let brightness = this.currentBrightness;
              brightness += getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_brightness")) * percent;
              if (brightness < 0) {
                brightness = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_min_brightness"));
              }
              if (brightness > getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_brightness"))) {
                brightness = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_brightness"));
              }
              const finalValue = brightness / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_brightness"));
              if (windowClass) {
                windowClass.setWindowBrightness(finalValue);
              }
              this.currentBrightness = brightness;
            }
            touchStartY = touchY;
          }
        })
        .onActionEnd( (event: GestureEvent | undefined) => {
          logger.info('Vertical Pan End');
          this.showVolumeUi = false;
          this.showBrightnessUi = false;
          this.isVerticalDrag = false;
        }), PanGesture(this.panOptionSeek)
        .onActionStart((event: GestureEvent | undefined) => {
          logger.info('Horizontal Pan Start');
          if (! this.iVideoPlayer || this.lock) {
            return;
          }
          if (this.loadingVisible === Visibility.Visible) {
            this.isLoadNotSeek = true;
            return;
          }
          if (this.isVerticalDrag) {
            return;
          }
          if (event && event.fingerList && event.fingerList[0]) {
            this.isSeek = true;
            this.iVideoPlayer.pause();
            this.showPlay = false;
            this.showPause = false;
            this.stopProgressTask();
            touchStartX = event.fingerList[0].localX;
            this.seekTimePosition = this.progressValue;
            logger.info('HorizontalSeekProgress event.onActionStart start x: ' + event.fingerList[0].localX + ' event.onActionStart start y: ' + event.fingerList[0].localY);
          }
        })
        .onActionUpdate( (event: GestureEvent | undefined) => {
          if (! this.iVideoPlayer || this.lock || this.isLoadNotSeek || this.isVerticalDrag) {
            return;
          }
          this.isHorizontalDrag = true;
          if (event && event.fingerList && event.fingerList[0]) {
            this.showSeekProgressUi = true;
            const touchX = event.fingerList[0].localX;
            const deltaX = touchX - touchStartX;
            if (deltaX > 0) {
              this.seekDirectionRes = $r("app.media.danmaku_player_video_forward_icon");
            } else {
              this.seekDirectionRes = $r("app.media.danmaku_player_video_backward_icon");
            }
            const position: number = this.iVideoPlayer.getCurrentPosition();
            const totalTimeDuration: number = this.iVideoPlayer.getDuration();
            let seekTimePosition: number = Number(position + (deltaX * totalTimeDuration / changeWidth));
            if (seekTimePosition < 0) {
              seekTimePosition = 0
            }
            if (seekTimePosition > totalTimeDuration) {
              seekTimePosition = totalTimeDuration;
            }
            // 当前调整的进度
            this.seekCurrentTime = this.stringForTime(seekTimePosition);
            // 设置当前进度
            if (totalTimeDuration !== 0) {
              this.seekTimePosition = Number((seekTimePosition / totalTimeDuration).toFixed(2)) * 100;
            }
          }
        })
        .onActionEnd( (event: GestureEvent | undefined) => {
          if (! this.iVideoPlayer) {
            return;
          }
          if (this.isLoadNotSeek) {
            this.isLoadNotSeek = false;
            return;
          }
          if (this.isHorizontalDrag && this.iVideoPlayer) {
            this.progressValue = this.seekTimePosition;
            this.loadingVisible = Visibility.Visible;
            this.showPause = false;
            this.iVideoPlayer.seekTo(this.seekTimePosition * (this.iVideoPlayer.getDuration() / 100));
            this.model.seekTo(this.seekTimePosition * (this.iVideoPlayer.getDuration() / 100));
          }
          this.isHorizontalDrag = false;
          this.showSeekProgressUi = false;
        }), TapGesture({
        count: 2
      })
        .onAction( (event: GestureEvent | undefined) => {
          if (this.lock || this.loadingVisible === Visibility.Visible || ! this.iVideoPlayer) {
            return;
          }
          logger.info('double click start');
          if (this.iVideoPlayer.xComponentId !== GlobalContext.getContext().getObject('xid')) {
            this.videoToPlay();
          } else {
            if (this.iVideoPlayer.isPlaying()) {
              this.videoToPause();
            } else {
              this.videoToPlay();
            }
          }
        })
    ))
    .onAreaChange( (oldValue: Area, newValue: Area) => {
      changeWidth = newValue.width as number;
      changeHeight = newValue.height as number;
      screenWidth = px2vp(display.getDefaultDisplaySync().width);
      screenHeight = px2vp(display.getDefaultDisplaySync().height);
      this.curDirection = this.getDirection();
      this.screenIsFull = (screenHeight - changeHeight) < getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_height_difference"));
      // 如果用户不隐藏状态栏，全屏的时候组件高度与手机的高度差距小于50.就显示上方控制栏
      if (this.curDirection === 1 && this.screenIsFull) {
        this.fullShowTop = true;
        this.fullShowLock = true;
      }
      this.model.setWidth(vp2px(changeWidth));
      this.model.setHeight(vp2px(changeHeight));
      if (this.danmakuShow) {
        this.model.hide();
        this.model.show();
      } else {
        this.model.hide();
      }
    })
    .backgroundColor(Color.Black)
  }

  /*
   * 注册的emitter消息回调，在list列表中，每个item都可以收到，只能通过xid区分当前是哪个才是真正的被点击的item
   * 去做相应的事件处理，不是当前选中的，一律变为初始状态（goInit）
   */
  private emitterInit() {
    emitter.on(videoPlayEvent, (data: emitter.EventData) => {
      if (data && data.data && typeof data.data.xid === 'string') {
        if (this.xComponentId === data.data.xid) {
          this.goPlaying();
        } else {
          this.goInit();
        }
      }
    });
    emitter.on(videoInitEvent, (data: emitter.EventData) => {
      if (data && data.data && typeof data.data.xid === 'string') {
        if (this.xComponentId === data.data.xid) {
          this.goInit();
        }
      }
    });
    emitter.on(videoPauseEvent, (data: emitter.EventData) => {
      if (data && data.data && typeof data.data.xid === 'string') {
        if (this.xComponentId === data.data.xid) {
          if (GlobalContext.getContext().getObject('playType') === PlayerType.SYSTEM_AVPLAYER) {
            if (this.iVideoPlayer && this.iVideoPlayer.isPlaying()) {
              this.goPause();
            }
          } else {
            this.goPause();
          }
        }
      }
    })
  }
  /*
   * 监听播放
   */
  private goPlaying() {
    logger.info('standardGSYVideoPlayer onPlayingListener');
    this.loadingVisible = Visibility.None;
    this.showPlay = false;
    this.showPause = true;
    this.showBottomUi = true;
    this.coverVisible = Visibility.None;
    this.timeCountdown();
    this.stopProgressTask();
    if (! this.isSeek) {
      this.model.resume();
    }
    this.isSeek = false;
    this.startProgressTask();
    this.ijkComponentVisible = Visibility.Visible;
    if (! this.iVideoPlayer) {
      return;
    }
    this.totalTime = this.stringForTime(this.iVideoPlayer.getDuration());
    logger.info('standardGSYVideoPlayer onPlayingListener end.');
  }
  /*
   * 监听初始化
   */
  private goInit() {
    logger.info('standardGSYVideoPlayer onErrorListener');
    clearTimeout(uiTime);
    if (this.iVideoPlayer && GlobalContext.getContext().getObject('playType') === PlayerType.SYSTEM_AVPLAYER) {
      logger.info('PlayerType.SYSTEM_AVPLAYER need to stop');
      this.iVideoPlayer.stop();
    }
    this.loadingVisible = Visibility.None;
    this.coverVisible = Visibility.Visible;
    this.ijkComponentVisible = Visibility.Hidden;
    this.showBottomUi = false;
    this.showPlay = true;
    this.showPause = false;
  }
  /*
   * 监听暂停
   */
  private goPause() {
    logger.info('standardGSYVideoPlayer onPauseListener');
    if (! this.isSeek) {
      this.showPlay = true;
      this.showPause = false;
    }
    this.stopProgressTask();
    clearTimeout(uiTime);
    clearTimeout(uiLockTime);
    this.model.pause();
    this.showBottomUi = true;
  }
  aboutToAppear() {
    logger.info('standardGSYVideoPlayer aboutToAppear');
    this.emitterInit();
    this.curDirection = this.getDirection();
    try {
      let promise = window.getLastWindow(getContext(this));
      promise.then( (data) => {
        windowClass = data;
      }).catch( (error: BusinessError) => {
        logger.info('Failed to obtain the top window. Cause: ' + JSON.stringify(error));
      })
    }
    catch (exception) {
      logger.info('Failed to obtain the top window. Cause: ' + JSON.stringify(exception));
    }
    const groupid = audio.DEFAULT_VOLUME_GROUP_ID;
    this.audioManager = audio.getAudioManager();
    const volumeManager: audio.AudioVolumeManager = this.audioManager.getVolumeManager();
    const audioVolumeGroupManager = volumeManager.getVolumeGroupManagerSync(groupid);
    this.maxVolumeValue = audioVolumeGroupManager.getMaxVolumeSync(audio.AudioVolumeType.MEDIA);
    this.currentVolumeValue = audioVolumeGroupManager.getVolumeSync(audio.AudioVolumeType.MEDIA);
    this.currentBrightness = Number(settings.getValueSync(getContext(this), settings.display.SCREEN_BRIGHTNESS_STATUS, '10'));
    setTimeout( () => {
      this.danmakuInit();
    }, 0)
  }
  /*
   * TODO: 知识点：初始化弹幕，设置弹幕相关参数
   */
  danmakuInit() {
    const maxLinesPair: Map<number, number> = new Map();
    // 滚动弹幕最大显示5行
    maxLinesPair.set(BaseDanmaku.TYPE_SCROLL_RL, getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_max_danmaku_lines")));
    // 设置是否禁止重叠
    const overlappingEnablePair: Map<number, boolean> = new Map();
    overlappingEnablePair.set(BaseDanmaku.TYPE_SCROLL_RL, true);
    overlappingEnablePair.set(BaseDanmaku.TYPE_FIX_TOP, true);
    this.context = DanmakuContext.create();
    const danmakuStyle = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_danmaku_style_example"))
    this.context.setDanmakuStyle(DANMAKU_STYLE_STROKEN, danmakuStyle)
    this.context.setDuplicateMergingEnabled(false)
    this.context.setScrollSpeedFactor(getContext(this).resourceManager.getNumber($r("app.float.danmaku_player_time_scroll_speed_factor")))
    this.context.setScaleTextSize(getContext(this).resourceManager.getNumber($r("app.float.danmaku_player_time_scale_text_size")))
    this.context.setCacheStuffer(new SpannedCacheStuffer(), this.cacheStufferAdapter)
    this.context.setMaximumLines(maxLinesPair).preventOverlapping(overlappingEnablePair)
    this.context.setDanmakuMargin(getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_danmaku_margin")))
    if (this.model === null) {
      return;
    }
    this.parser = this.createParser();
    this.model.setCallback(new Call(this));
    this.model.setOnDanmakuClickListener(new OnDanMaku(this));
    this.model.prepare(this.parser, this.context);
    this.model.showFPS(false);
  }

  aboutToDisappear() {
    logger.info('standardGSYVideoPlayer aboutToDisappear');
    this.emitterOff();
    this.stop();
    this.model.stop();
    this.model.release();
  }

  /*
   * 关闭事件监听
   */
  private emitterOff() {
    emitter.off(1);
    emitter.off(2);
    emitter.off(3);
  }
  /*
   * 获取当前是否全屏播放
   */
  private getDirection(): number {
    return getContext().getApplicationContext().resourceManager.getConfigurationSync().direction;
  }
  /*
   * 继续播放
   */
  resumePlay() {
    logger.info('standardGSYVideoPlayer resumePlay');
    if (! this.iVideoPlayer) {
      return;
    }
    this.timeCountdown();
    this.videoJudgeToPlay();
  }
  /*
   * 停止播放
   */
  stop() {
    logger.info('standardGSYVideoPlayer stop');
    this.stopProgressTask();
    if (! this.iVideoPlayer) {
      return;
    }
    this.iVideoPlayer.stop();
    this.iVideoPlayer.release();
  }
  /*
   * 时间格式化
   */
  private completionNum(num: number): string | number {
    if (num < getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_completion_time"))) {
      return '0' + num;
    } else {
      return num;
    }
  }
  /*
   * 获取时间字符串
   */
  private stringForTime(timeMs: number): string {
    const totalSeconds: number | string = (timeMs / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_ms_unit")));
    let seconds: number | string = totalSeconds % getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_second_unit"));
    let minutes: number | string = (totalSeconds / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_second_unit"))) % getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_minute_unit"));
    let hours: number | string = (totalSeconds / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_second_in_hour")));

    hours = this.completionNum(Math.floor(Math.floor(hours * getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_multiple"))) / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_multiple"))));
    minutes = this.completionNum(Math.floor(Math.floor(minutes * getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_multiple"))) / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_multiple"))));
    seconds = this.completionNum(Math.floor(Math.floor(seconds * getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_multiple"))) / getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_time_multiple"))));

    if (hours > 0) {
      return hours + ":" + minutes + ":" + seconds;
    } else {
      return minutes + ":" + seconds;
    }
  }
  private stopProgressTask() {
    logger.info('stopProgressTask');
    clearInterval(updateProgressTimer);
  }
  private startProgressTask() {
    const that = this;
    updateProgressTimer = setInterval( () => {
      logger.info('startProgressTask');
      if (! that.destroyPage) {
        that.setProgress();
      }
    }, 1000)
  }
  /*
   * 设置进度
   */
  private setProgress() {
    if (! this.iVideoPlayer) {
      return;
    }
    let position = this.iVideoPlayer.getCurrentPosition();
    const duration = this.iVideoPlayer.getDuration();
    let pos = 0;
    if (duration > 0) {
      this.slideEnable = true;
      const curPercent = position / duration;
      pos = curPercent * getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_percent"));
      this.progressValue = pos;
    }
    logger.info('setProgress position: ' + position + ' duration: ' + duration + ' progressValue: ' + pos);
    this.totalTime = this.stringForTime(duration);
    if (position > duration) {
      position = duration;
    }
    this.currentTime = this.stringForTime(position);
  }
  /*
   * 时间倒数
   */
  private timeCountdown() {
    clearTimeout(uiTime);
    this.showPause = true;
    this.showBottomUi = true;
    if (this.curDirection === 1 && this.screenIsFull) {
      this.fullShowLock = true;
      this.fullShowTop = true;
    }
    this.second = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_count_backwards"));
    uiTime = setInterval( () => {
      if (this.second <= 0) {
        clearTimeout(uiTime);
        this.showBottomUi = false;
        this.showPause = false;
        this.fullShowLock = false;
      } else {
        this.second--;
      }
    }, getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_interval_time")))
  }

  private timeLockCountdown() {
    clearTimeout(uiLockTime);
    this.fullShowLock = true;
    this.second = getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_count_backwards"));
    uiLockTime = setInterval( () => {
      if (this.second <= 0) {
        clearTimeout(uiLockTime);
        this.fullShowLock = false;
      } else {
        this.second--;
      }
    }, getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_interval_time")))
  }
}
class Call implements Callback {
  private that: ESObject;

  constructor(that: ESObject) {
    this.that = that;
  }

  public updateTimer(timer: DanmakuTimer): void {
  }

  public drawingFinished(): void {

  }

  public danmakuShown(danmaku: BaseDanmaku): void {
  }

  public prepared(): void {
  }
}

class OnDanMaku implements OnDanmakuClickListener {
  private that: ESObject;

  constructor(that: ESObject) {
    this.that = that;
  }
  /*
   * 弹幕点击逻辑
   */
  onDanmakuClick(danmakus: IDanmakus): boolean {
    console.log('DFM onDanmakuClick: danmakus size:' + danmakus.size());
    const latest: BaseDanmaku = danmakus.last();
    if (null !== latest) {
      console.log('DFM onDanmakuClick: text of latest danmaku:' + latest.text);
      return true;
    }
    return false;
  };
  /*
   * 弹幕长按逻辑
   */
  onDanmakuLongClick(danmakus: IDanmakus): boolean {
    return false;
  };
  /*
   * 点击视窗逻辑
   */
  onViewClick(view: IDanmakuView): boolean {
    this.that.isVisible = true;
    return false;
  };
}

class Pro extends Proxy {
  public prepareDrawing(danmaku: BaseDanmaku, fromWorkerThread: boolean): void {
  }

  public releaseResource(danmaku: BaseDanmaku): void {

    // TODO：知识点：重要:清理含有ImageSpan的text中的一些占用内存的资源 例如drawable
  }
}
;