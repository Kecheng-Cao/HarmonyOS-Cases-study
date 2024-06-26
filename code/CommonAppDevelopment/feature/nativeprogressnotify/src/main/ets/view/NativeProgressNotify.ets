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

import naitiveprogressnotify from 'libnativeprogressnotify.so';
import { NativeProgressNotifyConstants } from '../constants/NativeProgressNotifyConstants';
import { AppRouter } from '@ohos/dynamicsrouter/Index';

@AppRouter({ name: "nativeprogressnotify/NativeProgressNotify" })
@Component
export struct NativeProgressNotify {
  private START_DOWNLOAD: string = "Start Download";
  private DOWNING: string = "Downloading";
  private PROGRESS_START: number = 0;
  private PROGRESS_END: number = 100;
  @State progress: number = 0;
  @State buttonEnabled: boolean = true;
  @State buttonText: string = this.START_DOWNLOAD;

  build() {
    Column({ space: 10 }) {
      // TODO 知识点：进度信息使用Progress组件进行显示
      Progress({ value: this.progress, total: 100, type: ProgressType.Ring })
        .width($r("app.integer.nativeprogressnotify_progress_size"))
        .height($r("app.integer.nativeprogressnotify_progress_size"))
        .animation({ duration: NativeProgressNotifyConstants.PROGRESS_ANIMATION_DURATION, curve: Curve.Ease })
        .style({ strokeWidth: 15 })
      Text(`当前下载进度：${this.progress}%`)
      Button(this.buttonText)
        .onClick(() => {
          // TODO 知识点：调用native的下载方法，并传入回调函数，在回调函数中接收native侧传递过来的进度信息
          naitiveprogressnotify.startDownload((data: number) => {
            if (data === this.PROGRESS_START || data === this.PROGRESS_END) {
              this.buttonEnabled = true;
              this.buttonText = this.START_DOWNLOAD;
            }
            else {
              if (this.buttonEnabled) {
                this.buttonEnabled = false;
              }
              if (this.buttonText === this.START_DOWNLOAD) {
                this.buttonText = this.DOWNING;
              }
            }
            this.progress = data;
            console.info("[NativeProgressNotify]progress:" + this.progress);
          })
        })
        .enabled(this.buttonEnabled)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }
}

