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

import CommonConstants from '../common/constants/CommonConstants';
import { ProductItemComp } from '../components/ProductItemComp';
import { Product, ProductsDataSource } from '../model/ProductModel';
import { AppRouter, DynamicsRouter } from '@ohos/dynamicsrouter/Index';

/**
 * 商品瀑布流页面
 * 实现步骤：
 * 1.使用WaterFlow+LazyForEach+组件复用实现高性能瀑布流
 */

@AppRouter({ name: "imageresizable/ProductWaterFlowPage" })
@Component
export struct ProductWaterFlowPage {
  @State productsDataSource: ProductsDataSource = new ProductsDataSource();

  build() {
    WaterFlow() {
      LazyForEach(this.productsDataSource, (item: Product) => {
        FlowItem() {
          // TODO: 性能知识点：使用@Reusable修饰可复用的组件，并通过设置reuseId提供瀑布流滑动场景中的组件复用能力
          ProductItemComp({
            product: item
          })
            .reuseId(item.type)
        }
        .width('100%')
      })
    }
    .columnsTemplate(CommonConstants.MAIN_PAGE_WATERFLOW_COLUMNS_TEMPLATE)
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Fade)
  }
}