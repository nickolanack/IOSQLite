//
//  Database.h
//  Abbisure
//
//  Created by Nick Blackwell on 2013-05-10.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ResultSet;


@interface Database : NSObject

@property NSDictionary *tableDefinitions;

-(bool) open:(NSString *) name;
-(void)close;
-(ResultSet *)query:(NSString *)query;
-(bool)execute:(NSString *)command;


-(NSString *) error;
-(int) errorNum;



-(NSArray *) listTables;
-(long long) lastInsertId;
-(void) checkTables;

//Remove stirng
+(NSString *)Strip:(NSString *)s;

+(NSString *)Escape:(NSString *)s;
@end
