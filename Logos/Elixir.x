@import UIKit;
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>


// Global

UIViewController *ancestor;

#define isCurrentApp(string) [[[NSBundle mainBundle] bundleIdentifier] isEqual : string]


@interface PSListController ()
- (BOOL)areOrionOrShuffleInstalled;
@end


@interface UITableView ()
@property (nonatomic, strong) UILabel *tweakCount;
- (id)_viewControllerForAncestor;
@end


@interface TSRootListController : UIViewController
@property (copy, nonatomic) NSString *title;
@end


@interface AMightyClass : UIView
@property (nonatomic, strong) UILabel *tweakCount;
@property (copy, nonatomic) NSString *bundlePath;
@property (nonatomic, strong) NSArray *directoryContent;
@property (nonatomic) int elixirTweakCount;
@property (nonatomic, strong) NSFileManager *fileM;
@end


@implementation AMightyClass // fancy way to avoid code duplication, haha thanks Codine. But properties >> iVars


+ (AMightyClass *)sharedInstance {

	static AMightyClass *sharedInstance = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		
		sharedInstance = [AMightyClass new];

	});

	return sharedInstance;

}


- (instancetype)init {

	self = [super init];

	self.fileM = [NSFileManager defaultManager];

	self.bundlePath = @"/Library/PreferenceLoader/Preferences";
	self.directoryContent = [self.fileM contentsOfDirectoryAtPath:self.bundlePath error:nil];
	self.elixirTweakCount = [self.directoryContent count];

	[self setupElixirLabel];

	return self;

}


- (void)setupElixirLabel {

	self.tweakCount = [UILabel new];
	self.tweakCount.text = [NSString stringWithFormat:@"%d", self.elixirTweakCount];
	self.tweakCount.font = [UIFont boldSystemFontOfSize:18];
	self.tweakCount.translatesAutoresizingMaskIntoConstraints = NO;

}


@end


%hook UITableView


%property (nonatomic, strong) UILabel *tweakCount;


- (void)didMoveToWindow { // support for preference organizers tweaks


	%orig;

	ancestor = [self _viewControllerForAncestor];

	if([ancestor isKindOfClass:%c(OrionTweakSpecifiersController)]) {

		[self addSubview:[AMightyClass sharedInstance].tweakCount];

		// Hi, if you've reached to this part, please, do yourself a favor if this is your case.
		// Stop doing cursed and weird af UIScreen calculations and math with frames for UI layout stuff, 
		// learn and embrace constraints instead, they are natural and beautiful. Also known as AutoLayout, AUTO (It does the thing for you!!!)

		[[AMightyClass sharedInstance].tweakCount.centerXAnchor constraintEqualToAnchor : self.centerXAnchor].active = YES;
		[[AMightyClass sharedInstance].tweakCount.topAnchor constraintEqualToAnchor : self.topAnchor constant : 8].active = YES;

	}

	else if([ancestor isKindOfClass:%c(TweakPreferencesListController)]) { // Shuffle has a search bar so no space at the top :thishowitis:

		UIView *fuckingFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 10)];
		[fuckingFooterView addSubview:[AMightyClass sharedInstance].tweakCount];

		self.tableFooterView = fuckingFooterView;

		[[AMightyClass sharedInstance].tweakCount.centerXAnchor constraintEqualToAnchor : fuckingFooterView.centerXAnchor].active = YES;
		[[AMightyClass sharedInstance].tweakCount.centerYAnchor constraintEqualToAnchor : fuckingFooterView.centerYAnchor constant : 4].active = YES;


	}

}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {

 
	%orig;

	if(self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) 

		[AMightyClass sharedInstance].tweakCount.textColor = UIColor.whiteColor;

	else [AMightyClass sharedInstance].tweakCount.textColor = UIColor.blackColor;


}


%end




%hook TSRootListController


- (void)viewDidLoad { // support for Tweak Settings app


	%orig;

	if(!(isCurrentApp(@"com.creaturecoding.tweaksettings"))) return;

	self.title = [NSString stringWithFormat:@"%d", [AMightyClass sharedInstance].elixirTweakCount];


}


%end




%hook PSListController


- (void)viewDidLoad { // support for normal preferences


	%orig;

	if([self areOrionOrShuffleInstalled]) return;

	if(![self isMemberOfClass:%c(PSUIPrefsListController)]) return;

	PSSpecifier *emptySpecifier = [PSSpecifier emptyGroupSpecifier];

	NSString *elixirTweakCountLabel = [NSString stringWithFormat:@"%d Tweaks", [AMightyClass sharedInstance].elixirTweakCount];
	PSSpecifier *elixirSpecifier = [PSSpecifier preferenceSpecifierNamed:elixirTweakCountLabel target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
	[self insertContiguousSpecifiers:@[emptySpecifier, elixirSpecifier] afterSpecifier:[self specifierForID:@"APPLE_ACCOUNT"]];


}


%new

- (BOOL)areOrionOrShuffleInstalled {


	return (%c(OrionTweakSpecifiersController) || %c(TweakPreferencesListController));


}


%end