//
//  YJAutoReplyContentView.m
//  WeChatPlugin
//
//  Created by YJHou on 2017/7/9.
//  Copyright © 2017年 houmanager@hotmail.com. All rights reserved.
//

#import "YJAutoReplyContentView.h"
#import "WCAutoReplyModel.h"
#import "NSView+YJSuperExt.h"

@interface YJAutoReplyContentView () <NSTextFieldDelegate>

@property (nonatomic, strong) NSTextField *keywordLabel;
@property (nonatomic, strong) NSTextField *keywordTextField;
@property (nonatomic, strong) NSTextField *autoReplyLabel;
@property (nonatomic, strong) NSTextField *autoReplyContentField;
@property (nonatomic, strong) NSButton *enableGroupReplyBtn;

@end

@implementation YJAutoReplyContentView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    
    self.enableGroupReplyBtn = ({
        NSButton *btn = [NSButton checkboxWithTitle:@"是否开启群聊自动回复" target:self action:@selector(clickSelectBtn:)];
        btn.frame = NSMakeRect(20, 10, 400, 20);
        
        btn;
    });
    
    self.autoReplyContentField = ({
        NSTextField *textField = [[NSTextField alloc] init];
        textField.frame = NSMakeRect(20, 40, 350, 175);
        textField.placeholderString = @"请输入自动回复的内容";
        textField.delegate = self;
        
        textField;
    });
    
    self.autoReplyLabel = ({
        NSTextField *label = [NSTextField labelWithString:@"自动回复："];
        label.frame = NSMakeRect(20, 220, 350, 20);
        
        label;
    });
    
    self.keywordTextField = ({
        NSTextField *textField = [[NSTextField alloc] init];
        textField.frame = NSMakeRect(20, 260, 350, 50);
        textField.placeholderString = @"请输入关键字（ ‘*’ 为任何消息都回复，‘||’ 为匹配多个关键字）";
        textField.delegate = self;
        
        textField;
    });
    
    self.keywordLabel = ({
        NSTextField *label = [NSTextField labelWithString:@"关键字："];
        label.frame = NSMakeRect(20, 315, 350, 20);
        
        label;
    });
    
    [self addSafeSubviews:@[self.enableGroupReplyBtn,
                        self.autoReplyContentField,
                        self.autoReplyLabel,
                        self.keywordTextField,
                        self.keywordLabel]];
}

- (void)clickSelectBtn:(NSButton *)btn {
    self.model.replyGroupEnable = btn.state;
}

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
    self.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[NSColor lightGrayColor] CGColor];
    self.layer.cornerRadius = 3;
    self.layer.masksToBounds = YES;
    [self.layer setNeedsDisplay];
}

- (void)setModel:(WCAutoReplyModel *)model {
    _model = model;
    self.keywordTextField.stringValue = model.keyword != nil ? model.keyword : @"";
    self.autoReplyContentField.stringValue = model.replyContent != nil ? model.replyContent : @"";
    self.enableGroupReplyBtn.state = model.replyGroupEnable;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if (self.endEdit) {
        self.endEdit();
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSControl *control = notification.object;
    if (control == self.keywordTextField) {
        self.model.keyword = self.keywordTextField.stringValue;
    } else if (control == self.autoReplyContentField) {
        self.model.replyContent = self.autoReplyContentField.stringValue;
    }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;
    
    if (commandSelector == @selector(insertNewline:)) {
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    } else if (commandSelector == @selector(insertTab:)) {
        if (control == self.keywordTextField) {
            [self.autoReplyContentField becomeFirstResponder];
        } else if (control == self.autoReplyContentField) {
            [self.keywordTextField becomeFirstResponder];
        }
    }
    
    return result;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
