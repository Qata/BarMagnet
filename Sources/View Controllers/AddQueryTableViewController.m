//
//  AddQueryTableViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 24/01/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "AddQueryTableViewController.h"

@implementation AddQueryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.queryDictionary) {
        self.name.text = self.queryDictionary[@"name"];
        self.URL.text = self.queryDictionary[@"query"];
        self.usesQuery.on = [self.queryDictionary[@"uses_query"] boolValue];
    } else {
        self.navigationItem.leftBarButtonItem =
            [UIBarButtonItem.alloc initWithTitle:@"Cancel"
                                           style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(dismiss)];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [textField resignFirstResponder];
}

- (IBAction)save {
    if (self.name.text.length && self.URL.text.length) {
        NSString *URL = [self.URL.text stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        if (!self.usesQuery.on || [URL rangeOfString:@"%query%"].location != NSNotFound) {
            NSMutableArray *array = [[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] mutableCopy];
            if (!array) {
                array = NSMutableArray.new;
            }
            NSDictionary *object = @{ @"name" : self.name.text,
                                      @"query" : URL,
                                      @"uses_query" : @(self.usesQuery.on) };
            if (self.queryDictionary) {
                [array replaceObjectAtIndex:[[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] indexOfObject:self.queryDictionary] withObject:object];
            } else {
                [array addObject:object];
            }
            [NSUserDefaults.standardUserDefaults setObject:array forKey:@"queries"];
            [self dismiss];
        } else {
            [[UIAlertView.alloc initWithTitle:@"Error"
                                      message:@"The query URL needs to have \"%query%\" in it where the search parameters usually go"
                                     delegate:nil
                            cancelButtonTitle:@"Okay"
                            otherButtonTitles:nil] show];
        }
    }
}

- (void)dismiss {
    if (self.queryDictionary) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
