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

import { SceneModuleInfo } from '@ohos/functionalscenes';
import { DynamicsRouter } from '@ohos/dynamicsrouter/Index';

@Component
export struct HomePageSwiper {
  @Consume('pageStack') pageStack: NavPathStack;
  @State currentIndex: number = 0;
  @State swiperData: SceneModuleInfo[] = [
    new SceneModuleInfo($r("app.media.swipercomponent_mp_chart"), 'MpChart图表实现案例', "barchart/BarChartPage", '三方库', 1),
    new SceneModuleInfo($r("app.media.swipercomponent_lottie"), 'Lottie动画', "lottieview/LottieView", '三方库', 1),
    new SceneModuleInfo($r("app.media.swipercomponent_component_tack"), '组件堆叠', "componentstack/ComponentStack", 'UI'),
  ];

  build() {
    Swiper() {
      ForEach(this.swiperData, (dataItem: SceneModuleInfo) => {
        Image(dataItem.imageSrc)
          .width($r('app.integer.swiper_width'))
          .height($r('app.integer.swiper_height'))
          .objectFit(ImageFit.Cover)
          .borderRadius($r('app.integer.swiper_border_radius'))
          .onClick(() => {
            // 点击轮播图Item时，根据点击的模块信息，将页面放入路由栈
            DynamicsRouter.pushUri(dataItem.appUri, dataItem.param);
          })
      })
    }
    .autoPlay(true)
    .margin({ top: $r('app.integer.swiper_margin_top'), bottom: $r('app.integer.swiper_margin_bottom') })
  }
}
