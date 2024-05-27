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

import { TabBarDataType } from './DataType';

// TarBar数据
export const TABINFO: TabBarDataType[] = [
  new TabBarDataType(0, $r('app.string.custom_tab_home'), $r("app.media.custom_tab_tabBarMain"), $r("app.media.custom_tab_home")),
  new TabBarDataType(1, $r('app.string.custom_tab_news'), $r("app.media.custom_tab_new_selected"), $r("app.media.custom_tab_new")),
  new TabBarDataType(2, $r('app.string.custom_tab_community'), $r("app.media.custom_tab_community_selected"), $r("app.media.custom_tab_community")),
  new TabBarDataType(3, $r('app.string.custom_tab_shopping_cart'), $r("app.media.custom_tab_cart_selected"), $r("app.media.custom_tab_cart")),
  new TabBarDataType(4, $r('app.string.custom_tab_mine'), $r("app.media.custom_tab_user_selected"), $r("app.media.custom_tab_user")),
];