@interface NTFManager : NSObject

@property (nonatomic, retain) NSMutableArray *colorCache;
@property (nonatomic, retain) NSMutableDictionary *iconStore;

+(instancetype)sharedInstance;
-(id)init;
-(UIImage *)getIcon:(NSString *)bundleIdentifier;
-(UIColor *)getDynamicColorForBundleIdentifier:(NSString *)bundleIdentifier withIconImage:(UIImage*)image mode:(NSInteger)mode;

@end