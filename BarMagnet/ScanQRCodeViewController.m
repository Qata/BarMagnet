//
//  ScanQRCodeViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 26/01/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

@import AVFoundation;
#import "ScanQRCodeViewController.h"
#import "TorrentDelegate.h"
#import "SVModalWebViewController.h"

@interface ScanQRCodeViewController ()
@property (nonatomic, assign) BOOL presenting;
@end

@implementation ScanQRCodeViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[TorrentDelegate.sharedInstance.currentlySelectedClient showNotification:self.navigationController];
	AVCaptureSession *session = AVCaptureSession.new;
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;

	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	if (input)
	{
		[session addInput:input];
	}
	else
	{
		NSLog(@"Error: %@", error);
	}

	AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
	[output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
	[session addOutput:output];
#if !TARGET_IPHONE_SIMULATOR
	[output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
#endif
	AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    previewLayer.frame = self.view.frame;
    [self.view.layer addSublayer:previewLayer];

	[session startRunning];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.presenting = NO;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
	NSString * text = [metadataObjects.firstObject stringValue];
	NSString * magnet = @"magnet:";
	NSString * torrent = @".torrent";
	NSString * http = @"http";
	if (text.length > magnet.length && [[text substringWithRange:NSMakeRange(0, magnet.length)] isEqual:magnet])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient handleMagnetLink:text];
	}
	else if (text.length > torrent.length && [[text substringWithRange:NSMakeRange(text.length - torrent.length, torrent.length)] isEqual:torrent])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentURL:[NSURL URLWithString:text]];
	}
	else if (text.length > http.length && [[text substringWithRange:NSMakeRange(0, http.length)] isEqual:http])
	{
		if (!self.presenting++)
		{
			SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:text];
			[self.navigationController presentViewController:webViewController animated:YES completion:nil];
		}
	}
}

@end
