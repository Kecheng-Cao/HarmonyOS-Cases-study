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
import { SwiperComponent } from '@ohos/swipercomponent/Index';
import { SearchComponent } from '@ohos/searchcomponent/Index';
import { DynamicsRouter } from '@ohos/dynamicsRouter/Index';
import { FunctionalScenes, SceneModuleInfo } from '@ohos/functionalscenes/Index';
import { waterFlowData } from '../../data/WaterFlowData';
import { HelperView } from '../../view/HelperView';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct EntryView {
  // TODO:需求：路由栈信息，待后续封装路由管理HAR
  @State listData: SceneModuleInfo[] = waterFlowData;
  @Provide('fullScreenSize') fullScreenSize: string = '50%';
  @State windowWidth: number = 0;

  aboutToAppear(): void {
    // 存储初始数据用于搜索筛选
    AppStorage.setOrCreate('listData', this.listData)
    window.getLastWindow(getContext(this), (err: BusinessError, data: window.Window) => {
      const rect: window.Rect = data.getWindowProperties().windowRect;
      this.windowWidth = px2vp(rect.width);
    })
  }

  @Builder
  pageMap(name: string, param: ESObject) {
    NavDestination() {
      // 根据模块名，获取WrappedBuilder对象，通过builder接口创建页面
      DynamicsRouter.getBuilder(name).builder(param);
    }
    // 按需将NavDestinationMode配置为DIALOG类型，此时背景默认透明
    .mode(name === "multimodaltransion/HalfModalWindow" ?
    NavDestinationMode.DIALOG : NavDestinationMode.STANDARD)
    .hideTitleBar(true)
  }

  build() {
    Stack() {
      Navigation(DynamicsRouter.navPathStack) {
        // 使用规避手段增加外层嵌套，待系统问题修复后去除
        Column() {
          Scroll() {
            Column() {
              // 首页搜索组件
              SearchComponent()
              // 首页轮播图组件
              SwiperComponent()
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
      .backgroundColor($r('app.color.main_background_color'))
      .hideTitleBar(true)
      .navBarWidth(this.fullScreenSize)
      .navDestination(this.pageMap)
      .mode(NavigationMode.Split) // 视频全屏案例横屏时使用NavigationMode.Split模式显示。

      // 帮助功能：在每个案例的右下角添加“帮助”功能
      HelperView()
    }
    .alignContent(Alignment.BottomEnd)
    .height('100%')
    .backgroundColor($r('app.color.main_background_color'))
  }
}