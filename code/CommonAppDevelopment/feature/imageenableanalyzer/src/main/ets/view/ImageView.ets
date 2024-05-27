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

import image from '@ohos.multimedia.image';
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import promptAction from '@ohos.promptAction';

/**
 * 实现步骤：
 * 通过Image.enableAnalyzer(true)实现Image组件长摁拖拽元素并AI抠图：
 * 1. 目前AI分析支持传入的图片类型为PixelMap且为RGBA_8888类型的图片，因此定义方法使图片转成PixelMap且为RGBA_8888类型。
 * 2. 将需要AI抠图的Image组件添加.enableAnalyzer(true)方法，并传入PixelMap且为RGBA_8888类型的图片，即可开启AI抠图能力。
 * Image.enableAnalyzer()参考文档：
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-image-0000001815927572
 */

@AppRouter({ name: "imageenableanalyzer/ImageView" })
@Component
export struct ImageView {
  @State swiperIndex: number = 0;
  @State imagePixelMapList: Array<image.PixelMap> = []; // 定义转化过类型的图片数组
  scroller: Scroller = new Scroller();

  aboutToAppear() {
    const arr = [$r("app.media.imageenableanalyzer_cat"), $r("app.media.imageenableanalyzer_cat2")];
    arr.forEach(async (item) => {
      const imagePixelMap = await this.getPixmapFromMedia(item); // TODO：知识点：使jpg类型的图片转成PixelMap且为RGBA_8888类型
      this.imagePixelMapList.push(imagePixelMap);
    })
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Swiper() {
            ForEach(this.imagePixelMapList, (item: image.PixelMap) => { // 传入符合AI处理的图片类型并渲染图片
              /* 性能知识点：当数据量较大时，推荐使用懒加载加载数据。
               * 参考使用数据懒加载文章：
               * https://gitee.com/harmonyos-cases/cases/blob/master/docs/performance/arkts-performance-improvement-recommendation.md
               */
              Image(item)
                .enableAnalyzer(true)// TODO：知识点：开启Image组件的AI分析能力，目前支持分析PixelMap且为RGBA_8888类型的图片
                .objectFit(ImageFit.Contain)
                .width('100%')
                .draggable(false) // 禁止整张图片拖动
            })
          }
          .index(this.swiperIndex)
          .onChange((index: number) => {
            this.swiperIndex = index;
          })
          .indicator(new DotIndicator()
            .itemWidth($r('app.integer.imageenableanalyzer_indicator_itemWidth'))
            .itemHeight($r('app.integer.imageenableanalyzer_indicator_itemWidth'))
            .selectedItemWidth($r('app.integer.imageenableanalyzer_indicator_selectedItemWidth'))
            .selectedItemHeight($r('app.integer.imageenableanalyzer_indicator_selectedItemHeight'))
            .color(Color.Gray)
            .selectedColor(Color.Red))

          Text(`${this.swiperIndex + 1}/${this.imagePixelMapList.length}`)
            .fontSize($r('app.integer.imageenableanalyzer_bubble_text_fontSize'))
            .fontColor($r('app.color.imageenableanalyzer_white'))
            .width($r('app.integer.imageenableanalyzer_row_text_width'))
            .height($r('app.integer.imageenableanalyzer_row_text_height'))
            .borderRadius($r('app.integer.imageenableanalyzer_row_borderRadius'))
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.imageenableanalyzer_bg3'))
            .margin({
              right: $r('app.integer.imageenableanalyzer_row_margin_right'),
              bottom: $r('app.integer.imageenableanalyzer_row_margin_bottom')
            })
        }
        .width('100%')
        .height($r('app.integer.imageenableanalyzer_swiper_height'))
        .backgroundColor($r('app.color.imageenableanalyzer_white'))

        Column() {
          Content()
            .margin({ top: $r('app.integer.imageenableanalyzer_content_margin_top') })
        }
        .padding({
          left: $r('app.integer.imageenableanalyzer_column_padding_left'),
          right: $r('app.integer.imageenableanalyzer_column_padding_right')
        })
      }
      .width('100%')
      .margin({ top: $r('app.integer.imageenableanalyzer_column_margin_top') })
    }
    .scrollable(ScrollDirection.Vertical) // 滚动方向纵向
    .scrollBarColor(Color.Gray) // 滚动条颜色
    .scrollBarWidth(3) // 滚动条宽度
  }

  private async getPixmapFromMedia(resource: Resource) {
    const unit8Array = await getContext(this)?.resourceManager?.getMediaContent({
      bundleName: resource.bundleName,
      moduleName: resource.moduleName,
      id: resource.id
    })
    const imageSource = image.createImageSource(unit8Array.buffer.slice(0, unit8Array.buffer.byteLength));
    const createPixelMap: image.PixelMap = await imageSource.createPixelMap({
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    })
    await imageSource.release();
    return createPixelMap;
  }
}


@Component
  // 图片下面的文字内容组件
struct Content {
  build() {
    Column() {
      Text($r('app.string.imageenableanalyzer_image_drag_title')) // 文字标题
        .fontSize($r('app.integer.imageenableanalyzer_text_title_fontSize'))
        .fontWeight("bold")
        .padding({ top: $r('app.integer.imageenableanalyzer_text_padding_top') })
        .textAlign(TextAlign.Start)
      Text($r('app.string.imageenableanalyzer_image_drag_content')) // 文字内容
        .fontSize($r('app.integer.imageenableanalyzer_text_content_fontSize'))
        .padding({ top: $r('app.integer.imageenableanalyzer_text_padding_top') })
        .lineHeight($r('app.integer.imageenableanalyzer_contain_line_height'))
        .textAlign(TextAlign.Start)
      Text($r('app.string.imageenableanalyzer_image_drag_ref')) // 文字内容话题
        .fontSize($r('app.integer.imageenableanalyzer_text_content_fontSize'))
        .fontColor($r('app.color.imageenableanalyzer_content_color'))
        .padding({ top: $r('app.integer.imageenableanalyzer_text_padding_top') })
        .textAlign(TextAlign.Start)
        .onClick(()=>{
          // 调用Toast显示提示:此样式仅为案例展示
          promptAction.showToast({ message: $r('app.string.imageenableanalyzer_only_show_ui') });
        })
    }
    .width('100%')
    .padding({
      top: $r('app.integer.imageenableanalyzer_view_padding_top'), bottom: $r('app.integer.imageenableanalyzer_view_padding_bottom'),
      left: $r('app.integer.imageenableanalyzer_view_padding_left'), right: $r('app.integer.imageenableanalyzer_view_padding_right')
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.imageenableanalyzer_white'))
    .borderRadius($r('app.integer.imageenableanalyzer_view_borderRadius'))
  }
}
