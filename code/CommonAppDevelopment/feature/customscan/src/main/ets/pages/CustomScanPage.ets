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

import { display } from '@kit.ArkUI';
import { Callback } from '@ohos.base';
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import CustomScanViewModel from '../viewmodel/CustomScanViewModel';
import CustomScanCameraComp from '../components/CustomScanCameraComp';
import CustomScanCtrlComp from '../components/CustomScanCtrlComp';
import CommonConstants from '../common/constants/CommonConstants';

/**
 * 二维码扫描页面
 * 实现步骤：
 * 1.用户授权相机后初始化页面内子组件
 * 2.进二维码扫描路由时监控折叠屏状态变化，实时重新初始化扫码服务和相机流尺寸
 */
@AppRouter({ name: "customscan/CustomScanPage" })
@Component
export struct CustomScanPage {
  // 自定义扫码vm实例
  private customScanVM: CustomScanViewModel = CustomScanViewModel.getInstance();
  // 授权标志
  @State isGranted: boolean = false;
  // 通知Navigation组件隐藏导航栏
  @Consume('isFullScreen') isFullScreen: boolean;
  @State curFoldStatus: display.FoldStatus = 0;
  private screenW: number = px2vp(display.getDefaultDisplaySync().width);
  private readonly DEVICESIZE: number = 600; // 依据Navigation的mode属性说明，如使用Auto，窗口宽度>=600vp时，采用Split模式显示；窗口宽度<600vp时，采用Stack模式显示。
  private callBack:Callback<display.FoldStatus> = async (curFoldStatus: display.FoldStatus) =>
  {
    // 同一个状态重复触发不做处理
    if (this.curFoldStatus === curFoldStatus) {
      return;
    }
    // 缓存当前折叠状态
    this.curFoldStatus = curFoldStatus;
    this.hideNavBar(this.curFoldStatus);
  }

  async aboutToAppear() {
    // 进入窗口沉浸式
    this.customScanVM.setMainWindowImmersive(true);
    if (display.isFoldable()) {
      this.regDisplayListener();
    } else {
      if (this.screenW >= this.DEVICESIZE) {
        this.navigationAnimation(true);
      } else {
        this.navigationAnimation(false);
      }
    }
    // TODO：知识点：检测应用是否已被用户允许使用相机权限，未授权向申请授权
    const isGranted = await this.customScanVM.reqCameraPermission();
    if (!isGranted) {
      // 用户未授权，给出提示
      this.customScanVM.showPermissionDenied();
    }
    this.isGranted = isGranted;
  }

  /**
   * 注册屏幕状态监听
   * @returns {void}
   */
  regDisplayListener(): void {
    this.hideNavBar(display.getFoldStatus());
    display.on('foldStatusChange', this.callBack);
  }

  hideNavBar(status: number): void {
    if (status === display.FoldStatus.FOLD_STATUS_FOLDED) {
      this.navigationAnimation(false);
    } else {
      this.navigationAnimation(true);
    }
  }

  // 隐藏navigation导航栏，设置为全屏。
  navigationAnimation(isFullScreen: boolean): void {
    animateTo({
      duration: CommonConstants.SCAN_DURATION,
      curve: Curve.EaseInOut,
    }, () => {
      this.isFullScreen = isFullScreen;
    })
  }

  aboutToDisappear() {
    // 退出窗口沉浸式
    this.customScanVM.setMainWindowImmersive(false);
    this.navigationAnimation(false);
    if (display.isFoldable()) {
      display.off('foldStatusChange', this.callBack);
    }
  }

  build() {
    Stack() {
      if (this.isGranted) {
        CustomScanCameraComp()
        CustomScanCtrlComp({callBack:this.callBack})
      }
    }
    .alignContent(Alignment.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}