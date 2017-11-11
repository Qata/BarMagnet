//
//  XirvikQRCodeViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 2017-11-04.
//  Copyright © 2017 Charlotte Tortorella. All rights reserved.
//

#import "XirvikQRCodeViewController.h"
@import AVFoundation;

@interface XirvikQRCodeViewController ()
@property(nonatomic, assign) BOOL dismissing;
@end

@implementation XirvikQRCodeViewController

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSArray * elements = [[metadataObjects.firstObject stringValue] componentsSeparatedByString:@"\n"];
    if (elements.count == 3 && !self.dismissing) {
        self.dismissing = YES;
        self.delegate.hostnameField.text = elements[0];
        self.delegate.passwordField.text = elements[2];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
