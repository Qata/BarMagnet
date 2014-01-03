//
//  HelpViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 17/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()
@property (nonatomic, strong) NSDictionary * helpDictionary;
@end

@implementation HelpViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.textView.text = @{@"HTTPS":@"Only use HTTPS if you have enabled it on your server and have opened port 443.", @"Query":@"The query format is used to search a torrent site, to use it, you just replace the part of the URL where your query would normally be, with \"%query%\", \ne.g. \"http://www.google.com/q=%query%\"", @"Torrent Site":@"The torrent site is a static website that you can use when you just want to browse instead of searching, e.g. \"www.google.com\"", @"Relative Path":@"The relative path field does not need to use set unless you have ruTorrent or you have configured your torrent client to not use the default path.", @"Directory":@"The directory field only applies to ruTorrent at this time, it specifies which directory to save the files in.", @"Label":@"The label field is purely for ruTorrent. It seems to be entirely aesthetic but can help keep track of multiple users downloading to the same client."}[self.key];
}

- (IBAction)emailDeveloper:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[NSBundle mainBundle] infoDictionary][@"Email Address"]]];
}

@end