//
//  ResultSet.m
//  Abbisure
//
//  Created by Nick Blackwell on 2013-05-10.
//
//

#import "ResultSet.h"

@interface ResultSet()

@property sqlite3_stmt *statement;
@property int first;


-(id)objectValueAt:(int)i;
-(void)step;


@end

@implementation ResultSet




-(id)initWithStatement:(sqlite3_stmt *) statement{

    self = [super init];
    if (self) {
        self.statement=statement;
    }
    
    [self step];
    
    return self;
    

}

-(bool)hasNext{
    if(self.first==SQLITE_ROW)return true;
    return false;
}

-(NSArray *) next{
    if(![self hasNext])return nil;
    NSMutableArray *array=[[NSMutableArray alloc] init];
    
    
    for(int i=0; i<sqlite3_column_count(self.statement); i++){
        [array addObject:[self objectValueAt:i]];
        //[array setValue:[self objectValueAt:i] forKey:[NSString stringWithFormat:@"%d",i]];
    }
    
    [self step];
    
    
    return [NSArray arrayWithArray:array];
}

-(NSDictionary *) nextAssoc{
    if(![self hasNext])return nil;
    NSMutableDictionary *dictionary=[[NSMutableDictionary alloc] init];
    
    
    
    for(int i=0; i<sqlite3_column_count(self.statement); i++){
        //NSString *key=[NSString stringWithUTF8String:(const char *)sqlite3_column_name(self.statement, i)];
        //NSLog(@"%@",key);
        //NSLog(@"%@",[self objectValueAt:i]);
        
        [dictionary setValue:[self objectValueAt:i] forKey:[NSString stringWithUTF8String:(const char *)sqlite3_column_name(self.statement, i)]];
    }
    
    [self step];
    //NSLog(@"Array %@",dictionary);
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

-(void)step{
    self.first=sqlite3_step(self.statement);
   
}


-(id)objectValueAt:(int)index{
    switch(sqlite3_column_type(self.statement, index)){
            
        case SQLITE_INTEGER:
            //NSLog(@"objectValueAt Integer");
            return [NSNumber numberWithInteger:sqlite3_column_int(self.statement, index)];
            break;
            
        case SQLITE_FLOAT:
            //NSLog(@"objectValueAt Float");
            return [NSNumber numberWithDouble:sqlite3_column_double(self.statement, index)];
            break;
            
        case SQLITE_BLOB:
            //NSLog(@"objectValueAt Blob");
            return nil;
            break;
            
        case SQLITE_NULL:
            //NSLog(@"objectValueAt Null");
            return nil;
            break;
            
        case SQLITE3_TEXT:
            //NSLog(@"objectValueAt Text");
            return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(self.statement, index)];
            break;
            
    }
    return nil;
}

-(id)firstValue{
    if(![self hasNext])return nil;
    id value=[self objectValueAt:0];
    [self step];
    return value;
}

-(id)valueAt:(int) index{
    
    if(![self hasNext])return nil;
    id value=[self objectValueAt:index];
    [self step];
    return value;
    
}

-(id)lastValue{

    if(![self hasNext])return nil;
    
    id value=[self objectValueAt:(sqlite3_column_count(self.statement)-1)];
    [self step];
    return value;
}


@end
