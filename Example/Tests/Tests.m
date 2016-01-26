//
//  IOSQliteTests.m
//  IOSQliteTests
//
//  Created by nickolanack on 01/26/2016.
//  Copyright (c) 2016 nickolanack. All rights reserved.
//
#import "Database.h"

@import XCTest;

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    
    Database *db=[[Database alloc] init];
    [db open:@"Test"];
    
    
    
}

@end

