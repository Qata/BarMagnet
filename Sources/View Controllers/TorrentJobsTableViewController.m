//
//  FirstViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 4/06/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentJobsTableViewController.h"
#import "FileHandler.h"
#import "M13OrderedDictionary.h"
#import "SVModalWebViewController.h"
#import "SVWebViewController.h"
#import "TSMessage.h"
#import "TorrentDelegate.h"
#import "TorrentJobCheckerCell.h"

#define IPHONE_HEIGHT 22
#define IPAD_HEIGHT 28

enum ORDER { COMPLETED = 1, INCOMPLETE, DOWNLOAD_SPEED, UPLOAD_SPEED, ACTIVE, DOWNLOADING, SEEDING, PAUSED, NAME, SIZE, RATIO, DATE_ADDED, DATE_FINISHED };

@interface TorrentJobsTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIScrollViewDelegate,
                                              NSFileManagerDelegate>
@property(nonatomic, weak) UIActionSheet *controlSheet;
@property(nonatomic, weak) UIActionSheet *deleteTorrentSheet;
@property(nonatomic, strong) UIActionSheet *sortBySheet;
@property(nonatomic, strong) UIActionSheet *orderBySheet;
@property(nonatomic, strong) UIActionSheet *sortAndOrderSheet;
@property(nonatomic, strong) NSMutableArray *filteredArray;
@property(nonatomic, strong) UILabel *header;
@property(nonatomic, strong) NSArray *sortedKeys;
@property(nonatomic, strong) NSMutableOrderedDictionary *sortByDictionary;
@property(nonatomic, strong) UIView *totalsView;
@property(nonatomic, strong) UILabel *uploadTotalLabel;
@property(nonatomic, strong) UILabel *downloadTotalLabel;
@end

@implementation TorrentJobsTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [TSMessage setDefaultViewController:self];
  [self initialiseUploadDownloadLabels];
  [self initialiseHeader];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
  self.title = [FileHandler.sharedInstance settingsValueForKey:@"server_name"];
  self.tableView.contentOffset = CGPointMake(0.0, 44.0);

  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveUpdateTableNotification) name:@"update_torrent_jobs_table" object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveUpdateHeaderNotification) name:@"update_torrent_jobs_header" object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(changedClient) name:@"ChangedClient" object:nil];

  if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)] &&
      [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
    [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
  }
}

- (nullable UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
  CGPoint cellPostion = [self.tableView convertPoint:location fromView:self.view];
  NSIndexPath *path = [self.tableView indexPathForRowAtPoint:cellPostion];

  if (path) {
    NSDictionary *currentJob = nil;

    if (self.tableView == self.searchDisplayController.searchResultsTableView)
      currentJob = self.filteredArray[path.row];
    else
      currentJob = self.sortedKeys[path.row];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    TorrentDetailViewController *previewController = [storyboard instantiateViewControllerWithIdentifier:@"detail"];
    [previewController setHashString:currentJob[@"hash"]];
    previewingContext.sourceRect = [self.view convertRect:cell.frame fromView:self.tableView];
    return previewController;
  }
  return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
  [self showViewController:viewControllerToCommit sender:nil];
}

- (void)initialiseUploadDownloadLabels {
  unsigned height = 11;
  self.totalsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, height * 2)];
  self.totalsView.backgroundColor = [UIColor clearColor];

  UIFont *font = [UIFont fontWithName:@"Arial" size:height];

  self.uploadTotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, height)];
  self.downloadTotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, height, 80, height)];

  if ([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] < 7) {
    self.uploadTotalLabel.textColor = [UIColor whiteColor];
    self.downloadTotalLabel.textColor = [UIColor whiteColor];
  }

  self.uploadTotalLabel.font = font;
  self.downloadTotalLabel.font = font;
  self.uploadTotalLabel.backgroundColor = UIColor.clearColor;
  self.downloadTotalLabel.backgroundColor = UIColor.clearColor;
  [self.totalsView addSubview:self.uploadTotalLabel];
  [self.totalsView addSubview:self.downloadTotalLabel];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.totalsView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.shouldRefresh = YES;
  self.sortByDictionary = [NSMutableOrderedDictionary.alloc initWithObjects:@[
    @(COMPLETED), @(DATE_ADDED), @(DATE_FINISHED), @(DOWNLOAD_SPEED), @(UPLOAD_SPEED), @(ACTIVE), @(NAME), @(SIZE), @(RATIO), @(DOWNLOADING), @(SEEDING),
    @(PAUSED)
  ]
                                                             pairedWithKeys:@[
                                                               @"Progress", @"Date Added", @"Date Finished", @"Download Speed", @"Upload Speed", @"Active",
                                                               @"Name", @"Size", @"Ratio", @"Downloading", @"Seeding", @"Paused"
                                                             ]];
  self.tableView.rowHeight = self.searchDisplayController.searchResultsTableView.rowHeight =
      [[self.tableView dequeueReusableCellWithIdentifier:@"Compact"] frame].size.height;
  [self receiveUpdateTableNotification];
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)changedClient {
  self.title = [FileHandler.sharedInstance settingsValueForKey:@"server_name"];
}

- (void)initialiseHeader {
  self.header = [UILabel.alloc initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, [self sizeForDevice])];
  self.header.backgroundColor = [UIColor colorWithRed:0 green:0.9 blue:.2 alpha:.85];
  self.header.textColor = [UIColor whiteColor];
  self.header.text = @"Attempting Connection";
  self.header.font = [UIFont fontWithName:@"Arial" size:self.sizeForDevice - 6];
  self.header.textAlignment = NSTextAlignmentCenter;
  self.header.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
}

- (void)receiveUpdateTableNotification {
  if (!cancelNextRefresh) {
    if (self.shouldRefresh && !self.tableView.isEditing && !self.tableView.isDragging && !self.tableView.isDecelerating) {
      [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    }
  } else {
    cancelNextRefresh = NO;
  }
  [self createDownloadUploadTotals];
}

- (void)receiveUpdateHeaderNotification {
  if ([TorrentDelegate.sharedInstance.currentlySelectedClient isHostOnline]) {
    self.header.backgroundColor = [UIColor colorWithRed:.302 green:.584 blue:.772 alpha:.85];
    self.header.text = @"Host Online";
  } else {
    self.header.backgroundColor = [UIColor colorWithRed:.98 green:.196 blue:.196 alpha:.85];
    self.header.text = @"Host Offline";
  }
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
  self.shouldRefresh = NO;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
  self.shouldRefresh = YES;
  [self receiveUpdateTableNotification];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
  tableView.rowHeight = [[self.tableView dequeueReusableCellWithIdentifier:@"Compact"] frame].size.height;
}

- (IBAction)addTorrentPopup:(id)sender {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                  message:nil
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:@"Open URL", @"Search via Queries", @"Scan QR Code", nil];
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
    [[alertView textFieldAtIndex:0] resignFirstResponder];
    NSString *text = [[alertView textFieldAtIndex:0] text];
    switch (buttonIndex) {
    case 1: {
      if ([text length]) {
        NSString *magnet = @"magnet:";
        if (text.length > magnet.length && [[text substringWithRange:NSMakeRange(0, magnet.length)] isEqual:magnet]) {
          [[TorrentDelegate sharedInstance] handleMagnet:text];
          [self.navigationController popViewControllerAnimated:YES];
        } else if ([text rangeOfString:@".torrent"].location != NSNotFound) {
          [[TorrentDelegate sharedInstance] handleTorrentFile:text];
          [self.navigationController popViewControllerAnimated:YES];
        } else {
          if ([text rangeOfString:@"https://"].location != NSNotFound || [text rangeOfString:@"http://"].location != NSNotFound) {
            SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:text];
            [self.navigationController presentViewController:webViewController animated:YES completion:nil];
          } else {
            SVModalWebViewController *webViewController = [[SVModalWebViewController alloc]
                initWithAddress:[@"http://" stringByAppendingString:[text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            [self.navigationController presentViewController:webViewController animated:YES completion:nil];
          }
        }
      }
      break;
    }
    case 2: {
      [self performSegueWithIdentifier:@"query" sender:nil];
      break;
    }
    case 3: {
      if (([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] >= 7)) {
        [self performSegueWithIdentifier:@"scan" sender:nil];
      } else {
        [[UIAlertView.alloc initWithTitle:@"Unsupported Feature"
                                  message:@"QR code scanning is not supported on devices running a build earlier than 7.0"
                                 delegate:nil
                        cancelButtonTitle:@"Okay"
                        otherButtonTitles:nil] show];
      }
      break;
    }
    }
  }
}

- (IBAction)showListOfControlOptions:(id)sender {
  [[self.controlSheet = UIActionSheet.alloc initWithTitle:nil
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:@"Resume All", @"Pause All", nil] showFromToolbar:self.navigationController.toolbar];
}

- (void)showSortBySheet {
  self.sortBySheet = [UIActionSheet.alloc initWithTitle:@"Sort By" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  for (NSString *string in self.sortByDictionary.allKeys) {
    [self.sortBySheet addButtonWithTitle:string];
  }
  [self.sortBySheet addButtonWithTitle:@"Cancel"];
  self.sortBySheet.cancelButtonIndex = self.sortByDictionary.count;
  [self.sortBySheet showFromToolbar:self.navigationController.toolbar];
}

- (void)showOrderBySheet {
  self.orderBySheet = [UIActionSheet.alloc initWithTitle:@"Order As"
                                                delegate:self
                                       cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:@"Ascending", @"Descending", nil];
  [self.orderBySheet showFromToolbar:self.navigationController.toolbar];
}

- (IBAction)sortAndOrder:(id)sender {
  NSInteger orderBy = [[FileHandler.sharedInstance settingsValueForKey:@"order_by"] integerValue];
  self.sortAndOrderSheet = [UIActionSheet.alloc initWithTitle:[NSString stringWithFormat:@"%@, %@", [FileHandler.sharedInstance settingsValueForKey:@"sort_by"],
                                                                                         orderBy != NSOrderedAscending ? @"Descending" : @"Ascending"]
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"Order As", @"Sort By", nil];
  [self.sortAndOrderSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex != actionSheet.cancelButtonIndex) {
    if (actionSheet == self.sortAndOrderSheet) {
      switch (buttonIndex) {
      case 0:
        [self showOrderBySheet];
        break;
      case 1:
        [self showSortBySheet];
        break;
      }
    } else if (actionSheet == self.sortBySheet) {
      [FileHandler.sharedInstance setSettingsValue:[actionSheet buttonTitleAtIndex:buttonIndex] forKey:@"sort_by"];
      [self.tableView reloadData];
    } else if (actionSheet == self.orderBySheet) {
      switch (buttonIndex) {
      case 0:
        [FileHandler.sharedInstance setSettingsValue:@-1 forKey:@"order_by"];
        break;
      case 1:
        [FileHandler.sharedInstance setSettingsValue:@1 forKey:@"order_by"];
        break;
      }
      [self.tableView reloadData];
    } else if (actionSheet == self.controlSheet) {
      switch (buttonIndex) {
      case 0:
        [TorrentDelegate.sharedInstance.currentlySelectedClient resumeAllTorrents];
        break;
      case 1:
        [TorrentDelegate.sharedInstance.currentlySelectedClient pauseAllTorrents];
        break;
      }
    } else if (actionSheet == self.deleteTorrentSheet) {
      if (buttonIndex != [actionSheet cancelButtonIndex]) {
        self.shouldRefresh = NO;
        NSString *hashString = nil;
        NSUInteger index = 0;
        for (NSDictionary *dict in self.sortedKeys) {
          if ([dict[@"hash"] hash] == actionSheet.tag) {
            hashString = dict[@"hash"];
            index = [self.sortedKeys indexOfObject:dict];
            break;
          }
        }

        if (hashString) {
          [NSNotificationCenter.defaultCenter postNotificationName:@"cancel_refresh" object:nil];
          [TorrentDelegate.sharedInstance.currentlySelectedClient addTemporaryDeletedJob:4 forKey:hashString];
          [TorrentDelegate.sharedInstance.currentlySelectedClient removeTorrent:hashString removeData:buttonIndex == 0];
          [self.tableView deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          self.shouldRefresh = YES;
        });
      }
    }
  }
}

- (IBAction)openUI:(id)sender {
  if ([[TorrentDelegate.sharedInstance.currentlySelectedClient getUserFriendlyAppendedURL] length]) {
    SVModalWebViewController *webViewController =
        [SVModalWebViewController.alloc initWithAddress:TorrentDelegate.sharedInstance.currentlySelectedClient.getUserFriendlyAppendedURL];
    [self presentViewController:webViewController animated:YES completion:nil];
  }
}

- (NSComparisonResult)orderBy:(NSComparisonResult)orderBy comparing:(NSDictionary *)a with:(NSDictionary *)b usingKey:(NSString *)key {
  if (a[key] && b[key]) {
    NSComparisonResult res = orderBy != NSOrderedAscending ? [a[key] compare:b[key]] : [b[key] compare:a[key]];
    return res != NSOrderedSame ? res : [a[@"name"] compare:b[@"name"]];
  }
  return [a[@"name"] compare:b[@"name"]];
}

- (void)sortArray:(NSMutableArray *)array {
  NSInteger orderBy = [[FileHandler.sharedInstance settingsValueForKey:@"order_by"] integerValue];
  NSInteger sortBy = [self.sortByDictionary[[FileHandler.sharedInstance settingsValueForKey:@"sort_by"]] integerValue];
  switch (sortBy) {
  case COMPLETED:
  case INCOMPLETE: {
    [array
        sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) { return [self orderBy:orderBy comparing:b with:a usingKey:@"progress"]; }];
    break;
  }
  case DOWNLOAD_SPEED: {
    [array sortUsingComparator:(NSComparator) ^
                               (NSDictionary * a, NSDictionary * b) { return [self orderBy:orderBy comparing:b with:a usingKey:@"rawDownloadSpeed"]; }];
    break;
  }
  case UPLOAD_SPEED: {
    [array sortUsingComparator:(NSComparator) ^
                               (NSDictionary * a, NSDictionary * b) { return [self orderBy:orderBy comparing:b with:a usingKey:@"rawUploadSpeed"]; }];
    break;
  }
  case ACTIVE: {
    [array sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) {
      if ([a[@"rawUploadSpeed"] integerValue] | [a[@"rawDownloadSpeed"] integerValue]) {
        if (!([b[@"rawUploadSpeed"] integerValue] | [b[@"rawDownloadSpeed"] integerValue])) {
          return orderBy != NSOrderedAscending ? NSOrderedAscending : NSOrderedDescending;
        }
      } else if ([b[@"rawUploadSpeed"] integerValue] | [b[@"rawDownloadSpeed"] integerValue]) {
        return orderBy != NSOrderedAscending ? NSOrderedDescending : NSOrderedAscending;
      }
      return [a[@"name"] compare:b[@"name"]];
    }];
    break;
  }
  case DOWNLOADING:
  case SEEDING:
  case PAUSED: {
    [array sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) {
      if ([self.sortByDictionary[a[@"status"]] integerValue] == sortBy) {
        if (!([self.sortByDictionary[b[@"status"]] integerValue] == sortBy)) {
          return orderBy != NSOrderedAscending ? NSOrderedAscending : NSOrderedDescending;
        }
      } else if ([self.sortByDictionary[b[@"status"]] integerValue] == sortBy) {
        return orderBy != NSOrderedAscending ? NSOrderedDescending : NSOrderedAscending;
      }
      return [a[@"name"] compare:b[@"name"]];
    }];
    break;
  }
  case SIZE: {
    [array sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) { return [self orderBy:orderBy comparing:b with:a usingKey:@"size"]; }];
    break;
  }
  case RATIO: {
    [array sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) { return [self orderBy:orderBy comparing:b with:a usingKey:@"ratio"]; }];
    break;
  }
  case DATE_ADDED: {
    [array
        sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) { return [self orderBy:orderBy comparing:b with:a usingKey:@"dateAdded"]; }];
    break;
  }
  case DATE_FINISHED: {
    [array
        sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) { return [self orderBy:orderBy comparing:b with:a usingKey:@"dateDone"]; }];
    break;
  }
  default:
  case NAME: {
    [array sortUsingComparator:(NSComparator) ^ (NSDictionary * a, NSDictionary * b) {
      return orderBy != NSOrderedAscending ? [b[@"name"] compare:a[@"name"]] : [a[@"name"] compare:b[@"name"]];
    }];
    break;
  }
  }
}

- (void)createDownloadUploadTotals {
  NSUInteger uploadSpeed = 0, downloadSpeed = 0;
  for (NSDictionary *dict in TorrentDelegate.sharedInstance.currentlySelectedClient.getJobsDict.allValues) {
    if (dict[@"rawUploadSpeed"] && dict[@"rawDownloadSpeed"]) {
      uploadSpeed += [dict[@"rawUploadSpeed"] integerValue];
      downloadSpeed += [dict[@"rawDownloadSpeed"] integerValue];
    }
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    self.uploadTotalLabel.text = [NSString stringWithFormat:@"↑ %@", @(uploadSpeed).transferRateString];
    self.downloadTotalLabel.text = [NSString stringWithFormat:@"↓ %@", @(downloadSpeed).transferRateString];
  });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  NSMutableArray *dictValues = [TorrentDelegate.sharedInstance.currentlySelectedClient.getJobsDict.allValues mutableCopy];
  [self sortArray:dictValues];
  self.sortedKeys = dictValues;

  return 1;
}

- (void)addProgressViewToCell:(TorrentJobCheckerCell *)cell withJob:(NSDictionary *)currentJob {
  NSInteger tag = -(1 << 8);
  if (![[cell viewWithTag:tag].class isEqual:UIView.class]) {
    UIView *view = [UIView.alloc initWithFrame:cell.frame];
    view.tag = tag;
    [cell insertSubview:view atIndex:0];
  }

  UIView *progressView = [cell viewWithTag:tag];
  CGRect frame = progressView.frame;
  double completeValue = [[[TorrentDelegate.sharedInstance.currentlySelectedClient class] completeNumber] doubleValue];
  frame.size.width = cell.frame.size.width * (completeValue ? [currentJob[@"progress"] doubleValue] / completeValue : 0);
  progressView.frame = frame;

  if ([currentJob[@"status"] isEqualToString:@"Seeding"]) {
    progressView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:.4 alpha:.3];
  } else if ([currentJob[@"status"] isEqualToString:@"Downloading"]) {
    progressView.backgroundColor = [UIColor colorWithRed:0 green:.478 blue:1 alpha:.3];
  } else {
    progressView.backgroundColor = [UIColor colorWithRed:.85 green:.85 blue:.85 alpha:.5];
  }

  [progressView setNeedsDisplay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TorrentJobCheckerCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Compact"];
  cell.table = self;
  if ([cell.subviews.firstObject isKindOfClass:UIScrollView.class]) {
    [cell.subviews.firstObject setDelegate:self];
  }
  NSDictionary *currentJob = nil;

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    currentJob = self.filteredArray[indexPath.row];
  } else {
    currentJob = self.sortedKeys[indexPath.row];
  }

  cell.name.text = currentJob[@"name"];
  cell.hashString = currentJob[@"hash"];
  cell.currentStatus.text = currentJob[@"status"];

  double completeValue = [TorrentDelegate.sharedInstance.currentlySelectedClient.class completeNumber].doubleValue;
  cell.percentBar.progress = completeValue ? [currentJob[@"progress"] doubleValue] / completeValue : 0;

  if ([currentJob[@"ETA"] length] &&
      [currentJob[@"progress"] doubleValue] != [[TorrentDelegate.sharedInstance.currentlySelectedClient.class completeNumber] doubleValue]) {
    cell.ETA.text = [NSString stringWithFormat:@"ETA: %@", currentJob[@"ETA"]];
  } else if (currentJob[@"ratio"]) {
    cell.ETA.text = [NSString stringWithFormat:@"Ratio: %.3f", [currentJob[@"ratio"] doubleValue]];
  } else {
    cell.ETA.text = @"";
  }
  cell.downloadSpeed.text = [NSString stringWithFormat:@"%@ ↓", currentJob[@"downloadSpeed"]];

  MGSwipeButton *delete = [MGSwipeButton buttonWithTitle:@"Delete"
                                         backgroundColor:[UIColor redColor]
                                                callback:^BOOL(MGSwipeTableCell *sender) {
                                                  UIActionSheet *popupQuery = nil;
                                                  if (TorrentDelegate.sharedInstance.currentlySelectedClient.supportsEraseChoice) {
                                                    popupQuery = [[UIActionSheet alloc] initWithTitle:@"Also delete data?"
                                                                                             delegate:self
                                                                                    cancelButtonTitle:@"Cancel"
                                                                               destructiveButtonTitle:@"Delete data"
                                                                                    otherButtonTitles:@"Delete torrent", nil];
                                                  } else {
                                                    popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?"
                                                                                             delegate:self
                                                                                    cancelButtonTitle:@"Cancel"
                                                                               destructiveButtonTitle:@"Delete torrent"
                                                                                    otherButtonTitles:nil];
                                                  }
                                                  self.deleteTorrentSheet = popupQuery;
                                                  popupQuery.tag = [currentJob[@"hash"] hash];
                                                  [popupQuery showFromToolbar:self.navigationController.toolbar];
                                                  return YES;
                                                }];

  if ([currentJob[@"status"] isEqualToString:@"Paused"]) {
    cell.rightButtons = @[
      delete, [MGSwipeButton buttonWithTitle:@"Resume"
                             backgroundColor:[UIColor greenColor]
                                    callback:^BOOL(MGSwipeTableCell *sender) {
                                      [TorrentDelegate.sharedInstance.currentlySelectedClient resumeTorrent:currentJob[@"hash"]];
                                      return YES;
                                    }]
    ];
  } else {
    cell.rightButtons = @[
      delete, [MGSwipeButton buttonWithTitle:@"Pause"
                             backgroundColor:[UIColor lightGrayColor]
                                    callback:^BOOL(MGSwipeTableCell *sender) {
                                      [TorrentDelegate.sharedInstance.currentlySelectedClient pauseTorrent:currentJob[@"hash"]];
                                      return YES;
                                    }]
    ];
  }

  if ([currentJob[@"status"] isEqualToString:@"Seeding"]) {
    cell.percentBar.progressTintColor = [UIColor colorWithRed:0 green:1 blue:.4 alpha:1];
  } else if ([currentJob[@"status"] isEqualToString:@"Downloading"]) {
    cell.percentBar.progressTintColor = [UIColor colorWithRed:0 green:.478 blue:1 alpha:1];
  } else {
    cell.percentBar.progressTintColor = [UIColor darkGrayColor];
  }

  cell.uploadSpeed.text = [NSString stringWithFormat:@"↑ %@", currentJob[@"uploadSpeed"]];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    UIFont *font = [UIFont fontWithName:@"Arial" size:10];
    cell.downloadSpeed.font = font;
    cell.uploadSpeed.font = font;
    cell.currentStatus.font = font;
    cell.ETA.font = font;
  }
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return self.shouldRefresh;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  self.tableView = tableView;
  UIActionSheet *popupQuery = nil;
  if (TorrentDelegate.sharedInstance.currentlySelectedClient.supportsEraseChoice) {
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"Also delete data?"
                                             delegate:self
                                    cancelButtonTitle:@"Cancel"
                               destructiveButtonTitle:@"Delete data"
                                    otherButtonTitles:@"Delete torrent", nil];
  } else {
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?"
                                             delegate:self
                                    cancelButtonTitle:@"Cancel"
                               destructiveButtonTitle:@"Delete torrent"
                                    otherButtonTitles:nil];
  }
  self.deleteTorrentSheet = popupQuery;
  popupQuery.tag = indexPath.row;
  [popupQuery showFromToolbar:self.navigationController.toolbar];
}

- (CGFloat)sizeForDevice {
  return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? IPHONE_HEIGHT : IPAD_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return [self sizeForDevice];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return self.shouldRefresh ? self.header : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return self.filteredArray.count;
  }
  return [[[TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict] allKeys] count];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.destinationViewController isKindOfClass:TorrentDetailViewController.class]) {
    if ([sender isKindOfClass:TorrentJobCheckerCell.class]) {
      [segue.destinationViewController setHashString:[sender hashString]];
    } else if ([sender isKindOfClass:NSString.class]) {
      [segue.destinationViewController setHashString:sender];
    }
  }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  cancelNextRefresh = NO;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
  return [[[TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict] allKeys] count] ? YES : NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
  [self filterContentForSearchText:searchString
                             scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                       objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
  return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
  [self filterContentForSearchText:self.searchDisplayController.searchBar.text
                             scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
  return YES;
}

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope {
  self.filteredArray = NSMutableArray.new;
  NSDictionary *jobs = [TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict];
  for (NSDictionary *job in jobs.allValues) {
    if ([[job[@"name"] lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound) {
      [self.filteredArray addObject:job];
    }
  }
  [self sortArray:self.filteredArray];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  cancelNextRefresh = YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  cancelNextRefresh = YES;
}

@end
