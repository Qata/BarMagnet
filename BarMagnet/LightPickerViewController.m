//
//  PickerViewController.m
//  DALI Lighting
//
//  Created by Carlo Tortorella on 31/05/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "LightPickerViewController.h"

@implementation LightPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"%@", @"Loaded");
    errorString = @"Indy, BIG problem";
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    //Three columns
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
            return 2;
            break;
        case 1:
            return 4;
        case 2:
            if ([pickerView selectedRowInComponent:0] == 0)
                return 16;
            else
                return 64;
            break;
        default:
            return 0;
            break;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
            if (row == 0)
                return @"Group";
            else
                return @"Ballast";
            break;
        case 1:
            return [NSString stringWithFormat:@"Line %li", (long)row + 1];
            break;
        case 2:
            return [NSString stringWithFormat:@"Add %li", (long)row + 1];
        default:
            return errorString;
            break;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == 0)
    {
        [pickerView reloadAllComponents];
    }
}

@end
