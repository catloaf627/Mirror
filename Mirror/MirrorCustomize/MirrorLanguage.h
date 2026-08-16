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

@end

NS_ASSUME_NONNULL_END
