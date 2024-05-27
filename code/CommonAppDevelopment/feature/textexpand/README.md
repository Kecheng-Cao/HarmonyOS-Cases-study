# 文字展开收起案例

### 介绍

本示例介绍了[@ohos.measure](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-measure-0000001774280802)
组件接口实现文字展开收起的功能。
该场景多用于图文列表展示等。

### 效果图预览

<img src="../../product/entry/src/main/resources/base/media/text_expand.gif" width="300">

**使用说明**：

* 点击展开按钮，展开全部文字。
* 点击收起按钮，收起多余文字。

## 实现步骤

想要实现文字收起，难点在于如何判断展示多少文字可以达到只显示到指定行数（以两行为例）的目的。通过判断文字其在容器内的高度来将文字缩减到指定行数，可以实现收起效果的目的。利用 [measure.measureTextSize](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-measure-0000001774280802#ZH-CN_TOPIC_0000001811158890__measuremeasuretextsize10)
方法去分别计算文字总体的高度和两行文字的高度，再进行缩减文字，直到文字高度符合两行文字的要求。

1. 使用measure.measureTextSize方法来判断总体文字的高度

```ts
let titleSize: SizeOptions = measure.measureTextSize({
  textContent: this.rawTitle, // 被计算文本内容
  constraintWidth: 350, // 被计算文本布局宽度
  fontSize: 16 // 被计算文本字体大小
})
```

2. 使用measure.measureTextSize方法来判断两行文字的高度，当前为两行文字的高度

```ts
let twoLineSize: SizeOptions = measure.measureTextSize({
  textContent: this.rawTitle,
  constraintWidth: 350,
  fontSize: 16,
  maxLines: 2  // 被计算文本最大行数
})
```

3. 减少接收文字字符数。当接收文字高度小于指定行数高度时，使文字显示两行，达到实现收起状态的目的。否则继续计算直到小于指定行数的高度

```ts
while (Number(titleSize.height) > Number(twoLineSize.height)) {
  clipTitle = clipTitle.substring(0, clipTitle.length - 1); // 每次减少一个字符长度，再进行比较计算，直到符合高度要求
  titleSize = measure.measureTextSize({
    textContent: clipTitle + '...' + '展开', // 按钮文字也要放入进行计算
    constraintWidth: 350,
    fontSize: 16
  });
}
```

### 高性能知识点

**不涉及**

### 工程结构&模块类型

   ```
   textexpand                                         // har
   |---component                                         
   |   |---ItemPart.ets                               // 文字展开收起组件
   |---view
   |   |---TextExpand.ets                             // TextExpand 页面
   ```

### 模块依赖

1. 本实例依赖common模块来获取[日志工具类logger](../../common/utils/src/main/ets/log/Logger.ets)。

### 参考资料

[@ohos.measure](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-measure-0000001774280802)
