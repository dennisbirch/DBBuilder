//
//  DBBEditMeetingWindowController.h
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/26/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DBBMeeting;
@protocol MeetingEditorDelegate;

@interface DBBEditMeetingWindowController : NSWindowController

@property (nonatomic, strong) DBBMeeting *meeting;
@property (nonatomic, weak) id <MeetingEditorDelegate>delegate;

@end


@protocol MeetingEditorDelegate <NSObject>

- (void)didCloseMeetingEditor:(DBBEditMeetingWindowController *)meetingEditor;

@end
