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
import { SearchComponent } from '@ohos/searchcomponent/Index';
import { DynamicsRouter } from '@ohos/dynamicsrouter/Index';
import { FunctionalScenes, SceneModuleInfo } from '@ohos/functionalscenes/Index';
import { GlobalStateDialog, GlobalStateDialogManager } from '@ohos/base/Index';
import { waterFlowData } from '../data/WaterFlowData';
import { HelperView } from '../view/HelperView';
import { HomePageSwiper } from '../view/HomePageSwiper';
import { display, promptAction } from '@kit.ArkUI';

@Entry
@Component
struct EntryView {
  // Navigation路由栈,控制页面跳转
  @Provide('pageStack') pageStack: NavPathStack = DynamicsRouter.navPathStack;
  // TODO:需求：路由栈信息，待后续封装路由管理HAR
  @State listData: SceneModuleInfo[] = waterFlowData;
  @Provide('isFullScreen') isFullScreen: boolean = false;
  @State navigationMode: number = NavigationMode.Stack;
  @State curFoldStatus: number = 0;

  private readonly miniPlayerAnimationPage: string ='miniplayeranimation/MiniPlayerAnimation';
  private readonly loginPage: string = 'multimodaltransion/HalfModalWindow';
  private screenW: number = px2vp(display.getDefaultDisplaySync().width);
  private readonly DEVICESIZE: number = 600; // 依据Navigation的mode属性说明，如使用Auto，窗口宽度>=600vp时，采用Split模式显示；窗口宽度<600vp时，采用Stack模式显示。
  private isSecondPressBack: boolean = false; // 在侧滑退出应用时，用于判断是否第二次滑动
  private readonly EXIT_TOAST_DURATION: number = 1800; // 侧滑拦截toast提示时长
  private readonly EXIT_PRESS_BACK_DURATION: number = 1000; // 两次侧滑事件间隔时长

  aboutToAppear(): void {
    // 存储初始数据用于搜索筛选
    AppStorage.setOrCreate('listData', this.listData);
    // 初始化登录状态
    AppStorage.setOrCreate("login", false);
    GlobalStateDialogManager.getGlobalStateDialogNodeController().setUIContext(this.getUIContext());
    if (display.isFoldable()) {
      this.regDisplayListener();
    } else {
      if (this.screenW >= this.DEVICESIZE) {
        this.navigationMode = NavigationMode.Split;
      } else {
        this.navigationMode = NavigationMode.Stack;
      }
    }
  }

  // 侧滑返回拦截功能：用于首页侧滑返回时，需在1秒内侧滑两次才能退出应用
  onBackPress(): boolean {
    if (this.isSecondPressBack) {
      return false;
    } else {
      this.isSecondPressBack = true;
      setTimeout(() => {
        this.isSecondPressBack = false;
      }, this.EXIT_PRESS_BACK_DURATION);
      promptAction.showToast({
        message: $r('app.string.app_exit_toast_msg'),
        duration: this.EXIT_TOAST_DURATION
      });
      return true;
    }
  }

  @Builder
  pageMap(name: string, param: ESObject) {
    if (this.loginPage === name) {
      NavDestination() {
        // 根据模块名，获取WrappedBuilder对象，通过builder接口创建页面
        DynamicsRouter.getBuilder(name).builder(param);
      }
      // 登录页是半模态，需要背景透明，设置为DIALOG
      .mode(NavDestinationMode.DIALOG)
      .hideTitleBar(true)
    } else if (this.miniPlayerAnimationPage === name) {
      // 音乐播放转场一镜到底案例需要全屏显示
      NavDestination() {
        // 根据模块名，获取WrappedBuilder对象，通过builder接口创建页面
        DynamicsRouter.getBuilder(name).builder(param);
      }
      .backgroundColor($r('app.color.main_background_color'))
      .hideTitleBar(true)
    } else {
      if (this.getModuleTitle(name) !== null) {
        // 显示标题
        NavDestination() {
          this.navDestinationTitle(name);
          // 根据模块名，获取WrappedBuilder对象，通过builder接口创建页面
          DynamicsRouter.getBuilder(name).builder(param);
        }
        .padding({
          bottom: $r('app.integer.nav_destination_padding_bottom')
        })
        .backgroundColor($r('app.color.main_background_color'))
        .hideTitleBar(true)
      } else {
        // 不显示标题
        NavDestination() {
          // 根据模块名，获取WrappedBuilder对象，通过builder接口创建页面
          DynamicsRouter.getBuilder(name).builder(param);
        }
        .padding({
          bottom: $r('app.integer.nav_destination_padding_bottom_no_title')
        })
        .backgroundColor($r('app.color.main_background_color'))
        .hideTitleBar(true)
      }
    }
  }

  @Builder
  navDestinationTitle(name: string) {
    Row() {
      Row() {
        Row() {
          Column() {
            Image($r('app.media.ic_public_arrow_left'))
              .width($r('app.integer.nav_destination_title_image_size'))
          }
          .onClick(() => {
            DynamicsRouter.popAppRouter();
          })
          .justifyContent(FlexAlign.Center)
          .width($r('app.integer.nav_destination_title_image_background_size'))
          .height($r('app.integer.nav_destination_title_image_background_size'))
          .borderRadius($r('app.integer.nav_destination_title_image_border_radius'))
          .backgroundColor($r('app.color.nav_destination_title_image_background_color'))

          Text(this.getModuleTitle(name))
            .fontWeight(FontWeight.Bold)
            .fontSize($r('app.integer.nav_destination_title_text_size'))
            .margin({ left: $r('app.integer.nav_destination_title_text_margin') })
        }

        HelperView({ name: name })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width($r('app.integer.nav_destination_title_width'))
      .height($r('app.integer.nav_destination_title_height'))
    }
    .backgroundColor($r('app.color.main_background_color'))
    .margin({ bottom: $r('app.integer.nav_destination_title_bottom') })
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  /**
   * 获取当前页面name
   * @param name 模块路由信息
   * @returns
   */
  getModuleTitle(name: string): null | string {
    let moduleName = name.split('/')[1];
    for (let index = 0; index < waterFlowData.length; index++) {
      if (waterFlowData[index].appUri.split('/')[0] === moduleName) {
        return waterFlowData[index].name;
      }
    }
    return null;
  }

  /**
   * 注册屏幕状态监听
   * @returns {void}
   */
  regDisplayListener(): void {
    this.changeNavigationMode(display.getFoldStatus());
    display.on('foldStatusChange', async (curFoldStatus: display.FoldStatus) => {
      // 同一个状态重复触发不做处理
      if (this.curFoldStatus === curFoldStatus) {
        return;
      }
      // 缓存当前折叠状态
      this.curFoldStatus = curFoldStatus;
      this.changeNavigationMode(this.curFoldStatus);
    })
  }

  // 更改NavigationMode
  changeNavigationMode(status: number): void {
    if (status === display.FoldStatus.FOLD_STATUS_FOLDED) {
      this.navigationMode = NavigationMode.Stack;
    } else {
      this.navigationMode = NavigationMode.Split;
    }
  }

  build() {
    Stack() {
      Navigation(this.pageStack) {
        // 使用规避手段增加外层嵌套，待系统问题修复后去除
        Column() {
          // 首页搜索组件
          SearchComponent()
          Scroll() {
            Column() {
              // 首页轮播图组件
              HomePageSwiper()
              // 首页列表组件
              FunctionalScenes({ listData: this.listData })
            }
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Vertical)
        }
      }
      .padding({ bottom: 1 })
      .backgroundColor($r('app.color.main_background_color'))
      .hideTitleBar(true)
      .navBarWidth($r('app.string.entry_half_size'))
      .hideNavBar(this.isFullScreen)
      .navDestination(this.pageMap)
      .mode(this.navigationMode)

      // 全局状态保留能力弹窗
      GlobalStateDialog()
    }
    .alignContent(Alignment.BottomEnd)
    .height('100%')
    .backgroundColor($r('app.color.main_background_color'))
  }
}