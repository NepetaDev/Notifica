#import "NTFConfigurator.h"

@implementation NTFConfigurator
    - (instancetype)initWithFrame:(CGRect)frame {
        self = [super initWithFrame:frame];
        [self setUserInteractionEnabled:YES];
        self.windowLevel = UIWindowLevelAlert + 1;
        self.backgroundColor = [UIColor whiteColor];
        [self setHidden:NO];
        self.alpha = 1.0;
        [self makeKeyAndVisible];

        self.welcomeView = [[NTFWelcomeView alloc] initWithFrame:frame];
        [self insertSubview:self.welcomeView atIndex:0];
        return self;
    }

    -(void)nextStep {
        [self setUserInteractionEnabled:NO];
        [UIView animateWithDuration:0.5 animations:^{
            self.alpha = 0.0;
        }];
    }
@end

@implementation NTFWelcomeView
    - (instancetype)initWithFrame:(CGRect)frame {
        self = [super initWithFrame:frame];
        
        self.notificaLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, frame.size.width, 50)];
        self.notificaLabel.text = @"Notifica";
        self.notificaLabel.textColor = [UIColor blackColor];
        self.notificaLabel.textAlignment = NSTextAlignmentCenter;
        self.notificaLabel.font = [self.notificaLabel.font fontWithSize:50];
        self.notificaLabel.alpha = 0.0;
        [self addSubview:self.notificaLabel];

        self.welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 140, frame.size.width, 30)];
        self.welcomeLabel.text = @"Welcome!";
        self.welcomeLabel.textColor = [UIColor blackColor];
        self.welcomeLabel.textAlignment = NSTextAlignmentCenter;
        self.welcomeLabel.font = [self.welcomeLabel.font fontWithSize:25];
        self.welcomeLabel.alpha = 0.0;
        [self addSubview:self.welcomeLabel];

        self.configureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.configureButton.frame = CGRectMake(0, frame.size.height - 120, frame.size.width, 50);
        [self.configureButton addTarget:self action:@selector(nextStep) forControlEvents:UIControlEventTouchUpInside];
        [self.configureButton setTitle:@"Configure" forState:UIControlStateNormal];
        [self.configureButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        self.configureButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.configureButton.titleLabel.font = [self.configureButton.titleLabel.font fontWithSize:25];
        self.configureButton.alpha = 0.0;
        [self addSubview:self.configureButton];

        UIImage *icon = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/NotificaPrefs.bundle/bigIcon.png"];
        self.iconView = [[UIImageView alloc] initWithImage:icon];
        self.iconView.frame = CGRectMake(frame.size.width/2 - 30, frame.size.height/2 - 30, 60, 60);
        self.iconView.alpha = 0.0;
        [self addSubview:self.iconView];

        return self;
    }


    -(void)nextStep {
        NTFConfigurator *ntfc = (NTFConfigurator *)self.superview;
        [ntfc nextStep];
    }

    -(void)didMoveToSuperview {
        [UIView animateWithDuration:2 animations:^{
            self.notificaLabel.alpha = 1.0;
            self.welcomeLabel.alpha = 1.0;
            self.configureButton.alpha = 1.0;
            self.iconView.alpha = 1.0;
        }];
    }
@end