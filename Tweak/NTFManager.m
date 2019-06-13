#import <Nepeta/NEPColorUtils.h>
#import "NTFManager.h"
#import "IconHeaders.h"

@implementation NTFManager

+(instancetype)sharedInstance {
    static NTFManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [NTFManager alloc];
        sharedInstance.iconStore = [NSMutableDictionary new];
        sharedInstance.colorCache = [NSMutableArray new];

        [sharedInstance.colorCache addObject:[NSMutableDictionary new]];
        [sharedInstance.colorCache addObject:[NSMutableDictionary new]];
        [sharedInstance.colorCache addObject:[NSMutableDictionary new]];
    });
    return sharedInstance;
}

-(id)init {
    return [NTFManager sharedInstance];
}

-(UIImage *)getIcon:(NSString *)bundleIdentifier {
    if (self.iconStore[bundleIdentifier]) return self.iconStore[bundleIdentifier];

    SBIconModel *model = [[(SBIconController *)[NSClassFromString(@"SBIconController") sharedInstance] homescreenIconViewMap] iconModel];
    SBIcon *icon = [model applicationIconForBundleIdentifier:bundleIdentifier];
    UIImage *image = [icon getIconImage:2];

    if (!image) {
        icon = [model applicationIconForBundleIdentifier:@"com.apple.Preferences"];
        image = [icon getIconImage:2];
    }

    if (!image) {
        image = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifier format:0 scale:[UIScreen mainScreen].scale];
    }

    if (image) {
        self.iconStore[bundleIdentifier] = [image copy];
    }

    return image ?: [UIImage new];
}

-(UIColor *)getDynamicColorForBundleIdentifier:(NSString *)bundleIdentifier withIconImage:(UIImage*)image mode:(NSInteger)mode {
    if (!image) return nil;
    if (self.colorCache[mode][bundleIdentifier]) return [self.colorCache[mode][bundleIdentifier] copy];
    
    UIColor *color = [UIColor blackColor];
    NEPPalette *colors = nil;

    switch (mode) {
        case 0:
            color = [NEPColorUtils averageColor:image withAlpha:1.0];
            break;
        case 1:
            colors = [NEPColorUtils averageColors:image withAlpha:1.0];
            color = colors.primary;
            break;
        default:
            break;
    }

    self.colorCache[mode][bundleIdentifier] = [color copy];
    return [color copy];
}

@end