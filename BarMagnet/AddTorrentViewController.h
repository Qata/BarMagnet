//
//  AddTorrentViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 15/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddTorrentViewController : UIViewController <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *textBox;
@property (strong, nonatomic) IBOutlet UIButton *scanQRCodeButton;

@end
