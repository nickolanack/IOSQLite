//
//  ResultSet.h
//  Abbisure
//
//  Created by Nick Blackwell on 2013-05-10.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface ResultSet : NSObject


-(id)initWithStatement:(sqlite3_stmt *) statement;
-(NSArray *) next;
-(NSDictionary *) nextAssoc;
-(bool)hasNext;


/** 
Returns the object value of the field at index 0 of the current result. This is usually the first result row, however you can iterate the entire result list using this method. 
 */
-(id)firstValue;
/**
 Returns the object value of the field at index (index passed as argurment) of the current result. You can iterate the entire result list using this method.
 */
-(id)valueAt:(int) index;
/**
 Returns the object value of the last field of the current result. You can iterate the entire result list using this method.
 */
-(id)lastValue;

@end
