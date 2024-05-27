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

import { curves, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import { logger } from '@ohos/base';
import { Constants } from '../common/Constants';

/**
 * 实现步骤：
 *  1. 悬浮窗组件使用Stack嵌套video布局，使用属性position绝对定位使组件悬浮。
 *  2. 在悬浮窗组件的aboutToAppear中获取应用窗口尺寸，使用窗口宽度减去悬浮窗宽度和右边距让悬浮窗初始靠右。
 *  3. 使用getWindowAvoidArea获取顶部状态栏高度和底部导航栏高度。
 *  4. 悬浮窗组件添加onTouchEvent回调，在手指按下时保存触摸点与悬浮窗左上角的偏移量offsetX和offsetY，用于移动时悬浮窗位置的计算。
 *  5. 手指移动时，获取触摸点相对于应用窗口左上角的X和Y坐标，通过计算设置悬浮窗的position坐标实现拖拽，使用默认参数的弹性跟手动画曲线curves.responsiveSpringMotion结合animateTo实现跟手动画效果。
 *  6. 手指抬起时，通过判断悬浮窗中心在水平方向位于窗口中心的左侧或右侧设置悬浮窗靠左或靠右，如果悬浮窗超出内容区上下边界，则将悬浮窗设置在边界位置，使用curves.springMotion弹性动画曲线实现吸附边界时的弹性动画效果。
 */

const TAG = 'FloatWindow';

@AppRouter({ name: "floatwindow/FloatWindowMainPage" })
@Component
export struct FloatWindowMainPage {
  private scroller: Scroller = new Scroller();

  @Builder
  server(text: Resource) {
    Text() {
      ImageSpan($r('app.media.float_window_service'))
        .objectFit(ImageFit.Contain)
        .width($r('app.integer.float_window_icon_width'))
        .aspectRatio(Constants.ASPECT_RATIO)
        .margin({ right: $r('app.string.ohos_id_elements_margin_vertical_m') })
      Span(text)
    }
    .fontSize($r('app.string.ohos_id_text_size_body2'))
    .fontColor($r('app.color.ohos_id_color_foreground'))
  }

  @Builder
  addressService() {
    // 配送地址
    Row() {
      Text($r('app.string.float_window_send_to'))
        .fontSize($r('app.string.ohos_id_text_size_body2'))
        .fontColor($r('app.color.ohos_id_color_foreground'))
        .fontWeight(FontWeight.Bold)
        .margin({ right: $r('app.string.ohos_id_elements_margin_vertical_l') })
      Image($r('app.media.float_window_local'))
        .width($r('app.integer.float_window_icon_width'))
        .aspectRatio(Constants.ASPECT_RATIO)
        .margin({ right: $r('app.string.ohos_id_elements_margin_vertical_m') })
      Text($r('app.string.float_window_address'))
        .fontSize($r('app.string.ohos_id_text_size_body2'))
        .fontColor($r('app.color.ohos_id_color_foreground'))
        .opacity($r('app.string.float_window_opacity'))
    }
    .alignItems(VerticalAlign.Top)
    .width($r('app.string.float_window_full_size'))
    .margin({ top: $r('app.string.ohos_id_card_margin_start') })
    .padding({
      top: $r('app.string.ohos_id_card_padding_start'),
      left: $r('app.string.ohos_id_card_padding_start'),
      right: $r('app.string.ohos_id_card_padding_start')
    })
    .backgroundColor($r('app.color.ohos_id_color_background'))
    .borderRadius({
      topLeft: $r('app.string.ohos_id_corner_radius_default_l'),
      topRight: $r('app.string.ohos_id_corner_radius_default_l')
    })

    // 服务
    Row() {
      Text($r('app.string.float_window_service'))
        .fontSize($r('app.string.ohos_id_text_size_body2'))
        .fontColor($r('app.color.ohos_id_color_foreground'))
        .fontWeight(FontWeight.Bold)
        .margin({ right: $r('app.string.ohos_id_elements_margin_vertical_l') })
      Column({ space: Constants.PRODUCT_SERVICE_SPACE }) {
        this.server($r('app.string.float_window_free_hipping'))
        this.server($r('app.string.float_window_store_delivery'))
        this.server($r('app.string.float_window_return_goods'))
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width($r('app.string.float_window_full_size'))
    .alignItems(VerticalAlign.Top)
    .padding($r('app.string.ohos_id_card_padding_start'))
    .backgroundColor($r('app.color.ohos_id_color_background'))
    .borderRadius($r('app.string.ohos_id_corner_radius_default_l'))
    .borderRadius({
      bottomLeft: $r('app.string.ohos_id_corner_radius_default_l'),
      bottomRight: $r('app.string.ohos_id_corner_radius_default_l')
    })
  }

  @Builder
  choice() {
    Row() {
      Text($r('app.string.float_window_selected'))
        .fontSize($r('app.string.ohos_id_text_size_body2'))
        .fontColor($r('app.color.ohos_id_color_foreground'))
      Text($r('app.string.float_window_select_configuration'))
        .fontSize($r('app.string.ohos_id_text_size_body2'))
        .padding({ left: $r('app.integer.float_window_selected_padding') })
        .layoutWeight(Constants.LAYOUT_WEIGHT)
    }
    .width($r('app.string.float_window_full_size'))
    .padding($r('app.string.ohos_id_card_padding_start'))
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Top)
    .backgroundColor($r('app.color.ohos_id_color_background'))
    .borderRadius($r('app.string.ohos_id_corner_radius_default_l'))
    .margin({ top: $r('app.string.ohos_id_card_margin_start') })
  }

  @Builder
  information() {
    Column() {
      Text($r('app.string.float_window_price'))
        .fontSize($r('app.string.ohos_id_text_size_headline'))
        .fontColor($r('app.color.ohos_id_color_warning'))
        .fontWeight(FontWeight.Bold)

      Text($r('app.string.float_window_product'))
        .fontSize($r('app.string.ohos_id_text_size_body1'))
        .margin({ top: $r('app.string.ohos_id_elements_margin_vertical_m') })
    }
    .padding($r('app.string.ohos_id_card_padding_start'))
    .width($r('app.string.float_window_full_size'))
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.ohos_id_color_background'))
    .borderRadius($r('app.string.ohos_id_corner_radius_default_l'))
    .margin({ top: $r('app.string.ohos_id_card_margin_start') })
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 商品信息展示组件
      Scroll(this.scroller) {
        Column() {
          Image($r('app.media.float_window_product'))
            .objectFit(ImageFit.Contain)
            .backgroundColor($r('app.color.ohos_id_color_background'))
            .width($r('app.string.float_window_full_size'))
            .borderRadius($r('app.string.ohos_id_corner_radius_default_l'))
          // 商品信息
          this.information()
          // 商品型号
          this.choice()
          // 配送地址和服务
          this.addressService()
        }
      }
      .width($r('app.string.float_window_full_size'))
      .height($r('app.string.float_window_full_size'))
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .padding(Constants.PAGE_PADDING)

      // 悬浮窗
      FloatWindowView()
    }
    .width($r('app.string.float_window_full_size'))
    .height($r('app.string.float_window_full_size'))
    .backgroundColor($r('app.color.ohos_id_color_sub_background'))
  }
}

@Component
struct FloatWindowView {
  // 悬浮窗左上角相对于父容器左上角的偏移位置
  @State positionX: number = 0;
  @State positionY: number = Constants.INIT_POSITION_Y;
  // 触摸点相对于悬浮窗左上角的偏移位置
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  // 设备顶部状态栏高度
  @State topRectHeight: number = 0;
  // 设备底部导航栏高度
  @State bottomRectHeight: number = 0;
  // 应用窗口尺寸
  private windowRectWidth: number = 0;
  private windowRectHeight: number = 0;
  private videoController: VideoController = new VideoController();

  aboutToAppear(): void {
    const type = window.AvoidAreaType.TYPE_SYSTEM;
    window.getLastWindow(getContext(), (err: BusinessError, windowClass: window.Window) => {
      if (err.code) {
        logger.error(TAG, 'Failed to obtain the top window. Cause: ' + JSON.stringify(err));
        return;
      }
      try {
        const properties = windowClass.getWindowProperties();
        // 获取应用窗口宽高
        this.windowRectWidth = px2vp(properties.windowRect.width);
        this.windowRectHeight = px2vp(properties.windowRect.height)
        // 窗口宽度减去悬浮窗宽度和右边距让悬浮窗初始靠右
        this.positionX = this.windowRectWidth - Constants.FLOAT_WINDOW_WIDTH - Constants.PAGE_PADDING;
      } catch (exception) {
        logger.error(TAG, 'Failed to obtain the window properties. Cause: ' + JSON.stringify(exception));
      }
      try {
        const avoidArea = windowClass.getWindowAvoidArea(type);
        // 获取顶部状态栏高度
        this.topRectHeight = px2vp(avoidArea.topRect.height);
        // 获取底部导航栏高度
        this.bottomRectHeight = px2vp(avoidArea.bottomRect.height);
      } catch (exception) {
        logger.error(TAG, 'Failed to obtain the area. Cause:' + JSON.stringify(exception));
      }
      logger.info(TAG, 'Succeeded in obtaining the top window. Data: ' + JSON.stringify(windowClass));
    });
  }

  /**
   * 触摸回调，悬浮窗跟手和贴边动画
   */
  onTouchEvent(event: TouchEvent): void {
    switch (event.type) {
      case TouchType.Down: {
        this.offsetX = event.touches[0].x;
        this.offsetY = event.touches[0].y;
        break;
      }
      case TouchType.Move: {
        const windowX: number = event.touches[0].windowX;
        const windowY: number = event.touches[0].windowY;
        // TODO：知识点：跟手动画，推荐使用默认参数的弹性跟手动画曲线curves.responsiveSpringMotion。
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
          this.positionX = windowX - this.offsetX - Constants.PAGE_PADDING;
          this.positionY = windowY - this.offsetY - this.topRectHeight - Constants.PAGE_PADDING; // 减去手指位置到悬浮窗左上角的y轴偏移和设备顶部状态栏高度
        })
        break;
      }
      case TouchType.Up: {
        // TODO：知识点：通过判断悬浮窗在窗口中的位置，设置悬浮窗贴边，使用curves.springMotion()弹性动画曲线，可以实现阻尼动画效果
        animateTo({ curve: curves.springMotion() }, () => {
          // 判断悬浮窗中心在水平方向是否超过窗口宽度的一半，根据结果设置靠左或靠右
          if (this.positionX > (this.windowRectWidth - Constants.FLOAT_WINDOW_WIDTH) / 2) {
            this.positionX = this.windowRectWidth - Constants.FLOAT_WINDOW_WIDTH - Constants.PAGE_PADDING; // 悬浮窗靠右
          } else {
            this.positionX = Constants.PAGE_PADDING; // 悬浮窗靠左
          }
          // 页面高度
          const pageHeight: number = this.windowRectHeight - this.topRectHeight - this.bottomRectHeight;
          // 判断悬浮窗是否超出内容区上下边界，根据结果将悬浮窗设置在边界位置
          if (this.positionY < Constants.PAGE_PADDING) {
            this.positionY = Constants.PAGE_PADDING;
          } else if (this.positionY > pageHeight - Constants.FLOAT_WINDOW_HEIGHT - Constants.PAGE_PADDING) {
            this.positionY = pageHeight - Constants.FLOAT_WINDOW_HEIGHT - Constants.PAGE_PADDING;
          }
        })
        break;
      }
      default: {
        break;
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Video({
        src: $rawfile('float_window_video.mp4'),
        controller: this.videoController
      })
        .controls(false)
        .autoPlay(true)
        .loop(true)
        .muted(true)
        .width($r('app.string.float_window_full_size'))
        .onClick(() => {
          this.videoController.requestFullscreen(true);
        })
        .borderRadius($r('app.integer.float_window_content_border_radius'))
      Text($r('app.string.float_window_live_text'))
        .width($r('app.string.float_window_full_size'))
        .fontSize($r('app.string.ohos_id_text_size_body1'))
        .fontColor($r('app.color.ohos_id_color_background'))
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.ohos_id_color_list_alert'))
        .borderRadius({
          bottomLeft: $r('app.integer.float_window_content_border_radius'),
          bottomRight: $r('app.integer.float_window_content_border_radius')
        })
    }
    .clip(true)
    .border({
      width: $r('app.integer.float_window_border_width'),
      color: $r('app.color.ohos_id_color_background')
    })
    .borderRadius($r('app.string.ohos_id_corner_radius_default_l'))
    .width(Constants.FLOAT_WINDOW_WIDTH)
    .height(Constants.FLOAT_WINDOW_HEIGHT)
    .backgroundColor($r('app.color.ohos_id_color_foreground'))
    .position({ x: this.positionX, y: this.positionY })
    .onTouch((event: TouchEvent) => {
      this.onTouchEvent(event);
    })
  }
}