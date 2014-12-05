//
//  DBBPerson.h
//  DBBuilder
//
//  Created by Dennis Birch on 10/2/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "DBTableRepresentation.h"

@interface DBBPerson : DBTableRepresentation

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *middleInitial;
@property (nonatomic, copy) NSString *department;
@property (nonatomic, strong) NSData *imageData;

+ (NSArray *)allPeople;

- (NSString *)fullName;
- (NSString *)fullNameAndDepartment;


#if TARGET_OS_IPHONE
- (UIImage *)image;
- (void)setJPEGImage:(UIImage *)image withCompression:(CGFloat)compression;
- (void)setPNGImage:(UIImage *)image;
#endif

@end
