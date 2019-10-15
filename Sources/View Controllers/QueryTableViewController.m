//
//  QueryTableViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 24/01/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "QueryTableViewController.h"
#import "AddQueryTableViewController.h"
#import "QueryCell.h"
#import "SVModalWebViewController.h"
#import "TorrentDelegate.h"
#import "TorrentDownloaderModalWebViewController.h"
@import MobileCoreServices;

@interface QueryTableViewController () <UITextFieldDelegate, UIAlertViewDelegate, UIDocumentPickerDelegate, UIDocumentMenuDelegate>
@property(nonatomic, strong) UIAlertView *alertView;
@property(nonatomic, strong) NSString *previousQuery;
@end

@implementation QueryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [[TorrentDelegate sharedInstance] handleTorrentFile:url viewController:self];
}

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField_UniqueString *)textField {
    NSString *text = [textField text];
    if ([text length]) {
        [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:YES];
        if (self.alertView && self.alertView.tag == -1) {
            [self openURL:[NSURL URLWithString:text]];
        } else if (self.alertView) {
            [self search:[self.alertView textFieldAtIndex:0].text withQuery:[NSUserDefaults.standardUserDefaults objectForKey:@"queries"][self.alertView.tag]];
        }
    }
    return [textField resignFirstResponder];
}

- (void)openURL:(NSURL *)url {
    NSString *magnet = @"magnet:";
    if ([url.scheme isEqual:magnet]) {
        [[TorrentDelegate sharedInstance] handleMagnet:url.absoluteString];
    } else if ([url.path hasSuffix:@".torrent"]) {
        [[TorrentDelegate sharedInstance] handleTorrentFile:url viewController:self];
    } else {
        if ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) {
            TorrentDownloaderModalWebViewController *webViewController = [TorrentDownloaderModalWebViewController.alloc initWithURL:url];
            [self.navigationController presentViewController:webViewController animated:YES completion:nil];
        } else if (url) {
            TorrentDownloaderModalWebViewController *webViewController = [TorrentDownloaderModalWebViewController.alloc
                initWithURL:url];
            [self.navigationController presentViewController:webViewController animated:YES completion:nil];
        }
    }
}

- (void)search:(NSString *)text withQuery:(NSDictionary *)query {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.previousQuery = trimmed;
    TorrentDownloaderModalWebViewController *webViewController = [TorrentDownloaderModalWebViewController.alloc
        initWithAddress:[NSString
                            stringWithFormat:@"%@%@", [query[@"query"] rangeOfString:@"https://"].location != NSNotFound ? @"" : @"http://",
                                             [query[@"query"]
                                                 stringByReplacingOccurrencesOfString:@"%query%"
                                                                           withString:[trimmed stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]]]];
    [self.navigationController presentViewController:webViewController animated:YES completion:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.editing = NO;
    [super viewDidDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
        case 1:
            return [[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] count];
        case 2:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QueryCell *cell = nil;
    if (indexPath.section == 1) {
        NSDictionary *query = [NSUserDefaults.standardUserDefaults objectForKey:@"queries"][indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:@"Static"];
        cell.textLabel.text = query[@"name"];
        cell.queryDictionary = query;
    } else if (!indexPath.section) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"System"];
        cell.textLabel.text = @[ @"Open URL", @"Scan QR Code", @"Browse Files" ][indexPath.row];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Add"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if ([[NSUserDefaults.standardUserDefaults objectForKey:@"queries"][indexPath.row][@"uses_query"] boolValue]) {
            self.alertView = [UIAlertView.alloc initWithTitle:[NSUserDefaults.standardUserDefaults objectForKey:@"queries"][indexPath.row][@"name"]
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Search", nil];
            self.alertView.tag = indexPath.row;
            self.alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField *textField = [self.alertView textFieldAtIndex:0];
            textField.returnKeyType = UIReturnKeySearch;
            textField.delegate = self;
            textField.autocorrectionType = UITextAutocorrectionTypeYes;
            if (self.previousQuery) {
                textField.text = self.previousQuery;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [textField selectAll:nil];
                });
            }
            [self.alertView show];
        } else {
            NSString *query = [NSUserDefaults.standardUserDefaults objectForKey:@"queries"][indexPath.row][@"query"];
            TorrentDownloaderModalWebViewController *webViewController = [TorrentDownloaderModalWebViewController.alloc
                                                                          initWithAddress:[NSString stringWithFormat:@"%@%@", [query rangeOfString:@"https://"].location != NSNotFound ? @"" : @"http://", query]];
            [self.navigationController presentViewController:webViewController animated:YES completion:nil];
        }
    } else if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: {
                self.alertView = [UIAlertView.alloc initWithTitle:@"Open URL" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
                self.alertView.tag = -1;
                self.alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [self.alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeURL;
                [self.alertView textFieldAtIndex:0].returnKeyType = UIReturnKeyGo;
                [self.alertView textFieldAtIndex:0].delegate = self;
                [self.alertView show];
                break;
            }
            case 1: {
                [self performSegueWithIdentifier:@"scanQRCode" sender:self];
                break;
            }
            case 2: {
                UIDocumentMenuViewController * picker = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode: UIDocumentPickerModeOpen];
                picker.delegate = self;
                picker.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:picker animated:YES completion:nil];
                break;
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.alertView = nil;
    if (buttonIndex != alertView.cancelButtonIndex && alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text.length) {
        if (alertView.tag == -1) {
            [self openURL:[alertView textFieldAtIndex:0].text];
        } else {
            [self search:[alertView textFieldAtIndex:0].text withQuery:[NSUserDefaults.standardUserDefaults objectForKey:@"queries"][alertView.tag]];
        }
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    return alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text.length > 0;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"editQuery" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section) {
        return UITableViewCellEditingStyleNone;
    } else if (indexPath.section == 2) {
        return UITableViewCellEditingStyleInsert;
    }
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *array = [[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] mutableCopy];
        [array removeObjectAtIndex:indexPath.row];
        [NSUserDefaults.standardUserDefaults setObject:array forKey:@"queries"];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self performSegueWithIdentifier:@"addQuery" sender:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1;
}

- (NSIndexPath *)tableView:(UITableView *)tableView
targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.section < 1) {
        return [NSIndexPath indexPathForRow:0 inSection:1];
    } else if (proposedDestinationIndexPath.section > 1) {
        return [NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:1] - 1 inSection:1];
    }
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSMutableArray *array = [[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] mutableCopy];
    NSDictionary *object = array[sourceIndexPath.row];
    [array removeObjectAtIndex:sourceIndexPath.row];
    [array insertObject:object atIndex:destinationIndexPath.row];
    [NSUserDefaults.standardUserDefaults setObject:array forKey:@"queries"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController respondsToSelector:@selector(setQueryDictionary:)]) {
        if ([sender respondsToSelector:@selector(queryDictionary)]) {
            [segue.destinationViewController setQueryDictionary:[sender queryDictionary]];
        }
    }
    segue.destinationViewController.modalPresentationStyle = UIModalPresentationFullScreen;
}

@end
