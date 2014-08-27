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
- (IBAction)addWord:(id)sender;
@property (weak) IBOutlet NSTextField *word;
@property (weak) IBOutlet NSTextField *meaning;
@property (weak) IBOutlet NSButton *btnAddWord;

@end
