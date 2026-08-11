//
//  MirrorLanguage.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorLanguage : NSObject

+(NSString *)mirror_stringWithKey:(NSString *)key; // 无参数
+ (NSString *)mirror_stringWithKey:(NSString *)key languageKey:(NSInteger)languageKey;
+ (NSString *)mirror_stringWithKey:(NSString *)key
                  with1Placeholder:(NSString *)placeholder; // 1参数
+ (NSString *)localizedSampleTaskNameWithEnglishName:(NSString *)englishName;
+ (NSArray<NSString *> *)localizedSampleTaskNamesForEnglishName:(NSString *)englishName;
+ (NSString *)localizedSampleRecordNoteForEnglishTaskName:(NSString *)englishName index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
