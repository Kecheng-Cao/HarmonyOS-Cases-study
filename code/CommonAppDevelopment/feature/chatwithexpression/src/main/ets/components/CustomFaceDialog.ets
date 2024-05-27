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

import { EmojiData, EmojiModel } from '../model/Emoji';
import { FaceGridConstants } from '../constants/ChatConstants';

// TODO 知识点：在CustomDialog中使用Grid创建表情键盘
@CustomDialog
export struct CustomFaceDialog {
  customFaceDialogCtl: CustomDialogController;
  imageSize: number = 0;
  private controller: RichEditorController = new RichEditorController();

  build() {
    Column() {
      Grid() {
        // TODO: 性能知识点：使用ForEach组件循环渲染数据
        ForEach(EmojiData, (item: EmojiModel) => {
          GridItem() {
            Image(item.imgSrc)
              .width(FaceGridConstants.EMOJI_IMAGE_SIZE)
              .height(FaceGridConstants.EMOJI_IMAGE_SIZE)
              .onClick(() => {
                // TODO 知识点：将表情热键添加到输入框中
                this.controller.addImageSpan(item.imgSrc, {
                  imageStyle: { size: [this.imageSize, this.imageSize], verticalAlign: ImageSpanAlignment.CENTER }
                });
              })
          }
        })
      }
      .maxCount(FaceGridConstants.GRID_MAX_COUNT)
      .columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr") // 分成6份
      .rowsGap(FaceGridConstants.ROWS_GAP)
      .margin($r('app.integer.chat_with_expression_grid_item_margin'))
      .width($r('app.string.chat_with_expression_layout_100'))
    }
    .backgroundColor($r('app.color.chat_with_expression_message_body_background'))
    .width($r('app.string.chat_with_expression_layout_100'))
  }
}