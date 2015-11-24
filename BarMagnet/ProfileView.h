//
//  PickerViewController.h
//  DALI Lighting
//
//  Created by Charlotte Tortorella on 31/05/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LightPickerViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>
{
    NSString * errorString;
}
@property (weak, nonatomic) IBOutlet UIPickerView *pickerViewOutlet;

@end
