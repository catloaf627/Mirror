//
//  MirrorLanguage.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import "MirrorLanguage.h"
#import "MirrorSettings.h"

@implementation MirrorLanguage

+ (NSString *)mirror_stringWithKey:(NSString *)key
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];
    
    // tabs
    [mirrorDict setValue:@[@"Start", @"计时"] forKey:@"start"];
    [mirrorDict setValue:@[@"Today", @"今天"] forKey:@"today"];
    [mirrorDict setValue:@[@"Data", @"数据"] forKey:@"data"];
    [mirrorDict setValue:@[@"Record", @"记录"] forKey:@"record"];
    
    // Settings
    [mirrorDict setValue:@[@"Use Chinese", @"使用中文"] forKey:@"apply_chinese"];
    [mirrorDict setValue:@[@"Weeks start on Monday", @"周一作为一周的第一天"] forKey:@"week_starts_on_Monday"];
    [mirrorDict setValue:@[@"Show record indexes", @"展示记录的序号"] forKey:@"show_record_indexes"];
    [mirrorDict setValue:@[@"Histogram on Data", @"数据页使用柱状图"] forKey:@"show_histogram_on_data"];
    [mirrorDict setValue:@[@"Piechart on Record", @"记录页使用饼状图"] forKey:@"show_piechart_on_record"];
    [mirrorDict setValue:@[@"Heatmap on Record", @"记录页使用热力图"] forKey:@"heatmap"];
    [mirrorDict setValue:@[@"Export/Import data", @"导出/导入数据"] forKey:@"export_import_data"];
    [mirrorDict setValue:@[@"Export or import data?", @"选择导入或是导出"] forKey:@"export_or_import"];
    [mirrorDict setValue:@[@"Export data", @"导出数据"] forKey:@"export_data"];
    [mirrorDict setValue:@[@"Import data", @"导入数据"] forKey:@"import_data"];
    [mirrorDict setValue:@[@"Import data?", @"确认导入该数据？"] forKey:@"import_data_?"];
    [mirrorDict setValue:@[@"Current data will be replaced by the imported data", @"导入后当前的数据将被覆盖"] forKey:@"import_data_?_message"];
    [mirrorDict setValue:@[@"Import", @"导入"] forKey:@"import"];
    [mirrorDict setValue:@[@"Wrong data format", @"数据格式错误"] forKey:@"wrong_data_format"];
    [mirrorDict setValue:@[@"OK", @"好的"] forKey:@"ok"];
    [mirrorDict setValue:@[@"Contact me", @"联系作者"] forKey:@"contact_me"];
    [mirrorDict setValue:@[@"Copy author's email address to clipboard", @"拷贝作者邮箱地址到剪切板"] forKey:@"copy_email_address_to_clipboard"];
    [mirrorDict setValue:@[@"Copy", @"拷贝"] forKey:@"copy"];
    
    // Profile edit cell
    [mirrorDict setValue:@[@"Save", @"保存"] forKey:@"save"];
    [mirrorDict setValue:@[@"Remove", @"移掉"] forKey:@"remove"];
    [mirrorDict setValue:@[@"Delete", @"删除"] forKey:@"delete"];
    [mirrorDict setValue:@[@"Archive", @"归档"] forKey:@"archive"];
    [mirrorDict setValue:@[@"Cancel", @"取消"] forKey:@"cancel"];
    // Profile add cell
    [mirrorDict setValue:@[@"Enter task title", @"输入任务名称"] forKey:@"enter_task_title"];
    [mirrorDict setValue:@[@"Create", @"创建"] forKey:@"create"];
    [mirrorDict setValue:@[@"Discard", @"放弃"] forKey:@"discard"];
    [mirrorDict setValue:@[@"Enter a title to create a new task", @"输入名称以创建新的任务"] forKey:@"add_taskname_hint"];
    [mirrorDict setValue:@[@"Name field cannot be empty", @"任务名不能为空"] forKey:@"name_field_cannot_be_empty"];
    [mirrorDict setValue:@[@"Gotcha", @"知道啦"] forKey:@"gotcha"];
    [mirrorDict setValue:@[@"Task cannot be duplicated", @"任务不可重复"] forKey:@"task_cannot_be_duplicated"];
    [mirrorDict setValue:@[@"This task exists in the current task list", @"这个任务已经存在于当前任务列表中"] forKey:@"this_task_exists_in_current_task_list"];
    [mirrorDict setValue:@[@"This task exists in the archived task list. You can activate it in [Data]", @"这个任务已经存在于归档任务列表中。你可以在【数据】中重新激活此任务。"] forKey:@"this_task_exists_in_the_archived_task_list"];
    
    // 全屏
    [mirrorDict setValue:@[@"Go!", @"开始!"] forKey:@"go"];
    [mirrorDict setValue:@[@"Give up", @"放弃"] forKey:@"give_up"];
    [mirrorDict setValue:@[@"Stop", @"结束"] forKey:@"stop"];
    
    // Task record
    [mirrorDict setValue:@[@"Counting...", @"计时中..."] forKey:@"counting"];
    [mirrorDict setValue:@[@"Lasted: ", @"持续时间："] forKey:@"lasted"];
    [mirrorDict setValue:@[@" (Archived) ", @"（已归档）"] forKey:@"archived_tag"];
    
    // Delete period
    [mirrorDict setValue:@[@"Delete this time period? ", @"确定删除这个时间段？"] forKey:@"delete_period_?"];
    
    // Time VC
    [mirrorDict setValue:@[@"Go to edit page(upper right) to reorder tasks" , @"进入编辑页面（右上角）可以编辑顺序"] forKey:@"timeVC_hint0"];
    [mirrorDict setValue:@[@"Go to edit page(upper right) to edit tasks" , @"进入编辑页面（右上角）可以编辑任务"] forKey:@"timeVC_hint1"];
    [mirrorDict setValue:@[@"Archived tasks will not be displayed on the main page" , @"已经归档的任务将不会展示在主页面"] forKey:@"timeVC_hint2"];
    [mirrorDict setValue:@[@"Up to 8 tasks can be created" , @"最多可建立8个任务"] forKey:@"timeVC_hint3"];
    
    // All tasks
    [mirrorDict setValue:@[@"Long press to reorder tasks" , @"长按拖动可以编辑顺序"] forKey:@"alltasks_hint0"];
    [mirrorDict setValue:@[@"Tap task name to edit" , @"轻点任务名可编辑"] forKey:@"alltasks_hint1"];
    [mirrorDict setValue:@[@"Archived tasks will not be displayed on the main page" , @"已经归档的任务将不会展示在主页面"] forKey:@"alltasks_hint2"];
    [mirrorDict setValue:@[@"Up to 8 tasks can be created" , @"最多可建立8个任务"] forKey:@"alltasks_hint3"];
    [mirrorDict setValue:@[@"Delete this task? ", @"确定删除这个任务？"] forKey:@"delete_task_?"];
    [mirrorDict setValue:@[@"Created at " , @"创建于 "] forKey:@"created_at"];
    [mirrorDict setValue:@[@"Edit tasks" , @"编辑任务"] forKey:@"edit_tasks"];
    
    // History type switch
    [mirrorDict setValue:@[@"Day", @"日"] forKey:@"segment_day"];
    [mirrorDict setValue:@[@"Week", @"周"] forKey:@"segment_week"];
    [mirrorDict setValue:@[@"Month", @"月"] forKey:@"segment_month"];
    [mirrorDict setValue:@[@"Year", @"年"] forKey:@"segment_year"];
    
    // 星期
    [mirrorDict setValue:@[@"Sun", @"周日"] forKey:@"sunday"];
    [mirrorDict setValue:@[@"Mon", @"周一"] forKey:@"monday"];
    [mirrorDict setValue:@[@"Tue", @"周二"] forKey:@"tuesday"];
    [mirrorDict setValue:@[@"Wed", @"周三"] forKey:@"wednesday"];
    [mirrorDict setValue:@[@"Thu", @"周四"] forKey:@"thursday"];
    [mirrorDict setValue:@[@"Fri", @"周五"] forKey:@"friday"];
    [mirrorDict setValue:@[@"Sat", @"周六"] forKey:@"saturday"];
    
    // 月份
    [mirrorDict setValue:@[@"Jan", @"1月"] forKey:@"january"];
    [mirrorDict setValue:@[@"Feb", @"2月"] forKey:@"february"];
    [mirrorDict setValue:@[@"Mar", @"3月"] forKey:@"march"];
    [mirrorDict setValue:@[@"Apr", @"4月"] forKey:@"april"];
    [mirrorDict setValue:@[@"May", @"5月"] forKey:@"may"];
    [mirrorDict setValue:@[@"Jun", @"6月"] forKey:@"june"];
    [mirrorDict setValue:@[@"Jul", @"7月"] forKey:@"july"];
    [mirrorDict setValue:@[@"Aug", @"8月"] forKey:@"august"];
    [mirrorDict setValue:@[@"Sep", @"9月"] forKey:@"september"];
    [mirrorDict setValue:@[@"Oct", @"10月"] forKey:@"october"];
    [mirrorDict setValue:@[@"Nov", @"11月"] forKey:@"november"];
    [mirrorDict setValue:@[@"Dec", @"12月"] forKey:@"december"];
    
    
    
    // Span histogram empty hint
    [mirrorDict setValue:@[@"No data", @"暂无数据"] forKey:@"no_data"];
    // Today empty hint
    [mirrorDict setValue:@[@"No task today", @"今天暂无任务"] forKey:@"no_data_today"];
    
    // today total
    [mirrorDict setValue:@[@"Total: ", @"总时长："] forKey:@"total"];
    
    // Time editing (这个页面需要的save，上面已经有了)
    [mirrorDict setValue:@[@"Starts at", @"开始时间"] forKey:@"starts_at"];
    [mirrorDict setValue:@[@"OR", @"或"] forKey:@"or"];
    [mirrorDict setValue:@[@"\"Now\" is occupied by the other task", @"当前时间已被其他任务占用"] forKey:@"now_is_occupied"];
    
    [mirrorDict setValue:@[@"Start now", @"开始计时"] forKey:@"start_now"];
    [mirrorDict setValue:@[@" hours", @" 小时"] forKey:@"picker_hours"];
    [mirrorDict setValue:@[@" mins", @" 分钟"] forKey:@"picker_mins"];
    [mirrorDict setValue:@[@" hour", @" 小时"] forKey:@"picker_hour"];
    [mirrorDict setValue:@[@" min", @" 分钟"] forKey:@"picker_min"];
    
    // All records
    [mirrorDict setValue:@[@"All records", @"所有记录"] forKey:@"all_records"];
    [mirrorDict setValue:@[@"Records", @"记录"] forKey:@"records"];
    
    // Motto
    [mirrorDict setValue:@[@"Something you want to keep in mind?", @"想记下来什么？"] forKey:@"motto"];
    
    
    NSInteger index = [MirrorSettings appliedChinese] ? 1 : 0;
    return [mirrorDict valueForKey:key][index];
}


+ (NSString *)mirror_stringWithKey:(NSString *)key
                  with1Placeholder:(NSString *)placeholder
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];

    // 时间
    [mirrorDict setValue:@[@"%@h ", @"%@时"] forKey:@"h"];
    [mirrorDict setValue:@[@"%@m ", @"%@分"] forKey:@"m"];
    [mirrorDict setValue:@[@"%@s", @"%@秒"] forKey:@"s"];
    
    [mirrorDict setValue:@[@"%@ hour ", @"%@小时"] forKey:@"hour"];
    [mirrorDict setValue:@[@"%@ min ", @"%@分钟"] forKey:@"min"];
    [mirrorDict setValue:@[@"%@ second", @"%@秒"] forKey:@"second"];
    
    [mirrorDict setValue:@[@"%@ hours ", @"%@小时"] forKey:@"hours"];
    [mirrorDict setValue:@[@"%@ mins ", @"%@分钟"] forKey:@"mins"];
    [mirrorDict setValue:@[@"%@ seconds", @"%@秒"] forKey:@"seconds"];
    
    NSInteger index = [MirrorSettings appliedChinese] ? 1 : 0;
    return [NSString stringWithFormat:[mirrorDict valueForKey:key][index], placeholder];
}

@end
