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

import { BaseVideoPlayer, GlobalContext, OrientationUtil, StandardGSYVideoModel, } from '@ohos/gsyvideoplayer';
import Window from '@ohos.window';
import display from '@ohos.display';
import { DanmakuVideoPlayer } from '../model/DanmakuVideoPlayer';
import { AppRouter } from '@ohos/dynamicsrouter/Index';

// 当前屏幕方向
enum Directions { HORIZONTAL, VERTICAL }

// 当前旋转状态，1为垂直，0为水平
let direction = Directions.HORIZONTAL;
// 当前视频宽度
let screenWidth = 0;

@AppRouter({ name: "danmakuplayer/DanmakuVideoDemo" })
@Component
export struct DanmakuVideoDemo {

  // 设置视频高度
  @State screenHeight: string = '30%';
  // 实例化StandardGSYVideoModel实例
  videoModel: StandardGSYVideoModel = new StandardGSYVideoModel();
  /*
   * 从全屏点左上角返回，视频旋转回来同时返回上一页面
   * */
  backClickListener: () => void = () => {
    if (screenWidth < getContext(this)
      .resourceManager
      .getNumber($r("app.integer.danmaku_player_screen_width_standard")) && direction === Directions.VERTICAL) {
      this.changeOrientation();
    }
  }
  /*
   * 点击全屏按钮，旋转
   * */
  fullClickListener: () => void = () => {
    this.changeOrientation();
  }
  // 视频来源
  private videoUrl = getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_video_url"));

  build() {
    Row() {
      DanmakuVideoPlayer({
        videoModel: this.videoModel
      })
        .height(this.screenHeight)
    }
    .width('100%')
    .height('100%')
  }

  async aboutToAppear() {
    this.videoModel.setUrl(this.videoUrl, false); //设置播放源
    this.videoModel.setTitle("这是测试视频的标题"); //设置标题
    this.videoModel.setBackClickListener(this.backClickListener); //设置退出全屏的回调
    this.videoModel.setFullClickListener(this.fullClickListener); //设置进入全屏的回调
    this.videoModel.setCoverImage($r('app.media.danmaku_player_cover')); //设置封面图
    direction = this.getDirection() === 0 ? Directions.HORIZONTAL : Directions.VERTICAL; //获取当前方向
    screenWidth = px2vp(display.getDefaultDisplaySync().width); //获取视频宽度
  }

  /*
   * 页面消失停止播放
   * */
  aboutToDisappear() {
    const player: BaseVideoPlayer = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.stop();
    }
    if (direction === Directions.VERTICAL) {
      this.changeOrientation();
    }
  }

  /*
   * 页面展示时重新播放
   * */
  onPageShow() {
    const player: BaseVideoPlayer = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (! player) {
      return;
    }
    player.resumePlay();
  }

  /*
   * 页面隐藏时播放暂停
   * */
  onPageHide() {
    const player: BaseVideoPlayer = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (! player) {
      return;
    }
    player.pause();
  }

  /*
   * 如果是全屏状态，侧滑退出时就旋转，否则暂停播放器，退出页面
   * */
  onBackPress() {
    const player: BaseVideoPlayer = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.stop();
    }
    if (screenWidth > getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_screen_width_standard")) && direction === Directions.VERTICAL) {
      this.changeOrientation();
    }
  }

  /*
   * 获取当前旋转状态
   * */
  private getDirection(): number {
    return getContext().getApplicationContext().resourceManager.getConfigurationSync().direction;
  }

  /*
   * 旋转方法
   * */
  private changeOrientation() {
    if (screenWidth > getContext(this).resourceManager.getNumber($r("app.integer.danmaku_player_screen_width_standard"))) {
      if (direction === Directions.HORIZONTAL) {
        this.screenHeight = getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_screen_height_horizontal"));
        direction = Directions.VERTICAL;
      } else {
        this.screenHeight = getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_screen_height_vertical"));
        direction = Directions.HORIZONTAL;
      }
    } else {
      if (direction === Directions.HORIZONTAL) {
        OrientationUtil.changeOrientation(getContext(), Window.Orientation.LANDSCAPE_INVERTED);
        this.screenHeight = getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_screen_height_horizontal"));
        direction = Directions.VERTICAL;
      } else {
        OrientationUtil.changeOrientation(getContext(), Window.Orientation.PORTRAIT);
        this.screenHeight = getContext(this).resourceManager.getStringSync($r("app.string.danmaku_player_screen_height_vertical"));
        direction = Directions.HORIZONTAL;
      }
    }
  }
}
