//
//  DBBEditPersonWindowController.h
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/28/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DBBPerson;
@protocol EditPersonDelegate;

@interface DBBEditPersonWindowController : NSWindowController

@property (nonatomic, strong) DBBPerson *participant;
@property (nonatomic, weak) id <EditPersonDelegate> delegate;

@end

@protocol EditPersonDelegate <NSObject>

- (void)didCloseEditPersonWindow:(DBBEditPersonWindowController *)editPersonController;

@end
