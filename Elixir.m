@import UIKit;
#import <dlfcn.h>
#import <substrate.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>


#define kClass(string) NSClassFromString(string)
#define kIsCurrentApp(string) [[[NSBundle mainBundle] bundleIdentifier] isEqual: string]
#define kOrion dlopen("/Library/MobileSubstrate/DynamicLibraries/OrionSettings.dylib", RTLD_LAZY)
#define kShuffle dlopen("/Library/MobileSubstrate/DynamicLibraries/shuffle.dylib", RTLD_LAZY)


@interface PSUIPrefsListController : PSListController
@end


@interface TSRootListController : UIViewController
@property (copy, nonatomic) NSString *title;
@end


@interface UITableView ()
- (UIViewController *)_viewControllerForAncestor;
@end


@interface ElixirLabel : UILabel
@property (assign, nonatomic) NSInteger elixirTweakCount;
@end


@implementation ElixirLabel { // fancy way to avoid code duplication, haha thanks Cero

	NSString *bundlePath;
	NSArray *directoryContent;

}


+ (ElixirLabel *)sharedInstance {

	static ElixirLabel *sharedInstance = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{ sharedInstance = [self new]; });

	return sharedInstance;

}


- (id)init {

	self = [super init];
	if(!self) return nil;

	NSFileManager *fileM = [NSFileManager defaultManager];

	bundlePath = @"/Library/PreferenceLoader/Preferences/";
	directoryContent = [fileM contentsOfDirectoryAtPath:bundlePath error:nil];
	self.elixirTweakCount = [directoryContent count];

	[self setupElixirLabel];

	return self;

}


- (void)setupElixirLabel {

	self.font = [UIFont boldSystemFontOfSize: 18];
	self.text = [NSString stringWithFormat:@"%ld", self.elixirTweakCount];
	self.textColor = UIColor.labelColor;
	self.translatesAutoresizingMaskIntoConstraints = NO;

}


- (void)centerElixirLabelOnBothAxesOfView:(UIView *)view {

	// Hi, if you've reached here, please do yourself a favor if this is your case.
	// Stop doing cursed and weird af UIScreen calculations and math with frames for UI layout stuff, 
	// learn and embrace constraints instead, they are natural and beautiful,
	// also known as AutoLayout, AUTO (it does the thing for you!!!)

	[self.centerXAnchor constraintEqualToAnchor: view.centerXAnchor].active = YES;
	[self.centerYAnchor constraintEqualToAnchor: view.centerYAnchor constant: -4].active = YES;

}


- (void)pinElixirLabelToTheTopCenteredOnTheXAxisOfView:(UIView *)view {

	[self.topAnchor constraintEqualToAnchor: view.topAnchor constant: 8].active = YES;
	[self.centerXAnchor constraintEqualToAnchor: view.centerXAnchor].active = YES;

}

@end


static void(*origDMTW)(UITableView *self, SEL _cmd);

static void overrideDMTW(UITableView *self, SEL _cmd) {

	origDMTW(self, _cmd);

	UIViewController *ancestor = [self _viewControllerForAncestor];

	if([ancestor isKindOfClass:kClass(@"OrionTweakSpecifiersController")]) {

		[self addSubview:[ElixirLabel sharedInstance]];
		[[ElixirLabel sharedInstance] pinElixirLabelToTheTopCenteredOnTheXAxisOfView: self];

	}

	else if([ancestor isKindOfClass:kClass(@"TweakPreferencesListController")]) { // Shuffle has a search bar so no space at the top :thishowitis:

		UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 10)];
		[footerView addSubview:[ElixirLabel sharedInstance]];

		self.tableFooterView = footerView;
		[[ElixirLabel sharedInstance] centerElixirLabelOnBothAxesOfView: footerView];

	}

}

static void(*origTSVDL)(TSRootListController *self, SEL _cmd);

static void overrideTSVDL(TSRootListController *self, SEL _cmd) {

	origTSVDL(self, _cmd);
	self.title = [NSString stringWithFormat:@"%ld", [ElixirLabel sharedInstance].elixirTweakCount];

}

static void (*origVDL)(PSUIPrefsListController *self, SEL _cmd);

static void overrideVDL(PSUIPrefsListController *self, SEL _cmd) {

	origVDL(self, _cmd);

	PSSpecifier *emptySpecifier = [PSSpecifier emptyGroupSpecifier];

	NSString *elixirTweakCountLabel = [NSString stringWithFormat:@"%ld Tweaks", [ElixirLabel sharedInstance].elixirTweakCount];
	PSSpecifier *elixirSpecifier = [PSSpecifier preferenceSpecifierNamed:elixirTweakCountLabel target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
	[elixirSpecifier setProperty:@YES forKey:@"enabled"];
	[self insertContiguousSpecifiers:@[emptySpecifier, elixirSpecifier] afterSpecifier:[self specifierForID:@"APPLE_ACCOUNT"]];

}


__attribute__((constructor)) static void init() {

	if(kOrion != nil || kShuffle != nil)

		MSHookMessageEx(kClass(@"UITableView"), @selector(didMoveToWindow), (IMP) &overrideDMTW, (IMP *) &origDMTW);

	else MSHookMessageEx(kClass(@"PSUIPrefsListController"), @selector(viewDidLoad), (IMP) &overrideVDL, (IMP *) &origVDL);

	if(!kIsCurrentApp(@"com.creaturecoding.tweaksettings")) return;
	MSHookMessageEx(kClass(@"TSRootListController"), @selector(viewDidLoad), (IMP) &overrideTSVDL, (IMP *) &origTSVDL);

}
