//
//  DBBProjectListWindowController.h
//  DBBuilder-Mac
//
//  Created by Dennis Birch on 11/20/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DBBProject;

@interface DBBProjectListWindowController : NSWindowController

- (void)setupForSubprojectSelectionWithParentProject:(DBBProject *)parentProject;

@end
