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

import image from '@ohos.multimedia.image';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import { display } from '@kit.ArkUI';
import { logger } from '@ohos/base';
import { createWaterMarkView } from './WaterMarkView';
import { FeatureData, ImageData } from '../model/MockData';
import { FeatureDataType, ImageDataType } from '../model/DataType';

const CONTEXT: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
const DURATION: number = 300;

/**
 * 本示例主要从两个方面添加水印，一方面Canvas组件绘制水印，然后将水印组件通过overlay属性将水印作为浮层放置在页面中，另一方面获取初始图片的pixelMap对象，
 * 通过OffscreenCanvas绘制水印，并生成一个新的pixelMap对象进行保存。
 */
@AppRouter({ name: "watermark/MainView" })
@Component
export struct MainView {
  @State imageDataSource: ImageDataType[] = ImageData;
  @State imageScale: number = 1; // 初始化放大比例
  @State pixelMap: image.PixelMap | undefined = undefined; // pixelMap对象
  @State imageSource: Resource = $r("app.media.water_mark_image_1");
  @State currentIndex: number = 0;
  @State isShow: boolean = false; // 控制班模态页面的显示
  @State translateY: number = 0;

  /**
   * 弹窗函数
   */
  showToast() {
    promptAction.showToast({
      message: $r('app.string.water_mark_toast_message')
    })
  }

  /**
   * 隐藏半模态页面
   */
  hideHalfModule() {
    this.isShow = false;
    animateTo({ curve: Curve.Friction, duration: DURATION }, () => {
      this.translateY = 0;
    })
  }

  /**
   * 添加水印
   */
  addWaterMark() {
    CONTEXT.resourceManager.getMediaContent(this.imageSource.id, (error, value) => {
      if (error) {
        return;
      }
      const imageSource: image.ImageSource = image.createImageSource(value.buffer);
      imageSource.getImageInfo((err, data) => {
        if (err) {
          return;
        }
        let opts: image.DecodingOptions = {
          editable: true,
          desiredSize: {
            height: data.size.height,
            width: data.size.width
          }
        }
        imageSource.createPixelMap(opts, async (err, pixelMap) => {
          if (err) {
            return;
          }
          // TODO:知识点:通过OffscreenCanvasRenderingContext2D绘制水印
          const offScreenCanvas = new OffscreenCanvas(data.size.width, data.size.height);
          const offScreenContext: OffscreenCanvasRenderingContext2D = offScreenCanvas.getContext('2d');
          this.imageScale = offScreenCanvas.width / display.getDefaultDisplaySync().width;
          offScreenContext.drawImage(pixelMap, 0, 0, offScreenCanvas.width, offScreenCanvas.height);
          offScreenContext.textAlign = 'right';
          offScreenContext.textBaseline = 'bottom';
          offScreenContext.fillStyle = '#FFFFFF';
          // 设置字体大小
          offScreenContext.font = 32 * this.imageScale + 'vp';
          // 添加文字阴影
          offScreenContext.shadowBlur = 20;
          offScreenContext.shadowColor = '#F3F3F3';
          // 绘制文本
          offScreenContext.fillText('追逐繁星的太阳', offScreenCanvas.width - 20 * this.imageScale, offScreenCanvas.height - 20 * this.imageScale);
          this.pixelMap = offScreenContext.getPixelMap(0, 0, offScreenCanvas.width, offScreenCanvas.height);
          const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(CONTEXT);
          const uri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
          if (this.pixelMap !== undefined) {
            // 保存图片到本地
            const imagePacker = image.createImagePacker();
            const imageBuffer = await imagePacker.packing(this.pixelMap, { format: 'image/png', quality: 100 });
            try {
              // 通过uri打开媒体库文件
              let file = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
              logger.info(`openFile success, fd: ${file.fd}`);
              // 写到媒体库文件中
              fs.writeSync(file.fd, imageBuffer);
              fs.closeSync(file.fd);
            } catch (err) {
              logger.info(`fs failed ${err.code},errMessage:message`);
            }
          }
        })
      })
    })
  }

  build() {
    Stack() {
      Column() {
        // 标题
        this.titleBar()
        // 内容
        this.contentView()
      }

      this.maskBuilder()
    }.width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  maskBuilder() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .opacity(0.4)
      .onClick(() => {
        this.hideHalfModule();
      })

      this.halfModuleView()
    }.visibility(this.isShow ? Visibility.Visible : Visibility.None)

  }

  @Builder
  titleBar() {
    Row() {
      Image($r("app.media.water_mark_image_3"))
        .width($r('app.integer.water_mark_avatar_image_size'))
        .height($r('app.integer.water_mark_avatar_image_size'))
        .borderRadius($r('app.integer.water_mark_avatar_image_border_radius'))
      Text($r('app.string.water_mark_user_name'))
        .margin({ left: $r('app.string.ohos_id_elements_margin_vertical_l') })
      Blank()
      Text($r('app.string.water_mark_care_text'))
        .width($r('app.integer.water_mark_care_text_width'))
        .height($r('app.integer.water_mark_care_text_height'))
        .textAlign(TextAlign.Center)
        .fontColor($r('app.color.water_mark_color_4'))
        .border({
          color: $r('app.color.water_mark_color_4'),
          width: 1,
          radius: $r('app.integer.water_mark_care_text_border_radius')
        })
        .onClick(() => {
          this.showToast();
        })
    }.width('100%')
    .padding($r('app.string.ohos_id_card_padding_start'))
  }

  @Builder
  contentView() {
    Stack() {
      Column() {
        Swiper() {
          ForEach(this.imageDataSource, (item: ImageDataType, index: number) => {
            Image(item.imageSource)
              .width('100%')
              .height($r('app.integer.water_mark_show_image_height'))
              .draggable(false)
              .gesture(
                LongPressGesture()
                  .onAction(() => {
                    this.isShow = true;
                    animateTo({ curve: Curve.Friction, duration: DURATION }, () => {
                      // 半模态页面向上偏移300
                      this.translateY = -300;
                    })
                  })
              )
          })
        }
        .height($r('app.integer.water_mark_show_image_height'))
        .indicator(false)
        .onChange((index: number) => {
          this.imageSource = this.imageDataSource[index].imageSource;
          this.currentIndex = index;
        })

        // 自定义导航点
        Row() {
          ForEach(this.imageDataSource, (item: ImageDataType, index: number) => {
            Text()
              .width($r('app.integer.water_mark_indicator_size'))
              .height($r('app.integer.water_mark_indicator_size'))
              .borderRadius($r('app.integer.water_mark_indicator_border_radius'))
              .backgroundColor(this.currentIndex === index ? $r('app.color.water_mark_color_2') : $r('app.color.water_mark_color_3'))
              .margin($r('app.integer.water_mark_indicator_margin_size'))
          })
        }

        // 内容介绍
        Column() {
          Text($r('app.string.water_mark_content'))
            .width('100%')
            .padding($r('app.string.ohos_id_card_padding_start'))
        }
      }
      .height('100%')
      .overlay(createWaterMarkView())

    }
  }

  @Builder
  halfModuleView() {
    Column() {
      Row() {
        ForEach(FeatureData, (item: FeatureDataType, index: number) => {
          // 保存按钮的下标为1，除了保存功能，其他功能使用弹窗显示
          if (index !== 1) {
            Column() {
              Image(item.image)
                .width($r('app.integer.water_mark_feature_image_size'))
                .height($r('app.integer.water_mark_feature_image_size'))
              Text(item.text)
                .fontWeight(FontWeight.Medium)
                .fontFamily('HarmonyOS Sans')
                .margin({ top: $r('app.string.ohos_id_elements_margin_vertical_m') })
            }
            .width($r('app.integer.water_mark_feature_area_size'))
            .height($r('app.integer.water_mark_feature_area_size'))
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius($r('app.string.ohos_id_corner_radius_default_l'))
            .onClick(() => {
              this.showToast();
              this.hideHalfModule();
            })
          } else {
            SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE, buttonType: ButtonType.Normal })
              .fontColor(Color.Black)
              .width($r('app.integer.water_mark_feature_area_size'))
              .height($r('app.integer.water_mark_feature_area_size'))
              .iconColor(Color.Black)
              .iconSize($r('app.integer.water_mark_save_button_icon_size'))
              .backgroundColor(Color.White)
              .layoutDirection(SecurityComponentLayoutDirection.VERTICAL)
              .borderRadius($r('app.integer.water_mark_save_button_border_radius'))
              .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                console.info(`mast SaveButtonOnClickResult.${JSON.stringify(result)}`); //符合条件则进入
                this.isShow = false;
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  try {
                    this.addWaterMark();
                    this.hideHalfModule();
                  } catch (err) {
                    console.info(`mast the err is ${err.code},errMessage:${err.message}`);
                  }
                }
              })
          }
        })
      }.width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Image($r("app.media.water_mark_chat"))
          .width($r('app.integer.water_mark_share_image_size'))
          .height($r('app.integer.water_mark_share_image_size'))
          .borderRadius($r('app.integer.water_mark_share_image_border_radius'))
        Text($r('app.string.water_mark_share_text'))
          .margin({ left: $r('app.string.ohos_id_elements_margin_vertical_m') })
      }
      .width('100%')
      .height($r('app.integer.water_mark_share_area_height'))
      .backgroundColor(Color.White)
      .margin({ top: $r('app.string.ohos_id_elements_margin_vertical_l') })
      .padding($r('app.string.ohos_id_card_padding_start'))
      .borderRadius($r('app.string.ohos_id_corner_radius_default_m'))
      .onClick(() => {
        this.showToast();
        this.hideHalfModule();
      })
    }
    .width('100%')
    .height($r('app.integer.water_mark_half_module_height'))
    .backgroundColor($r('app.color.water_mark_color_1'))
    .position({ x: 0, y: '100%' })
    .translate({ x: 0, y: this.translateY })
    .padding($r('app.string.ohos_id_card_padding_start'))
    .border({
      radius: {
        topLeft: $r('app.string.ohos_id_corner_radius_default_l'),
        topRight: $r('app.string.ohos_id_corner_radius_default_l')
      }
    })
  }
}