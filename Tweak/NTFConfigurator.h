@interface NTFConfigurator : UIWindow

@property (nonatomic, retain) UIView *welcomeView;
@property (nonatomic, retain) UIView *step1View;
@property (nonatomic, retain) UIView *goodbyeView;

@property (nonatomic, assign) int step;

-(void)nextStep;

@end

@interface NTFWelcomeView : UIView

@property (nonatomic, retain) UILabel *notificaLabel;
@property (nonatomic, retain) UILabel *welcomeLabel;
@property (nonatomic, retain) UIButton *configureButton;
@property (nonatomic, retain) UIImageView *iconView;

-(void)nextStep;

@end