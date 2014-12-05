//
//  DBBEditPersonView.m
//  DBBuilder
//
//  Created by Dennis Birch on 11/5/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBEditPersonView.h"
#import "DBBPerson.h"

@interface DBBEditPersonView () <UITextFieldDelegate>

@property (nonatomic, strong) DBBPerson *person;
@property (nonatomic, strong) void (^saveAction)();
@property (nonatomic, strong) void (^cancelAction)();
@property (nonatomic, strong) UITextField *firstNameField;
@property (nonatomic, strong) UITextField *lastNameField;
@property (nonatomic, strong) UITextField *middleInitialField;
@property (nonatomic, strong) UITextField *departmentField;
@property (nonatomic, strong) UITextField *currentTextField;

@end

@implementation DBBEditPersonView


- (instancetype)initWithFrame:(CGRect)frame person:(DBBPerson *)person saveAction:(void (^)(DBBPerson *person))saveAction cancelAction:(void (^)())cancelAction
{
    self = [super initWithFrame:frame];
    if (self) {
        self.saveAction = saveAction;
        self.cancelAction = cancelAction;
        self.person = person;
    }
    
    return self;
}

- (void)setPerson:(DBBPerson *)person
{
    _person = person;
    
    self.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.95f];
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveButton addTarget:self action:@selector(performSaveAction) forControlEvents:UIControlEventTouchUpInside];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    saveButton.frame = CGRectMake(20, 20, 70, 32);
    [self addSubview:saveButton];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton addTarget:self action:@selector(performCancelAction) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.frame = CGRectMake(self.bounds.size.width - 90, 20, 70, 32);
    [self addSubview:cancelButton];
    
    // add labels for First, Last, Middle, Department
    CGFloat top = 100.0f;
    static CGFloat textItemHeight = 22;
    static CGFloat titleLabelLeft = 20;
    static CGFloat titleLabelWidth = 56;
    static CGFloat textFieldLeft = 80;
    static CGFloat textFieldWidth = 220;
    
    UILabel *titleLabel = [self labelWithTitle:@"First" frame:CGRectMake(titleLabelLeft, top, titleLabelWidth, textItemHeight)];
    [self addSubview:titleLabel];
    self.firstNameField = [self textFieldWithPlaceholder:@"First Name" frame:CGRectMake(textFieldLeft, top, textFieldWidth, textItemHeight)];
    
    top += (textItemHeight + 20);
    titleLabel = [self labelWithTitle:@"Middle" frame:CGRectMake(titleLabelLeft, top, titleLabelWidth, textItemHeight)];
    [self addSubview:titleLabel];
    self.middleInitialField = [self textFieldWithPlaceholder:@"Middle Initial" frame:CGRectMake(textFieldLeft, top, textFieldWidth, textItemHeight)];
    
    top += (textItemHeight + 20);
    titleLabel = [self labelWithTitle:@"Last" frame:CGRectMake(titleLabelLeft, top, titleLabelWidth, textItemHeight)];
    [self addSubview:titleLabel];
    self.lastNameField = [self textFieldWithPlaceholder:@"Last Name" frame:CGRectMake(textFieldLeft, top, textFieldWidth, textItemHeight)];
    
    top += (textItemHeight + 20);
    titleLabel = [self labelWithTitle:@"Dept." frame:CGRectMake(titleLabelLeft, top, titleLabelWidth, textItemHeight)];
    [self addSubview:titleLabel];
    self.departmentField = [self textFieldWithPlaceholder:@"Department" frame:CGRectMake(textFieldLeft, top, textFieldWidth, textItemHeight)];
    
    self.firstNameField.text = person.firstName;
    self.middleInitialField.text = person.middleInitial;
    self.lastNameField.text = person.lastName;
    self.departmentField.text = person.department;

    // add ability to add photo?
    
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder frame:(CGRect)frame
{
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    textField.placeholder = placeholder;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.delegate = self;
    [self addSubview:textField];
    
    return textField;
}

- (UILabel *)labelWithTitle:(NSString *)title frame:(CGRect)frame
{
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:frame];
    titleLabel.textAlignment = NSTextAlignmentRight;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.text = title;
    
    return titleLabel;
}

- (void)performSaveAction
{
    [self.currentTextField resignFirstResponder];
    
    if (self.saveAction != nil) {
        self.person.firstName = [self.firstNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *middle = [self.middleInitialField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.person.middleInitial = middle.length > 0 ? [[middle substringToIndex:1] uppercaseString] : @"";
        self.person.lastName = [self.lastNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.person.department = [self.departmentField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.saveAction(self.person);
    }
}

- (void)performCancelAction
{
    [self.currentTextField resignFirstResponder];
    
    if (self.cancelAction != nil) {
        self.cancelAction();
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.currentTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.currentTextField = nil;
	[self.person makeDirty];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
	
	if (textField == self.firstNameField) {
		[self.middleInitialField becomeFirstResponder];
	} else if (textField == self.middleInitialField) {
		[self.lastNameField becomeFirstResponder];
	} else if (textField == self.lastNameField) {
		[self.departmentField becomeFirstResponder];
	}
    
    return YES;
}

@end
