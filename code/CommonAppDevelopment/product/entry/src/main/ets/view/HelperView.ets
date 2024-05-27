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
import { PanPositionModel } from '../model/PanPositionModel';
import { connection } from '@kit.NetworkKit';
import { promptAction, window } from '@kit.ArkUI';
import { clearHelperWeb, createNWeb, getNWeb, stopWebLoad } from '../common/utils/NWebUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { HelperConstants } from '../constants/HelperConstants';
import { waterFlowData } from '../data/WaterFlowData';

@Component
export struct HelperView {
  windowSize: window.Size = { width: 0, height: 0 };
  @State isShowReadMe: boolean = false;
  @Consume('pageStack') @Watch("onPageStackChange") pageStack: NavPathStack;
  @State @Watch("onHelperUrlChange") helperUrl: string = HelperConstants.HELPER_URL_HOME;
  @State helperIconOffset: PanPositionModel = new PanPositionModel();
  private name: string = '';

  onPageStackChange(): void {
    if (!this.pageStack.size()) {
      this.helperUrl = HelperConstants.HELPER_URL_HOME;
    } else {
      const size: number = this.pageStack.size();
      let moduleName: string = this.pageStack.getAllPathName()[size-1].split('/')[1];
      this.helperUrl = HelperConstants.HELPER_URL_PROTOTYPE.replace("{placeholder}", moduleName);
    }
  }

  onHelperUrlChange(): void {
    stopWebLoad();
    createNWeb(this.helperUrl, this.getUIContext());
    console.debug(`[onHelperUrlChange]${this.helperUrl}`);
  }

  aboutToAppear(): void {
    createNWeb(this.helperUrl, this.getUIContext());
    window.getLastWindow(getContext(this), (err: BusinessError, data: window.Window) => {
      let rect: window.Rect = data.getWindowProperties().windowRect;
      this.windowSize.width = px2vp(rect.width);
      this.windowSize.height = px2vp(rect.height);
    })
  }

  aboutToDisappear(): void {
    clearHelperWeb();
  }

  build() {
    Column() {
      Image($r("app.media.ic_public_help"))
        .width($r('app.integer.helper_help_image_size'))
        .backgroundColor($r('app.color.nav_destination_title_image_background_color'))
        .offset({ x: this.helperIconOffset.currentX, y: this.helperIconOffset.currentY })
        .gesture(
          GestureGroup(
            GestureMode.Exclusive,
            TapGesture({ fingers: 1, count: 1 })
              .onAction(() => {
                if (connection.hasDefaultNetSync()) {
                  this.isShowReadMe = !this.isShowReadMe;
                } else {
                  promptAction.showToast({ message: $r("app.string.no_network_prompt_msg") });
                }
              }),
            PanGesture({ fingers: 1 })
              .onActionUpdate((event: GestureEvent) => {
                const ICON_SIZE: number = 54;
                this.helperIconOffset.currentX = event.offsetX + this.helperIconOffset.lastX;
                this.helperIconOffset.currentY = event.offsetY + this.helperIconOffset.lastY;

                // 限制icon的偏移：不能超出屏幕
                if (this.helperIconOffset.currentX > 0) {
                  this.helperIconOffset.currentX = 0;
                } else if (this.helperIconOffset.currentX < -1 * (this.windowSize.width - ICON_SIZE)) {
                  this.helperIconOffset.currentX = -1 * (this.windowSize.width - ICON_SIZE);
                }
                if (this.helperIconOffset.currentY > 0) {
                  this.helperIconOffset.currentY = 0;
                } else if (this.helperIconOffset.currentY < -1 * (this.windowSize.height - ICON_SIZE * 2)) {
                  this.helperIconOffset.currentY = -1 * (this.windowSize.height - ICON_SIZE * 2);
                }
              })
              .onActionEnd((event: GestureEvent) => {
                this.helperIconOffset.stash();
              })
          )
        )
        .margin($r("sys.float.ohos_id_card_margin_start"))
        .bindSheet($$this.isShowReadMe, this.buildReadMeSheet(), {
          detents: [SheetSize.MEDIUM, SheetSize.LARGE],
          showClose: false,
          dragBar: true,
          backgroundColor: $r("app.color.helper_bindsheet_bgc"),
          preferType: SheetType.CENTER,
          enableOutsideInteractive: true,
        })
    }
    .width($r('app.integer.helper_width'))
    .backgroundColor('#E5E7E9')
    .borderRadius($r('app.integer.helper_border_radius'))
  }

  getModuleTitle(name: string): null | string {
    let moduleName = name.split('/')[1];
    for (let index = 0; index < waterFlowData.length; index++) {
      if (waterFlowData[index].appUri.split('/')[0] === moduleName) {
        return waterFlowData[index].name;
      }
    }
    return null;
  }

  // 帮助功能：半模态弹窗显示对应案例README
  @Builder
  buildReadMeSheet(): void {
    Column() {
      Row() {
        Row() {
          Text(this.getModuleTitle(this.name))
            .textOverflow({ overflow: TextOverflow.Clip })
            .fontColor(Color.White)
            .fontWeight(700)
            .fontSize($r('app.integer.nav_destination_title_text_size'))
        }
        .width($r('app.integer.readme_sheet_text_size'))

        Column() {
          Stack() {
            Column() {
            }
            .width($r('app.integer.readme_sheet_size'))
            .height($r('app.integer.readme_sheet_size'))
            .borderRadius($r('app.integer.nav_destination_title_image_border_radius'))
            .backgroundColor(Color.White)
            .opacity(0.05)

            Image($r('app.media.ic_public_cancel'))
              .fillColor(Color.White)
              .width($r('app.integer.readme_sheet_cancel_image_width'))
          }
        }
        .onClick(() => {
          this.isShowReadMe = false;
        })
        .justifyContent(FlexAlign.Center)
        .width($r('app.integer.readme_sheet_size'))
        .height($r('app.integer.readme_sheet_size'))
        .borderRadius($r('app.integer.nav_destination_title_image_border_radius'))
      }
      .padding({ left: $r('app.integer.readme_sheet_padding'), right: $r('app.integer.readme_sheet_padding') })
      .margin({ top: $r('app.integer.readme_sheet_margin'), })
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      NodeContainer(getNWeb(this.helperUrl))
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}