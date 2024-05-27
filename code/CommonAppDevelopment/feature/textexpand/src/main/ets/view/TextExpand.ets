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

import promptAction from '@ohos.promptAction';
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import { ItemPart } from '../components/ItemPart';

const SEARCH_BUTTON: string = '搜索'; // 搜索按钮文字

/*
 * 实现步骤
 * 想要实现文字收起，难点在于如何判断展示多少文字可以达到只显示到指定行数（以两行为例）的目的。通过判断文字其在容器内的高度来将文字缩减到指定行数，可以实现收起效果的目的。利用 measure.measureTextSize 方法去分别计算文字总体的高度和两行文字的高度，再进行缩减文字，直到文字高度符合两行文字的要求。
 * 1. 使用measure.measureTextSize方法来判断总体文字的高度
 * 2. 使用measure.measureTextSize方法来判断两行文字的高度，当前为两行文字的高度
 * 3. 减少接收文字字符数。当接收文字高度小于指定行数高度时，使文字显示两行，达到实现收起状态的目的。否则继续计算直到小于指定行数的高度
 * */

// 单条信息对象
class ItemData {
  profileImg: Resource = $r('app.string.text_expand_url1');
  rawTitle: Resource = $r('app.string.text_expand_long_title');
  imgUrlList: Resource[] | string[] = [
    $r('app.string.text_expand_url2'),
    $r('app.string.text_expand_url3'),
    $r('app.string.text_expand_url4')
  ];
}

// TabContent对象
class TabData {
  id: number;
  name: string | Resource;
  ItemList: ItemData[] = [
    new ItemData(),
    new ItemData(),
    new ItemData()
  ];

  constructor(id: number, name: string | Resource) {
    this.id = id;
    this.name = name
  }
}

@AppRouter({ name: "textexpand/TextExpand" })
@Component
export struct TextExpand {
  @State currentIndex: number = 0; // 当前索引
  @State changeValue: string = ''; // 搜索框关键词
  private controller: TabsController = new TabsController();
  private controllerSearch: SearchController = new SearchController();
  tabData: TabData[] = [
    new TabData(0, $r('app.string.text_expand_tab_name_main_page')),
    new TabData(1, $r('app.string.text_expand_tab_name_hot')),
    new TabData(2, $r('app.string.text_expand_tab_name_same_city')),
    new TabData(3, $r('app.string.text_expand_tab_name_else'))
  ];

  @Builder
  tabBuilder(index: number, name: string | Resource) {
    Column() {
      Text(name)
        .fontColor(this.currentIndex === index ? $r('app.color.text_expand_selected_tab_name') : $r('app.color.text_expand_tab_name'))
        .font({
          size: $r('app.integer.text_expand_text_font_size'),
          weight: this.currentIndex === index ? 500 : 400
        })
        .lineHeight($r('app.integer.text_expand_text_line_height'))
        .margin({
          top: $r('app.integer.text_expand_text_margin_top'),
          bottom: $r('app.integer.text_expand_text_margin_bottom')
        })
      Divider()
        .strokeWidth(2)
        .color($r('app.color.text_expand_divider_color'))
        .opacity(this.currentIndex === index ? $r('app.integer.text_expand_divider_opacity_1') : $r('app.integer.text_expand_divider_opacity_0'))
    }
    .width($r('app.string.text_expand_layout_100'))
  }

  build() {
    Column() {
      Search({
        value: this.changeValue,
        placeholder: $r('app.string.text_expand_search_placeholder'),
        controller: this.controllerSearch
      })
        .enableKeyboardOnFocus(false)
        .searchButton(SEARCH_BUTTON)
        .width($r('app.string.text_expand_layout_95'))
        .height($r('app.integer.text_expand_search_height'))
        .backgroundColor($r('app.color.text_expand_search_background_color'))
        .placeholderColor(Color.Grey)
        .placeholderFont({
          size: $r('app.integer.text_expand_search_placeholder_font_size'),
          weight: 400
        })
        .onSubmit((value: string) => {
          promptAction.showToast({ message: $r('app.string.text_expand_show_button') });
        })
        .onChange((value: string) => {
          this.changeValue = value;
        })
      Tabs({
        barPosition: BarPosition.Start, index: this.currentIndex, controller: this.controller
      }) {
        ForEach(this.tabData, (item: TabData, index: number) => {
          TabContent() {
            Column() {
              List({ space: 20, initialIndex: 0 }) {
                ForEach(item.ItemList, (itemData: ItemData) => {
                  // 自定义 ItemPart 组件
                  ItemPart({
                    profileImg: itemData.profileImg,
                    imgUrlList: itemData.imgUrlList,
                    rawTitle: itemData.rawTitle
                  })
                })
              }
              .width($r('app.string.text_expand_layout_100'))
              .height($r('app.string.text_expand_layout_100'))
              .divider({
                strokeWidth: $r('app.integer.text_expand_divider_stroke_width'),
                color: $r('app.color.text_expand_divider_0c_color')
              })
            }
            .width($r('app.string.text_expand_layout_100'))
            .height($r('app.string.text_expand_layout_100'))
          }
          .tabBar(this.tabBuilder(item.id, item.name))
        })
      }
      .vertical(false)
      .barMode(BarMode.Fixed)
      .barWidth($r('app.integer.text_expand_tab_bar_width'))
      .barHeight($r('app.integer.text_expand_tab_bar_height'))
      .animationDuration(400)
      .onChange((index: number) => {
        // 变更时修改当前索引
        this.currentIndex = index;
      })
      .width($r('app.string.text_expand_layout_100'))
      .height($r('app.string.text_expand_layout_100'))
      .backgroundColor($r('app.color.text_expand_bar_background_color'))
    }
    .width($r('app.string.text_expand_layout_100'))
  }
}
