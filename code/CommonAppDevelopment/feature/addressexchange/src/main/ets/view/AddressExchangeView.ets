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
import curves from '@ohos.curves';
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import { promptAction } from '@kit.ArkUI';

/**
 * 实现步骤：
 * 1. 创建左右两边Text组件显示地址。设置初始偏移量以及文本对齐方式。
 * 2. 点击中间的图标时，修改是否切换的状态变量值和通过animateTo修改偏移量的值，来实现动态更新左右两边地址的显示，完成动画效果。
 */

@AppRouter({ name: "addressexchange/AddressExchangeView" })
@Component
export struct AddressExchangeView {
  // 旋转角度
  @State rotateAngle: number = 0;
  // 偏移量
  @State translateX: number = 0;
  // 是否已交换
  @State swap: boolean = false;
  // 整体内容区宽度
  private rowWidth: number = 300;
  // 单次偏移距离
  private distance: number = this.rowWidth * 0.6;
  // 内容相隔距离
  private columnSpace: number = 16;
  // 初始化偏移距离
  private zeroTranslate: number = 0;
  // 单次旋转180°
  private rotateAddAngle: number = 180;
  // toast弹窗时长
  private toastDuration: number = 2000;

  build() {
    // 地址交换
    Column({ space: this.columnSpace }) {
      Row() {
        Text($r('app.string.address_exchange_address_left'))
          .translate({ x: this.translateX })
          .width($r('app.string.address_exchange_address_width'))
          .textAlign(this.swap ? TextAlign.End : TextAlign.Start)
          .onClick(() => {
            promptAction.showToast({
              message: $r('app.string.address_exchange_other_function'),
              duration: this.toastDuration
            });
          })

        Stack() {
          Image($r('app.media.address_exchange_airplane'))
            .size({
              height: $r('app.integer.address_exchange_airplane_size'),
              width: $r('app.integer.address_exchange_airplane_size')
            })
          Image($r('app.media.address_exchange_recycle'))
            .size({
              height: $r('app.integer.address_exchange_recycle_size'),
              width: $r('app.integer.address_exchange_recycle_size')
            })
            .rotate({ angle: this.rotateAngle })
            .animation({
              curve: Curve.EaseOut,
              playMode: PlayMode.Normal,
            })
        }
        .width($r('app.string.address_exchange_image_width'))
        .onClick(() => {
          this.swap = !this.swap
          // TODO 知识点：动画效果，修改偏移量，修改旋转角度，实现效果
          animateTo({ curve: curves.springMotion() }, () => {
            if (this.swap) {
              this.translateX = this.distance;
            } else {
              this.translateX = this.zeroTranslate;
            }
          })
          this.rotateAngle += this.rotateAddAngle;
        })

        Text($r('app.string.address_exchange_address_right'))
          .translate({ x: -this.translateX })
          .width($r('app.string.address_exchange_address_width'))
          .textAlign(this.swap ? TextAlign.Start : TextAlign.End)
          .onClick(() => {
            promptAction.showToast({
              message: $r('app.string.address_exchange_other_function'),
              duration: this.toastDuration
            });
          })
      }
      .width(this.rowWidth)
      .height($r('app.integer.address_exchange_content_height'))

      Row({ space: this.columnSpace }) {
        Text($r('app.string.address_exchange_date'))
          .fontSize($r('app.string.ohos_id_text_size_headline'))
          .fontWeight(FontWeight.Medium)
          .height($r('app.integer.address_exchange_date_height'))
        Text($r('app.string.address_exchange_week'))
          .height($r('app.integer.address_exchange_date_height'))
      }
      .width(this.rowWidth)
      .onClick(() => {
        promptAction.showToast({
          message: $r('app.string.address_exchange_other_function'),
          duration: this.toastDuration
        });
      })

      Button($r('app.string.address_exchange_search_ticket'))
        .fontColor(Color.White)
        .height($r('app.integer.address_exchange_button_height'))
        .width(this.rowWidth)
        .onClick(() => {
          promptAction.showToast({
            message: $r('app.string.address_exchange_other_function'),
            duration: this.toastDuration
          });
        })
    }
    .backgroundColor($r('app.color.ohos_id_color_sub_background'))
    .borderRadius($r('app.string.ohos_id_corner_radius_default_m'))
    .width($r('app.string.address_exchange_content_size'))
    .height($r('app.integer.address_exchange_total_height'))
    .margin($r('app.string.ohos_id_card_margin_start'))
  }
}
