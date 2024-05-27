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

import { ListInfo } from '../model/ListInfo';
import { MEMO_DATA } from '../model/MockData';
import { ListExchangeCtrl } from '../model/ListExchangeCtrl';
import { AppRouter } from '@ohos/dynamicsrouter/Index';

const ITEM_HEIGHT: number = 50; // 列表项高度

/**
 * 首先创建一个数组modifier来添加自定义属性对象，根据组合手势GestureGroup来控制自定义属性的值并通过attributeModifier绑定自定义属性对象来动态加载属性。
 * 然后swipeAction属性绑定删除组件，左滑显示此喊出组件，点击实现列表项的删除。
 */
@AppRouter({ name: "listexchange/ListExchangeView" })
@Component
export struct ListExchangeView {
  @Provide appInfoList: ListInfo[] = MEMO_DATA; // 列表数据
  @Provide currentData: ListInfo = new ListInfo();
  @State listExchangeCtrl: ListExchangeCtrl<ListInfo> = new ListExchangeCtrl<ListInfo>(this.appInfoList); // 初始化列表排序管理
  @StorageLink('isLongPress') isLongPress: boolean = false; // 初始化长按状态

  /**
   * 删除按钮
   * @param item
   */
  @Builder
  deleteBuilder(item: ListInfo) {
    Image($r("app.media.list_exchange_icon_delete"))
      .width($r('app.integer.list_exchange_icon_size'))
      .height($r('app.integer.list_exchange_icon_size'))
      .objectFit(ImageFit.Cover)
      .margin({ right: $r('app.integer.list_exchange_delete_icon_margin_right') })
      .interpolation(ImageInterpolation.High)// 抗锯齿
      .onClick(() => {
        this.listExchangeCtrl.deleteItem(item);
      })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text($r('app.string.list_exchange_deduction_sort'))
          .textAlign(TextAlign.Start)
        Blank()
        Text($r('app.string.list_exchange_custom_sort'))
      }
      .backgroundColor(Color.White)
      .border({
        radius: {
          topLeft: $r('app.string.ohos_id_corner_radius_default_l'),
          topRight: $r('app.string.ohos_id_corner_radius_default_l')
        }
      })
      .padding({
        left: $r('app.string.ohos_id_card_padding_start'),
        right: $r('app.string.ohos_id_card_padding_start')
      })
      .width('100%')
      .height($r('app.integer.list_exchange_title_height'))

      // 列表区域
      List() {
        ForEach(this.appInfoList, (item: ListInfo) => {
          ListItem() {
            DeductionView({ listItemInfo: item })
          }
          .zIndex(this.currentData === item ? 2 : 1) // 层级属性
          .swipeAction({ end: this.deleteBuilder(item) }) // 用于设置ListItem的划出组件
          .transition(TransitionEffect.OPACITY)
          .attributeModifier(this.listExchangeCtrl.getModifier(item)) //动态设置组件的属性方法， 参数为属性修改器
          .gesture(
            // 以下组合手势为顺序识别，当长按手势事件未正常触发时，则不会出发拖动手势事件
            GestureGroup(GestureMode.Sequence,
              // 长按
              LongPressGesture()
                .onAction((event: GestureEvent) => {
                  this.currentData = item;
                  this.isLongPress = true;
                  this.listExchangeCtrl.onLongPress(item);
                }),
              // 拖动
              PanGesture()
                .onActionUpdate((event: GestureEvent) => {
                  this.listExchangeCtrl.onMove(item, event.offsetY);
                })
                .onActionEnd((event: GestureEvent) => {
                  this.listExchangeCtrl.onDrop(item);
                })
            ).onCancel(() => {
              if (!this.isLongPress) {
                return;
              }
              this.listExchangeCtrl.onDrop(item);
            })
          )
        }, (item: ListInfo) => JSON.stringify(item))
      }
      .divider({ strokeWidth: '1px', color: 0xeaf0ef })
      .scrollBar(BarState.Off)
      .border({
        radius: {
          bottomLeft: $r('app.string.ohos_id_corner_radius_default_l'),
          bottomRight: $r('app.string.ohos_id_corner_radius_default_l')
        }
      })
      .backgroundColor(Color.White)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.list_exchange_background_color'))
    .padding({ left: $r('app.string.ohos_id_card_padding_start'), right: $r('app.string.ohos_id_card_padding_start') })
  }
}

/**
 * ListItem自定义组件
 */
@Component
struct DeductionView {
  @ObjectLink listItemInfo: ListInfo;
  @Consume appInfoList: ListInfo[];
  @Consume currentData: ListInfo;

  build() {
    Row() {
      Image(this.listItemInfo.icon)
        .width($r('app.integer.list_exchange_icon_size'))
        .height($r('app.integer.list_exchange_icon_size'))
        .draggable(false) // TODO：知识点：保持默认值true时，图片有默认拖拽效果，会影响Grid子组件拖拽判断，所以修改为false
      Text(this.listItemInfo.name)
        .margin({ left: $r('app.string.ohos_id_elements_margin_vertical_l') })
      Blank()
      Image($r("app.media.list_exchange_ic_public_drawer"))
        .width($r('app.integer.list_exchange_icon_size'))
        .height($r('app.integer.list_exchange_icon_size'))
        .objectFit(ImageFit.Cover)
        .draggable(false) // TODO：知识点：保持默认值true时，图片有默认拖拽效果，会影响Grid子组件拖拽判断，所以修改为false
    }
    .width('100%')
    .height(ITEM_HEIGHT)
    .backgroundColor(Color.White)
    .padding({
      left: $r('app.string.ohos_id_card_padding_start'),
      right: $r('app.string.ohos_id_card_padding_start')
    })
  }
}