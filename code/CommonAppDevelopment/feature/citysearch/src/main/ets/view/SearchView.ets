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
export struct SearchView {
  private scroller: Scroller = new Scroller(); // List组件里可以绑定的可滚动组件的控制器
  @Link searchList: string[];
  @Link isSearchState: boolean;
  @Link changeValue: string;

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      List({ space: 14, initialIndex: 0, scroller: this.scroller }) {
        ForEach(this.searchList, (item: string) => {
          ListItem() {
            Column() {
              Text(item)
                .height(30)
                .fontSize(14)
            }.onClick(()=>{
              this.changeValue= item;
            })
          }
        })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.None)
      .divider({
        strokeWidth: $r('app.integer.citysearch_divider_strokeWidth'), color: $r('app.color.citysearch_divider_color'),
        startMargin: $r('app.integer.citysearch_divider_start'), endMargin: $r('app.integer.citysearch_divider_end')
      })
      .listDirection(Axis.Vertical)
      .sticky(StickyStyle.Header)
    }
    .width("100%")
    .height("100%")
    .layoutWeight(1)
    /* 性能知识点：由于需要通过搜索按钮频繁的控制自定义组件的显隐状态，因此推荐使用显隐控制替代条件渲染，
     * 参考合理选择条件渲染和显隐控制文章：
     * https://docs.openharmony.cn/pages/v4.0/zh-cn/application-dev/performance/proper-choice-between-if-and-visibility.md/
     */
    .visibility(this.isSearchState ? Visibility.Visible : Visibility.None)
  }
}