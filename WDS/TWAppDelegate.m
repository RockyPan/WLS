//
//  TWAppDelegate.m
//  WDS
//
//  Created by PanKyle on 14-8-11.
//  Copyright (c) 2014年 TGD. All rights reserved.
//

#import "TWAppDelegate.h"
#import <CoreData/CoreData.h>

@interface TWAppDelegate () <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>

@property (nonatomic, strong) NSMutableArray * wordsObj;
@property (nonatomic, strong) NSMutableArray * tableContent;
@property (nonatomic, strong) NSMutableArray * filterWords;

@end

@implementation TWAppDelegate

- (NSManagedObjectContext *) getManagedObjectContext
{
    static NSManagedObjectContext * _managedObjectContext = nil;
    if (nil == _managedObjectContext) {
        NSPersistentStoreCoordinator * coordinator = [self getPersistentStoreCoordinator];
        if (nil != coordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *) getManagedObjectModel
{
    static NSManagedObjectModel * _managedObjectModel = nil;
    if (nil == _managedObjectModel) {
        NSURL * modelURL =
        [[self getApplicationDocumentsDirectory] URLByAppendingPathComponent:@"words.momd"];
//        [[NSBundle mainBundle] URLForResource:@"words" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *) getPersistentStoreCoordinator
{
    static NSPersistentStoreCoordinator * _persistentStoreCoordinator = nil;
    if (nil == _persistentStoreCoordinator) {
        NSURL * storeURL = [[self getApplicationDocumentsDirectory] URLByAppendingPathComponent:@"words.sqlite"];
        NSError * error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self getManagedObjectModel]];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:nil
                                                               error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

- (NSURL *)getApplicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void) saveContext
{
    NSError * error = nil;
    NSManagedObjectContext * managedObjectContext = [self getManagedObjectContext];
    if (nil != managedObjectContext) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)loadWords {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity = [NSEntityDescription entityForName:@"Words" inManagedObjectContext:[self getManagedObjectContext]];
    [request setEntity:entity];
    
    NSError * error = nil;
    self.wordsObj = [[[self getManagedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
    //[self sortWords];
    
    //[self logWords];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [self loadWords];
    self.tableContent = self.wordsObj;
    [self.table reloadData];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self.word setDelegate:self];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    if ([obj object] == self.word) {
        NSString * str = self.word.stringValue;
        if (str.)
        NSPredicate * pre = [NSPredicate predicateWithFormat:@"word beginsWith %@", self.word.stringValue];
        self.filterWords = [[self.wordsObj filteredArrayUsingPredicate:pre] mutableCopy];
        self.tableContent = self.filterWords;
        [self.table reloadData];
        //self.word.f];

    }
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    return self.tableContent.count;
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView * cell = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    //PK the identifier of colomn is the same as filed name of table
    cell.textField.stringValue = [self.tableContent[row] valueForKey:[tableColumn identifier]];
    return cell;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [self.tableContent sortUsingDescriptors:[tableView sortDescriptors]];
    [tableView reloadData];
}
- (IBAction)addWord:(id)sender {
}
@end
