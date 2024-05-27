# Text实现部分文本高亮和超链接样式

### 介绍

本示例通过自定义Span类型，在Text组件中使用ForEach遍历，根据不同的Span类型生成不同样式和功能的Span组件，实现部分文本高亮和超链接。

### 效果图预览

![](../../product/entry/src/main/resources/base/media/styled_text.gif)

**使用说明**

1. 点击超链接，根据链接类型出现相应提示弹窗。
2. 长按消息卡片出现提示弹窗。

### 实现思路

1. 定义 CustomSpanType 枚举类型，此处定义了 Normal、Hashtag、Mention、VideoLink 和 DetailLink 五种类型。

```ts
export enum CustomSpanType {
  Normal, // 普通文本，不含任何特殊格式或标记
  Hashtag, // 话题标签
  Mention, // @提及
  VideoLink, // 视频链接
  DetailLink // 正文详情
}
```

2. 创建 CustomSpan 数据类，用于表示不同类型的 Span 对象。

```ts
export class CustomSpan {
  type: CustomSpanType; // 文本类型
  content: string; // 文本内容
  url?: string; // 跳转的链接地址

  constructor(type: CustomSpanType = CustomSpanType.Normal, content: string, url?: string) {
    this.type = type;
    this.content = content;
    if (url) {
      this.url = url;
    }
  }
}
```

3. 使用 Text 组件结合 ForEach 方法遍历 spans 中的 CustomSpan 对象，根据不同的 Span 类型生成不同样式和功能的 Span 组件。

```ts
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
```

4. 对于 Normal 类型的 Span，直接使用 Span 组件展示文本内容，并设置相应的样式。

```ts
Span(item.content)
  .fontSize($r('app.string.ohos_id_text_size_body1'))
```
5. 对于 Hashtag、Mention 和 DetailLink 类型的 Span，在 TextLinkSpan 组件中添加带有超链接功能的 Span 组件，根据 CustomSpan 的类型和内容，实现对应的样式和交互功能，例如显示提示信息或执行其他操作。

```ts
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

  build(){
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
```

6. 对于 VideoLink 类型的 Span，使用 VideoLinkSpan 组件添加图标和超链接功能，在点击事件中显示提示信息或执行跳转视频页操作。

```ts
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
```

### 高性能知识点

本示例使用了[LazyForEach](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V4/arkts-rendering-control-lazyforeach-0000001820879609-V4?catalogVersion=V4)进行数据懒加载

### 工程结构&模块类型

   ```
   styledtext                                   // har类型
   |---/src/main/ets/mock                        
   |   |---MockData.ets                         // mock数据
   |---/src/main/ets/model                        
   |   |---DataSource.ets                       // 列表数据模型                        
   |   |---TextModel.ets                        // 数据类型定义
   |---/src/main/ets/pages                        
   |   |---StyledText.ets                       // 视图层-主页面
   ```

### 模块依赖

1. 本实例依赖[common模块](../../common/utils/src/main/resources)中的资源文件。
2. 本示例依赖[动态路由模块](../../feature/routermodule/src/main/ets/router/DynamicsRouter.ets)来实现页面的动态加载。

### 参考资料

[Text组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-text-0000001815927600)

[Span组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-span-0000001862607421)

[ContainerSpan组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-containerspan-0000001862607393)