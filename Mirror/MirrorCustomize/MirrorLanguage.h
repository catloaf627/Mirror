//
//  MirrorLanguage.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MirrorLanguageKey) {
    MirrorLanguageKeyEnglish = 0,
    MirrorLanguageKeySimplifiedChinese = 1,
    MirrorLanguageKeySpanish = 2,
    MirrorLanguageKeyFrench = 3,
    MirrorLanguageKeyJapanese = 4,
    MirrorLanguageKeyKorean = 5,
    MirrorLanguageKeyGerman = 6,
    MirrorLanguageKeyRussian = 7,
};

@interface MirrorLanguage : NSObject

+(NSString *)mirror_stringWithKey:(NSString *)key; // 无参数
+ (NSString *)mirror_stringWithKey:(NSString *)key languageKey:(MirrorLanguageKey)languageKey;
+ (NSString *)mirror_stringWithKey:(NSString *)key
                  with1Placeholder:(NSString *)placeholder; // 1参数
+ (NSString *)mirror_stringWithKey:(NSString *)key
                  with1Placeholder:(NSString *)placeholder1
                  with2Placeholder:(NSString *)placeholder2; // 2参数
+ (NSString *)mirror_dateStringWithYear:(long)year
                                  month:(long)month
                                    day:(long)day
                                weekday:(long)weekday;
+ (NSString *)mirror_shortDateStringWithMonth:(long)month
                                          day:(long)day
                                      weekday:(long)weekday; // 不带年份的短日期
+ (NSString *)mirror_dateStringWithYear:(long)year
                                  month:(long)month
                                    day:(long)day;
+ (NSString *)mirror_monthStringWithYear:(long)year
                                   month:(long)month;

@end

NS_ASSUME_NONNULL_END
