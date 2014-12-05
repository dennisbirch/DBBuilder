//
//  DBBEditProjectWindowController.h
//  DBBuilder-Mac
//
//  Created by Dennis Birch on 11/20/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DBBProject;
@protocol ProjectEditorDelegate;

@interface DBBEditProjectWindowController : NSWindowController

@property (nonatomic, strong) DBBProject *project;
@property (nonatomic, weak) id <ProjectEditorDelegate>delegate;

@end


@protocol ProjectEditorDelegate <NSObject>

- (void)closedProjectEditorWindow:(DBBEditProjectWindowController *)projectEditorWindow;

@end
