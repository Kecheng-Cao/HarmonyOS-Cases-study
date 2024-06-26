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
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import { TabsWaterFlowView } from '../view/TabsWaterFlowView';
import { DesignCattleView } from '../view/DesignCattleView';
import { CONFIGURATION } from '../common/Constants';

@AppRouter({ name: "dragtoswitchpictures/DragToSwitchPictures" })
@Component
export struct DragToSwitchPictures {
  build() {
    Scroll() {
      Column() {
        // AI设计视图
        DesignCattleView();
        // 瀑布流视图
        TabsWaterFlowView();
      }
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.dragtoswitchpictures_home_page_backgroundcolor'))
    }
    .width($r('app.string.dragtoswitchpictures_full_size'))
    .height($r('app.string.dragtoswitchpictures_full_size'))
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
    .zIndex(CONFIGURATION.ZINDEX1)
  }
}