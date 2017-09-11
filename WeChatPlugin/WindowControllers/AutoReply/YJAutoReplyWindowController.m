//
//  YJAutoReplyWindowController.m
//  WeChatPlugin
//
//  Created by YJHou on 2017/7/9.
//  Copyright © 2017年 houmanager@hotmail.com. All rights reserved.
//

#import "YJAutoReplyWindowController.h"
#import "WCAutoReplyModel.h"
#import "YJAutoReplyContentView.h"
#import "WeChatPluginConfig.h"
#import "YJAutoReplyControlCell.h"

@interface YJAutoReplyWindowController () <NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) YJAutoReplyContentView *contentView;
@property (nonatomic, strong) NSButton *addButton;
@property (nonatomic, strong) NSButton *reduceButton;
@property (nonatomic, strong) NSAlert *alert;

@property (nonatomic, strong) NSMutableArray *autoReplyModels;
@property (nonatomic, assign) NSInteger lastSelectIndex;

@property (nonatomic, strong) NSButton *replyPreventRevokeBtn;

@end

@implementation YJAutoReplyWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self initSubviews];
    [self setup];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self.tableView reloadData];
    [self.contentView setHidden:YES];
    if (self.autoReplyModels && self.autoReplyModels.count == 0) {
        [self addModel];
    }
    if (self.autoReplyModels.count > 0 && self.tableView) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
    }
}

- (void)initSubviews {
    NSScrollView *scrollView = ({
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        scrollView.hasVerticalScroller = YES;
        scrollView.frame = NSMakeRect(30, 50, 200, 375);
        scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        scrollView;
    });
    
    self.tableView = ({
        NSTableView *tableView = [[NSTableView alloc] init];
        tableView.frame = scrollView.bounds;
        tableView.allowsTypeSelect = YES;
        tableView.delegate = self;
        tableView.dataSource = self;
        NSTableColumn *column = [[NSTableColumn alloc] init];
        column.title = @"自动回复列表";
        column.width = 200;
        [tableView addTableColumn:column];
        
        tableView;
    });
    
    self.contentView = ({
        YJAutoReplyContentView *contentView = [[YJAutoReplyContentView alloc] init];
        contentView.frame = NSMakeRect(250, 50, 400, 375);
        contentView.hidden = YES;
        
        contentView;
    });
    
    self.addButton = ({
        NSButton *btn = [NSButton buttonWithTitle:@"＋" target:self action:@selector(addModel)];
        btn.frame = NSMakeRect(30, 10, 40, 40);
        btn.bezelStyle = NSBezelStyleTexturedRounded;
        
        btn;
    });
    
    self.reduceButton = ({
        NSButton *btn = [NSButton buttonWithTitle:@"－" target:self action:@selector(reduceModel)];
        btn.frame = NSMakeRect(80, 10, 40, 40);
        btn.bezelStyle = NSBezelStyleTexturedRounded;
        btn.enabled = NO;
        
        btn;
    });
    
    self.replyPreventRevokeBtn = ({
        NSButton *btn = [NSButton checkboxWithTitle:@"是否开启单聊撤回消息自动发出" target:self action:@selector(clickReplyPreventRevokeBtn:)];
        btn.frame = NSMakeRect(270, 20, 400, 20);
        btn.state = [[WeChatPluginConfig sharedInstance] replyPreventRevokeEnable];
        btn;
    });
    
    self.alert = ({
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"您还有一条自动回复设置未完成"];
        [alert setInformativeText:@"请完善未完成的自动回复设置"];
        
        alert;
    });
    
    scrollView.contentView.documentView = self.tableView;
    
    [self.window.contentView addSafeSubviews:@[scrollView,
                                               self.contentView,
                                               self.addButton,
                                               self.reduceButton,
                                               self.replyPreventRevokeBtn
                                               ]];
}

- (void)setup {
    self.window.title = @"自动回复设置";
    self.window.contentView.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];
    [self.window.contentView.layer setNeedsDisplay];
    
    self.lastSelectIndex = -1;
    self.autoReplyModels = [[WeChatPluginConfig sharedInstance] autoReplyModels];
    [self.tableView reloadData];
    
    __weak typeof(self) weakSelf = self;
    self.contentView.endEdit = ^(void) {
        
        [weakSelf.tableView reloadData];
        if (weakSelf.lastSelectIndex != -1) {
            [weakSelf.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:weakSelf.lastSelectIndex] byExtendingSelection:YES];
        }
    };
}

- (void)clickReplyPreventRevokeBtn:(NSButton *)btn{
    
    [[WeChatPluginConfig sharedInstance] setReplyPreventRevokeEnable:btn.state];
}

/** 关闭窗口事件 */
- (BOOL)windowShouldClose:(id)sender {
    [[WeChatPluginConfig sharedInstance] saveAutoReplyModelsToFile];
    return YES;
}

#pragma mark - addButton & reduceButton ClickAction
- (void)addModel {
    if (self.contentView.hidden) {
        self.contentView.hidden = NO;
    }
    __block NSInteger emptyModelIndex = -1;
    [self.autoReplyModels enumerateObjectsUsingBlock:^(WCAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.hasEmptyKeywordOrReplyContent) {
            emptyModelIndex = idx;
            *stop = YES;
        }
    }];
    
    if (self.autoReplyModels.count > 0 && emptyModelIndex != -1) {
        [self.alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn){
                if (self.tableView.selectedRow != -1) {
                    [self.tableView deselectRow:self.tableView.selectedRow];
                }
                [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:emptyModelIndex] byExtendingSelection:YES];
            }
        }];
        return;
    };
    
    WCAutoReplyModel *model = [[WCAutoReplyModel alloc] init];
    [self.autoReplyModels addObject:model];
    [self.tableView reloadData];
    self.contentView.model = model;
    
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
}

- (void)reduceModel {
    NSInteger index = self.tableView.selectedRow;
    if (index > -1) {
        [self.autoReplyModels removeObjectAtIndex:index];
        [self.tableView reloadData];
        if (self.autoReplyModels.count == 0) {
            self.contentView.hidden = YES;
            self.reduceButton.enabled = NO;
        } else {
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
        }
    }
}

#pragma mark - NSTableViewDataSource && NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.autoReplyModels.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    YJAutoReplyControlCell *cell = [[YJAutoReplyControlCell alloc] init];
    cell.frame = NSMakeRect(0, 0, self.tableView.frame.size.width, 40);
    cell.model = self.autoReplyModels[row];
    
    return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 50;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    self.contentView.hidden = tableView.selectedRow == -1;
    self.reduceButton.enabled = tableView.selectedRow != -1;
    
    if (tableView.selectedRow != -1) {
        WCAutoReplyModel *model = self.autoReplyModels[tableView.selectedRow];
        self.contentView.model = model;
        self.lastSelectIndex = tableView.selectedRow;
        __block NSInteger emptyModelIndex = -1;
        [self.autoReplyModels enumerateObjectsUsingBlock:^(WCAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if (model.hasEmptyKeywordOrReplyContent) {
                emptyModelIndex = idx;
                *stop = YES;
            }
        }];
        
        if (emptyModelIndex != -1 && tableView.selectedRow != emptyModelIndex) {
            [self.alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                if(returnCode == NSAlertFirstButtonReturn){
                    if (self.tableView.selectedRow != -1) {
                        [self.tableView deselectRow:self.tableView.selectedRow];
                    }
                    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:emptyModelIndex] byExtendingSelection:YES];
                }
            }];
        }
    }
}

@end
