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

import measure from '@ohos.measure';
import { BusinessError } from '@ohos.base';

const MAX_LINES: number = 2; // 收起时文本最大行数
const MEASURE_ELLIPSIS: string = '...'; // 省略符

@Component
export struct ItemPart {
  @State needProcess: boolean = true; // 是否展示展开收起按钮
  @State expanded: boolean = true; // 是否展开
  @State lastSpan: string | Resource = ''; // 最后位置的文字
  @State title: string | Resource = ''; // 展示文字
  @Prop profileImg: string | Resource = ''; // 头像图片
  @Prop imgUrlList: Array<string | Resource> = []; // 展示图片
  @Prop rawTitle: Resource; // 接收到的文字
  @State exceedOneLine: boolean = false; // 加上'收起'二字时超过一行需要换行

  // 判断执行展开还是收起
  process(): void {
    if (!this.needProcess) {
      return;
    }
    if (this.expanded) {
      this.collapseText();
    } else {
      this.expandText();
    }
  }

  aboutToAppear(): void {
    this.process();
  }

  // 展开文字
  expandText(): void {
    if (this.needProcess) {
      this.lastSpan = this.getStringFromResource($r('app.string.text_expand_collapse_title'));
      this.expanded = true;
      this.title = this.rawTitle;
      let clipTitle: string = this.getStringFromResource(this.rawTitle);
      // 计算接收文字的高度
      // TODO：知识点：使用 measure.measureTextSize 方法计算全部文字占用的高度
      let titleSize: SizeOptions = measure.measureTextSize({
        textContent: this.rawTitle, // 被计算文本内容
        constraintWidth: $r('app.string.text_expand_item_main_body_title_width'), // 被计算文本布局宽度
        fontSize: $r('app.string.text_expand_measure_font_size') // 被计算文本字体大小
      })
      // 计算文字加'收起'时的高度
      // TODO：知识点：使用 measure.measureTextSize 方法计算文字加'收起'时占用的高度
      let twoLineSize: SizeOptions = measure.measureTextSize({
        textContent: clipTitle + `  ${this.lastSpan}`, // 被计算文本内容
        constraintWidth: $r('app.string.text_expand_item_main_body_title_width'), // 被计算文本布局宽度
        fontSize: $r('app.string.text_expand_measure_font_size'), // 被计算文本字体大小
      })
      // 判断接收文字高度是否等于文字加'收起'时的高度，若等于则不用另起一行显示'收起'
      if (Number(titleSize.height) === Number(twoLineSize.height)) {
        this.exceedOneLine = false;
        return;
      } else {
        this.exceedOneLine = true;
      }
    }
  }

  // 收起文字
  collapseText(): void {
    if (!this.needProcess) {
      return;
    }
    // 计算接收文字的高度
    // TODO：知识点：使用 measure.measureTextSize 方法计算全部文字占用的高度
    let titleSize: SizeOptions = measure.measureTextSize({
      textContent: this.rawTitle, // 被计算文本内容
      constraintWidth: $r('app.string.text_expand_item_main_body_title_width'), // 被计算文本布局宽度
      fontSize: $r('app.string.text_expand_measure_font_size') // 被计算文本字体大小
    })
    // 计算指定行数文字的高度
    // TODO：知识点：使用 measure.measureTextSize 方法计算文本最大行数(maxLines参数)文字占用的高度
    let twoLineSize: SizeOptions = measure.measureTextSize({
      textContent: this.rawTitle, // 被计算文本内容
      constraintWidth: $r('app.string.text_expand_item_main_body_title_width'), // 被计算文本布局宽度
      fontSize: $r('app.string.text_expand_measure_font_size'), // 被计算文本字体大小
      maxLines: MAX_LINES // 被计算文本最大行数
    })
    // 判断接收文字高度是否大于指定行数文字高度，若不大于则返回不执行收起
    if (Number(titleSize.height) <= Number(twoLineSize.height)) {
      this.title = this.rawTitle;
      this.needProcess = false;
      return;
    }
    let clipTitle: string = this.getStringFromResource(this.rawTitle);
    this.lastSpan = this.getStringFromResource($r('app.string.text_expand_expand_title'));
    // 计算在指定行数内的字符数
    while (Number(titleSize.height) > Number(twoLineSize.height)) {
      this.expanded = true;
      clipTitle = clipTitle.substring(0, clipTitle.length - 1); // 每次减少一个字符长度，再进行比较计算，直到符合高度要求
      titleSize = measure.measureTextSize({
        textContent: clipTitle + MEASURE_ELLIPSIS + `  ${this.lastSpan}`, // 按钮文字也要放入进行计算
        constraintWidth: $r('app.string.text_expand_item_main_body_title_width'), // 被计算文本布局宽度
        fontSize: $r('app.string.text_expand_measure_font_size') // 被计算文本字体大小
      });
    }
    this.exceedOneLine = false;
    this.title = clipTitle + MEASURE_ELLIPSIS;
    this.expanded = false;
  }

  // 字符串资源转换为字符串的方法
  getStringFromResource(source: Resource | string): string {
    try {
      if (typeof source === 'string') {
        return source;
      }
      return getContext(this).resourceManager.getStringSync(source);
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      console.log('getStringFromResource' + code + message);
      return '';
    }
  }

  build() {
    ListItem() {
      Flex({ direction: FlexDirection.Column }) {
        Row() {
          Image($r(`app.media.${this.getStringFromResource(this.profileImg)}`))
            .width($r('app.integer.text_expand_image_width'))
            .height($r('app.integer.text_expand_image_height'))
            .borderRadius($r('app.integer.text_expand_image_border_radius'))
          Column() {
            Text($r('app.string.text_expand_text_name'))
              .fontSize($r('app.integer.text_expand_item_text_font_size'))
            Text($r('app.string.text_expand_text_date'))
              .fontSize($r('app.integer.text_expand_item_text_date_font_size'))
              .fontColor($r('app.color.text_expand_item_text_font_color'))
          }
          .margin({ left: $r('app.integer.text_expand_item_column_margin') })
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .margin($r('app.integer.text_expand_item_row_margin'))

        Column() {
          Text() {
            Span(this.title)
            if (this.needProcess && !this.exceedOneLine) {
              Span(`  ${this.lastSpan}`)
                .fontColor(Color.Orange)
            }
          }
          .fontSize($r('app.integer.text_expand_item_main_body_font'))
          .width($r('app.integer.text_expand_item_main_body_title_width'))

          if (this.exceedOneLine) {
            Text(this.lastSpan)
              .fontSize($r('app.integer.text_expand_item_main_body_font'))
              .width($r('app.integer.text_expand_item_main_body_title_width'))
              .textAlign(TextAlign.End)
              .fontColor(Color.Orange)
          }
        }
        .onClick(() => {
          this.process();
        })
        .margin({
          left: $r('app.integer.text_expand_item_main_body_column_margin'),
          bottom: $r('app.integer.text_expand_item_main_body_column_margin'),
          right: $r('app.integer.text_expand_item_main_body_column_margin')
        })

        Row() {
          ForEach(this.imgUrlList, (item: string, index: number) => {
            Image($r(`app.media.${this.getStringFromResource(item)}`))
              .width($r('app.integer.text_expand_item_main_body_image_width'))
              .height($r('app.integer.text_expand_item_main_body_image_height'))
              .margin({
                right: index === this.imgUrlList.length - 1 ? 0 : $r('app.integer.text_expand_item_main_body_image_margin')
              })
          })
        }
        .margin({ left: $r('app.integer.text_expand_item_row_margin') })
      }
    }
  }
}