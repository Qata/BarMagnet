//
//  SVWebViewController.m
//
//  Created by Sam Vermette on 08.11.10.
//  Copyright 2010 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "SVWebViewController.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"

static const CGFloat kNavBarHeight = 52.0f;
static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 2.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 26.0f;

@interface SVWebViewController () <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSArray *adKeys;
@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong, readonly) UIActionSheet *pageActionSheet;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* stop;
@property (nonatomic, strong) UILabel* pageTitle;
@property (nonatomic, strong) UITextField* addressField;

@property (nonatomic, strong) UIWebView *mainWebView;
@property (nonatomic, strong) NSURL *URL;

@property (nonatomic, strong) NSMutableData * torrentData;
@property (nonatomic, strong) NSURL * torrentURL;

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL*)URL;
- (void)loadURL:(NSURL*)URL;

- (void)updateToolbarItems;

- (void)goBackClicked:(UIBarButtonItem *)sender;
- (void)goForwardClicked:(UIBarButtonItem *)sender;
- (void)reloadClicked:(UIBarButtonItem *)sender;
- (void)stopClicked:(UIBarButtonItem *)sender;
- (void)actionButtonClicked:(UIBarButtonItem *)sender;

@end

@interface UINavigationController (DismissAnimated)

- (void)dismissViewControllerAnimated;

@end

@implementation UINavigationController (DismissAnimated)

- (void)dismissViewControllerAnimated
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation SVWebViewController

@synthesize availableActions;

@synthesize URL, mainWebView;
@synthesize backBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, actionBarButtonItem, pageActionSheet;

#pragma mark - setters and getters

- (UIBarButtonItem *)backBarButtonItem {
    
    if (!backBarButtonItem) {
        backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/SVWebViewControllerBack"] style:UIBarButtonItemStylePlain target:self action:@selector(goBackClicked:)];
        backBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
		backBarButtonItem.width = 18.0f;
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    
    if (!forwardBarButtonItem) {
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/SVWebViewControllerNext"] style:UIBarButtonItemStylePlain target:self action:@selector(goForwardClicked:)];
        forwardBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
		forwardBarButtonItem.width = 18.0f;
    }
    return forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    
    if (!refreshBarButtonItem) {
        refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    }
    
    return refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    
    if (!stopBarButtonItem) {
        stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    }
    return stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    
    if (!actionBarButtonItem) {
        actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonClicked:)];
    }
    return actionBarButtonItem;
}

- (UIActionSheet *)pageActionSheet {
    
    if(!pageActionSheet) {
        pageActionSheet = [[UIActionSheet alloc] 
                        initWithTitle:self.mainWebView.request.URL.absoluteString
                        delegate:self 
                        cancelButtonTitle:nil   
                        destructiveButtonTitle:nil   
                        otherButtonTitles:nil]; 

        if((self.availableActions & SVWebViewControllerAvailableActionsCopyLink) == SVWebViewControllerAvailableActionsCopyLink)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Copy Link", @"SVWebViewController", @"")];
        
        if((self.availableActions & SVWebViewControllerAvailableActionsOpenInSafari) == SVWebViewControllerAvailableActionsOpenInSafari)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Open in Safari", @"SVWebViewController", @"")];
        
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]] && (self.availableActions & SVWebViewControllerAvailableActionsOpenInChrome) == SVWebViewControllerAvailableActionsOpenInChrome)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Open in Chrome", @"SVWebViewController", @"")];
        
        if([MFMailComposeViewController canSendMail] && (self.availableActions & SVWebViewControllerAvailableActionsMailLink) == SVWebViewControllerAvailableActionsMailLink)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Mail Link to this Page", @"SVWebViewController", @"")];
        
        [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"SVWebViewController", @"")];
        pageActionSheet.cancelButtonIndex = [self.pageActionSheet numberOfButtons]-1;
    }
    
    return pageActionSheet;
}

#pragma mark - Initialization

- (id)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL*)pageURL
{
    
    if(self = [super init])
	{
        self.URL = pageURL;
        self.availableActions = SVWebViewControllerAvailableActionsOpenInSafari | SVWebViewControllerAvailableActionsOpenInChrome | SVWebViewControllerAvailableActionsMailLink;
    }
    
    return self;
}

- (void)loadURL:(NSURL *)pageURL {
    [mainWebView loadRequest:[NSURLRequest requestWithURL:pageURL]];
}

#pragma mark - View lifecycle

- (void)loadView {
    mainWebView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    mainWebView.delegate = self;
    mainWebView.scalesPageToFit = YES;
    [self loadURL:self.URL];
    self.view = mainWebView;
}

- (void)loadAddress:(id)sender event:(UIEvent *)event
{
	if ([self.addressField.text length])
	{
		if ([self.addressField.text rangeOfString:@"https://"].location != NSNotFound)
		{
			[self.mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.addressField.text]]];
		}
		else
		{
			[self.mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[@"http://" stringByAppendingString:self.addressField.text]]]];
		}
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.torrentData = NSMutableData.new;
	self.adKeys = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"AdBlocker" ofType:@"plist"]][@"ads"];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:[self navigationController] action:@selector(dismissViewControllerAnimated)];
    [self updateToolbarItems];
}

- (void)showPageAddress
{
	[[UIAlertView.alloc initWithTitle:mainWebView.request.URL.absoluteString message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    mainWebView = nil;
    backBarButtonItem = nil;
    forwardBarButtonItem = nil;
    refreshBarButtonItem = nil;
    stopBarButtonItem = nil;
    actionBarButtonItem = nil;
    pageActionSheet = nil;
}

- (void)viewWillAppear:(BOOL)animated {

    NSAssert(self.navigationController, @"SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.");
    
	[super viewWillAppear:animated];
	
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (void)dealloc
{
    [mainWebView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    mainWebView.delegate = nil;
}

#pragma mark - Toolbar

- (void)updateToolbarItems {
    self.backBarButtonItem.enabled = self.self.mainWebView.canGoBack;
    self.forwardBarButtonItem.enabled = self.self.mainWebView.canGoForward;
    self.actionBarButtonItem.enabled = !self.self.mainWebView.isLoading;

    UIBarButtonItem *refreshStopBarButtonItem = self.self.mainWebView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat toolbarWidth = 250.0f;
        fixedSpace.width = 35.0f;

        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          refreshStopBarButtonItem,
                          fixedSpace,
                          self.backBarButtonItem,
                          fixedSpace,
                          self.forwardBarButtonItem,
                          fixedSpace,
                          self.actionBarButtonItem,
                          nil];

        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarWidth, 44.0f)];
        toolbar.items = items;
        toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    }

    else {
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.backBarButtonItem,
                          flexibleSpace,
                          self.forwardBarButtonItem,
                          flexibleSpace,
                          refreshStopBarButtonItem,
                          flexibleSpace,
                          self.actionBarButtonItem,
                          fixedSpace,
                          nil];

        self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.toolbarItems = items;
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"%@", request.URL.absoluteString);
	for (NSString * key in self.adKeys)
	{
		if ([request.URL.absoluteString rangeOfString:key].location != NSNotFound)
		{
			return NO;
		}
	}

	if ([[request URL] absoluteString].length > 7 && [[[[request URL] absoluteString] substringToIndex:7] isEqual:@"magnet:"])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient handleMagnetLink:request.URL.absoluteString];
		[TorrentDelegate.sharedInstance.currentlySelectedClient showNotification:self.navigationController];
		return NO;
	}
	else if ([[request URL] absoluteString].length > 8 && [[[[request URL] absoluteString] substringFromIndex:request.URL.absoluteString.length - 8] isEqual:@".torrent"])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentURL:request.URL];
		[TorrentDelegate.sharedInstance.currentlySelectedClient showNotification:self.navigationController];
		return NO;
	}
	else
	{
		[NSURLConnection connectionWithRequest:request delegate:self];
	}
	return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([response.MIMEType isEqualToString:@"application/x-bittorrent"])
	{
		self.torrentURL = response.URL;
	}
	else
	{
		[connection cancel];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.torrentData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[TorrentDelegate.sharedInstance.currentlySelectedClient showNotification:self.navigationController];
	[TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentData:self.torrentData withURL:self.torrentURL];
	self.torrentData = NSMutableData.new;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[self updateToolbarItems];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

	NSString *strJSFunction = [NSString stringWithFormat:@"function increaseMaxZoomFactor(){var element = document.createElement('meta'); element.name = \"viewport\"; element.content = \"maximum-scale=15.0\"; var head = document.getElementsByTagName('head')[0]; head.appendChild(element);}"];

	[webView stringByEvaluatingJavaScriptFromString:strJSFunction];
	[webView stringByEvaluatingJavaScriptFromString:@"increaseMaxZoomFactor()"];
	if ([[[[webView request] URL] absoluteString] isEqual:@"about:blank"])
	{
		[webView goBack];
	}
	else
	{
		UILabel * titleView = [UILabel.alloc initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
		titleView.backgroundColor = UIColor.clearColor;
		titleView.textAlignment = NSTextAlignmentCenter;
		if ([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] < 7)
		{
			titleView.textColor = [UIColor whiteColor];
		}
		titleView.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
		titleView.userInteractionEnabled = YES;
		[titleView addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(showPageAddress)]];
		self.navigationItem.titleView = titleView;
		[self updateToolbarItems];
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbarItems];
}

#pragma mark - Target actions

- (void)goBackClicked:(UIBarButtonItem *)sender {
    [mainWebView goBack];
}

- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [mainWebView goForward];
}

- (void)reloadClicked:(UIBarButtonItem *)sender {
    [mainWebView reload];
}

- (void)stopClicked:(UIBarButtonItem *)sender {
    [mainWebView stopLoading];
	[self updateToolbarItems];
}

- (void)actionButtonClicked:(id)sender {
    
    if(pageActionSheet)
        return;
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self.pageActionSheet showFromBarButtonItem:self.actionBarButtonItem animated:YES];
    else
        [self.pageActionSheet showFromToolbar:self.navigationController.toolbar];
    
}

- (void)doneButtonClicked:(id)sender
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
    [self dismissModalViewControllerAnimated:YES];
#else
    [self dismissViewControllerAnimated:YES completion:NULL];
#endif
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	if([title localizedCompare:NSLocalizedStringFromTable(@"Open in Safari", @"SVWebViewController", @"")] == NSOrderedSame)
        [[UIApplication sharedApplication] openURL:self.mainWebView.request.URL];
    
    if([title localizedCompare:NSLocalizedStringFromTable(@"Open in Chrome", @"SVWebViewController", @"")] == NSOrderedSame) {
        NSURL *inputURL = self.mainWebView.request.URL;
        NSString *scheme = inputURL.scheme;
        
        NSString *chromeScheme = nil;
        if ([scheme isEqualToString:@"http"]) {
            chromeScheme = @"googlechrome";
        } else if ([scheme isEqualToString:@"https"]) {
            chromeScheme = @"googlechromes";
        }
        
        if (chromeScheme) {
            NSString *absoluteString = [inputURL absoluteString];
            NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
            NSString *urlNoScheme =
            [absoluteString substringFromIndex:rangeForScheme.location];
            NSString *chromeURLString =
            [chromeScheme stringByAppendingString:urlNoScheme];
            NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
            
            [[UIApplication sharedApplication] openURL:chromeURL];
        }
    }
    
    if([title localizedCompare:NSLocalizedStringFromTable(@"Copy Link", @"SVWebViewController", @"")] == NSOrderedSame) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.mainWebView.request.URL.absoluteString;
    }
    
    else if([title localizedCompare:NSLocalizedStringFromTable(@"Mail Link to this Page", @"SVWebViewController", @"")] == NSOrderedSame) {
        
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        
		mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:[self.mainWebView stringByEvaluatingJavaScriptFromString:@"document.title"]];
  		[mailViewController setMessageBody:self.mainWebView.request.URL.absoluteString isHTML:NO];
		mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
		[self presentModalViewController:mailViewController animated:YES];
#else
        [self presentViewController:mailViewController animated:YES completion:NULL];
#endif
	}
    
    pageActionSheet = nil;
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
	[self dismissModalViewControllerAnimated:YES];
#else
    [self dismissViewControllerAnimated:YES completion:NULL];
#endif
}

@end
