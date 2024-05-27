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

@Component
struct WaterMarkView {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .onReady(() => {
        // TODO:知识点:通过canvas绘制水印
        this.context.fillStyle = '#10000000';
        this.context.font = '16vp';
        this.context.textAlign = 'center';
        this.context.textBaseline = 'middle';
        for (let i = 0; i < this.context.width / 120; i++) {
          this.context.translate(120, 0);
          let j = 0;
          for (; j < this.context.height / 120; j++) {
            this.context.rotate(-Math.PI / 180 * 30);
            this.context.fillText('水印水印', -60, -60);
            this.context.rotate(Math.PI / 180 * 30);
            this.context.translate(0, 120);
          }
          this.context.translate(0, -120 * j);
        }
      })
  }
}

@Builder
export function createWaterMarkView() {
  WaterMarkView()
    .hitTestBehavior(HitTestMode.None) // 必须设置其触摸测试为None或者transparent，否则正常组件无法响应时间
}