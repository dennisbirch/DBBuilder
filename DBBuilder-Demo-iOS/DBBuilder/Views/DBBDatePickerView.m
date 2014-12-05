//
//  DBBDatePickerView.m
//  DBBuilder
//
//  Created by Dennis Birch on 11/10/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBDatePickerView.h"

@interface DBBDatePickerView ()

@property (nonatomic, strong) UIDatePicker *datePicker;

@end

@implementation DBBDatePickerView

- (instancetype)initWithDate:(NSDate *)date section:(NSInteger)section
{
	self = [[DBBDatePickerView alloc] init];
	
	if (self) {
		CGRect frame = CGRectMake(0, 0, 320.0f, 242.0f);
		self.frame = frame;
		self.backgroundColor = [[UIColor lightGrayColor]colorWithAlphaComponent:.95f];
		frame.origin.y += 80.0f;
		frame.size.height -= 80.0f;
		UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:self.frame];
		if (date == nil) {
			date = [NSDate date];
		}
		datePicker.date = date;
		datePicker.tag = section;
		[datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
		[self addSubview:datePicker];
		
		UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
		[closeButton setTitle:@"Done" forState:UIControlStateNormal];
		closeButton.frame = CGRectMake(260.0f, 0.0f, 60.0f, 32.0f);
		[closeButton addTarget:self action:@selector(closeDatePickerView) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:closeButton];
	}
	
	return self;
}


- (void)datePickerValueChanged:(UIDatePicker *)datePicker
{
	[self.delegate datePickerView:self valueChanged:datePicker.date];
}

- (void)closeDatePickerView
{
	[self.delegate didDismissDatePickerView:self];
}

@end
