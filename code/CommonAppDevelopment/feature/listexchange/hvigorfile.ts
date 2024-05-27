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

"use strict";
import { harTasks } from '@ohos/hvigor-ohos-plugin';
import { PluginConfig, etsGeneratorPlugin } from '@app/ets-generator';

const config: PluginConfig = {
  scanFiles: ["src/main/ets/view/ListExchangeView"],
}
export default {
  system: harTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [etsGeneratorPlugin(config)] /* Custom plugin to extend the functionality of Hvigor. */
}
