#import "Preferences.h"

@implementation NTFPrefsListController
@synthesize respringButton;

- (instancetype)init {
    self = [super init];

    if (self) {
        HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
        appearanceSettings.tintColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1];
        appearanceSettings.tableViewCellSeparatorColor = [UIColor colorWithWhite:0 alpha:0];
        self.hb_appearanceSettings = appearanceSettings;
        self.respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" 
                                    style:UIBarButtonItemStylePlain
                                    target:self 
                                    action:@selector(respring:)];
        self.respringButton.tintColor = [UIColor redColor];
        self.navigationItem.rightBarButtonItem = self.respringButton;
    }

    return self;
}

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Prefs" target:self] retain];
    }
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    CGRect frame = self.table.bounds;
    frame.origin.y = -frame.size.height;
	
    [self.navigationController.navigationController.navigationBar setShadowImage: [UIImage new]];
    self.navigationController.navigationController.navigationBar.translucent = YES;
}

- (void)testNotifications:(id)sender {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"me.nepeta.notifica/TestNotifications", nil, nil, true);
}

- (void)testBanner:(id)sender {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"me.nepeta.notifica/TestBanner", nil, nil, true);
}

- (void)resetPrefs:(id)sender {
    HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
    [prefs removeAllObjects];

    NSError *error;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:COLORS_PATH]) {
        [[NSFileManager defaultManager] removeItemAtPath:COLORS_PATH error:&error];
    }

    [self respring:sender];
}

- (void)respring:(id)sender {
    NSTask *t = [[[NSTask alloc] init] autorelease];
    [t setLaunchPath:@"/usr/bin/killall"];
    [t setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
    [t launch];
}

-(void)removeSavedSettingsAtIndex:(int)i {
    HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
    
    NSMutableArray *savedSettings = nil;

    if ([prefs objectForKey:@"SavedSettings"]) {
        savedSettings = [[prefs objectForKey:@"SavedSettings"] mutableCopy];
        [savedSettings removeObjectAtIndex:i];
    } else {
        savedSettings = [@[] mutableCopy];
    }

    [prefs setObject:savedSettings forKey:@"SavedSettings"];
}

-(NSDictionary*)dictionaryWithCurrentSettingsAndName:(NSString*)name {
    NSMutableDictionary *settingsToSave = [NSMutableDictionary new];

    HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];

    settingsToSave[@"name"] = name;

    settingsToSave[@"prefs"] = [NSMutableDictionary new];
    for (NSString *key in [prefs dictionaryRepresentation]) {
        if ([key isEqualToString:@"SavedSettings"] || [key isEqualToString:@"SelectedSettings"]) continue;
        settingsToSave[@"prefs"][key] = [prefs objectForKey:key];
    }

    NSDictionary *colors = [[NSDictionary alloc] initWithContentsOfFile:COLORS_PATH];
    if (colors) {
        settingsToSave[@"colors"] = colors;
    }

    return settingsToSave;
}

-(void)restoreSettingsFromDictionary:(NSDictionary *)settings {
    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
    for (NSString *key in [file dictionaryRepresentation]) {
        if ([key isEqualToString:@"SavedSettings"] || [key isEqualToString:@"SelectedSettings"]) continue;
        [file removeObjectForKey:key];
    }

    for (NSString *key in settings[@"prefs"]) {
        if ([key isEqualToString:@"SavedSettings"] || [key isEqualToString:@"SelectedSettings"]) continue;
        [file setObject:settings[@"prefs"][key] forKey:key];
    }

    [file setObject:settings[@"name"] forKey:@"SelectedSettings"];

    NSError *error;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:COLORS_PATH]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:COLORS_PATH error:&error];
        if (success && settings[@"colors"]) {
            [settings[@"colors"] writeToFile:COLORS_PATH atomically:YES];
        }
    }
}

-(void)saveCurrentSettingsWithName:(NSString *)name {
    HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];

    NSMutableArray *savedSettings = nil;
    if ([prefs objectForKey:@"SavedSettings"]) {
        savedSettings = [[prefs objectForKey:@"SavedSettings"] mutableCopy];
    } else {
        savedSettings = [@[] mutableCopy];
    }

    [savedSettings addObject:[self dictionaryWithCurrentSettingsAndName:name]];
    [prefs setObject:savedSettings forKey:@"SavedSettings"];
}

-(void)saveSettings:(id)sender {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Notifica"
        message:@"Enter name"
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action){
            NSString *name = [(UITextField *)alert.textFields[0] text];

            [self saveCurrentSettingsWithName:name];

            UIAlertController* savedAlert = [UIAlertController alertControllerWithTitle:@"Notifica"
                                        message:@"Saved!"
                                        preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {}];
            [savedAlert addAction:defaultAction];
            [self presentViewController:savedAlert animated:YES completion:nil];

            [alert dismissViewControllerAnimated:YES completion:nil];
        }
    ];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }
    ];

    [alert addAction:ok];
    [alert addAction:cancel];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"name";
        textField.keyboardType = UIKeyboardTypeDefault;
    }];

    [self presentViewController:alert animated:YES completion:nil];
}
@end