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

/**
 * 轮播图数据类
 */
export class ImageDataType {
  id: string;
  imageSource: Resource;

  constructor(id: string, imageSource: Resource) {
    this.id = id;
    this.imageSource = imageSource;
  }
}

/**
 * 功能数据类
 */
export class FeatureDataType {
  image: Resource;
  text: ResourceStr;

  constructor(image: Resource, text: ResourceStr) {
    this.image = image;
    this.text = text;
  }
}