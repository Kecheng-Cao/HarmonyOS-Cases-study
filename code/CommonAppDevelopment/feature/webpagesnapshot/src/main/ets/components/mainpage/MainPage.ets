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
import { logger } from '@ohos/base';
import Constants from '../../common/Constants';
import { sleep } from '../../common/Utils';
import webview from '@ohos.web.webview';
import { BusinessError } from '@kit.BasicServicesKit';
import { componentSnapshot, display, promptAction } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';
import { AppRouter } from '@ohos/dynamicsrouter/Index';

/**
 * 实现思路：
 *  1. 创建Web组件加载指定的网页，获取Web组件和网页的实际尺寸，并给Web组件绑定自定义的id。
 *  2. 创建截图函数，执行滚动截图并拼接。
 *  3. 截图后弹出预览窗口，可以滚动查看完整的截图，并保存图片到用户相册中。
 */

const TAG: string = '[WebPageSnapshot]:';

@AppRouter({ name: "webpagesnapshot/WebPageSnapshot" })
@Component
export struct WebPageSnapshot {
  private context: Context = getContext(this);
  private webPageUrl: string = Constants.EXAMPLE_URL;
  private webviewController: webview.WebviewController = new webview.WebviewController();
  // 网页尺寸
  @State h5Width: number = 0;
  @State h5Height: number = 0;
  // Web组件尺寸
  private webWidth: number = 0;
  private webHeight: number = 0;
  // 当前网页位置
  private curXOffset: number = 0;
  private curYOffset: number = 0;
  // 备份当前网页位置
  private xOffsetBefore: number = 0;
  private yOffsetBefore: number = 0;
  // 截图过程的Web组件覆盖
  @State webMaskImage: PixelMap | undefined = undefined;
  private webMaskImageZIndex: number = -1;
  // 合并后的图片
  @State mergedImage: PixelMap | undefined = undefined;
  // 截图后小窗大小
  @State snapPopupWidth: number = Constants.SNAP_WINDOW_WIDTH;
  @State snapPopupHeight: number = Constants.SNAP_WINDOW_HEIGHT;
  @State snapPopupPosition: Position = { x: 0, y: 0 };
  // 是否显示预览窗口
  @State @Watch('onShowChanged') isShowSnapPopup: boolean = false;
  @State showPreview: boolean = false;
  // 屏幕尺寸
  private displayWidth: number = 0;
  private displayHeight: number = 0;
  // 侧滑手势
  private panOption: PanGestureOptions = new PanGestureOptions({
    direction: PanDirection.Left | PanDirection.Right,
    distance: 5
  });
  // 保存侧滑前的位置信息
  xPositionBefore: number = 0;
  // 预览浮窗 Scroll 控制器
  private previewerScroller: Scroller = new Scroller();
  private previewerScrollYOffset: number = 0;

  aboutToAppear(): void {
    // TODO: 性能知识点: 提前进行Web组件动态库的加载和Web内核主进程的初始化，最终以提高启动性能，减少白屏时间
    webview.WebviewController.initializeWebEngine();
    // 预连接，对url进行DNS解析、socket建链操作，不获取主资源子资源
    webview.WebviewController.prepareForPageLoad(Constants.EXAMPLE_URL, true, 2);
    // 获取屏幕尺寸
    const displayData = display.getDefaultDisplaySync();
    this.displayWidth = px2vp(displayData.width);
    this.displayHeight = px2vp(displayData.height);
  }

  build() {
    Column({
      space: Constants.CARD_MARGIN_START
    }) {
      // 标题Header栏
      Row() {
        Text($r('app.string.web_snap_page_title'))
          .fontSize($r('app.string.ohos_id_text_size_headline'))
          .fontWeight(FontWeight.Medium)
        Button($r('app.string.web_snap_snapshot_button_title'))
          .width(Constants.BUTTON_WIDTH)
          .onClick(() => {
            this.snapShot();
          })
      }
      .width($r('app.string.web_snap_full_size'))
      .justifyContent(FlexAlign.SpaceBetween)

      Stack() {
        // 截图过程的遮罩层，避免用户察觉屏幕快速滑动，提高用户体验
        Image(this.webMaskImage)
          .width($r('app.string.web_snap_full_size'))
          .height($r('app.string.web_snap_full_size'))
          .zIndex(this.webMaskImageZIndex)

        Web({
          src: this.webPageUrl,
          controller: this.webviewController
        })
          .width($r('app.string.web_snap_full_size'))
          .height($r('app.string.web_snap_full_size'))
          .id(Constants.WEB_ID)
          .onAreaChange((oldValue, newValue) => {
            // TODO: 高性能知识点: onAreaChange为高频回调，组件变动时每帧都会调用，避免冗余和耗时操作。
            this.webWidth = newValue.width as number;
            this.webHeight = newValue.height as number;
            logger.debug(TAG, `Web component width: ${this.webWidth}, height: ${this.webHeight}`);
          })
          .onPageEnd(() => {
            const SCRIPT = '[document.documentElement.scrollWidth, document.documentElement.scrollHeight]';
            this.webviewController.runJavaScriptExt(SCRIPT).then((result) => {
              try {
                switch (result.getType()) {
                  case webview.JsMessageType.ARRAY:
                    this.h5Width = (result.getArray() as number[])[0]; // 这里的单位是vp
                    this.h5Height = (result.getArray() as number[])[1];
                    logger.info(TAG, `h5Width = ${this.h5Width}, h5Height = ${this.h5Height}`);
                    break;
                  default:
                    logger.error(TAG, `Get web page size tyep error.`);
                    break;
                }
              } catch (e) {
                const err = e as BusinessError;
                logger.error(TAG, `Run script to get web page size failed. ErrorCode: ${err.code}, Message: ${err.message}`);
              }
            });
            promptAction.showToast({
              message: Constants.FINISH_LOAD_PROMPT,
              duration: Constants.FINISH_PROMPT_DURATION
            });
          })
          .onScroll((event) => {
            this.curXOffset = event.xOffset;
            this.curYOffset = event.yOffset;
            logger.info(TAG, `Web page current position (x: ${event.xOffset}, y: ${event.yOffset})`);
          })
      }
      .width($r('app.string.web_snap_full_size'))
      .layoutWeight(1)
      .borderRadius($r('app.string.ohos_id_corner_radius_default_m'))
      .bindContentCover($$this.isShowSnapPopup, this.screenShotPopup(), { modalTransition: ModalTransition.NONE })
    }
    .margin($r('app.string.ohos_id_card_margin_start'))
    .padding($r('app.string.ohos_id_card_padding_start'))
    .width($r('app.string.web_snap_full_size'))
    .height($r('app.string.web_snap_full_size'))
  }

  /**
   * 截图函数。
   */
  async snapShot() {
    // 截图前的状态初始化
    await this.beforeSnapshot();
    // TODO: 性能知识点: 使用Canvas离屏绘制在缓冲区拼接截图
    const canvasSetting: RenderingContextSettings = new RenderingContextSettings(true);
    const offCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(this.h5Width, this.h5Height, canvasSetting);
    // 前置常量
    const snipTimes = Math.ceil(this.h5Height / this.webHeight);
    logger.info(TAG, `Need to snapshot ${snipTimes} times.`);
    const lastTime = snipTimes - 1;
    const leftoverHeight = this.h5Height % this.webHeight;
    const cropLeftover: image.Region = {
      x: 0,
      y: vp2px(this.webHeight - leftoverHeight),
      size: {
        height: vp2px(leftoverHeight),
        width: vp2px(this.webWidth)
      }
    };
    // 开始截图
    for (let i = 0; i < snipTimes; i++) {
      const curSnip = await componentSnapshot.get(Constants.WEB_ID);
      // 最后一次截图需要特殊处理，去除重复部分
      if (i === lastTime) {
        logger.info(TAG, `The last snapshot image height ${leftoverHeight}`);
        await curSnip.crop(cropLeftover);
        offCanvasCtx.drawImage(curSnip, 0, this.webHeight * i, this.webWidth, leftoverHeight);
      } else {
        offCanvasCtx.drawImage(curSnip, 0, this.webHeight * i, this.webWidth, this.webHeight);
      }
      // debug使用，否则影响性能
      logger.debug(TAG, `Screenshot ${i}: ${JSON.stringify(await curSnip.getImageInfo())}`);
      // 继续滚动
      this.webviewController.scrollBy(0, this.webHeight);
      // 延时保证滚动完成
      await sleep(Constants.SCROLL_DURATION);
    }
    // 截图后的操作
    await this.afterSnapshot();
    // 获取pixelMap
    this.mergedImage = offCanvasCtx.getPixelMap(0, 0, this.h5Width, this.h5Height);
    // 拼接之后修改可动画变量
    this.afterGeneratorImage();
  }

  /**
   * 截图开始前的操作。
   * - 保存网页当前位置，用于恢复状态
   * - 截图当前页面作为遮罩层，避免用户察觉组件的滚动，提高用户体验
   * - Web页面滚动到顶部，准备开始截图
   * - 设置截图后小弹窗的位置，提示用户暂时不要操作，等待截图
   * - 开启提示小弹窗
   */
  async beforeSnapshot() {
    // 保存网页当前位置，用于恢复
    this.xOffsetBefore = this.curXOffset;
    this.yOffsetBefore = this.curYOffset;
    // TODO: 知识点: 使用componentSnapshot.get接口直接获取组件的渲染结果，而不需要将屏幕截图
    this.webMaskImage = await componentSnapshot.get(Constants.WEB_ID);
    this.webMaskImageZIndex = Constants.MASK_TOP_LAYER;
    this.webviewController.scrollTo(0, 0);
    promptAction.showToast({
      message: $r('app.string.web_snap_prompt_snapshotting'),
      duration: Constants.PROMPT_SNAPSHOT_DURATION
    });
    this.setPopupCenter();
    this.isShowSnapPopup = true;
    // 延时确保已经滚动到了顶部
    await sleep(Constants.SCROLL_DURATION);
  }

  /**
   * 截图之后的操作。
   * - 恢复web页面到截图之前的位置
   * - 取消遮罩层
   */
  async afterSnapshot() {
    this.webviewController.scrollTo(this.xOffsetBefore, this.yOffsetBefore);
    await sleep(Constants.SCROLL_DURATION);
    this.webMaskImageZIndex = -1;
    this.webMaskImage = undefined;
  }

  /**
   * 生成拼接后图片的操作。用于窗口形成移动的动画。
   */
  async afterGeneratorImage() {
    // 小窗在屏幕中间短暂停留，避免位置突变，无法形成动画
    await sleep(Constants.SCROLL_DURATION);
    // 修改弹窗位置，形成移动动画
    this.setPopupBottomLeft();
  }

  /**
   * 设置弹窗居中。
   */
  setPopupCenter() {
    this.snapPopupPosition = {
      x: (this.displayWidth - this.snapPopupWidth) / 2,
      y: (this.displayHeight - this.snapPopupHeight) / 2
    }
  }

  /**
   * 设置弹窗位置为左下。
   */
  setPopupBottomLeft() {
    this.snapPopupPosition = {
      x: Constants.POPUP_MARGIN_LEFT,
      y: this.displayHeight - this.snapPopupHeight - Constants.POPUP_MARGIN_BOTTOM
    }
  }

  /**
   * 保存图片到相册。
   */
  async saveSnapshot(result: SaveButtonOnClickResult) {
    // TODO: 知识点：使用SaveButton组件可以免申请权限，用户点击后，临时将文件存入系统目录
    if (result === SaveButtonOnClickResult.SUCCESS) {
      const helper = photoAccessHelper.getPhotoAccessHelper(this.context);
      // 使用保存控件
      try {
        // onClick触发后10秒内通过createAsset接口创建图片文件，10秒后createAsset权限收回。
        const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
        // 使用uri打开文件，可以持续写入内容，写入过程不受时间限制
        const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        const imagePackerApi: image.ImagePacker = image.createImagePacker();
        const packOpts: image.PackingOption = {
          format: Constants.SAVE_IMAGE_FORMAT,
          quality: Constants.SAVE_IMAGE_QUALITY,
        };
        imagePackerApi.packing(this.mergedImage, packOpts).then((data) => {
          fs.writeSync(file.fd, data);
          logger.info(TAG, `Succeeded in packToFile`);
          promptAction.showToast({
            message: $r('app.string.web_snap_saved_to_album'),
            duration: Constants.SAVED_TO_ALBUM_PROMPT_DURATION
          })
        }).catch((error: BusinessError) => {
          logger.error(TAG, `Failed to packToFile. Error code is ${error.code}, message is ${error.message}`);
        });
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        logger.error(TAG, `Failed to save photo. Error code is ${err.code}, message is ${err.message}`);
      }
    }
    this.closeSnapPopup();
  }

  /**
   * 关闭截图弹窗，恢复状态。
   */
  closeSnapPopup() {
    this.isShowSnapPopup = false; // 关闭模态窗口
    this.mergedImage = undefined; // 清除合并的图片
    this.snapPopupWidth = Constants.SNAP_WINDOW_WIDTH; // 恢复窗口大小
    this.snapPopupHeight = Constants.SNAP_WINDOW_HEIGHT;
    this.setPopupCenter(); // 窗口归位居中
    this.showPreview = false; // 缩小弹窗下，关闭按钮
  }

  /**
   * 当侧滑返回时，恢复初始状态。
   * 全屏模态窗口无法捕获返回键/右滑返回的事件，
   * 所以监听全屏模态窗口显隐flag捕获返回事件
   */
  onShowChanged() {
    if (this.isShowSnapPopup === false) {
      this.closeSnapPopup();
    }
  }

  /**
   * 截图时的弹窗。
   */
  @Builder
  screenShotPopup() {
    Column() {
      // 长截图未生成前显示提示语，生成后显示预览窗格
      if (this.mergedImage) {
        this.previewWindow();
      } else {
        // 提示截图中的弹窗
        Text($r('app.string.web_snap_popup_prompt_snapshotting'))
          .backgroundColor($r('app.string.web_snap_text_popup_backgroundcolor'))
          .borderRadius(Constants.BORDER_RADIUS)
          .width(Constants.TEXT_POPUP_WIDTH)
          .height(Constants.TEXT_POPUP_HEIGHT)
          .padding(Constants.TEXT_POPUP_PADDING)
      }
    }
    .width($r('app.string.web_snap_full_size'))
    .height(($r('app.string.web_snap_full_size')))
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 点击弹窗周围，缩小中间预览大窗到左下角
      if (this.showPreview) {
        this.snapPopupWidth = Constants.SNAP_WINDOW_WIDTH;
        this.snapPopupHeight = Constants.SNAP_WINDOW_HEIGHT;
        this.setPopupBottomLeft();
        this.previewerScroller.scrollTo({
          xOffset: 0,
          yOffset: this.previewerScrollYOffset *= (Constants.SNAP_WINDOW_WIDTH / Constants.SNAP_LARGE_WINDOW_WIDTH)
        });
        this.showPreview = false;
      }
    })
  }

  /**
   * 滚动查看图片的组件。
   */
  @Builder previewSnapshot() {
    Scroll(this.previewerScroller) {
      Column() {
        Image(this.mergedImage)
          .objectFit(ImageFit.Auto)
          .width(this.snapPopupWidth)
          .borderRadius(Constants.BORDER_RADIUS)
          .animation({
            duration: Constants.ANIMATE_DURATION,
            curve: Curve.Friction
          })
          .onClick(() => {
            // 点击打开预览大窗
            if (!this.showPreview) {
              this.snapPopupWidth = Constants.SNAP_LARGE_WINDOW_WIDTH;
              this.snapPopupHeight = Constants.SNAP_LARGE_WINDOW_HEIGHT;
              this.setPopupCenter();
              this.previewerScroller.scrollTo({
                xOffset: 0,
                yOffset: this.previewerScrollYOffset *= (Constants.SNAP_LARGE_WINDOW_WIDTH / Constants.SNAP_WINDOW_WIDTH)
              });
              this.showPreview = true;
            }
          })
      }
      .borderRadius(Constants.BORDER_RADIUS)
    }
    .width($r('app.string.web_snap_full_size'))
    .height($r('app.string.web_snap_full_size'))
    .onScroll(() => {
      this.previewerScrollYOffset = this.previewerScroller.currentOffset().yOffset;
    })
  }

  /**
   * 保存或取消保存的操作栏。
   */
  @Builder buttonBar() {
    Row() {
      SaveButton({
        icon: SaveIconStyle.FULL_FILLED,
        text: SaveDescription.SAVE_IMAGE,
        buttonType: ButtonType.Capsule
      })
        .onClick(async (event, result) => {
          this.saveSnapshot(result);
        })
        .backgroundColor($r('app.string.web_snap_button_backgrounp_color'))
        .width(Constants.BUTTON_WIDTH)

      Button($r('app.string.web_snap_cancel'))
        .backgroundColor($r('app.string.web_snap_button_backgrounp_color'))
        .width(Constants.BUTTON_WIDTH)
        .onClick(() => {
          // 恢复一切状态
          this.closeSnapPopup();
        })
    }
    .justifyContent(FlexAlign.SpaceEvenly)
    .width(this.snapPopupWidth)
    .height(Constants.BUTTON_BAR_HEIGHT)
    .padding({
      top: Constants.BUTTON_BAR_PADDING,
      bottom: Constants.BUTTON_BAR_PADDING
    })
    .backgroundColor($r('app.string.web_snap_window_bottom_backgrounp_color'))
    .animation({
      duration: Constants.ANIMATE_DURATION,
      curve: Curve.Friction
    })
    .borderRadius({
      bottomLeft: Constants.BORDER_RADIUS,
      bottomRight: Constants.BORDER_RADIUS
    })
    .transition(TransitionEffect.OPACITY.animation({
      duration: Constants.ANIMATE_DURATION,
      curve: Curve.Ease
    })
      .combine(TransitionEffect.scale({ y: Constants.BUTTON_BAR_SCALE }))
    )
    .visibility(this.showPreview ? Visibility.Visible : Visibility.Hidden)
  }

  /**
   * 截图后的预览窗口。
   */
  @Builder previewWindow() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 预览图片小窗
      this.previewSnapshot();

      // 保存按钮，预览大图时才显示
      this.buttonBar();
    }
    .width(this.snapPopupWidth)
    .height(this.snapPopupHeight)
    .position(this.snapPopupPosition)
    .border({
      width: Constants.BORDER_WIDTH,
      color: Constants.BORDER_COLOR,
      radius: Constants.BORDER_RADIUS
    })
    .animation({
      duration: Constants.ANIMATE_DURATION,
      curve: Curve.Friction
    })
    .gesture(
      PanGesture(this.panOption)
        .onActionStart(() => {
          this.xPositionBefore = this.snapPopupPosition.x as number;
        })
        .onActionUpdate((event) => {
          logger.debug(TAG, `Pan gesture offsetX: ${event.offsetX}.`);
          // 左滑弹窗关闭，但允许向右滑动一小部分，形成弹性效果，提升操作手感
          if (event.offsetX < Constants.POPUP_RIGHT_PAN_GESTURE) {
            this.snapPopupPosition.x = this.xPositionBefore + event.offsetX;
          }
        })
        .onActionEnd((event) => {
          // 左滑超过一定阈值才会触发关闭弹窗，提升用户体验
          if (event.offsetX < Constants.POPUP_LEFT_PAN_GESTURE && !this.showPreview) {
            logger.debug(TAG, `Colse popup offsetX: ${event.offsetX}.`);
            // 避免瞬间消失，而是平移动画后消失
            this.snapPopupPosition.x = Constants.POPUP_LEFT_SCREEN;
            sleep(Constants.ANIMATE_DURATION).then(() => {
              this.isShowSnapPopup = false;
            })
          } else if (!this.showPreview) {
            // 小窗预览时，右滑或者左滑没有达到阈值时恢复弹窗位置，结合动画属性形成弹性效果
            this.setPopupBottomLeft();
          }
        })
    )
  }
}