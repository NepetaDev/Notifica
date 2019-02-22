#import "Tweak.h"
#import <Nepeta/NEPColorUtils.h>
#import <AudioToolbox/AudioToolbox.h>

#define MODERNXI_Y_OFFSET 27

static BBServer *bbServer = nil;

static bool enabled = false;

static NTFConfig *configNotifications = nil;
static NTFConfig *configBanners = nil;
static NTFConfig *configWidgets = nil;
static NTFConfig *configNC = nil;
static NTFConfig *configDetails = nil;
static NTFConfig *configNowPlaying = nil;

SBDashBoardAdjunctItemView *itemViewMP = nil;

bool negativePull = false;
SBCoverSheetPrimarySlidingViewController* sbcspsvc = nil;

static dispatch_queue_t getBBServerQueue() {
	static dispatch_queue_t queue;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		void *handle = dlopen(NULL, RTLD_GLOBAL);
		if (handle) {
			dispatch_queue_t __weak *pointer = (__weak dispatch_queue_t *) dlsym(handle, "__BBServerQueue");
			if (pointer) {
				queue = *pointer;
			}
			dlclose(handle);        
		}
	});
	return queue;
}

void ntfMoveUpBy(int y, UIView *view) {
    if (view.frame.origin.y != 0) return;
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - y, view.frame.size.width, view.frame.size.height + y);
}

UIButton* ntfGetIconButtonFromHCV(MTPlatterHeaderContentView* hcv) {
    if (!hcv) return nil;

    if ([hcv respondsToSelector:@selector(iconButton)]) {
        return (UIButton *)[hcv iconButton];
    } else if ([hcv respondsToSelector:@selector(iconButtons)]) {
        return (UIButton *)[hcv iconButtons][0];
    } else {
        return nil;
    }
}

static void fakeNotification(NSString *sectionID, NSDate *date, NSString *message, bool banner) {
    BBBulletin *bulletin = [[%c(BBBulletin) alloc] init];

    bulletin.title = @"Notifica";
    bulletin.message = message;
    bulletin.sectionID = sectionID;
    bulletin.bulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
    bulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
    bulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
    bulletin.date = date;
    bulletin.defaultAction = [%c(BBAction) actionWithLaunchBundleID:sectionID callblock:nil];

    if (banner) {
        SBLockScreenNotificationListController *listController=([[%c(UIApplication) sharedApplication] respondsToSelector:@selector(notificationDispatcher)] && [[[%c(UIApplication) sharedApplication] notificationDispatcher] respondsToSelector:@selector(notificationSource)]) ? [[[%c(UIApplication) sharedApplication] notificationDispatcher] notificationSource]  : [[[%c(SBLockScreenManager) sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
        [listController observer:[listController valueForKey:@"observer"] addBulletin:bulletin forFeed:14];
    } else {
        if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:alwaysToLockScreen:)]) {
            dispatch_sync(getBBServerQueue(), ^{
                [bbServer publishBulletin:bulletin destinations:4 alwaysToLockScreen:YES];
            });
        } else if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:)]) {
            dispatch_sync(getBBServerQueue(), ^{
                [bbServer publishBulletin:bulletin destinations:4];
            });
        }
    }
}

void NTFTestNotifications() {
    [[%c(SBLockScreenManager) sharedInstance] lockUIFromSource:1 withOptions:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 1!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 2!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 3!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 4!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 5!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 6!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 7!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 8!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 9!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 10!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 11!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 12!", false);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 13!", false);
        fakeNotification(@"com.apple.Music", [NSDate date], @"Test notification 14!", false);
        fakeNotification(@"com.apple.mobilephone", [NSDate date], @"Test notification 15!", false);
    });
}

void NTFTestBanner() {
    fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test banner!", true);
}

%group Notifica

%hook MTMaterialView

%property (nonatomic, retain) CAGradientLayer *ntfGradientLayer;

%new
-(void)ntfColorize:(UIColor *)color withBlurColor:(UIColor *)bgColor {
    UIView *view = MSHookIvar<UIView *>(self, "_backdropView");
    if (!view || !color || !bgColor) return;

    if ([view respondsToSelector:@selector(setColorMatrixColor:)]) {
        _MTBackdropView *backdropView = (_MTBackdropView *)view;

        [backdropView setBackgroundColor: bgColor];
        [backdropView setColorMatrixColor: [color colorWithAlphaComponent:CGColorGetAlpha(bgColor.CGColor)]];
    } else {
        _UIBackdropView *backdropView = (_UIBackdropView *)view;

        if (backdropView.colorTintView) {
            backdropView.colorTintView.backgroundColor = color;
        }

        if (backdropView.grayscaleTintView && bgColor) {
            backdropView.grayscaleTintView.backgroundColor = bgColor;
        }
    }
}

%new
-(void)ntfGradient:(UIColor *)color {
    UIView *view = MSHookIvar<UIView *>(self, "_backdropView");
    if (self.ntfGradientLayer) {
        [self.ntfGradientLayer removeFromSuperlayer];
    }

    self.ntfGradientLayer = [CAGradientLayer layer];

    self.ntfGradientLayer.frame = view.bounds;
    self.ntfGradientLayer.startPoint = CGPointMake(0.0, 0.5);
    self.ntfGradientLayer.endPoint = CGPointMake(1.0, 0.5);
    self.ntfGradientLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)color.CGColor];

    [view.layer insertSublayer:self.ntfGradientLayer atIndex:[view.layer.sublayers count]];
}

%new
-(void)ntfSetCornerRadius:(double)cornerRadius {
    UIView *view = MSHookIvar<UIView *>(self, "_backdropView");

    if ([view respondsToSelector:@selector(setColorMatrixColor:)]) {
        _MTBackdropView *backdropView = (_MTBackdropView *)view;
        backdropView.layer.cornerRadius = cornerRadius;

        CALayer *backdropLayer = (CALayer *)[backdropView _backdropLayer];
        backdropLayer.cornerRadius = cornerRadius;
    } else {
        _UIBackdropView *backdropView = (_UIBackdropView *)view;
        if (backdropView.backdropEffectView) backdropView.backdropEffectView.backdropLayer.cornerRadius = cornerRadius;
        if (backdropView.grayscaleTintView) backdropView.grayscaleTintView.layer.cornerRadius = cornerRadius;
        if (backdropView.colorTintView) backdropView.colorTintView.layer.cornerRadius = cornerRadius;
    }
}

%end

%hook PLPlatterHeaderContentView

-(void)_layoutTitleLabelWithScale:(double)arg1 {
    %orig;
    NTFConfig *config = nil;
    if (self.superview && self.superview.superview) {
        if ([self.superview.superview isKindOfClass:%c(NCNotificationShortLookView)]) {
            NCNotificationShortLookView* sv = (NCNotificationShortLookView *)self.superview.superview;
            config = [sv ntfConfig];
        } else if ([self.superview.superview isKindOfClass:%c(WGWidgetPlatterView)]) {
            config = configWidgets;
        }
    }

    if ([config style] == 1) {
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x + 5, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width - 5, self.titleLabel.frame.size.height);
    }
}
%end

%hook MTPlatterHeaderContentView

-(void)_layoutTitleLabelWithScale:(double)arg1 {
    %orig;
    NTFConfig *config = nil;
    if (self.superview && self.superview.superview) {
        if ([self.superview.superview isKindOfClass:%c(NCNotificationShortLookView)]) {
            NCNotificationShortLookView* sv = (NCNotificationShortLookView *)self.superview.superview;
            config = [sv ntfConfig];
        } else if ([self.superview.superview isKindOfClass:%c(WGWidgetPlatterView)]) {
            config = configWidgets;
        }
    }

    if (!config || ![config enabled]) return;

    if ([config style] == 1) {
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x + 5, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width - 5, self.titleLabel.frame.size.height);
    }
}
%end

%end

%group NotificaNotifications

/* -- NOTIFICATIONS */

%hook NCNotificationShortLookViewController

-(void)viewWillAppear:(bool)whatever {
    %orig;
    [self.view.contentView ntfColorize];
}

-(void)viewDidAppear:(bool)whatever {
    %orig;
    [self.view.contentView ntfColorize];
}

%end

%hook NCNotificationViewControllerView

-(void)layoutSubviews {
    %orig;
    NTFConfig *config = nil;
    if ([self.contentView isKindOfClass:%c(NCNotificationShortLookView)]) {
        NCNotificationShortLookView* sv = (NCNotificationShortLookView *)self.contentView;
        config = [sv ntfConfig];
    }

    if (!config || ![config enabled]) return;

    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:%c(PLPlatterView)]) {
            PLPlatterView *view = (PLPlatterView *)subview;
            [view setCornerRadius:[config cornerRadius]];
            view.layer.cornerRadius = [config cornerRadius];

            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y + MODERNXI_Y_OFFSET, view.frame.size.width, view.frame.size.height - MODERNXI_Y_OFFSET);

            for (UIView *subsubview in view.subviews) {
                if ([subsubview isKindOfClass:%c(MTMaterialView)]) {
                    subsubview.layer.cornerRadius = [config cornerRadius];
                    [((MTMaterialView *)subsubview) ntfSetCornerRadius:[config cornerRadius]];
                    UIView *view = MSHookIvar<UIView *>(subsubview, "_backdropView");
                    view.alpha = [config backgroundBlurAlpha];

                    if ([config colorizeBackground]) {
                        if ([config dynamicBackgroundColor]) {
                            [((MTMaterialView *)subsubview) ntfColorize:self.contentView.ntfDynamicColor withBlurColor:[config blurColor]];
                        } else {
                            [((MTMaterialView *)subsubview) ntfColorize:[config backgroundColor] withBlurColor:[config blurColor]];
                        }
                    }

                    if ([config backgroundGradient]) {
                        [((MTMaterialView *)subsubview) ntfGradient:[config backgroundGradientColor]];
                    }
                }
            }
        }
    }
}

%end

%hook NCNotificationListCell

-(void)layoutSubviews {
    %orig;
    [self.contentViewController.view.contentView ntfColorize];

    if ([configNotifications style] == 1) {
        [self.contentViewController.view.contentView ntfRepositionHeader];
    }

    self.alpha = [configNotifications alpha];
}

-(void)setAlpha:(double)alpha {
    if ([configNotifications alpha] != 1.0) {
        alpha = [configNotifications alpha];
    }

    %orig;
}

%end

%hook NCNotificationListCellActionButtonsView

-(void)layoutSubviews {
    if ([configNotifications enabled] && [configNotifications style] == 1) {
        ntfMoveUpBy(-1 * MODERNXI_Y_OFFSET, self);
    }

    %orig;

    if (![configNotifications enabled]) return;

    if (!self.superview || !self.superview.superview || !self.superview.superview.superview) return;

    NCNotificationListCell *cell = (NCNotificationListCell *)self.superview.superview.superview;
    UIColor *dynamicColor = cell.contentViewController.view.contentView.ntfDynamicColor;
    self.clippingView.layer.cornerRadius = [configNotifications cornerRadius];
    if (self.superview) {
        self.superview.layer.cornerRadius = [configNotifications cornerRadius];
    }

    for (NCNotificationListCellActionButton *button in self.buttonsStackView.arrangedSubviews) {
        if ([configNotifications colorizeBackground]) {
            if ([configNotifications dynamicBackgroundColor]) {
                [button.backgroundView ntfColorize:dynamicColor withBlurColor:[configNotifications blurColor]];
                [button.backgroundOverlayView ntfColorize:dynamicColor withBlurColor:[configNotifications blurColor]];
            } else {
                [button.backgroundView ntfColorize:[configNotifications backgroundColor] withBlurColor:[configNotifications blurColor]];
                [button.backgroundOverlayView ntfColorize:[configNotifications backgroundColor] withBlurColor:[configNotifications blurColor]];
            }
        }

        if ([configNotifications colorizeHeader]) {
            [button.titleLabel.layer setFilters:nil];
            if ([configNotifications dynamicHeaderColor]) {
                [button.titleLabel setTextColor:dynamicColor];
            } else {
                [button.titleLabel setTextColor:[configNotifications headerColor]];
            }
        }
    }
}

%end

%hook NCNotificationListCoalescingHeaderCell

%new;
-(void)ntfColorizeHeader:(UIColor *)color {
    [self.headerTitleView.titleLabel legibilitySettings].primaryColor = color;
    [self.headerTitleView.titleLabel _updateLabelForLegibilitySettings];
    [self.headerTitleView.titleLabel _updateLegibilityView];
}

%new;
-(void)ntfColorizeContent:(UIColor *)color {
    for (NCToggleControl *control in [self.coalescingControlsView.toggleControlPair toggleControls]) {
        [[control _titleLabel].layer setFilters:nil];
        [[control _titleLabel] setTextColor:color];

        [[control _glyphView].layer setFilters:nil];
        [[control _glyphView] setTintColor:color];
    }
}

%new;
-(void)ntfColorizeBackground:(UIColor *)color {
    for (NCToggleControl *control in [self.coalescingControlsView.toggleControlPair toggleControls]) {
        [[control _backgroundMaterialView] ntfColorize:color withBlurColor:[configNotifications blurColor]];
    }
}

%end

%hook NCNotificationListCollectionView

-(void)layoutSubviews {
    %orig;
    if (![configNC colorizeSection]) return;

    NCNotificationListCoalescingHeaderCell *cell = nil;
    for (UIView *view in [self subviews]) {
        if ([view isKindOfClass:%c(NCNotificationListCoalescingHeaderCell)]) {
            cell = (NCNotificationListCoalescingHeaderCell *)view;
            
            if ([configNotifications colorizeBackground] && ![configNotifications dynamicBackgroundColor]) {
                [cell ntfColorizeBackground:[configNotifications backgroundColor]];
            }

            if ([configNotifications colorizeHeader] && ![configNotifications dynamicHeaderColor]) {
                [cell ntfColorizeHeader:[configNotifications headerColor]];
            }

            if ([configNotifications colorizeContent] && ![configNotifications dynamicContentColor]) {
                [cell ntfColorizeContent:[configNotifications contentColor]];
            }
        } else if (cell && [view isKindOfClass:%c(NCNotificationListCell)]) {
            UIColor *dynamicColor = ((NCNotificationListCell *)view).contentViewController.view.contentView.ntfDynamicColor;

            if ([configNotifications colorizeBackground] && [configNotifications dynamicBackgroundColor]) {
                [cell ntfColorizeBackground:dynamicColor];
            }

            if ([configNotifications colorizeHeader] && [configNotifications dynamicHeaderColor]) {
                [cell ntfColorizeHeader:dynamicColor];
            }

            if ([configNotifications colorizeContent] && [configNotifications dynamicContentColor]) {
                [cell ntfColorizeContent:dynamicColor];
            }

            cell = nil;
        }
    }
}

%end

%end

/* -- WIDGETS */

%group NotificaWidgets

%hook WGWidgetPlatterView

%property (nonatomic, retain) UIColor *ntfDynamicColor;

-(void)setIcon:(UIImage *)arg1 {
    %orig;
    if (![self listItem]) return;
    if (!arg1) return;
    [self ntfColorize];
}

-(void)layoutSubviews{
    %orig;
    if (![self listItem]) return;

    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:%c(MTMaterialView)]) {
            subview.layer.cornerRadius = [config cornerRadius];
        }
    }

    if (self.customContentView && self.customContentView.superview) {
        for (UIView *subview in self.customContentView.superview.subviews) {
            if ([subview isKindOfClass:%c(MTMaterialView)]) {
                subview.hidden = YES;
            }
        }
    }

    if ([config hideHeaderBackground]) {
        MSHookIvar<UILabel *>(self, "_headerOverlayView").hidden = YES;
    }

    if ([config style] == 1) {
        MSHookIvar<UILabel *>(self, "_headerOverlayView").hidden = YES;
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:%c(UIImageView)]) {
                subview.hidden = YES;
            }

            if ([subview isKindOfClass:%c(MTMaterialView)]) {
                ntfMoveUpBy(-1 * MODERNXI_Y_OFFSET, subview);
            }
        }

        UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);

        if (iconButton) {
            iconButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            iconButton.contentVerticalAlignment   = UIControlContentVerticalAlignmentFill;
            iconButton.contentEdgeInsets = UIEdgeInsetsMake(5,5,5,5);

            iconButton.layer.shadowRadius = 3.0f;
            iconButton.layer.shadowColor = [UIColor blackColor].CGColor;
            iconButton.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
            iconButton.layer.shadowOpacity = 0.5f;
            iconButton.layer.masksToBounds = NO;
        }

        [self ntfRepositionHeader];
    }

    [self ntfHideStuff];
    [self ntfColorize];
}

%new
-(NTFConfig *)ntfConfig {
    return configWidgets;
}

%new
-(void)ntfColorizeHeader:(UIColor *)color {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
    
    // Taken from @the_casle's Nine.
    [[[headerContentView _dateLabel] layer] setFilters:nil];
    [[[headerContentView _titleLabel] layer] setFilters:nil];

    [headerContentView setTintColor:color];
    [[headerContentView _dateLabel] setTextColor:color];
    [[headerContentView _titleLabel] setTextColor:color];

    if ([self showMoreButton]) {
        [[[[self showMoreButton] titleLabel] layer] setFilters:nil];
        [[self showMoreButton] setTitleColor:color forState:UIControlStateNormal];
    }
}

%new
-(void)ntfColorizeContent:(UIColor *)color {
}

%new
-(void)ntfRepositionHeader {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
    if (headerContentView.frame.origin.y != 0) return;

    [headerContentView setNeedsLayout];
    [headerContentView layoutIfNeeded];
    
    ntfMoveUpBy(5, headerContentView);
    
    if (headerContentView.bounds.origin.x - headerContentView.frame.origin.x == 0) {
        headerContentView.bounds = CGRectInset(headerContentView.bounds, -5.0f, 0);
    }

    if ([config style] == 1) {
        headerContentView.titleLabel.frame = CGRectMake(headerContentView.titleLabel.frame.origin.x + 5, headerContentView.titleLabel.frame.origin.y, headerContentView.titleLabel.frame.size.width - 5, headerContentView.titleLabel.frame.size.height);
    }
}

%new
-(void)ntfColorize {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    self.ntfDynamicColor = nil;

    if ([config dynamicBackgroundColor] || [config dynamicHeaderColor] || [config dynamicContentColor]) {
        MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
        UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);
        if (iconButton) {
            self.ntfDynamicColor = [NEPColorUtils averageColor:iconButton.imageView.image withAlpha:1.0];
        } else {
            self.ntfDynamicColor = [config backgroundColor];
        }
    }

    if (!self.backgroundMaterialView) return;
    self.backgroundMaterialView.hidden = NO;
    [self.backgroundMaterialView ntfSetCornerRadius:[config cornerRadius]];
    UIView *view = MSHookIvar<UIView *>(self.backgroundMaterialView, "_backdropView");
    view.alpha = [config backgroundBlurAlpha];
    if ([config colorizeBackground]) {
        if ([config dynamicBackgroundColor]) {
            [self.backgroundMaterialView ntfColorize:self.ntfDynamicColor withBlurColor:[config blurColor]];
        } else {
            [self.backgroundMaterialView ntfColorize:[config backgroundColor] withBlurColor:[config blurColor]];
        }
    }

    if ([config backgroundGradient]) {
        [self.backgroundMaterialView ntfGradient:[config backgroundGradientColor]];
    }

    if ([config colorizeHeader]) {
        if ([config dynamicHeaderColor]) {
            [self ntfColorizeHeader:self.ntfDynamicColor];
        } else {
            [self ntfColorizeHeader:[config headerColor]];
        }
    }

    if ([config colorizeContent]) {
        if ([config dynamicContentColor]) {
            [self ntfColorizeContent:self.ntfDynamicColor];
        } else {
            [self ntfColorizeContent:[config contentColor]];
        }
    }

    [self ntfHideStuff];
}

%new
-(void)ntfHideStuff {
    NTFConfig *config = [self ntfConfig];
    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
    [[headerContentView _titleLabel] setHidden:[config hideAppName]];

    UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);
    [iconButton setHidden:[config hideIcon]];
}

%end

%end

/* -- DETAILS */

%group NotificaDetails

%hook NCNotificationLongLookView

%property (nonatomic, retain) UIColor *ntfDynamicColor;

-(void)setIcon:(UIImage *)arg1 {
    %orig;
    if (!arg1) return;
    [self ntfColorize];
}

-(void)layoutSubviews{
    %orig;

    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    NCNotificationContentView *notificationContentView = MSHookIvar<NCNotificationContentView *>(self, "_notificationContentView");
    if ([config centerText]) {
        ((UITextView *)[notificationContentView _secondaryTextView]).textAlignment = NSTextAlignmentCenter;
        ((UILabel *)[notificationContentView _primaryLabel]).textAlignment = NSTextAlignmentCenter;
        ((UILabel *)[notificationContentView _primarySubtitleLabel]).textAlignment = NSTextAlignmentCenter;
        if ([notificationContentView respondsToSelector:@selector(_secondaryLabel)]) ((UILabel *)[notificationContentView _secondaryLabel]).textAlignment = NSTextAlignmentCenter;
        if ([notificationContentView respondsToSelector:@selector(_summaryLabel)]) ((UILabel *)[notificationContentView _summaryLabel]).textAlignment = NSTextAlignmentCenter;
    }

    [self ntfHideStuff];
    [self ntfColorize];
}

%new
-(NTFConfig *)ntfConfig {
    return configDetails;
}

%new
-(void)ntfColorizeHeader:(UIColor *)color {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    MTPlatterHeaderContentView *headerContentView = MSHookIvar<MTPlatterHeaderContentView *>(self, "_headerContentView");
    
    // Taken from @the_casle's Nine.
    [[[headerContentView _titleLabel] layer] setFilters:nil];

    [headerContentView setTintColor:color];
    [[headerContentView _titleLabel] setTextColor:color];
}

%new
-(void)ntfColorizeContent:(UIColor *)color {
    NCNotificationContentView *notificationContentView = MSHookIvar<NCNotificationContentView *>(self, "_notificationContentView");

    [[notificationContentView _secondaryTextView] setTextColor:color];
    [[notificationContentView _primaryLabel] setTextColor:color];
    [[notificationContentView _primarySubtitleLabel] setTextColor:color];
    if ([notificationContentView respondsToSelector:@selector(_secondaryLabel)]) [[notificationContentView _secondaryLabel] setTextColor:color];
    if ([notificationContentView respondsToSelector:@selector(_summaryLabel)]) [[notificationContentView _summaryLabel] setTextColor:color];
}

%new
-(void)ntfColorize {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    self.ntfDynamicColor = nil;
    MTPlatterHeaderContentView *headerContentView = MSHookIvar<MTPlatterHeaderContentView *>(self, "_headerContentView");
    NCNotificationContentView *notificationContentView = MSHookIvar<NCNotificationContentView *>(self, "_notificationContentView");

    if ([config dynamicBackgroundColor] || [config dynamicHeaderColor] || [config dynamicContentColor]) {
        UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);
        if (iconButton) {
            self.ntfDynamicColor = [NEPColorUtils averageColor:iconButton.imageView.image withAlpha:1.0];
        } else {
            self.ntfDynamicColor = [config backgroundColor];
        }
    }

    self.layer.cornerRadius = [config cornerRadius];
    if ([config colorizeBackground]) {
        if ([config dynamicBackgroundColor]) {
            [headerContentView setBackgroundColor:self.ntfDynamicColor];
            [notificationContentView setBackgroundColor:self.ntfDynamicColor];
        } else {
            [headerContentView setBackgroundColor:[config backgroundColor]];
            [notificationContentView setBackgroundColor:[config backgroundColor]];
        }
    }

    if ([config colorizeHeader]) {
        if ([config dynamicHeaderColor]) {
            [self ntfColorizeHeader:self.ntfDynamicColor];
        } else {
            [self ntfColorizeHeader:[config headerColor]];
        }
    }

    if ([config colorizeContent]) {
        if ([config dynamicContentColor]) {
            [self ntfColorizeContent:self.ntfDynamicColor];
        } else {
            [self ntfColorizeContent:[config contentColor]];
        }
    }

    [self ntfHideStuff];
}

%new
-(void)ntfHideStuff {
    NTFConfig *config = [self ntfConfig];
    MTPlatterHeaderContentView *headerContentView = MSHookIvar<MTPlatterHeaderContentView *>(self, "_headerContentView");
    [[headerContentView _titleLabel] setHidden:[config hideAppName]];
    [[headerContentView _utilityButton] setHidden:[config hideX]];

    UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);
    [iconButton setHidden:[config hideIcon]];
}

%end

%end

/* -- NOTIFICATIONS/BANNERS */

%group NotificaNotificationsBanners

%hook NCNotificationShortLookView

%property (nonatomic, retain) UIColor *ntfDynamicColor;

-(void)setIcon:(UIImage *)arg1 {
    %orig;
    if (!arg1) return;
    [self ntfColorize];
}

-(void)layoutSubviews{
    %orig;

    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    UIViewController *controller = nil;
    if (self.nextResponder.nextResponder.nextResponder) {
        controller = (UIViewController*)self.nextResponder.nextResponder.nextResponder;
    }

    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:%c(MTMaterialView)]) {
            subview.layer.cornerRadius = [config cornerRadius];
            subview.hidden = YES;
        }
    }

    self.backgroundMaterialView.hidden = NO;

    if ([config centerText]) {
        ((UITextView *)[[self _notificationContentView] _secondaryTextView]).textAlignment = NSTextAlignmentCenter;
        ((UILabel *)[[self _notificationContentView] _primaryLabel]).textAlignment = NSTextAlignmentCenter;
        ((UILabel *)[[self _notificationContentView] _primarySubtitleLabel]).textAlignment = NSTextAlignmentCenter;
        if ([[self _notificationContentView] respondsToSelector:@selector(_secondaryLabel)]) ((UILabel *)[[self _notificationContentView] _secondaryLabel]).textAlignment = NSTextAlignmentCenter;
        if ([[self _notificationContentView] respondsToSelector:@selector(_summaryLabel)]) ((UILabel *)[[self _notificationContentView] _summaryLabel]).textAlignment = NSTextAlignmentCenter;

        // StackXI compatibility
        if ([controller isKindOfClass:%c(NCNotificationShortLookViewController)] && [controller respondsToSelector:@selector(sxiNotificationCount)]) {
            ((UILabel *)[((NCNotificationShortLookViewController *)controller) sxiNotificationCount]).textAlignment = NSTextAlignmentCenter;
        }
    }

    if ([config style] == 1) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:%c(UIImageView)]) {
                subview.hidden = YES;
            }

            if ([subview isKindOfClass:%c(MTMaterialView)]) {
                ntfMoveUpBy(-1 * MODERNXI_Y_OFFSET, subview);
            }
        }

        UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);

        if (iconButton) {
            iconButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            iconButton.contentVerticalAlignment   = UIControlContentVerticalAlignmentFill;
            iconButton.contentEdgeInsets = UIEdgeInsetsMake(5,5,5,5);

            iconButton.layer.shadowRadius = 3.0f;
            iconButton.layer.shadowColor = [UIColor blackColor].CGColor;
            iconButton.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
            iconButton.layer.shadowOpacity = 0.5f;
            iconButton.layer.masksToBounds = NO;
        }
    
        /*if (controller && ((NCNotificationShortLookViewController *)controller).notificationRequest) {
            NCNotificationRequest *req = ((NCNotificationShortLookViewController *)controller).notificationRequest;
            if (req.bulletin && req.bulletin.sectionID) {
                UIImage *icon = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:req.bulletin.sectionID];
                if (icon) {
                    [iconButton setImage:icon forState:UIControlStateNormal];
                }
            }
        }*/

        [self ntfRepositionHeader];
    }

    [self ntfHideStuff];
    [self ntfColorize];
}

%new
-(NTFConfig *)ntfConfig {
    if (![[self _viewControllerForAncestor] respondsToSelector:@selector(delegate)]) return nil;
    
    if ([[[self _viewControllerForAncestor] delegate] isKindOfClass:%c(SBNotificationBannerDestination)]) {
        return configBanners;
    } else {
        return configNotifications;
    }
}

%new
-(void)ntfColorizeHeader:(UIColor *)color {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
    
    // Taken from @the_casle's Nine.
    [[[headerContentView _dateLabel] layer] setFilters:nil];
    [[[headerContentView _titleLabel] layer] setFilters:nil];

    [headerContentView setTintColor:color];
    [[headerContentView _dateLabel] setTextColor:color];
    [[headerContentView _titleLabel] setTextColor:color];
}

%new
-(void)ntfColorizeContent:(UIColor *)color {
    [[[self _notificationContentView] _secondaryTextView] setTextColor:color];
    [[[self _notificationContentView] _primaryLabel] setTextColor:color];
    [[[self _notificationContentView] _primarySubtitleLabel] setTextColor:color];
    if ([[self _notificationContentView] respondsToSelector:@selector(_secondaryLabel)]) [[[self _notificationContentView] _secondaryLabel] setTextColor:color];
    if ([[self _notificationContentView] respondsToSelector:@selector(_summaryLabel)]) [[[self _notificationContentView] _summaryLabel] setTextColor:color];
}

%new
-(void)ntfRepositionHeader {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
    if (headerContentView.frame.origin.y != 0) return;

    [headerContentView setNeedsLayout];
    [headerContentView layoutIfNeeded];
    
    ntfMoveUpBy(5, headerContentView);
    
    if (headerContentView.bounds.origin.x - headerContentView.frame.origin.x == 0) {
        headerContentView.bounds = CGRectInset(headerContentView.bounds, -5.0f, 0);
    }

    if ([config style] == 1) {
        headerContentView.titleLabel.frame = CGRectMake(headerContentView.titleLabel.frame.origin.x + 5, headerContentView.titleLabel.frame.origin.y, headerContentView.titleLabel.frame.size.width - 5, headerContentView.titleLabel.frame.size.height);
    }
}

%new
-(void)ntfColorize {
    NTFConfig *config = [self ntfConfig];
    if (!config || ![config enabled]) {
        return;
    }

    self.ntfDynamicColor = nil;

    if ([config dynamicBackgroundColor] || [config dynamicHeaderColor] || [config dynamicContentColor]) {
        MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
        UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);
        if (iconButton) {
            self.ntfDynamicColor = [NEPColorUtils averageColor:iconButton.imageView.image withAlpha:1.0];
        } else {
            self.ntfDynamicColor = [config backgroundColor];
        }
    }

    if (!self.backgroundMaterialView) return;
    [self.backgroundMaterialView ntfSetCornerRadius:[config cornerRadius]];
    UIView *view = MSHookIvar<UIView *>(self.backgroundMaterialView, "_backdropView");
    view.alpha = [config backgroundBlurAlpha];
    if ([config colorizeBackground]) {
        if ([config dynamicBackgroundColor]) {
            [self.backgroundMaterialView ntfColorize:self.ntfDynamicColor withBlurColor:[config blurColor]];
        } else {
            [self.backgroundMaterialView ntfColorize:[config backgroundColor] withBlurColor:[config blurColor]];
        }
    }

    if ([config backgroundGradient]) {
        [self.backgroundMaterialView ntfGradient:[config backgroundGradientColor]];
    }

    if ([config colorizeHeader]) {
        if ([config dynamicHeaderColor]) {
            [self ntfColorizeHeader:self.ntfDynamicColor];
        } else {
            [self ntfColorizeHeader:[config headerColor]];
        }
    }

    if ([config colorizeContent]) {
        if ([config dynamicContentColor]) {
            [self ntfColorizeContent:self.ntfDynamicColor];
        } else {
            [self ntfColorizeContent:[config contentColor]];
        }
    }

    [self ntfHideStuff];
}

%new
-(void)ntfHideStuff {
    NTFConfig *config = [self ntfConfig];
    MTPlatterHeaderContentView *headerContentView = [self _headerContentView];
    [[headerContentView _dateLabel] setHidden:[config hideTime]];
    [[headerContentView _titleLabel] setHidden:[config hideAppName]];

    UIButton *iconButton = ntfGetIconButtonFromHCV(headerContentView);
    [iconButton setHidden:[config hideIcon]];
}

%end

%end

/* -- NOW PLAYING */

%group NotificaNowPlaying

%hook MediaControlsHeaderView

-(void)layoutSubviews {
    %orig;
    if (self.superview && self.superview.superview && self.superview.superview.superview && [self.superview.superview.superview isKindOfClass:%c(SBDashBoardMediaControlsView)] && itemViewMP) {
        [itemViewMP ntfReadjustColorBasedOnArtwork];
    }
}

%end

%hook SBDashBoardAdjunctItemView

%property (nonatomic, retain) UIColor *ntfDynamicColor;

-(void)layoutSubviews {
    %orig;
    NTFConfig *config = configNowPlaying;

    if (!config || ![config enabled] || ![config dynamicBackgroundColor]) return;
    if (!self.customContentView || ![self.customContentView subviews] || [[self.customContentView subviews] count] == 0) return;
    if ([self.customContentView subviews][0] && [[self.customContentView subviews][0] isKindOfClass:%c(SBDashBoardMediaControlsView)]) {
        itemViewMP = self;

        [self ntfColorize];
    }
}

-(void)dealloc {
    itemViewMP = nil;
    %orig;
}

%new
-(void)ntfReadjustColorBasedOnArtwork {
    NTFConfig *config = configNowPlaying;
    if (!config || ![config enabled] || ![config dynamicBackgroundColor]) return;
    if (!self.customContentView || ![self.customContentView subviews] || [[self.customContentView subviews] count] == 0) return;

    SBDashBoardMediaControlsView *view = (SBDashBoardMediaControlsView *)[self.customContentView subviews][0];
    MediaControlsPanelViewController *mcpvc = MSHookIvar<MediaControlsPanelViewController *>(view.nextResponder, "_mediaControlsPanelViewController");
    if (!mcpvc || !mcpvc.headerView || !mcpvc.headerView.artworkView || !mcpvc.headerView.artworkView.image || !self.backgroundMaterialView) return;
    
    self.ntfDynamicColor = [NEPColorUtils averageColor:mcpvc.headerView.artworkView.image withAlpha:1.0];
    [self.backgroundMaterialView ntfColorize:self.ntfDynamicColor withBlurColor:[config blurColor]];
    
    view.superview.layer.cornerRadius = [config cornerRadius];
}

%new
-(void)ntfColorize {
    NTFConfig *config = configNowPlaying;
    if (!config || ![config enabled]) {
        return;
    }

    self.ntfDynamicColor = nil;

    [self.backgroundMaterialView ntfSetCornerRadius:[config cornerRadius]];
    UIView *backdropView = MSHookIvar<UIView *>(self.backgroundMaterialView, "_backdropView");
    backdropView.alpha = [config backgroundBlurAlpha];
    SBDashBoardMediaControlsView *view = (SBDashBoardMediaControlsView *)[self.customContentView subviews][0];
    view.superview.layer.cornerRadius = [config cornerRadius];
    if ([config colorizeBackground]) {
        if ([config dynamicBackgroundColor]) {
            [self ntfReadjustColorBasedOnArtwork];
        } else {
            [self.backgroundMaterialView ntfColorize:[config backgroundColor] withBlurColor:[config blurColor]];
        }
    }
}

%end

%end

%group NotificaNC

/* -- NOTIFICATION CENTER */

/* -- Hide "no older notifications" */

%hook NCNotificationListSectionRevealHintView

-(void)layoutSubviews {
    %orig;
    MSHookIvar<UILabel *>(self, "_revealHintTitle").hidden = [configNC hideNoOlder];
}

%end

/* -- Vertical offset */

%hook SBDashBoardCombinedListViewController

-(UIEdgeInsets) _listViewDefaultContentInsets {
    UIEdgeInsets orig = %orig;
    double verticalOffset = [configNC verticalOffset];
    orig.top += verticalOffset;
    return orig;
}

-(void) _layoutListView {
    %orig;
    [self _updateListViewContentInset];
}

-(double) _minInsetsToPushDateOffScreen {
    double orig = %orig;
    double verticalOffset = [configNC verticalOffset];
    return orig + verticalOffset;
}

%end

/*%hook SBDashBoardAdjunctListView

-(void)layoutSubviews {
    UIEdgeInsets insets = self.layoutMargins;
    double verticalOffset = [configNC verticalOffsetNowPlaying];
    insets.top += verticalOffset;
    %orig;
}

%end*/

/* -- Pull to clear all */

%hook SBCoverSheetPrimarySlidingViewController

-(id)initWithContentViewController:(id)arg1 canBePulledDown:(BOOL)arg2 canBePulledUp:(BOOL)arg3 dismissalPreemptingGestureRecognizer:(id)arg4 {
    id orig = %orig;
    sbcspsvc = orig;
    return orig;
}

%end

%hook NCNotificationCombinedListViewController

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    %orig;

    if (![configNC pullToClearAll]) return;
    if ([sbcspsvc isTransitioning]) return;

    double verticalOffset = [configNC verticalOffset];
    if (scrollView.contentOffset.y - 50 >= (scrollView.contentSize.height - scrollView.bounds.size.height - verticalOffset)) negativePull = YES;

    if (scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.bounds.size.height - verticalOffset) && negativePull) {
        AudioServicesPlaySystemSound(1519);
        [self _clearAllPriorityListNotificationRequests];
        [self _clearAllSectionListNotificationRequests];
        negativePull = NO;
    }
}

%end

/* -- Disable Idle Timer */

%hook SBDashBoardIdleTimerProvider

-(bool)isIdleTimerEnabled {
    return [configNC idleTimerEnabled];
}

%end

%end

%group NotificaConfigurator

%hook SBCoverSheetWindow

%property (nonatomic, retain) UIWindow *ntfConfigurator;

-(id)initWithScreen:(id)arg1 debugName:(id)arg2 {
    id orig = %orig;

    self.ntfConfigurator = [[NTFConfigurator alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    return orig;
}

%end

%end

%group NotificaNotificationTest

%hook BBServer
-(id)initWithQueue:(id)arg1 {
    bbServer = %orig;
    #ifdef SIMULATOR
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NTFTestNotifications();
    });
    #endif
    return bbServer;
}

-(id)initWithQueue:(id)arg1 dataProviderManager:(id)arg2 syncService:(id)arg3 dismissalSyncCache:(id)arg4 observerListener:(id)arg5 utilitiesListener:(id)arg6 conduitListener:(id)arg7 systemStateListener:(id)arg8 settingsListener:(id)arg9 {
    bbServer = %orig;
    return bbServer;
}

- (void)dealloc {
  if (bbServer == self) {
    bbServer = nil;
  }

  %orig;
}
%end

%end

%ctor{
    bool showConfigurator = false;
    if (showConfigurator) {
        %init(NotificaConfigurator);
    }
    NSLog(@"[Notifica] init");

    #ifndef SIMULATOR
    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.notifica"];
    NSMutableDictionary *colors = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.nepeta.notifica-colors.plist"];
    enabled = [([file objectForKey:@"Enabled"] ?: @(YES)) boolValue];
    #else
    id file = nil;
    NSMutableDictionary *colors = nil;
    enabled = true;
    #endif

    if (enabled) {
        configNotifications = [[NTFConfig alloc] initWithSub:@"Notifications" prefs:file colors:colors];
        configBanners = [[NTFConfig alloc] initWithSub:@"Banners" prefs:file colors:colors];
        configWidgets = [[NTFConfig alloc] initWithSub:@"Widgets" prefs:file colors:colors];
        configNC = [[NTFConfig alloc] initWithSub:@"NotificationCenter" prefs:file colors:colors];
        configDetails = [[NTFConfig alloc] initWithSub:@"Details" prefs:file colors:colors];
        configNowPlaying = [[NTFConfig alloc] initWithSub:@"NowPlaying" prefs:file colors:colors];

        %init(Notifica);
        %init(NotificaNC);

        if ([configNotifications enabled] || [configBanners enabled]) %init(NotificaNotificationsBanners);
        if ([configNotifications enabled]) %init(NotificaNotifications);
        if ([configWidgets enabled]) %init(NotificaWidgets);
        if ([configDetails enabled]) %init(NotificaDetails);
        if ([configNowPlaying enabled]) %init(NotificaNowPlaying);
    }

    %init(NotificaNotificationTest);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)NTFTestNotifications, (CFStringRef)@"me.nepeta.notifica/TestNotifications", NULL, kNilOptions);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)NTFTestBanner, (CFStringRef)@"me.nepeta.notifica/TestBanner", NULL, kNilOptions);
}
