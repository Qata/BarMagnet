//
//  TorrentJobChecker.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 7/05/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentJobChecker.h"
#import "FileHandler.h"
#import "TorrentClient.h"
#import "TorrentDelegate.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "TSMessage.h"
#endif

@implementation TorrentJobChecker

static TorrentJobChecker *sharedInstance;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [TorrentJobChecker new];
    }
}

+ (TorrentJobChecker *)sharedInstance {
    return sharedInstance;
}

- (void)updateTorrentClientWithJobsData {
    [TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentJobs];
    dispatch_async(dispatch_get_main_queue(), ^{
      [NSNotificationCenter.defaultCenter postNotificationName:@"update_torrent_jobs_table" object:nil];
    });
}

- (void)jobCheckInvocation {
    double refresh = [[FileHandler.sharedInstance settingsValueForKey:@"refresh_connection_seconds"] doubleValue];
    for (;;) {
        @autoreleasepool {
            double t = clock();
            NSMutableURLRequest *request = [TorrentDelegate.sharedInstance.currentlySelectedClient checkTorrentJobs];
            [request setTimeoutInterval:0x20];
            if (request) {
                //[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:request.URL.host];
                NSMutableData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil].mutableCopy;
                if ([receivedData length]) {
                    if ([TorrentDelegate.sharedInstance.currentlySelectedClient isValidJobsData:receivedData]) {
                        TorrentDelegate.sharedInstance.currentlySelectedClient.jobsData = receivedData;
                    } else {
                        NSLog(@"Incorrect response to request for jobs data: %@", [receivedData toUTF8String]);
                    }
                }
            }

            double elapsed = (clock() - t) / CLOCKS_PER_SEC;
            if (elapsed < refresh) {
                double intpart, fractpart;
                fractpart = modf(refresh - elapsed, &intpart);
                struct timespec tspec = {.tv_sec = intpart, .tv_nsec = round(fractpart * 1e9)};
                nanosleep(&tspec, NULL);
            }
            [[TorrentJobChecker sharedInstance] updateTorrentClientWithJobsData];
        }
    }
}

- (void)connectionCheckInvocation {
    double refresh = [[FileHandler.sharedInstance settingsValueForKey:@"refresh_connection_seconds"] doubleValue] * 4;
    for (;;) {
        @autoreleasepool {
            double t = clock();
            NSMutableURLRequest *request =
                [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[TorrentDelegate.sharedInstance.currentlySelectedClient getAppendedURL]]];
            [request setTimeoutInterval:0x20];
            if (request) {
                NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                if (![receivedData length]) {
                    [request setURL:[NSURL URLWithString:[TorrentDelegate.sharedInstance.currentlySelectedClient getUserFriendlyAppendedURL]]];
                    receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                  [TorrentDelegate.sharedInstance.currentlySelectedClient setHostOnline:receivedData.length];
                  [NSNotificationCenter.defaultCenter postNotificationName:@"update_torrent_jobs_header" object:nil];
                });
            }
            double elapsed = (clock() - t) / CLOCKS_PER_SEC;
            if (elapsed < refresh) {
                double intpart, fractpart;
                fractpart = modf(refresh - elapsed, &intpart);
                struct timespec tspec = {.tv_sec = intpart, .tv_nsec = round(fractpart * 1e9)};
                nanosleep(&tspec, NULL);
            }
        }
    }
}

- (void)credentialsCheckInvocation {
    @autoreleasepool {
        NSMutableURLRequest *request = [TorrentDelegate.sharedInstance.currentlySelectedClient checkTorrentJobs];
        [request setTimeoutInterval:0x20];
        if (request) {
            NSError *error = nil;
            NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
            NSString *notification = nil;
            if (error) {
                if (error.code == -1012) {
                    notification = @"Incorrect or missing user credentials.";
                } else {
                    notification = [error localizedDescription];
                }
            } else if (![TorrentDelegate.sharedInstance.currentlySelectedClient isValidJobsData:receivedData]) {
                if (receivedData.length > 1) {
                    notification = [[TorrentDelegate.sharedInstance.currentlySelectedClient parseTorrentFailure:receivedData] sentenceParsedString];
                } else {
                    notification = @"No error info provided, are you sure that's the right port?";
                }
            }

            if (notification) {
                [TSMessage showNotificationWithTitle:@"Unable to authenticate" subtitle:notification type:TSMessageNotificationTypeError];
            }
        }
    }
}

@end
