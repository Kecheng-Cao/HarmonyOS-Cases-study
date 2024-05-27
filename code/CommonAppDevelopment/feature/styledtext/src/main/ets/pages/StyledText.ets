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

import { CustomMessage, CustomSpan, CustomSpanType } from '../model/TextModel';
import { AppRouter } from '@ohos/dynamicsrouter/Index';
import { MessageListDataSource } from '../model/DataSource';
import { MESSAGES_DATA } from '../mock/MockData';
import { promptAction } from '@kit.ArkUI';

/**
 * 实现步骤：
 * 1. 定义 CustomSpanType 枚举类型，此处定义了 Normal、Hashtag、Mention、VideoLink 和 DetailLink 五种类型。
 * 2. 创建 CustomSpan 数据类，用于表示不同类型的 Span 对象。
 * 3. 使用 Text 组件结合 ForEach 方法遍历 spans 中的 CustomSpan 对象，根据不同的 Span 类型生成不同样式和功能的 Span 组件。
 * 4. 对于 Normal 类型的 Span，直接使用 Span 组件展示文本内容，并设置相应的样式。
 * 5. 对于 Hashtag、Mention 和 DetailLink 类型的 Span，使用 TextLinkSpan 生成带有超链接功能的 Span 组件，根据 CustomSpan 的类型和内容，实现对应的样式和交互功能，例如显示提示信息或执行其他操作。
 * 6. 对于 VideoLink 类型的 Span，使用 VideoLinkSpan 组件添加图标和超链接功能，在点击事件中显示提示信息或执行跳转视频页操作。
 */

const BACKGROUND_CHANGE_DELAY: number = 100; // 链接变色延迟
const BORDER_RADIUS: number = 24; // 用户头像圆角
const CACHED_COUNT: number = 2; // 消息列表懒加载数量
const LAYOUT_WEIGHT: number = 1; // 组件自动分配剩余空间
const MAX_STRING_LENGTH: number = 140; // 正文内容最大字符长度

@AppRouter({ name: "styledtext/StyledTextMainPage" })
@Component
export struct StyledTextMainPage {
  private mockMessages: MessageListDataSource = new MessageListDataSource(); // 消息列表数据

  aboutToAppear(): void {
    // 初始化数据
    this.loadData();
  }

  loadData() {
    MESSAGES_DATA.forEach((item => {
      this.mockMessages.pushData(item);
    }))
  }

  build() {
    List() {
      /**
       * 性能知识点：列表中数据较多且不确定的情况下，使用LazyForEach进行数据循环渲染。
       * 当组件滑出可视区域外时，框架会进行组件销毁回收以降低内存占用。
       * 文档参考链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-rendering-control-lazyforeach-0000001820879609
       */
      LazyForEach(this.mockMessages, (messageItem: CustomMessage) => {
        ListItem() {
          MessageItem({ messageItem: messageItem })
        }
      })
    }
    .cachedCount(CACHED_COUNT)
    .width($r('app.string.styled_text_layout_100'))
    .height($r('app.string.styled_text_layout_100'))
    .divider({
      strokeWidth: $r('app.integer.styled_text_list_divider_width'),
      color: $r('app.color.styled_text_list_divider_color'),
      startMargin: $r('app.string.ohos_id_card_margin_start'),
      endMargin: $r('app.string.ohos_id_card_margin_start')
    })
    .onReachEnd(() => {
      this.loadData();
    })
  }
}

// 消息组件
@Component
struct MessageItem {
  @State messageBackgroundColor: Color | Resource = $r('app.color.ohos_id_color_background'); // 消息卡片背景色
  private messageItem: CustomMessage = new CustomMessage($r('app.media.styled_text_user_image1'), ``, ``, []);
  private spans: CustomSpan[] = []; // 经过处理后的自定义span列表数据

  aboutToAppear(): void {
    this.processCustomMessage(this.messageItem);
  }

  // 判断正文内容是否超过140字符，超过140需要截取字符串并显示...全文
  processCustomMessage(customMessage: CustomMessage): void {
    let charCount = 0; // 遍历拼接customMessage.spans，记录已拼接的字符串长度
    let spans: CustomSpan[] = []; // 用于存储处理后的文本

    customMessage.spans.forEach((span, index) => {
      if (charCount >= MAX_STRING_LENGTH) {
        return;
      }
      if (charCount + span.content.length >= MAX_STRING_LENGTH) {
        if (span.type === CustomSpanType.Normal) {
          // 正文内容下标140处为普通文本，截取该文本到下标140的字符串并拼接...
          spans.push(new CustomSpan(CustomSpanType.Normal, `${span.content.substring(0, MAX_STRING_LENGTH - charCount)}...`));
        } else {
          // 正文内容下标140处为非普通文本，不截断直接拼接...
          spans.push(new CustomSpan(CustomSpanType.Normal, '...'));
        }
        // 添加全文链接文本
        spans.push(new CustomSpan(CustomSpanType.DetailLink, '全文'));
        return;
      } else {
        spans.push(span);
      }
      charCount += span.content.length;
    })
    this.spans = spans;
  }

  // 分享、点赞、评论UI组件
  @Builder
  otherFunction(imageStr: Resource, text: string | Resource) {
    Row() {
      Image(imageStr)
        .height($r('app.integer.styled_text_other_function_image_width'))
        .width($r('app.integer.styled_text_other_function_image_width'))
        .objectFit(ImageFit.Contain)
        .autoResize(false)
      Text(text)
        .fontSize($r('app.string.ohos_id_text_size_body2'))
        .fontColor($r('app.color.styled_text_default_font_color'))
        .fontFamily('HarmonyHeiTi')
        .opacity($r('app.string.styled_text_other_function_text_opacity'))
        .margin({ left: $r('app.integer.styled_text_other_function_text_margin_left') })
    }
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      promptAction.showToast({
        message: $r('app.string.styled_text_other_function'),
      });
    })
  }

  build() {
    Column() {
      // 用户信息
      Row() {
        Image(this.messageItem.profile)
          .width($r('app.integer.styled_text_profile_image_width'))
          .height($r('app.integer.styled_text_profile_image_width'))
          .borderRadius(BORDER_RADIUS)
          .margin({ right: $r('app.integer.styled_text_profile_image_right') })
        Column() {
          Text(this.messageItem.userName)
            .fontSize($r('app.string.ohos_id_text_size_headline'))
            .fontColor($r('app.color.styled_text_user_name_color'))
          Text(this.messageItem.subTitle)
            .fontSize($r('app.string.ohos_id_text_size_body1'))
            .fontColor($r('app.color.styled_text_subtitle_color'))
        }
        .layoutWeight(LAYOUT_WEIGHT)
        .height($r('app.string.styled_text_layout_100'))
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Start)
      }
      .width($r('app.string.styled_text_layout_100'))
      .height($r('app.integer.styled_text_profile_height'))

      // 文本消息，一次加载完成，不使用LazyForEach
      // TODO：知识点：Text组件通过ForEach遍历文本数据，根据文本数据的类型渲染相应的组件，实现部分文本的特殊样式和点击处理。
      Text() {
        ForEach(this.spans, (item: CustomSpan) => {
          if (item.type === CustomSpanType.Normal) {
            Span(item.content)
              .fontSize($r('app.string.ohos_id_text_size_body1'))
          } else if (item.type === CustomSpanType.Hashtag || item.type === CustomSpanType.Mention || item.type === CustomSpanType.DetailLink) {
            TextLinkSpan({ item: item })
          } else {
            VideoLinkSpan({ item: item })
          }
        })
      }
      .width($r('app.string.styled_text_layout_100'))
      .fontSize($r('app.string.ohos_id_text_size_body1'))
      .margin({ top: $r('app.string.ohos_id_card_margin_start') })

      // 附图
      Stack() {
        if (this.messageItem.media) {
          Image(this.messageItem.media)
            .width($r('app.integer.styled_text_message_media'))
            .margin({ top: $r('app.string.ohos_id_card_margin_start') })
        }
      }

      // 分享、点赞、评论组件
      Row() {
        this.otherFunction($r('app.media.styled_text_ic_share'), $r('app.string.styled_text_share'))
        this.otherFunction($r('app.media.styled_text_ic_thumbsup'), $r('app.string.styled_text_thumbsup'))
        this.otherFunction($r('app.media.styled_text_ic_message'), $r('app.string.styled_text_message'))
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width($r('app.string.styled_text_layout_100'))
      .margin({
        top: $r('app.integer.styled_text_other_function_margin_top')
      })
    }
    .backgroundColor(this.messageBackgroundColor)
    .padding($r('app.string.ohos_id_card_padding_start'))
    .onClick(() => {
      promptAction.showToast({
        message: $r('app.string.styled_text_content_details_toast_message')
      });
    })
    .gesture(
      // 长按修改消息卡片整体背景色，可实现长按分享等功能
      LongPressGesture()
        .onAction((event?: GestureEvent) => {
          if (event) {
            this.messageBackgroundColor = $r('app.color.styled_text_long_press_background_color');
            promptAction.showToast({
              message: $r('app.string.styled_text_demo_function_message')
            });
          }
        })// 长按动作一结束触发
        .onActionEnd(() => {
          this.messageBackgroundColor = $r('app.color.ohos_id_color_background');
        })
    )
    .alignItems(HorizontalAlign.Start)
  }
}

// 仅文本的超链接Span组件
@Component
struct TextLinkSpan {
  @State linkBackgroundColor: Color | Resource = Color.Transparent; // 超链接背景色
  private item: CustomSpan = new CustomSpan(CustomSpanType.Normal, '');
  @State myItem: CustomSpan = this.item;

  aboutToAppear(): void {
    // LazyForEach中Text组件嵌套自定义组件会有数据初次不渲染问题，异步修改状态变量更新视图
    setTimeout(() => {
      this.myItem = this.item;
    })
  }

  build() {
    Span(this.myItem.content)
      .fontColor($r('app.color.styled_text_link_font_color'))// 超链接字体颜色
      .fontSize($r('app.string.ohos_id_text_size_body1'))
      .textBackgroundStyle({ color: this.linkBackgroundColor })
      .onClick(() => {
        this.linkBackgroundColor = $r('app.color.styled_text_link_clicked_background_color'); // 点击后的背景色
        setTimeout(() => {
          this.linkBackgroundColor = Color.Transparent;
        }, BACKGROUND_CHANGE_DELAY)
        // 根据文本超链接的类型做相应处理
        if (this.myItem.type === CustomSpanType.Hashtag) {
          promptAction.showToast({
            message: $r('app.string.styled_text_hashtag_toast_message')
          });
        } else if (this.myItem.type === CustomSpanType.Mention) {
          promptAction.showToast({
            message: $r('app.string.styled_text_user_page_toast_message')
          });
        } else {
          promptAction.showToast({
            message: $r('app.string.styled_text_content_details_toast_message')
          });
        }
      })
  }
}


// 带有图标的视频链接Span组件
@Component
struct VideoLinkSpan {
  @State linkBackgroundColor: Color | Resource = Color.Transparent;
  private item: CustomSpan = new CustomSpan(CustomSpanType.Normal, '');
  @State myItem: CustomSpan = this.item;

  aboutToAppear(): void {
    // LazyForEach中Text组件嵌套自定义组件会有数据初次不渲染问题，异步修改状态变量更新视图
    setTimeout(() => {
      this.myItem = this.item;
    })
  }

  build() {
    ContainerSpan() {
      ImageSpan($r('app.media.styled_text_ic_public_video'))
        .height($r('app.integer.styled_text_video_link_icon_height'))
        .verticalAlign(ImageSpanAlignment.CENTER)
      Span(this.myItem.content)
        .fontColor($r('app.color.styled_text_link_font_color'))
        .fontSize($r('app.string.ohos_id_text_size_body1'))
        .onClick(() => {
          this.linkBackgroundColor = $r('app.color.styled_text_link_clicked_background_color');
          setTimeout(() => {
            this.linkBackgroundColor = Color.Transparent;
          }, BACKGROUND_CHANGE_DELAY)
          promptAction.showToast({
            message: $r('app.string.styled_text_video_function_message')
          });
        })
    }
    .textBackgroundStyle({ color: this.linkBackgroundColor })
  }
}
