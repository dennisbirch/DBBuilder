//
//  CommonSetup.h
//  DBBuilder-Demo-Mac
//
//  Created by Dennis Birch on 12/3/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

@class DBManager;
@class DBBPerson;

@interface CommonSetup : XCTestCase

@property (nonatomic, strong) DBManager *manager;

- (void)performSetUp;
- (void)performTeardown;

- (NSArray <DBBPerson *>*)twoPeople;

@end
