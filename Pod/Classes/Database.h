//
//  Created by Nick Blackwell on 2013-05-10.
//
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class ResultSet;


@interface Database : NSObject

@property NSDictionary *tableDefinitions;

/**
 opens or creates a sqlite database file in the users documents folder. 
 with the file named: ~/[name].db all Database instances will share the underlying
 sqlite database object for a given name, 
 */
-(bool) open:(NSString *) name;
-(void)close;

-(ResultSet *)query:(NSString *)query;

/**
 executes the callback block with an associative dictionary of key values pairs for 
 each row
 */
-(void *)query:(NSString *)query iterate:(void (^)(NSDictionary *))callback;
/**
 executes the callback block with an associative dictionary of key values pairs for the first row
 or, if the result is empty, it is called with nil
 */
-(void *)query:(NSString *)query first:(void (^)(NSDictionary *))callback;

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
