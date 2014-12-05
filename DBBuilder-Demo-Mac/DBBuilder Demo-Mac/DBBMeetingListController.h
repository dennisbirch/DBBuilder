//
//  DBBMeetingListController.h
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/22/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DBBProject;
@protocol MeetingListWindowDelegate;

@interface DBBMeetingListController : NSWindowController

@property (nonatomic, strong) DBBProject *project;
@property (nonatomic, weak) id <MeetingListWindowDelegate> delegate;

@end

@protocol MeetingListWindowDelegate <NSObject>

- (void)didCloseMeetingListWindow:(DBBMeetingListController *)meetingListWindow;

@end
