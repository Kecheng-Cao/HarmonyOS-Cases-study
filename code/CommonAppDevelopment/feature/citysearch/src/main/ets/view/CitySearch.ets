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

import { ALL_CITY2, CITY_DATA } from '../model/DetailData';
import { SearchView } from '../view/SearchView';
import { CityView } from '../view/CityView';
import { AppRouter } from '@ohos/dynamicsrouter/Index';

const SEARCH_BUTTON_TEXT = '搜索';

/**
 * 实现步骤：
 * 通过AlphabetIndexer组件实现通过城市首字母快速定位城市的索引条导航：
 * 1. 当用户滑动List组件，list组件onScrollIndex监听到firstIndex的改变，绑定赋值给AlphabetIndexer的selected属性，从而定位到字母索引。
 * 2. 当点击AlphabetIndexer的字母索引时，通过scrollToIndex触发list组件滑动并指定firstIndex，从而实现List列表与AlphabetIndexer组件
 * 首字母联动吸顶展示。
 * AlphabetIndexer参考文档：
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V2/ts-container-alphabet-indexer-0000001427744828-V2
 */
@AppRouter({ name: "citysearch/CitySearch" })
@Component
export struct CitySearch {
  // 搜索值
  @State changeValue: string = '';
  // 占位
  @State placeholder: string = getContext().resourceManager.getStringSync($r('app.string.citysearch_placeholder'));
  // 搜索控制器
  controller: SearchController = new SearchController();
  // 是否展示搜索结果列表
  @State isSearchState: boolean = false;
  // 搜索结果
  @State searchList: string[] = [];

  build() {
    Column() {
      // 搜索框
      Search({ value: this.changeValue, placeholder: this.placeholder, controller: this.controller })
        .searchButton(SEARCH_BUTTON_TEXT)
        .width('100%')
        .height($r('app.integer.citysearch_search_height'))
        .margin({ left: $r('app.integer.citysearch_search_margin_left') })
        .backgroundColor($r('app.color.citysearch_search_bgc'))
        .placeholderColor(Color.Grey)
        .placeholderFont({ size: $r('app.integer.citysearch_placeholderFont_size'), weight: 400 })
        .textFont({ size: $r('app.integer.citysearch_placeholderFont_size'), weight: 400 })
        .onSubmit((value: string) => {
          // 如果没有输入数据，就使用占位符作为默认数据
          if (value.length === 0) {
            value = this.placeholder;
          }
          // 将值赋值给changeValue
          this.changeValue = value;
          this.isSearchState = true;
          // 搜索
          this.searchCityList(value);
        })
        .onChange((value: string) => {
          this.changeValue = value;
          // 搜索
          this.searchCityList(value);
          if (value.length === 0) {
            // 关闭搜索列表
            this.isSearchState = false;
            // 清空数据
            this.searchList.splice(0, this.searchList.length);
          } else {
            this.changeValue = value;
            // 搜索
            this.searchCityList(value);
            this.isSearchState = true;
          }
        })

      // 城市列表组件
      CityView({ isSearchState: $isSearchState, changeValue:$changeValue })
        .margin({ top: $r('app.integer.citysearch_list_margin_top') })

      // 搜索组件，将数据传递到搜索列表
      SearchView({ searchList: $searchList, isSearchState: $isSearchState, changeValue:$changeValue })
        .width("100%")
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: $r('app.integer.citysearch_padding_left'), right: $r('app.integer.citysearch_padding_right') })
    .backgroundColor($r('app.color.citysearch_bgc'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
  }

  // 搜索城市展示逻辑
  searchCityList(value: string) {
    const cityNames: string[] = [];
    ALL_CITY2.forEach(item => {
      if (item.name === value) {
        // 当搜索关键字，将相关城市信息展示。例如搜索"an"：展示"安庆"，"安阳"。
        item.city.forEach(city => {
          cityNames.push(city);
        })
      }
      this.searchList = cityNames;
      return;
    })
    CITY_DATA.forEach(item => {
      item.city.forEach(city => {
        // 当搜索汉字，会进行模糊搜索，将相关城市信息展示。例如搜索"长"：展示"长沙"，"长春"。
        if (city.includes(value)) {
          cityNames.push(city);
        }
      })
    })
    this.searchList = cityNames;
  }
}