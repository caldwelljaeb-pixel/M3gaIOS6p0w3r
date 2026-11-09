#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface M3gaEmojiBrowserController : UIViewController <UISearchBarDelegate, UIActionSheetDelegate> {
    UISearchBar *_searchBar;
    UIScrollView *_emojiScrollView;
    UILabel *_creditLabel;
    UILabel *_copyNotice;
    NSArray *_allEmojis;
    NSMutableArray *_visibleEmojis;
    NSDictionary *_selectedEmoji;
}
@end

@interface M3gaEmojiAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *_window;
}
@property (nonatomic, retain) UIWindow *window;
@end

@implementation M3gaEmojiAppDelegate
@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    M3gaEmojiBrowserController *browser = [[[M3gaEmojiBrowserController alloc] init] autorelease];
    UINavigationController *navigation = [[[UINavigationController alloc] initWithRootViewController:browser] autorelease];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)dealloc {
    [_window release];
    [super dealloc];
}
@end

@implementation M3gaEmojiBrowserController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"M3gaEmojiVault";
    self.view.backgroundColor = [UIColor whiteColor];

    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"Search emoji or name";
    _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:_searchBar];

    _emojiScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _emojiScrollView.alwaysBounceVertical = YES;
    _emojiScrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_emojiScrollView];

    _creditLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _creditLabel.text = @"made with ❤️ by M3gaIOS6p0w3r";
    _creditLabel.font = [UIFont systemFontOfSize:9.0];
    _creditLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    _creditLabel.textAlignment = NSTextAlignmentCenter;
    _creditLabel.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_creditLabel];

    _copyNotice = [[UILabel alloc] initWithFrame:CGRectZero];
    _copyNotice.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.92];
    _copyNotice.textColor = [UIColor whiteColor];
    _copyNotice.font = [UIFont boldSystemFontOfSize:12.0];
    _copyNotice.textAlignment = NSTextAlignmentCenter;
    _copyNotice.layer.cornerRadius = 8.0;
    _copyNotice.clipsToBounds = YES;
    _copyNotice.alpha = 0.0;
    [self.view addSubview:_copyNotice];

    [self loadEmojiList];
    [self filterEmojisWithText:@""];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    _searchBar.frame = CGRectMake(0.0, 0.0, width, 44.0);
    _creditLabel.frame = CGRectMake(0.0, height - 22.0, width, 22.0);
    _emojiScrollView.frame = CGRectMake(0.0, 44.0, width, height - 66.0);
    _copyNotice.frame = CGRectMake((width - 170.0) / 2.0, height - 58.0, 170.0, 28.0);
    [self rebuildGrid];
}

- (void)loadEmojiList {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Emoji" ofType:@"tsv"];
    NSString *contents = path ? [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] : nil;
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *line in [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        if ([line length] == 0 || [line hasPrefix:@"#"]) continue;
        NSArray *parts = [line componentsSeparatedByString:@"\t"];
        if ([parts count] < 3) continue;
        NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
                              [parts objectAtIndex:0], @"symbol",
                              [parts objectAtIndex:1], @"name",
                              [parts objectAtIndex:2], @"category", nil];
        [items addObject:item];
    }
    _allEmojis = [items copy];
}

- (void)filterEmojisWithText:(NSString *)text {
    [_visibleEmojis release];
    _visibleEmojis = [[NSMutableArray alloc] init];
    NSString *query = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSDictionary *item in _allEmojis) {
        NSString *symbol = [item objectForKey:@"symbol"];
        NSString *name = [item objectForKey:@"name"];
        NSString *category = [item objectForKey:@"category"];
        if ([query length] == 0 ||
            [symbol rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [name rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [category rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [_visibleEmojis addObject:item];
        }
    }
    [self rebuildGrid];
}

- (void)rebuildGrid {
    if (!_emojiScrollView || !_visibleEmojis) return;
    NSArray *oldSubviews = [[_emojiScrollView.subviews copy] autorelease];
    for (UIView *subview in oldSubviews) {
        [subview removeFromSuperview];
    }

    CGFloat width = _emojiScrollView.bounds.size.width;
    if (width < 1.0) width = self.view.bounds.size.width;
    NSInteger columns = 4;
    CGFloat cellWidth = floor(width / columns);
    CGFloat cellHeight = 70.0;

    for (NSUInteger index = 0; index < [_visibleEmojis count]; index++) {
        NSDictionary *item = [_visibleEmojis objectAtIndex:index];
        NSInteger row = (NSInteger)(index / columns);
        NSInteger column = (NSInteger)(index % columns);
        CGFloat x = column * cellWidth;
        CGFloat y = row * cellHeight;

        UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(x + 3.0, y + 3.0, cellWidth - 6.0, cellHeight - 6.0)];
        cell.backgroundColor = [UIColor colorWithWhite:0.965 alpha:1.0];
        cell.layer.cornerRadius = 7.0;

        UIButton *emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        emojiButton.frame = CGRectMake(0.0, 0.0, cellWidth - 6.0, 43.0);
        [emojiButton setTitle:[item objectForKey:@"symbol"] forState:UIControlStateNormal];
        UIFont *emojiFont = [UIFont fontWithName:@"AppleColorEmoji" size:30.0];
        emojiButton.titleLabel.font = emojiFont ? emojiFont : [UIFont systemFontOfSize:30.0];
        [emojiButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        emojiButton.tag = index;
        [emojiButton addTarget:self action:@selector(copyEmojiTapped:) forControlEvents:UIControlEventTouchUpInside];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(emojiLongPressed:)];
        longPress.minimumPressDuration = 0.45;
        longPress.cancelsTouchesInView = YES;
        [emojiButton addGestureRecognizer:longPress];
        [longPress release];

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(2.0, 43.0, cellWidth - 10.0, 18.0)];
        nameLabel.text = [item objectForKey:@"name"];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.font = [UIFont systemFontOfSize:8.0];
        nameLabel.textColor = [UIColor darkGrayColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.adjustsFontSizeToFitWidth = YES;
        nameLabel.minimumFontSize = 6.0;
        nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        [cell addSubview:emojiButton];
        [cell addSubview:nameLabel];
        [_emojiScrollView addSubview:cell];
        [nameLabel release];
        [cell release];
    }

    NSInteger rows = (NSInteger)(([_visibleEmojis count] + columns - 1) / columns);
    _emojiScrollView.contentSize = CGSizeMake(width, rows * cellHeight + 6.0);
}

- (void)copyEmojiTapped:(UIButton *)sender {
    if (sender.tag >= [_visibleEmojis count]) return;
    NSDictionary *item = [_visibleEmojis objectAtIndex:sender.tag];
    [self copyEmojiItem:item];
}

- (void)emojiLongPressed:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    UIButton *button = (UIButton *)recognizer.view;
    if (button.tag >= [_visibleEmojis count]) return;
    _selectedEmoji = [[_visibleEmojis objectAtIndex:button.tag] retain];
    NSString *title = [NSString stringWithFormat:@"%@\n%@", [_selectedEmoji objectForKey:@"symbol"], [_selectedEmoji objectForKey:@"name"]];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:title
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Copy", nil];
    [sheet showInView:self.view];
    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && _selectedEmoji) [self copyEmojiItem:_selectedEmoji];
    [_selectedEmoji release];
    _selectedEmoji = nil;
}

- (void)copyEmojiItem:(NSDictionary *)item {
    NSString *symbol = [item objectForKey:@"symbol"];
    [UIPasteboard generalPasteboard].string = symbol;
    _copyNotice.text = [NSString stringWithFormat:@"Copied %@   ✓", symbol];
    _copyNotice.alpha = 1.0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCopyNotice) object:nil];
    [self performSelector:@selector(hideCopyNotice) withObject:nil afterDelay:1.15];
}

- (void)hideCopyNotice {
    [UIView beginAnimations:@"hideCopyNotice" context:nil];
    [UIView setAnimationDuration:0.25];
    _copyNotice.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self filterEmojisWithText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)dealloc {
    [_searchBar release];
    [_emojiScrollView release];
    [_creditLabel release];
    [_copyNotice release];
    [_allEmojis release];
    [_visibleEmojis release];
    [_selectedEmoji release];
    [super dealloc];
}
@end

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int returnValue = UIApplicationMain(argc, argv, nil, NSStringFromClass([M3gaEmojiAppDelegate class]));
    [pool drain];
    return returnValue;
}
