//
//  PickerViewController.h
//  DALI Lighting
//
//  Created by Carlo Tortorella on 31/05/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LightPickerViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>
{
    NSString * errorString;
}
@property (weak, nonatomic) IBOutlet UIPickerView *pickerViewOutlet;

@end
