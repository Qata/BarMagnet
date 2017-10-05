//
//  UINavigationController+NoAutoRotation.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 20/11/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "UINavigationControllerNoAutoRotation.h"

@implementation UINavigationControllerNoAutoRotation

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationBar.prefersLargeTitles = YES;
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
@end
