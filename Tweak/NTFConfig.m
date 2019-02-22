#include "NTFConfig.h"

@implementation NTFConfig

-(NTFConfig *)initWithSub:(NSString*)sub prefs:(id)prefs colors:(NSDictionary*)colors {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    #ifndef SIMULATOR
    NSString *prefix = [@"NTF" stringByAppendingString:sub];

    for (NSString *key in [((HBPreferences *)prefs).dictionaryRepresentation allKeys]) {
        if ([key hasPrefix:prefix]) {
            dict[[key stringByReplacingOccurrencesOfString:prefix withString:@""]] = [prefs objectForKey:key];
        }
    }

    for (NSString *key in [colors allKeys]) {
        if ([key hasPrefix:prefix]) {
            dict[[key stringByReplacingOccurrencesOfString:prefix withString:@""]] = [colors objectForKey:key];
        }
    }
    #endif
    
    if ([sub isEqualToString:@"NowPlaying"]) {
        self.enabled = [([dict objectForKey:@"Enabled"] ?: @(NO)) boolValue];
    } else {
        self.enabled = [([dict objectForKey:@"Enabled"] ?: @(YES)) boolValue];
    }

    self.hideNoOlder = [([dict objectForKey:@"HideNoOlder"] ?: @(YES)) boolValue];
    self.hideAppName = [([dict objectForKey:@"HideAppName"] ?: @(NO)) boolValue];
    self.hideHeaderBackground = [([dict objectForKey:@"HideHeaderBackground"] ?: @(NO)) boolValue];
    self.hideTime = [([dict objectForKey:@"HideTime"] ?: @(NO)) boolValue];
    self.hideX = [([dict objectForKey:@"HideX"] ?: @(NO)) boolValue];
    self.hideIcon = [([dict objectForKey:@"HideIcon"] ?: @(NO)) boolValue];
    self.idleTimerEnabled = [([dict objectForKey:@"IdleTimerEnabled"] ?: @(YES)) boolValue];
    self.centerText = [([dict objectForKey:@"CenterText"] ?: @(NO)) boolValue];
    self.colorizeSection = [([dict objectForKey:@"ColorizeSection"] ?: @(NO)) boolValue];
    self.pullToClearAll = [([dict objectForKey:@"PullToClearAll"] ?: @(NO)) boolValue];
    self.alpha = [([dict objectForKey:@"Alpha"] ?: @(1.0)) doubleValue];

    self.style = [([dict objectForKey:@"Style"] ?: @(1)) intValue];
    self.verticalOffset = [([dict objectForKey:@"VerticalOffset"] ?: @(0)) doubleValue];
    self.verticalOffsetNotifications = [([dict objectForKey:@"VerticalOffsetNotifications"] ?: @(0)) doubleValue];
    self.verticalOffsetNowPlaying = [([dict objectForKey:@"VerticalOffsetNowPlaying"] ?: @(0)) doubleValue];
    self.cornerRadius = [([dict objectForKey:@"CornerRadius"] ?: @(13)) intValue];

    int backgroundColor = [([dict objectForKey:@"BackgroundColor"] ?: @(1)) intValue];
    int headerTextColor = [([dict objectForKey:@"HeaderTextColor"] ?: @(0)) intValue];
    int contentTextColor = [([dict objectForKey:@"ContentTextColor"] ?: @(0)) intValue];

    if (backgroundColor > 0) self.colorizeBackground = true;
    if (headerTextColor > 0) self.colorizeHeader = true;
    if (contentTextColor > 0) self.colorizeContent = true;

    if (backgroundColor == 1) self.dynamicBackgroundColor = true;
    if (headerTextColor == 1) self.dynamicHeaderColor = true;
    if (contentTextColor == 1) self.dynamicContentColor = true;

    #ifndef SIMULATOR
    self.backgroundColor = LCPParseColorString([dict objectForKey:@"CustomBackgroundColor"], @"#000000:1.0");
    self.backgroundGradientColor = LCPParseColorString([dict objectForKey:@"BackgroundGradientColor"], @"#ffffff:1.0");
    self.headerColor = LCPParseColorString([dict objectForKey:@"CustomHeaderTextColor"], @"#ffffff:1.0");
    self.contentColor = LCPParseColorString([dict objectForKey:@"CustomContentTextColor"], @"#ffffff:1.0");
    #else
    self.backgroundColor = [UIColor blackColor];
    self.backgroundGradientColor = [UIColor whiteColor];
    self.headerColor = [UIColor blackColor];
    self.contentColor = [UIColor blackColor];
    #endif

    int _backgroundBlurMode = [([dict objectForKey:@"BackgroundBlurMode"] ?: @(1)) intValue];
    self.backgroundBlurColorAlpha = [([dict objectForKey:@"BackgroundBlurColorAlpha"] ?: @(0.4)) doubleValue];
    self.backgroundBlurAlpha = [([dict objectForKey:@"BackgroundBlurAlpha"] ?: @(1.0)) doubleValue];

    if (_backgroundBlurMode == 1) {
        self.blurColor = [[UIColor whiteColor] colorWithAlphaComponent:self.backgroundBlurColorAlpha];
    } else if (_backgroundBlurMode == 2) {
        self.blurColor = [[UIColor blackColor] colorWithAlphaComponent:self.backgroundBlurColorAlpha];
    }

    self.backgroundGradient = [([dict objectForKey:@"BackgroundGradient"] ?: @(NO)) boolValue];

    return self;
}

@end