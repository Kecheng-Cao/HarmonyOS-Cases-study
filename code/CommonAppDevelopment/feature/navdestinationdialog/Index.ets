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
import { RouterInfo } from '@ohos/dynamicsrouter/Index';

export { NavDestinationDialog } from './src/main/ets/mainpage/MainPage';
export { CommentDialog } from './src/main/ets/viewmodel/CommentDialog';

// 动态import时需要调用的接口，接口名请使用harInit，用于动态加载页面
export function harInit(pageName: string) {
  switch (pageName) {
    case RouterInfo.NAVDESTINATION_DIALOG.pageName:
      import('./src/main/ets/mainpage/MainPage');
      break;
    case RouterInfo.NAVDESTINATION_COMMENT_DIALOG.pageName:
      import('./src/main/ets/viewmodel/CommentDialog');
      break;
  }
}