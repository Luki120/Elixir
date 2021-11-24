@import UIKit;
#import <dlfcn.h>
#import <substrate.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>


#define Class(string) NSClassFromString(string)
#define isCurrentApp(string) [[[NSBundle mainBundle] bundleIdentifier] isEqual : string]


@interface UITableView ()
- (id)_viewControllerForAncestor;
@end


@interface PSUIPrefsListController : PSListController
@end


@interface TSRootListController : UIViewController
@property (copy, nonatomic) NSString *title;
@end


@interface AMightyClass : UIView
@property (nonatomic, strong) UILabel *tweakCount;
@property (assign, nonatomic) int elixirTweakCount;
@end


@implementation AMightyClass { // fancy way to avoid code duplication, haha thanks Codine.

	NSString *bundlePath;
	NSArray *directoryContent;

}


+ (AMightyClass *)sharedInstance {

	static AMightyClass *sharedInstance = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{

		sharedInstance = [self new];

	});

	return sharedInstance;

}


- (id)init {

	self = [super init];

	if(self) {

		NSFileManager *fileM = [NSFileManager defaultManager];

		bundlePath = @"/Library/PreferenceLoader/Preferences";
		directoryContent = [fileM contentsOfDirectoryAtPath:bundlePath error:nil];
		self.elixirTweakCount = [directoryContent count];

		[self setupElixirLabel];

	}

	return self;

}


- (void)setupElixirLabel {

	self.tweakCount = [UILabel new];
	self.tweakCount.text = [NSString stringWithFormat:@"%d", self.elixirTweakCount];
	self.tweakCount.font = [UIFont boldSystemFontOfSize:18];
	self.tweakCount.textColor = UIColor.labelColor;
	self.tweakCount.translatesAutoresizingMaskIntoConstraints = NO;

}


@end


void(*origDMTW)(UITableView *self, SEL _cmd);

void overrideDMTW(UITableView *self, SEL _cmd) {

	origDMTW(self, _cmd);

	UIViewController *ancestor = [self _viewControllerForAncestor];

	if([ancestor isKindOfClass:Class(@"OrionTweakSpecifiersController")]) {

		[self addSubview:[AMightyClass sharedInstance].tweakCount];

		// Hi, if you've reached to this part, please, do yourself a favor if this is your case.
		// Stop doing cursed and weird af UIScreen calculations and math with frames for UI layout stuff, 
		// learn and embrace constraints instead, they are natural and beautiful. Also known as AutoLayout, AUTO (It does the thing for you!!!)

		[[AMightyClass sharedInstance].tweakCount.topAnchor constraintEqualToAnchor : self.topAnchor constant : 8].active = YES;
		[[AMightyClass sharedInstance].tweakCount.centerXAnchor constraintEqualToAnchor : self.centerXAnchor].active = YES;

	}

	else if([ancestor isKindOfClass:Class(@"TweakPreferencesListController")]) { // Shuffle has a search bar so no space at the top :thishowitis:

		UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 10)];
		[footerView addSubview:[AMightyClass sharedInstance].tweakCount];

		self.tableFooterView = footerView;

		[[AMightyClass sharedInstance].tweakCount.centerXAnchor constraintEqualToAnchor : footerView.centerXAnchor].active = YES;
		[[AMightyClass sharedInstance].tweakCount.centerYAnchor constraintEqualToAnchor : footerView.centerYAnchor constant : -4].active = YES;

	}

}

void(*origTSVDL)(TSRootListController *self, SEL _cmd);

void overrideTSVDL(TSRootListController *self, SEL _cmd) {

	origTSVDL(self, _cmd);

	if(!(isCurrentApp(@"com.creaturecoding.tweaksettings"))) return;

	self.title = [NSString stringWithFormat:@"%d", [AMightyClass sharedInstance].elixirTweakCount];

}

void (*origVDL)(PSUIPrefsListController *self, SEL _cmd);

void overrideVDL(PSUIPrefsListController *self, SEL _cmd) {

	origVDL(self, _cmd);

	PSSpecifier *emptySpecifier = [PSSpecifier emptyGroupSpecifier];

	NSString *elixirTweakCountLabel = [NSString stringWithFormat:@"%d Tweaks", [AMightyClass sharedInstance].elixirTweakCount];
	PSSpecifier *elixirSpecifier = [PSSpecifier preferenceSpecifierNamed:elixirTweakCountLabel target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
	[elixirSpecifier setProperty:@YES forKey:@"enabled"];
	[self insertContiguousSpecifiers:@[emptySpecifier, elixirSpecifier] afterSpecifier:[self specifierForID:@"APPLE_ACCOUNT"]];

}


__attribute__((constructor)) static void init() {

	MSHookMessageEx(Class(@"TSRootListController"), @selector(viewDidLoad), (IMP) &overrideTSVDL, (IMP *) &origTSVDL);

	if(dlopen("/Library/MobileSubstrate/DynamicLibraries/OrionSettings.dylib", RTLD_LAZY) != NULL || dlopen("/Library/MobileSubstrate/DynamicLibraries/shuffle.dylib", RTLD_LAZY) != NULL)

		MSHookMessageEx(Class(@"UITableView"), @selector(didMoveToWindow), (IMP) &overrideDMTW, (IMP *) &origDMTW);

	else MSHookMessageEx(Class(@"PSUIPrefsListController"), @selector(viewDidLoad), (IMP) &overrideVDL, (IMP *) &origVDL);

}
