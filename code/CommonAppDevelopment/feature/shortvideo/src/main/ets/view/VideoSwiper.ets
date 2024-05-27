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

import curves from '@ohos.curves';
import { promptAction } from '@kit.ArkUI';
import { GlobalStateDialogManager } from '@ohos/base/Index';
import { logger } from '@ohos/base';
import { BasicDataSource } from '../model/BasicDataSource';
import { CommentDataSource, VideoData } from '../model/DataModel';
import { Constants } from '../constant/Contants';
import { Side, VideoDes } from './Side';

const TAG = 'video_swiper';
// 视频下标
let videoIndex: number = 0;

// 视频划动组件
@Component
export struct VideoSwiper {
  private swiperController: SwiperController = new SwiperController();
  @State playBoo: boolean = true; // 是否为播放状态
  @State index: number = 0; // 当前视频下标
  @StorageProp('isShowGlobalStateDialog') isShowGlobalStateDialog: boolean = false; // 是否展示全局弹窗
  private data: VideoNew = new VideoNew();
  videoData: Array<VideoData> = [
    {
      video: $r("app.media.shortvideo_short_video1"),
      name: '@北大是只猫',
      description: '欢迎来到霍格莫德村',
      time: '2024-1-3 14:52',
      controller: new VideoController(),
      auto: true,
      duration: 0,
      head: $r("app.media.shortvideo_photo33"),
      likeCount: '1234',
      commentCount: '2234',
      favoriteCount: '3234',
      shareCount: '4234',
      hotspot: '猫长藓要多晒太阳',
      play: false,
      index: 0,
      commentDataSource: new CommentDataSource()
    },
    {
      video: $r("app.media.shortvideo_short_video2"),
      name: '@谭 雪',
      description: '#栈桥',
      time: '2024-1-2 10:52',
      controller: new VideoController(),
      auto: false,
      duration: 0,
      head: $r("app.media.shortvideo_photo35"),
      likeCount: '7890',
      commentCount: '8890',
      favoriteCount: '9990',
      shareCount: '9991',
      hotspot: '栈桥海鸥',
      play: false,
      index: 1,
      commentDataSource: new CommentDataSource()
    },
    {
      video: $r("app.media.shortvideo_short_video3"),
      name: '@刘格格',
      description: '生活不止眼前的苟且，还有诗和远方',
      time: '2024-1-2 16:03',
      controller: new VideoController(),
      auto: false,
      duration: 0,
      head: $r("app.media.shortvideo_photo37"),
      likeCount: '4567',
      commentCount: '5567',
      favoriteCount: '6667',
      shareCount: '7667',
      hotspot: '社恐',
      play: false,
      index: 2,
      commentDataSource: new CommentDataSource()
    }
  ]

  // 页面展示的时候，视频开始播放
  onPageShow() {
    this.data.getData(this.index).controller.start();
  }

  // 页面隐藏时，视频停止播放
  onPageHide() {
    this.data.getData(this.index).controller.pause();
  }

  // 视频数据初始化
  aboutToAppear() {
    if (videoIndex) {
      this.index = videoIndex;
    }

    for (let i = 0; i < this.videoData.length; i++) {
      // 模拟评论数据,真实场景需要请求后台获取评论数据
      for (let j = 0; j < 100; j++) {
        this.videoData[i].commentDataSource.pushData({
          id: j + "",
          avatar: this.videoData[i].head,
          name: "精灵球收七龙珠" + j,
          commentContent: "我没有看到后续，但总有人会看到" + j,
          timeAgo: j + "小时前",
          address: "广州",
          likeCount: j + ""
        });
      }
      this.data.pushData(this.videoData[i]);
    }
  }

  build() {
    Column() {
      Swiper(this.swiperController) { // 使用Swiper组件实现滑动轮播显示的能力
        /*
         *TODO 性能知识点：列表中数据较多且不确定的情况下，使用LazyForEach进行数据循环渲染。
         *当组件滑出可视区域外时，框架会进行组件销毁回收以降低内存占用。
         *文档参考链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/arkts-rendering-control-lazyforeach-0000001524417213-V2
         */
        LazyForEach(this.data, (item: VideoData, index: number) => {
          Stack({ alignContent: Alignment.Center }) { // 点击屏幕时，显示暂停图标
            Stack({ alignContent: Alignment.BottomStart }) { // 展示视频信息
              Stack({ alignContent: Alignment.TopEnd }) { // 视频播放组件
                Video({
                  // 使用Video组件实现播放视频并控制其播放状态
                  src: item.video,
                  controller: item.controller
                })
                  .width($r('app.string.shortvideo_hundred_percent'))
                  .height(this.isShowGlobalStateDialog ? $r('app.string.shortvideo_fifty_percent') : $r('app.string.shortvideo_hundred_percent'))
                  .animation({ duration: Constants.NUMBER_200 })
                  .objectFit(ImageFit.Contain)// 保持宽高比进行缩小或者放大，使得图片完全显示在显示边界内
                  .loop(true)
                  .autoPlay(item.auto)
                  .controls(false)// 控制视频播放的控制栏是否显示
                  .onPrepared((e) => { // 准备事件回调
                    item.duration = e.duration;
                    logger.info(TAG, 'onPrepared index=' + item.index.toString() + ', isplay=' + item.play.toString() + ', SwiperIndex=' + videoIndex.toString() + ', duration=' + e.duration.toString());
                  })
                  .onStart(() => {
                    logger.info(TAG, 'onStart index=' + item.index.toString() + ', isplay=' + item.play.toString() + ', SwiperIndex = ' + videoIndex.toString());
                    item.play = true;
                    this.playBoo = this.data.getData(this.index).play;
                  })
                  .onPause(() => {
                    logger.info(TAG, 'onPause index=' + item.index.toString() + ', isplay=' + item.play.toString() + ', SwiperIndex = ' + videoIndex.toString());
                    item.play = false;
                    this.playBoo = this.data.getData(this.index).play;
                  })
                  .onUpdate((e) => {
                    if (e !== undefined) {
                      const isPlayFinish: boolean = ((e.time === item.duration) ? true : false);
                      if (isPlayFinish) {
                        logger.debug(TAG, 'onUpdate index=' + item.index.toString() + ', isplay=' + item.play.toString() + ', SwiperIndex=' + videoIndex.toString() + ' duration=' + e.time.toString());
                      }
                    }
                  })
                  .onFinish(() => {
                    logger.info(TAG, 'onFinish index=' + item.index.toString() + ', isplay=' + item.play.toString() + ', SwiperIndex=' + videoIndex.toString());
                  })
                  .onError(() => {
                    logger.error(TAG, 'onError, index=' + item.index.toString() + ', isplay=' + item.play.toString() + ', SwiperIndex=' + videoIndex.toString());
                  })
                  .onClick(() => {
                    if (this.isShowGlobalStateDialog) {
                      GlobalStateDialogManager.operateGlobalStateDialog({ isShowGlobalStateDialog: false });
                      return;
                    }
                    if (item.play) {
                      item.controller.pause();
                    } else {
                      item.controller.start();
                    }
                  })// 组件可见区域变化事件
                  .onVisibleAreaChange([0.0, 1.0], (isVisisble: boolean, currentRatio: number) => {
                    // 通过设置ratios为[0.0, 1.0]，实现当组件完全显示或完全消失在屏幕中时触发回调
                    logger.info(TAG, 'onVisibleAreaChange index=' + item.index.toString() + ', isplay=' + item.play.toString() + ', SwiperIndex=' + videoIndex.toString() + ', visble=' + isVisisble.toString());
                    if (isVisisble && currentRatio >= 1.0 && item.index === videoIndex) {
                      item.controller.start();
                    }
                  })
                // 展示视频播放界面右侧用户头像、视频评论数量、收藏数量、分享数量等信息
                Side({
                  head: item.head,
                  likeCount: item.likeCount,
                  commentCount: item.commentCount,
                  favoriteCount: item.favoriteCount,
                  shareCount: item.shareCount,
                  index: item.index,
                  commentData: item.commentDataSource
                })
              }.width('100%').height('100%').padding($r("app.integer.shortvideo_stack_padding"))

              // 展示视频播放界面左下角作者名字、作品描述等相关信息
              VideoDes({ name: item.name, description: item.description, hotspot: item.hotspot, time: item.time })
                .margin({ bottom: $r("app.integer.shortvideo_video_des_margin_bottom") })
              Row() {
                Row() {
                  Image($r("app.media.shortvideo_ic_public_upgrade_filled"))
                    .height($r("app.integer.shortvideo_upgrade_icon_size"))
                    .width($r("app.integer.shortvideo_upgrade_icon_size"))
                  Text($r("app.string.shortvideo_upgrade_hot"))
                    .fontSize($r("app.integer.shortvideo_upgrade_text_font_size"))
                    .fontColor($r("app.color.shortvideo_up_color"))
                  Text(' · ' + item.hotspot)
                    .fontSize($r("app.integer.shortvideo_mus_font_size"))
                    .maxLines(1)
                    .width(item.hotspot.length * 12)
                    .fontColor(Color.White)
                    .height($r("app.integer.shortvideo_mus_height"))
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                }
                .width('66%')

                // 上升热点
                Row() {
                  Divider()
                    .vertical(true)
                    .color(Color.White)
                    .strokeWidth(1)
                    .height($r("app.integer.shortvideo_upgrade_text_font_size"))
                    .margin({
                      left: $r("app.integer.shortvideo_upgrade_margin"),
                      right: $r("app.integer.shortvideo_upgrade_margin")
                    })
                  Text($r("app.string.shortvideo_online_people"))
                    .fontSize($r("app.integer.shortvideo_mus_font_size"))
                    .fontColor(Color.White)
                  Image($r("app.media.shortvideo_ic_arrow_right"))
                    .width($r("app.integer.shortvideo_upgrade_text_font_size"))
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.End)
              }
              .width('100%')
              .height($r("app.integer.shortvideo_upgrade_height"))
              .backgroundColor(Color.Gray)
              .opacity($r("app.float.shortvideo_fabulous_opacity"))
              .padding({
                left: $r("app.integer.shortvideo_upgrade_padding"),
                right: $r("app.integer.shortvideo_upgrade_padding")
              })
              .justifyContent(FlexAlign.Start)
              .onClick(() => {
                // 调用Toast显示提示：此样式仅为案例演示
                promptAction.showToast({ message: $r("app.string.shortvideo_demo_toast_tips") });
              })

            }.width('100%').height('100%').padding(0)

            if (!this.playBoo) {
              Image($r("app.media.shortvideo_pau"))
                .height($r("app.integer.shortvideo_play_icon_size"))
                .width($r("app.integer.shortvideo_play_icon_size"))
                .onClick(() => {
                  item.controller.start();
                  item.play = true;
                  this.playBoo = true;
                })
            }
          }.width('100%').height('100%').padding($r("app.integer.shortvideo_stack_padding"))
        }, (item: VideoData) => JSON.stringify(item))
      }
      .index(videoIndex) // 设置当前在容器中显示的子组件的索引值
      .displayCount(1)
      .width('100%')
      .height('100%')
      .autoPlay(false)
      .indicator(false)
      .loop(true)
      .duration(200) // 子组件切换的动画时长
      .cachedCount(0)
      .vertical(true)
      .itemSpace(0)
      /**
       * 弹性曲线产生自然的弹簧效果，四个参数分别对应附着在弹簧上的对象的初始速度、附着在弹簧上的对象的质量、单位形变量所需弹力的大小、
       * 弹簧在振动过程中的减震力，使得弹簧振幅逐渐减小直至停止在平衡位置
       */
      .curve(curves.interpolatingSpring(-1, 1, 328, 34))
      .onAnimationStart((index: number, targetIndex: number, extraInfo: SwiperAnimationEvent) => {
        logger.info(TAG, 'onAnimationStart old index=' + index.toString() + ', isplay=' + this.data.getData(index).play.toString() + ', new index=' + targetIndex.toString());
        // 跳转之前停止当前视频
        this.data.getData(index).controller.pause();
      })
      .onChange(async (index) => {
        this.index = index;
        // 跳转成功之后播放当前视频
        this.data.getData(this.index).controller.start();
        this.playBoo = true;
        videoIndex = index;
        logger.info(TAG, 'onChange New index=' + this.index.toString() + ', isplay=' + this.data.getData(this.index).play.toString() + ', SwiperIndex=' + videoIndex.toString());
      })
    }
    .width('100%')
    .height('100%')
  }
}

class VideoNew extends BasicDataSource {
  videoNew: Array<VideoData> = [];

  // // 获取数组长度
  public totalCount(): number {
    return this.videoNew.length;
  }

  // 获取指定索引数据
  public getData(index: number): VideoData {
    return this.videoNew[index];
  }

  // 改变单个数据
  public addData(index: number, data: VideoData): void {
    this.videoNew.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  // 添加数据
  public pushData(data: VideoData): void {
    this.videoNew.push(data);
    this.notifyDataAdd(this.videoNew.length - 1);
  }
}
