//
//  TWAppDelegate.h
//  WDS
//
//  Created by PanKyle on 14-8-11.
//  Copyright (c) 2014年 TGD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TWAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *table;

@property (weak) IBOutlet NSTextField *word;
@property (weak) IBOutlet NSTextField *meaning;
@property (unsafe_unretained) IBOutlet NSTextView *log;
@property (weak) IBOutlet NSButton *btnAddWord;
@property (weak) IBOutlet NSButton *btnDelWord;

- (IBAction)addWord:(id)sender;
- (IBAction)delWord:(id)sender;
- (IBAction)returnOnTextField:(id)sender;

@end
