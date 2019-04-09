#import "SavedSettings.h"
#import "Preferences.h"

@implementation NTFSavedSettingsListController

- (id)initForContentSize:(CGSize)size {
    self = [super init];

    if (self) {
        self.savedSettings = [[NSMutableArray alloc] initWithCapacity:100];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelection:YES];
        [_tableView setAllowsMultipleSelection:NO];
        
        if ([self respondsToSelector:@selector(setView:)])
            [self performSelectorOnMainThread:@selector(setView:) withObject:_tableView waitUntilDone:YES];        
    }

    return self;
}

- (void)loadFromSpecifier:(PSSpecifier *)specifier {
    NSString *title = [specifier name];
    [self setTitle:title];
    [self.navigationItem setTitle:title];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
	[self loadFromSpecifier:specifier];
	[super setSpecifier:specifier];
}

- (void)refreshList {
    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:BUNDLE_ID];
    self.savedSettings = [file objectForKey:@"SavedSettings"];
    self.selectedSettings = [([file objectForKey:@"SelectedSettings"] ?: @"") stringValue];
}

- (id)view {
    return _tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [self refreshList];
}

- (void)dealloc { 
    self.savedSettings = nil;
    [super dealloc];
}

- (NSString*)navigationTitle {
    return @"Saved settings";
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.savedSettings.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SettingsCell"];
    }
    
    NSDictionary *settings = [self.savedSettings objectAtIndex:indexPath.row];
    cell.textLabel.text = settings[@"name"];    
    cell.selected = NO;

    /*if ([settings[@"name"] isEqualToString: self.selectedSettings] && !tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (!tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }*/

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *settings = (NSDictionary*)[self.savedSettings objectAtIndex:indexPath.row];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Notifica"
        message:[NSString stringWithFormat:@"Are you sure you want to restore \"%@\" and respring?", settings[@"name"]]
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action){
            NSDictionary *settings = (NSDictionary*)[self.savedSettings objectAtIndex:indexPath.row];

            NTFPrefsListController *parent = (NTFPrefsListController *)self.parentController;
            [parent restoreSettingsFromDictionary:settings];
            [parent respring:nil];
        }
    ];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }
    ];

    [alert addAction:ok];
    [alert addAction:cancel];

    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NTFPrefsListController *parent = (NTFPrefsListController *)self.parentController;
        [parent removeSavedSettingsAtIndex:indexPath.row];
        [self refreshList];
        [tableView reloadData];
    }
}

@end