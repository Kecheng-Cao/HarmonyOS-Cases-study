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

import { promptAction, Scale } from '@kit.ArkUI';
import { logger } from '@ohos/base';
import { FloorView } from './FloorView'; // 二楼视图、动画、时长
import { UserInformation } from '../model/UserInformation';

const ICON_NUM_IN_USER: number = 6; // 示例中用户信息数目
const EXPAND_FLOOR_INTERVAL_TIME: number = 50; // 展开二楼的时间
const FLING_FACTOR: number = 1.5; // 阻尼系数，可根据不同设备摩擦系数设置
const OFFSET_STEP: number = 30; // 用于计算下拉距离不够自动收起的常量
const TRIGGER_HEIGHT: number = 200; // 触发动画高度或者动效消失高度
const MINI_SHOW_DISTANCE: number = 3; // 动效最小展示距离

@Component
export struct SecondFloor {
  @Provide startPackUpFloor: boolean = false; // 监听当处于二楼状态点击标题时的状态
  @State topRectHeight: number | undefined = AppStorage.get('statusHeight'); // 顶部系统导航栏高度
  @State bottomRectHeight: number | undefined = AppStorage.get('bottomHeight'); // 底部系统导航栏高度
  @State floorHeight: number = 760; // floor高度
  @State expandFloorTriggerDistance: number = 200; // 展开二楼拉拽触发距离
  @State packUpFloorTriggerDistance: number = 150; // 收起二楼拉拽触发距离
  @State dragging: boolean = false; // 是否在拉拽
  @State offsetY: number = -this.floorHeight; // Y轴偏移量，下拉的距离（初始值为二楼高度的负值）
  private lastY: number = 0; // Y轴的值
  @State immediatelyScale: Scale = { x: 0, y: 0 }; // 设置动效组件缩放，初始值为0
  @State roundSize: number = 0; // 动效中圆的大小
  @State onShow: boolean = false; // 是否展示动效
  @State animationXLeft: number = 60; // 左圆平移距离，初始值为60使得左圆与中心圆重合
  @State animationXRight: number = -60; // 右圆平移距离，初始值为-60使得右圆与中心圆重合
  @State screenHeight: number | undefined = AppStorage.get("screenHeight"); // 当前窗口高度
  @State miniAppScale: Scale = { x: 0, y: 0 }; // 设置小程序缩放，初始值为0
  @State userInfoList: UserInformation[] = []; // 用户信息数组

  aboutToAppear() {
    // 将用户信息图片、名称、最后发送信息推入空数组
    for (let index = 1; index <= ICON_NUM_IN_USER; index++) {
      this.userInfoList.push(new UserInformation($r(`app.media.second_floor_ic_public_user${index}`), `User${index}`, `lastMsg${index}`));
    }
  }

  build() {
    Column() {
      // 开启沉浸式后上导航
      if (Math.abs(this.offsetY) <= this.floorHeight && Math.abs(this.offsetY) >= this.floorHeight - TRIGGER_HEIGHT) {
        Blank()
          .width($r('app.string.second_floor_full_size'))
          .height(px2vp(this.topRectHeight) * (1 - (this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT))
          .backgroundColor($r('app.color.second_floor_navigation_bar_color'))
      }
      Column() {
        // 二楼页面
        FloorView({
          floorHeight: this.floorHeight,
          mainPageOffsetY: $offsetY,
          packUpFloorTriggerDistance: this.packUpFloorTriggerDistance,
          immediatelyScale: $immediatelyScale,
          animationXLeft: $animationXLeft,
          animationXRight: $animationXRight,
          roundSize: $roundSize,
          onShow: $onShow,
          miniAppScale: $miniAppScale
        })
        // 三点动效布局
        if (this.onShow) {
          Row() {
            // this.floorHeight - Math.abs(this.offsetY)为下拉距离，下拉距离超过MINI_SHOW_DISTANCE（动效最小展示距离）且小于TRIGGER_HEIGHT（触发动画高度或者动效消失高度）展示动画
            if ((this.floorHeight - Math.abs(this.offsetY)) > MINI_SHOW_DISTANCE && (this.floorHeight - Math.abs(this.offsetY)) <= TRIGGER_HEIGHT) {
              Row() {
                // 向左偏移圆
                Blank()
                  .width(this.roundSize)
                  .height(this.roundSize)
                  .borderRadius($r('app.integer.second_floor_circular_border_radius'))
                  .scale(this.immediatelyScale)
                  .backgroundColor($r('app.color.second_floor_circular_color'))
                  .translate({ x: this.animationXLeft })
                  .opacity(((this.floorHeight - Math.abs(this.offsetY)) / this.floorHeight)) // 使用下拉距离除以二楼高度获得圆的透明度
                // 中心加载点
                Blank()
                  .width(this.roundSize)
                  .height(this.roundSize)
                  .borderRadius($r('app.integer.second_floor_circular_border_radius'))
                  .margin({
                    left: $r('app.integer.second_floor_center_circular_margin'),
                    right: $r('app.integer.second_floor_center_circular_margin')
                  })
                  .backgroundColor($r('app.color.second_floor_circular_color'))
                  .opacity(((this.floorHeight - Math.abs(this.offsetY)) / this.floorHeight))
                // 向右偏移圆
                Blank()
                  .width(this.roundSize)
                  .height(this.roundSize)
                  .borderRadius($r('app.integer.second_floor_circular_border_radius'))
                  .scale(this.immediatelyScale)
                  .backgroundColor($r('app.color.second_floor_circular_color'))
                  .translate({ x: this.animationXRight })
                  .opacity(((this.floorHeight - Math.abs(this.offsetY)) / this.floorHeight))
              }
            }
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .width($r('app.string.second_floor_full_size'))
          .height(this.floorHeight - Math.abs(this.offsetY))
          .backgroundColor($r('app.color.second_floor_screen_color'))
          // 当动效高度超过200的时候，背景色透明度开始改变，Math.abs(this.offsetY)除以(this.floorHeight - TRIGGER_HEIGHT)获取到的是超过动效高度的百分比可以来显示透明度，由于透明度小于0.6后蒙层效果不明显，所以当值小于0.6时固定为0.6
          .opacity(Math.abs(this.offsetY) / (this.floorHeight - TRIGGER_HEIGHT) >= 0.6 || Math.abs(this.offsetY) / (this.floorHeight - TRIGGER_HEIGHT) === 0 ? Math.abs(this.offsetY) / (this.floorHeight - TRIGGER_HEIGHT) : 0.6)
        }

        // 一楼页面
        Column() {
          this.mainPageBuilder();
        }
        .width($r('app.string.second_floor_full_size'))
        .layoutWeight(1)
        .position({
          x: 0,
          y: this.offsetY + this.floorHeight
        })
      }
      .width($r('app.string.second_floor_full_size'))
      .height($r('app.string.second_floor_full_size'))
      .clip(true) // TODO：知识点：按指定的形状对当前组件进行裁剪，参数为boolean类型时，设置是否按照父容器边缘轮廓进行裁剪。
      .onTouch((event) => {
        switch (event.type) {
          case TouchType.Down:
            this.onTouchDown(event);
            break;
          case TouchType.Move:
            this.onTouchMove(event);
            break;
          case TouchType.Up:
          case TouchType.Cancel:
            this.onTouchUp();
            break;
        }
        event.stopPropagation(); // 阻止冒泡
      })

      // 下导航键
      if (this.screenHeight && this.bottomRectHeight) {
        Blank()
          .width($r('app.string.second_floor_full_size'))
          .height(px2vp(this.bottomRectHeight))
          .position({ x: 0, y: px2vp(this.screenHeight - this.bottomRectHeight) }) // 使用屏幕高度减去下导航键高度获得Y轴的值
          .backgroundColor(Color.White)
      }
    }
  }

  /**
   * 按下事件、获取按下事件的位置
   * @param event 触屏事件
   */
  private onTouchDown(event: TouchEvent): void {
    this.lastY = event.touches[0].windowY;
    this.onShow = true;
    this.dragging = false;
  }

  /**
   * 触摸抬起或取消触摸事件
   */
  private onTouchUp(): void {
    if (this.dragging) {
      // 二楼自身的高度减去向下Y轴的位移的绝对值大于触发值进入二楼，否则回弹
      if ((this.floorHeight - Math.abs(this.offsetY)) > this.expandFloorTriggerDistance) {
        // 进入二楼
        this.expandSecondFloor();
      } else {
        // 未达到触发距离回弹
        this.scrollByTop();
      }
    }
  }

  /**
   * 滑动事件
   * @param event 触屏事件
   */
  private onTouchMove(event: TouchEvent): void {
    this.onShow = true;
    let currentY = event.touches[0].windowY;
    // onTouch事件中本次Y轴大小减去上一次获取的Y轴大小，为负值则是向上滑动，为正值则是向下滑动
    let deltaY = currentY - this.lastY;
    if (this.dragging) {
      // TODO：知识点：确定是滑动状态后，进入动效界面，this.floorHeight减去this.offsetY的绝对值为滑动距离，在大于60(60指的是中心圆加载范围)和隐藏动效高度范围对左右圆的平移距离和和缩放进行设置
      if (((this.floorHeight - Math.abs(this.offsetY)) <= TRIGGER_HEIGHT) && (this.floorHeight - Math.abs(this.offsetY)) >= 60) {
        this.roundSize = 20;
        this.animationXLeft = 60;
        this.animationXRight = -60;
        // (this.floorHeight - Math.abs(this.offsetY))除以TRIGGER_HEIGHT 获取下拉百分比，使用百分比乘以60（60是根据圆最开始的位置获取）获得每次平移的距离，用来达到左右圆的X轴最后为0
        this.animationXLeft = this.animationXLeft - ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT) * 60;
        this.animationXRight = this.animationXRight + ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT) * 60;
        // 使用移动距离除以动效消失的高度，用来获取左右圆的缩放比例
        this.immediatelyScale = {
          x: ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT),
          y: ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT)
        };
      } else if (((this.floorHeight - Math.abs(this.offsetY)) < 60)) {
        // TODO：知识点：在中心圆加载的时候，左右圆是不显示的，因此将左右圆缩放比例大小调整为0，使用移动高度除以60（中心圆加载高度）再乘以20（圆的最终大小），以此来达到中心圆的加载效果
        this.roundSize = 0;
        this.roundSize = 20 * ((this.floorHeight - Math.abs(this.offsetY)) / 60);
        this.immediatelyScale = {
          x: 0,
          y: 0
        };
      } else {
        // 设置当二楼回收显示一楼时，三个圆属于加载成功状态
        this.roundSize = 20;
        this.immediatelyScale = { x: 1, y: 1 };
        this.animationXLeft = 0;
        this.animationXRight = 0;
      }

      // 在Y轴为达到0的之前使用1 - (Math.abs(this.offsetY) / this.floorHeight)来控制二楼页面缩放
      this.miniAppScale = {
        x: 1 - (Math.abs(this.offsetY) / this.floorHeight),
        y: 1 - (Math.abs(this.offsetY) / this.floorHeight)
      };

      // 拖动过程中向上拖动
      if (deltaY < 0) {
        if (this.offsetY > -this.floorHeight) {
          // 往回拖动一楼漏出高度
          this.offsetY = this.offsetY + px2vp(deltaY) * FLING_FACTOR;
        } else {
          this.offsetY = -this.floorHeight;
        }
      } else {
        // 向下拖动二楼漏出高度
        this.offsetY = this.offsetY + px2vp(deltaY) * FLING_FACTOR;
      }
      this.lastY = currentY;
    } else {
      if (deltaY > 0) {
        this.dragging = true;
        this.lastY = currentY;
      }
    }
  }

  /**
   * 展开二楼时添加一个动效、加计时器将二楼坐标轴改为0
   */
  private expandSecondFloor(): void {
    if (this.offsetY < 0) {
      animateTo({
        duration: 500,
        curve: Curve.EaseOut,
        iterations: 1,
        playMode: PlayMode.Normal,
        finishCallbackType: FinishCallbackType.REMOVED,
        onFinish: () => {
          this.onShow = false;
        }
      }, () => {
        this.offsetY = 0;
        // 在Y轴为达到0的时候缩放比例为正常显示
        this.miniAppScale = { x: 1, y: 1 };
      });
    }
  }

  /**
   * 回弹方法
   */
  private scrollByTop(): void {
    // 坐标位置不等于二楼高度进入判断
    if (this.offsetY !== -this.floorHeight) {
      let intervalId = setInterval(() => {
        if (this.offsetY <= -this.floorHeight) {
          this.offsetY = -this.floorHeight;
          clearInterval(intervalId);
        } else {
          // 相当于回弹的速度
          this.offsetY = ((this.offsetY - OFFSET_STEP) < -this.floorHeight) ? (-this.floorHeight) : (this.offsetY - OFFSET_STEP);
        }
        // TODO：知识点：this.floorHeight减去this.offsetY的绝对值为滑动距离，在大于60(60指的是中心圆加载范围)和隐藏动效高度范围对左右圆的平移距离和和缩放进行设置
        if (((this.floorHeight - Math.abs(this.offsetY)) <= TRIGGER_HEIGHT) && (this.floorHeight - Math.abs(this.offsetY)) >= 60) {
          this.animationXLeft = 60;
          this.animationXRight = -60;
          // this.totalY / TRIGGER_HEIGHT 获取下拉百分比
          this.animationXLeft = this.animationXLeft - ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT) * 60;
          this.animationXRight = this.animationXRight + ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT) * 60;
          this.immediatelyScale = {
            x: ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT),
            y: ((this.floorHeight - Math.abs(this.offsetY)) / TRIGGER_HEIGHT)
          };
        } else if (((this.floorHeight - Math.abs(this.offsetY)) < 60)) {
          // TODO：知识点：在中心圆加载的时候，左右圆是不显示的，因此将左右圆缩放比例大小调整为0，使用移动高度除以60（中心圆加载高度）再乘以20（圆的最终大小），以此来达到中心圆的加载效果
          this.roundSize = 0;
          this.roundSize = 20 * ((this.floorHeight - Math.abs(this.offsetY)) / 60);
          this.immediatelyScale = {
            x: 0,
            y: 0
          };
        } else {
          // 设置当二楼回收显示一楼时，三个圆属于加载成功状态
          this.roundSize = 20;
          this.immediatelyScale = { x: 1, y: 1 };
          this.animationXLeft = 0;
          this.animationXRight = 0;
        }
      }, EXPAND_FLOOR_INTERVAL_TIME);
    } else {
      logger.debug("scrollByTop(): already scrolled to top edge")
    }
  }

  /**
   * 首页视图
   */
  @Builder
  mainPageBuilder() {
    // 二楼底层/一楼标题
    this.mainPageTitle();
    // 聊天列表
    this.userInfo();
  }

  /**
   * 二楼底层/一楼标题
   */
  @Builder
  mainPageTitle() {
    Row() {
      Blank()
        .width($r('app.integer.second_floor_main_page_title_blank_width'))
      Text($r('app.string.second_floor_main_page_title'))
        .fontSize($r('app.integer.second_floor_main_page_title_blank_font_size'))
      // 搜索、查询
      this.mainPageSearch();
    }
    .backgroundColor("#EDEDED")
    .width($r('app.string.second_floor_full_size'))
    .height($r('app.integer.second_floor_main_page_title_height'))
    .justifyContent(FlexAlign.SpaceEvenly)
    .onClick(event => {
      // 点击触发startPackUp方法，收起二楼页面
      this.startPackUpFloor = true;
    })
  }

  /**
   * 搜索、查询
   */
  @Builder
  mainPageSearch() {
    Row() {
      Image($r('app.media.second_floor_search_main'))
        .width($r('app.integer.second_floor_main_page_search_image'))
        .height($r('app.integer.second_floor_main_page_search_image'))
        .margin({ right: $r('app.integer.second_floor_main_page_search_image_margin_right') })
        .onClick(() => {
          // 调用Toast显示提示:此样式仅为案例展示
          promptAction.showToast({ message: $r("app.string.second_floor_toast_tips") });
        })
      Image($r('app.media.second_floor_type_select'))
        .width($r('app.integer.second_floor_main_page_search_image'))
        .height($r('app.integer.second_floor_main_page_search_image'))
        .onClick(() => {
          // 调用Toast显示提示:此样式仅为案例展示
          promptAction.showToast({ message: $r("app.string.second_floor_toast_tips") });
        })
    }
    .height($r('app.integer.second_floor_main_page_search_row_height'))
    .width($r('app.integer.second_floor_main_page_search_row_width'))
    .margin({ left: $r('app.integer.second_floor_main_page_search_margin_left') })
  }

  /**
   * 聊天列表
   */
  @Builder
  userInfo() {
    Column() {
      List() {
        // 性能关注点：本例首次进入页面就需要全部加载且数据不大就不需要使用LazyForeach懒加载。如果是数据过大超过可视区域就需要使用LazyForEach进行数据懒加载，List布局时会根据可视区域按需创建组件，并在组件滑出可视区域外时销毁以降低内存占用。
        ForEach(this.userInfoList, (item: UserInformation) => {
          // 用户信息
          this.chatView(item);
        })
      }
      .width($r('app.string.second_floor_full_size'))
      .height($r('app.string.second_floor_full_size'))
      .padding({
        left: $r('app.integer.second_floor_userinfo_list_padding'),
        right: $r('app.integer.second_floor_userinfo_list_padding')
      })
      .edgeEffect(EdgeEffect.None)
    }
  }

  /**
   * 用户信息
   */
  @Builder
  chatView(userinfo: UserInformation) {
    Row() {
      Column() {
        Stack({ alignContent: Alignment.TopEnd }) {
          // 用户头像
          Image(userinfo.icon)
            .width($r('app.integer.second_floor_chat_view_image'))
            .height($r('app.integer.second_floor_chat_view_image'))
            .margin({ left: $r('app.integer.second_floor_chat_view_image_margin') })
            .borderRadius($r('app.integer.second_floor_chat_view_image_border_radius'))
            .autoResize(false)
        }
      }
      .layoutWeight(1)
      .padding({ right: $r('app.integer.second_floor_chat_view_image_padding') })

      // 对方用户名
      Column() {
        Text(userinfo.name)
          .fontColor(Color.Black)
          .fontSize($r('app.integer.second_floor_chat_view_userinfo_name_font_size'))
          .margin({ bottom: $r('app.integer.second_floor_chat_view_userinfo_name_margin') })
        Text(userinfo.lastMsg)
          .fontColor($r('app.color.second_floor_chat_view_userinfo_last_msg_font_color'))
          .maxLines(1)
          .fontSize($r('app.integer.second_floor_chat_view_userinfo_last_msg_font_size'))
          .margin({ top: $r('app.integer.second_floor_chat_view_userinfo_last_msg_margin') })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(5)
    }
    .width($r('app.string.second_floor_full_size'))
    .height($r('app.integer.second_floor_chat_view_height'))
    .padding({
      left: $r('app.integer.second_floor_chat_view_padding_left'),
      right: $r('app.integer.second_floor_chat_view_padding'),
      top: $r('app.integer.second_floor_chat_view_padding'),
      bottom: $r('app.integer.second_floor_chat_view_padding')
    })
    .border({ width: { bottom: 1.5 }, color: $r('app.color.second_floor_chat_view_border_color') })
    .onClick(() => {
      // 调用Toast显示提示:此样式仅为案例展示
      promptAction.showToast({ message: $r("app.string.second_floor_toast_tips") });
    })
  }
}
