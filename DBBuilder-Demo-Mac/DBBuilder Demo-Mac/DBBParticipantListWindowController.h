//
//  DBBParticipantListWindowController.h
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/27/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DBBMeeting;
@protocol ParticipantListDelegate;

@interface DBBParticipantListWindowController : NSWindowController

@property (nonatomic, strong) DBBMeeting *meeting;
@property (nonatomic, weak) id <ParticipantListDelegate> delegate;

@end

@protocol ParticipantListDelegate <NSObject>

- (void)didCloseParticipantListWindow:(DBBParticipantListWindowController *)participantListController;

@end
