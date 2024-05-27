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

import { BasicDataSource } from './BasicDataSource';

// 视频数据结构
export interface VideoData {
  video: Resource | string;
  name: string;
  description: string;
  time: string;
  controller: VideoController;
  auto: boolean;
  duration: number; // 视频时长
  head: Resource;
  likeCount: string;
  commentCount: string;
  favoriteCount: string;
  shareCount: string;
  hotspot: string;
  play: boolean;
  index: number;
  commentDataSource: CommentDataSource;
}

// 继承自BasicDataSource的子类，重写了方法
export class TopTabContent extends BasicDataSource {
  private tabContent: string[] = ['关注', '精选', '推荐', '放映厅'];

  // 获取数组长度
  public totalCount(): number {
    return this.tabContent.length;
  }

  // 获取指定索引数据
  public getData(index: number): string {
    return this.tabContent[index];
  }

  // 改变单个数据
  public addData(index: number, data: string): void {
    this.tabContent.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  // 添加数据
  public pushData(data: string): void {
    this.tabContent.push(data);
    this.notifyDataAdd(this.tabContent.length - 1);
  }
}

/**
 * 评论属性
 */
@Observed
export class Comment {
  id?: string; // 评论id
  avatar?: Resource; // 评论人头像
  name?: string; // 评论人昵称
  commentContent?: string; // 评论内容
  timeAgo?: string; // 评论时间
  address?: string; // 评论地址
  likeCount?: string; // 评论的点赞人数
}

/**
 * 评论数据源
 */
@Observed
export class CommentDataSource extends BasicDataSource {
  private commentArray: Comment[] = [];

  public totalCount(): number {
    return this.commentArray.length;
  }

  /**
   * 获取指定索引数据
   * @param index
   * @returns
   */
  public getData(index: number): Comment {
    return this.commentArray[index];
  }

  /**
   * 改变单个数据
   * @param index
   * @param data
   */
  public addData(index: number, data: Comment): void {
    this.commentArray.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  /**
   * 添加数据
   * @param data
   */
  public pushData(data: Comment): void {
    this.commentArray.push(data);
    this.notifyDataAdd(this.commentArray.length - 1);
  }
}