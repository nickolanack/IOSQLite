//
//  IOSQliteTests.m
//  IOSQliteTests
//
//  Created by nickolanack on 01/26/2016.
//  Copyright (c) 2016 nickolanack. All rights reserved.
//
#import "Database.h"
#import "ResultSet.h"

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
    XCTAssert([db execute:@"CREATE TABLE IF NOT EXISTS users (userid INTEGER PRIMARY KEY AUTOINCREMENT, uname TEXT, fullname TEXT, password TEXT, data TEXT, passcode TEXT, email TEXT);"]);
    
    
    bool insert1=[db execute:[NSString stringWithFormat:
                           @"INSERT INTO users (uname, fullname, password, data, passcode, email) VALUES('%@', '%@', '%@', '%@', '%@', '%@')", @"userone", @"User One", @"e4d909c290d0fb1ca068ffaddf22cbd0", @"{}", @"12345", @"userone@test.com"]];
    
    bool insert2=[db execute:[NSString stringWithFormat:
                              @"INSERT INTO users (uname, fullname, password, data, passcode, email) VALUES('%@', '%@', '%@', '%@', '%@', '%@')", @"usertwo", @"User Two", @"e4d909c290d0fb1ca068ffaddf22cbd0", @"{}", @"12345", @"usertwo@test.com"]];
    
    bool insert3=[db execute:[NSString stringWithFormat:
                              @"INSERT INTO users (uname, fullname, password, data, passcode, email) VALUES('%@', '%@', '%@', '%@', '%@', '%@')", @"userthree", @"User Three", @"e4d909c290d0fb1ca068ffaddf22cbd0", @"{}", @"12345", @"userthree@test.com"]];
    
    XCTAssert(insert1&&insert2&insert3);
    
    
    
    ResultSet *r=[db query:[NSString stringWithFormat:@"SELECT userid FROM users WHERE uname='%@'", @"userone"]];
    //NSString *e=[db error];
    bool classCheck=[r isKindOfClass:[ResultSet class]];
    XCTAssert(classCheck);
    
   
    
    
    
    
    
    
}

@end

