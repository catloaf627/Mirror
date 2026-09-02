//
//  TimelineBackgroundView.h
//  Mirror
//

#import <UIKit/UIKit.h>

@class TimelineBackgroundView;

NS_ASSUME_NONNULL_BEGIN

@protocol TimelineBackgroundViewDelegate <NSObject>

- (long)timelineView:(TimelineBackgroundView *)timelineView timestampForTimelineY:(CGFloat)y;
- (void)timelineView:(TimelineBackgroundView *)timelineView didSelectTaskName:(NSString *)taskName startTimestamp:(long)startTimestamp;
- (void)timelineView:(TimelineBackgroundView *)timelineView didSelectScheduleStartTimestamp:(long)startTimestamp;

@optional
- (BOOL)timelineViewShouldBeginAddingRecord:(TimelineBackgroundView *)timelineView;

@end

@interface TimelineBackgroundView : UIView

@property (nonatomic, weak) id<TimelineBackgroundViewDelegate> delegate;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, assign) CGFloat bottomInset;
@property (nonatomic, assign) BOOL showsScheduleOption;
@property (nonatomic, assign) BOOL showsTaskOptions;

- (void)dismissTaskPicker;

@end


/*
Record 有三种状态
• Idle：普通状态，背景是 task color alpha=0.7，文字是 pulse color。
• TapSelected：短按选中，显示 border + 上下两个小圆点，可拖动/改开始/改结束。
• LongSelected：长按选中，不显示 border/圆点，只把背景 alpha 提到 1.0，然后弹 edit menu。

短按
• 点 record 触发 tapRecordView:。
• 如果当前 cell 已经在编辑态，会 endInlineEditing，相当于取消选中。
• 否则通知 VC：timelineRecordViewDidRequestInlineEditing:。
• VC 走 beginTapSelectionForRecordView:，最后调用：
beginInlineEditingWithMinimumTimestamp:...
• 进入 TapSelected 后：
   • allowsMoveDrag = YES
   • pan 手势允许开始
   • 显示 border + handles
   • 可以整体拖、拖 start、拖 end

长按
• 长按 record 触发 longPressRecordView:。
• 通知 VC：timelineRecordViewDidRequestLongSelection:。
• VC 走 beginLongSelectionForRecordView:，最后调用：
beginLongSelectionWithMinimumTimestamp:...
• 进入 LongSelected 后：
   • allowsMoveDrag = NO
   • pan 手势不允许开始
   • 不显示 border/handles
   • 只做 alpha 高亮并弹出 UIEditMenuInteraction
   • 必须点 menu/picker 里的 edit/delete 等操作才修改

切换选中 cell
• 不管当前是短按选中还是长按选中，短按/长按另一个 record 时，VC 会先结束旧的 activeRecordView，再选中新 record。
• 也就是说选中态不会锁死在一个 cell 上。

点击空白处
• TimelineBackgroundView 点空白时会先问 VC：timelineViewShouldBeginAddingRecord:。
• 如果当前有 activeRecordView，VC 会结束选中并返回 NO。
• 所以有短按或长按选中时，点空白只取消选择，不会新增 record。

滚动
• TimelineRecordView 的 pan 只有 TapSelected 才能开始：
gestureRecognizerShouldBegin 里判断 selectionState == TapSelected。
• 长按选中时不会吃掉拖动编辑手势。
• VC 现在没有真的禁用 timelineScrollView.scrollEnabled，所以滚动主要靠手势命中区域和 pan 是否能 begin 来协调。
 
 
 用户使用逻辑可以这样理解：

 1. 普通状态
    • 直接上下滑动：滚动时间轴。
    • 点空白处：新增一条记录。

 2. 短按一条记录
    • 进入“时间微调模式”。
    • 这条记录会显示边框和上下两个小圆点。
    • 拖记录中间：整体移动这段时间。
    • 拖上面的小圆点：改开始时间。
    • 拖下面的小圆点：改结束时间。
    • 再点这条记录或点空白处：退出这个模式。
    • 点/长按其他记录：切换到其他记录。

 3. 长按一条记录
    • 进入“菜单编辑模式”。
    • 这条记录只变得更实一些，不显示边框和小圆点。
    • 用户不能直接拖动它改时间。
    • 必须从弹出的菜单里选择操作，比如 edit/delete。
    • 点空白处：退出这个模式，不新增记录。
    • 点/长按其他记录：切换到其他记录。

 4. 滚动规则
    • 没有选中记录时，正常滚动。
    • 有记录被短按选中时，如果手指从这条选中的记录上开始拖，就是编辑时间；如果从别的地方开始拖，就是滚动时间轴。
    • 长按选中时不支持拖动编辑，所以拖动应该还是滚动为主。
 
*/

NS_ASSUME_NONNULL_END
