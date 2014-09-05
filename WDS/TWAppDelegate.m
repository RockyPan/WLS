//
//  TWAppDelegate.m
//  WDS
//
//  Created by PanKyle on 14-8-11.
//  Copyright (c) 2014年 TGD. All rights reserved.
//

#import "TWAppDelegate.h"
#import "GCDAsyncSocket.h"
#import <CoreData/CoreData.h>

@interface TWAppDelegate () <NSTableViewDataSource, NSTableViewDelegate>

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

- (void)awakeFromNib {
    [self addObserver:self forKeyPath:@"strWord" options:0 context:nil];
    [self addObserver:self forKeyPath:@"strMeaning" options:0 context:nil];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [self loadWords];
    self.tableContent = self.wordsObj;
    [self.table reloadData];
    
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    connectedSockets = [[NSMutableArray alloc] init];
    NSError * err = nil;
    if ([asyncSocket acceptOnPort:0 error:&err]) {
        UInt16 port = [asyncSocket localPort];
        [self printLog:[NSString stringWithFormat:@"开始在端口%i接受连接。。。", (int)port]];
        netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_WDS._tcp." name:@"" port:port];
        [netService setDelegate:self];
        [netService publish];
    } else {
        [self printLog:[NSString stringWithFormat:@"开始接受连接失败，错误信息：%@", err]];
    }
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    [self printLog:[NSString stringWithFormat:@"成功发布Bonjour服务：domain(%@) type(%@) name(%@) port(%i)", [sender domain], [sender type], [sender name], (int)[sender port]]];
}
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    [self printLog:[NSString stringWithFormat:@"发布Bonjour服务失败：domain(%@) type(%@) name(%@) - %@", [sender domain], [sender type], [sender name], errorDict]];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    [self printLog:[NSString stringWithFormat:@"接受来自%@:%hu的连接！", [newSocket connectedHost], [newSocket connectedPort]]];
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (!([keyPath isEqualToString:@"strWord"] || [keyPath isEqualToString:@"strMeaning"])) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    //PK activiate "add" button ?
    //NSLog(@"%@ - %@", self.strWord, self.strMeaning);
    [self.btnAddWord setEnabled:(0 != self.strWord.length && 0 != self.strMeaning.length)];
 
    //PK filter words list according to input word
    static NSString * preWord = nil;
    if ([self.strWord isEqualToString:preWord]) return;
    preWord = [self.strWord copy];
    
    if (self.strWord.length == 0) {
        self.tableContent = self.wordsObj;
    } else  {
        
        NSPredicate * pre = [NSPredicate predicateWithFormat:@"word beginsWith %@", self.word.stringValue];
        self.filterWords = [[self.wordsObj filteredArrayUsingPredicate:pre] mutableCopy];
        self.tableContent = self.filterWords;
        
        //PK 直接设置textfield的stringValue不会引起绑定的对象变化，所以只有手动设置一下
        self.meaning.stringValue = @"";
        self.strMeaning = @"";
        for (NSManagedObject * val in self.filterWords) {
            NSString * word = [val valueForKey:@"word"];
            if ([word isEqualToString:self.strWord]) {
                NSString * meaning = [self.filterWords[0] valueForKey:@"meaning"];
                self.meaning.stringValue = meaning;
                self.strMeaning = meaning;
            }
        }
    }
    [self.table reloadData];
}


//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
////    if (control == self.word) {
////        [self.meaning becomeFirstResponder];
////    }
////    if (control == self.meaning) {
//        if (0 != self.strWord.length && 0 != self.strMeaning.length) [self addWord:nil];
////    }
//    return YES;
//    
//}

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

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView * table = notification.object;
    [self.btnDelWord setEnabled:0 != [table numberOfSelectedRows]];
}

- (IBAction)addWord:(id)sender {
    NSString * word = self.word.stringValue;
    NSString * meaning = self.meaning.stringValue;
    
    //检查单词是否重复了
    NSPredicate * pre = [NSPredicate predicateWithFormat:@"word == %@", word];
    NSArray * matchs = [self.wordsObj filteredArrayUsingPredicate:pre];
    if (0 != [matchs count]) {  //PK 修改内容
        [matchs[0] setValue:meaning forKeyPath:@"meaning"];
        [self printLog:[NSString stringWithFormat:@"修改单词：%@ - %@", word, meaning]];
    } else {                    //保存单词
        NSManagedObjectContext * context = [self getManagedObjectContext];
        NSManagedObject * obj = [NSEntityDescription insertNewObjectForEntityForName:@"Words" inManagedObjectContext:context];
        [obj setValue:word forKey:@"word"];
        [obj setValue:meaning forKey:@"meaning"];
        [obj setValue:[NSDate date] forKey:@"lastAccess"];
        [obj setValue:[NSNumber numberWithInt:0] forKey:@"familiarity"];
        [self.wordsObj addObject:obj];
        [self printLog:[NSString stringWithFormat:@"添加单词：%@ - %@", word, meaning]];
    }
    [self saveContext];
    
    //清空textfield内容
    self.word.stringValue = @"";
    self.meaning.stringValue = @"";
    self.strWord = @"";
    self.strMeaning = @"";
    [self.btnAddWord setEnabled:NO];
    [self.word becomeFirstResponder];
    self.tableContent = self.wordsObj;
    [self.table reloadData];
}

- (IBAction)delWord:(id)sender {
    NSInteger no = [self.table numberOfSelectedRows];
    if (0 != no) {
        NSInteger choice = NSRunAlertPanel(@"删除确认", @"您确认要删除选中的这%ld个单词吗？", @"确认", @"取消", nil, no);
        if (NSAlertDefaultReturn != choice) return;
    } else {
        return;
    }
    
    NSIndexSet * rows = [self.table selectedRowIndexes];
    [rows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [[self getManagedObjectContext] deleteObject:self.tableContent[idx]];
        NSString * log = [NSString stringWithFormat:@"删除单词：%@ - %@",
                        [self.tableContent[idx] valueForKey:@"word"],
                        [self.tableContent[idx] valueForKey:@"meaning"]];
        [self printLog:log];
        NSLog(@"%@", log);
    }];
    [self saveContext];
    
    if (self.tableContent == self.wordsObj) {
        [self.wordsObj removeObjectsAtIndexes:rows];
    } else {
        //PK 如果删除时用的时过滤表，要把原表中相应的项也删除
        NSArray * objs = [self.filterWords objectsAtIndexes:rows];
        [self.filterWords removeObjectsAtIndexes:rows];
        [self.wordsObj removeObjectsInArray:objs];
    }
    [self.table reloadData];
    [self.btnDelWord setEnabled:NO];
}

- (IBAction)returnOnTextField:(id)sender {
    if (self.btnAddWord.isEnabled) [self addWord:nil];
}

- (void)printLog:(NSString *)log {
    [self.log insertText:[NSString stringWithFormat:@"%@\r\n", log]];
}


@end
