//
//  Created by Nick Blackwell on 2013-05-10.
//
//

#import "Database.h"
#import "ResultSet.h"

//private definitions.
@interface Database()

@property sqlite3 *db;
@property bool isOpen;

@property NSString *errorMsg;
@property int errorCode;

@end

@implementation Database

+(void)SetDatabase:(sqlite3 *)database forName:(NSString *)name{
    [[Database GetDictionary] setObject:[NSValue valueWithPointer:database] forKey:name];
}
+(sqlite3 *)GetDatabase:(NSString *)name{
    return (sqlite3 *)[((NSValue *)[[Database GetDictionary] objectForKey:name]) pointerValue];
}
+(bool)HasDatabase:(NSString *)name{

    if([[Database GetDictionary] objectForKey:name]!=nil)return true;
    return false;
    
}
+(NSMutableDictionary *)GetDictionary{
    static NSMutableDictionary *dictionary=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = [[NSMutableDictionary alloc] init];
    });
    return dictionary;
}
/*
 * opening a database that is already open, will result in two Database objects sharing the sqlite_3 db. it is possible for queries may become thread locked...
 */
-(bool)open:(NSString *)name{
    sqlite3* db=nil;
    
    
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    NSString *fileName=[[name componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];

    
    
    if([Database HasDatabase:name]){
        db=[Database GetDatabase:name];
    }else{
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *databasePath = [[documentsPath stringByAppendingPathComponent:fileName] stringByAppendingString:@".db"];
        
        
        int error;
        if((error=sqlite3_open([databasePath UTF8String], &db)) != SQLITE_OK) {
            
            self.errorMsg=[NSString stringWithFormat:@"sqlite3_open failed(%d) with %@", error, databasePath];
            self.errorCode=error;
            
            sqlite3_close(db);
            
            return false;
        }
        
        [Database SetDatabase:db forName:name];
        
    }
    self.db=db;
    self.isOpen=true;
    return true;
    
    
}


-(void)close{
    if(self.isOpen){
        sqlite3_close(self.db);
    }
    
    self.db=nil;
    self.isOpen=false;

}


-(ResultSet *)query:(NSString *)query{
    if(self.isOpen){
        
        
        
        sqlite3_stmt    *statement;
        int pErr;
        if((pErr=sqlite3_prepare_v2(self.db, [query UTF8String], -1, &statement, nil))==SQLITE_OK){

            return [[ResultSet alloc] initWithStatement:statement];
            
        }else{
 
            self.errorMsg=[NSString stringWithFormat:@"SQL Prepare Error - %d", pErr];
            self.errorCode=pErr;
            
        }

        
    }
    return nil;
}

-(void)query:(NSString *)query iterate:(void (^)(NSDictionary *))callback{
    ResultSet *r=[self query:query];
    if(r){
        [r iterate:callback];
    }else{
        @throw [[NSException alloc] initWithName:@"Sql Error" reason:[self error] userInfo:nil];
    }
}

-(void)query:(NSString *)query first:(void (^)(NSDictionary *))callback{
    
    ResultSet *r=[self query:query];
    if(r){
        if([r hasNext]){
            callback([r nextAssoc]);
        }else{
            callback(nil);
        }
    }else{
        @throw [[NSException alloc] initWithName:@"Sql Error" reason:[self error] userInfo:nil];
    }
    
}



-(bool)execute:(NSString *)command{
    if(self.isOpen){
    
        int eReturnError;
        char *eError;
        
        
        
        eReturnError=sqlite3_exec(self.db, [command UTF8String], 0, 0, &eError);
        if(!eReturnError){

            return true;
            
        }else{
            self.errorMsg=[NSString stringWithFormat:@"SQL Execute Error: %s",eError];
            self.errorCode=eReturnError;
        }
    }
    return false;
}



-(NSArray *)listTables{
    NSMutableArray *array=[[NSMutableArray alloc] init];
    ResultSet *results;
    if((results=[self query:@"SELECT name FROM sqlite_master WHERE type = 'table'"])){
    
        NSString *name;
        while((name=(NSString *)[results firstValue])){
            [array addObject:name];
        }
        
    }else{
        NSLog(@"%@",[self error]);
    }
    
    return [NSArray arrayWithArray:array];
}


//field definitions from sql create statement
-(NSArray *)splitFieldsString:(NSString *)fieldsStr{

    if([fieldsStr isEqualToString:@""])return @[]; //empty array base case.
    NSMutableArray *parts=[[NSMutableArray alloc] init];
    
    NSMutableCharacterSet *set=[[NSMutableCharacterSet alloc] init];
    [set addCharactersInString:@",()"];
    
    NSScanner *scnr=[[NSScanner alloc] initWithString:fieldsStr];
    NSString *part=nil;
    NSString *rest=nil;
    
    //int depth=0;

    while(part==nil){
        [scnr scanUpToCharactersFromSet:set intoString:&part];
        long loc=[scnr scanLocation]+1;
        if([fieldsStr length]<=loc){
            rest=@"";
        }else{
            rest=[fieldsStr substringFromIndex:loc];
        }
    }
    [parts addObject:part];

    return [parts arrayByAddingObjectsFromArray:[self splitFieldsString:rest]];

}
-(NSDictionary *)parseFieldMetadataString:(NSString *)fieldStr index:(int)cid{
    NSMutableDictionary *meta=[[NSMutableDictionary alloc] init];
    
    [meta setObject:[NSNumber numberWithInt:cid] forKey:@"cid"];
   
    NSScanner *scnr=[[NSScanner alloc] initWithString:fieldStr];
    NSMutableCharacterSet *set=[[NSMutableCharacterSet alloc] init];
    [set addCharactersInString:@" "];
    
    NSString *name=nil;
    [scnr scanUpToCharactersFromSet:set intoString:&name];
    [meta setObject:name forKey:@"name"];
    [scnr scanString:@" " intoString:nil];

    
    NSString *type=nil;
    [scnr scanUpToCharactersFromSet:set intoString:&type];
    [meta setObject:type forKey:@"type"];
    [scnr scanString:@" " intoString:nil];
    
    
    
    if([fieldStr rangeOfString:@"PRIMARY KEY"].location!=NSNotFound){
        [meta setObject:[NSNumber numberWithBool:true] forKey:@"pk"];
    }else{
        [meta setObject:[NSNumber numberWithBool:false] forKey:@"pk"];
    }
    
    if([fieldStr rangeOfString:@"NOT NULL"].location!=NSNotFound){
        [meta setObject:[NSNumber numberWithBool:true] forKey:@"notnull"];
    }else{
        [meta setObject:[NSNumber numberWithBool:false] forKey:@"notnull"];
    }
    
    NSRange r=[fieldStr rangeOfString:@"DEFAULT"];
    if(r.location!=NSNotFound){
        
        NSString *dflt=[[fieldStr componentsSeparatedByString:@"DEFAULT"] lastObject];
        if([dflt rangeOfString:@"\""].location==0){
            @throw [[NSException alloc] initWithName:@"Unimplemented" reason:@"Quote in create" userInfo:nil];
        }else if([dflt rangeOfString:@"'"].location==0){
            @throw [[NSException alloc] initWithName:@"Unimplemented" reason:@"Quote in create" userInfo:nil];
        }else{
            dflt=[[[[dflt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@" "] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [meta setObject:dflt forKey:@"dflt_value"];
        }
        
        
    }
    
    return[[NSDictionary alloc] initWithDictionary:meta];
}

-(NSArray *)tableInfoFromDefinition:(NSString *) definition{
    
    NSArray *parts=[definition componentsSeparatedByString:@"("];
    NSString *str=[[parts subarrayWithRange:NSMakeRange(1, [parts count]-1)] componentsJoinedByString:@""];
    parts=[str componentsSeparatedByString:@")"];
    str=[[parts subarrayWithRange:NSMakeRange(0, [parts count]-1)] componentsJoinedByString:@""];
   
    NSArray *fields=[self splitFieldsString:str];
    NSMutableArray *fieldsMetadata=[[NSMutableArray alloc] init];
    int cid=0;
    for(NSString *fieldDefinition in fields){
        [fieldsMetadata addObject:[self parseFieldMetadataString:fieldDefinition index:cid]];
        cid++;
    }
    
    
    
    return [[NSArray alloc] initWithArray:fieldsMetadata];

}



-(NSArray *)listTableFields:(NSString *)table{
    NSMutableArray *array=[[NSMutableArray alloc] init];
    for(NSDictionary *fieldMetadata in [self listTableFieldsMetadata:table]){
        [array addObject:[fieldMetadata objectForKey:@"name"]];
    }
   
    return [NSArray arrayWithArray:array];
}

-(NSArray *)listTableFieldsMetadata:(NSString *)table{
    NSMutableArray *array=[[NSMutableArray alloc] init];
    ResultSet *results;
    if((results=[self query:[NSString stringWithFormat:@"pragma table_info(%@)",table]])){
        
        // NSString *name;
        while([results hasNext]){
            [array addObject:[results nextAssoc]];
        }
        
    }else{
        NSLog(@"%@",[self error]);
    }
    return [NSArray arrayWithArray:array];
}

-(NSDictionary *)tableFieldMetadata:(NSString *)table field:(NSString *) field{

    for(NSDictionary *fieldMetadata in [self listTableFieldsMetadata:table]){
        if([[fieldMetadata objectForKey:@"name"] isEqualToString:field])return fieldMetadata;
    }
    return nil;
}

-(long long) lastInsertId{
    return sqlite3_last_insert_rowid(self.db);
}



-(NSString *)error{
    if(!self.errorMsg)return @"";
    return self.errorMsg;
}

-(int)errorNum{
    return self.errorCode;
}



-(void) checkTables{
    
    //TODO: move this somewhere
    
    NSArray *tables=[self listTables];
    NSArray *keys=[self.tableDefinitions allKeys];
    //NSLog(@"All Tables %@, Expected Tables: %@",tables, keys);
    for (NSString *table in keys) {
        bool dropTable=false;
        if([tables indexOfObject:table]==NSNotFound){
            //table didn't exist
            if(![self execute:[self.tableDefinitions valueForKey:table]]){
                NSLog(@"%s: Error Creating Table: %@", __PRETTY_FUNCTION__, [self error]);
            }else{
                //NSLog(@"%@: Creating Table: %@", [self class], table);
            }
        }else{
            //NSLog(@"%@: Table Exists: %@", [self class], table);
            NSLog(@"Table Exists checking fields");
            NSArray *sqlFields=[self listTableFieldsMetadata:table];
            //SLog(@"SQL Table[%@]:%@", table, sqlFields);
            NSArray *definitionFields=[self tableInfoFromDefinition:[self.tableDefinitions objectForKey:table]];
           // NSLog(@"Definition Table[%@]:%@", table, definitionFields);
            for(NSDictionary *field in definitionFields){
                NSString *fieldName=[field objectForKey:@"name"];
                NSDictionary *foundField=nil;
                for(NSDictionary *sqlField in sqlFields){
                    NSString *sqlName=[sqlField objectForKey:@"name"];
                    if([fieldName isEqualToString:sqlName]){
                        foundField=sqlField;
                    }
                }
                if(foundField!=nil){
                    if(![foundField isEqualToDictionary:field]){
                        dropTable=true;
                        //NSLog(@"Mismatch: sql[%@] def[%@]",foundField, field);
                        //NSLog(@"Missing field def[%@]",field);
                        NSString *def=[NSString stringWithFormat:@"%@",[field objectForKey:@"type"]];
                        NSString *dflt=nil;
                        if((dflt=[field objectForKey: @"dflt_value"])!=nil){
                            [def stringByAppendingString:[NSString stringWithFormat:@" DEFAULT %@",dflt]];
                        }
                        if([[field objectForKey:@"notnull"] boolValue]){
                            [def stringByAppendingString:@" NOT NULL"];
                        }
                        if([[field objectForKey:@"pk"] boolValue]){
                            [def stringByAppendingString:@" PRIMARY KEY"];
                        }
                        
                        int cid;
                        
                        if((cid=[[field objectForKey:@"cid"] intValue])!=[[foundField objectForKey:@"cid"] intValue]){
                            if(cid==0){
                                def=[def stringByAppendingString:@" FIRST"];
                            }else{
                                def=[def stringByAppendingString:[NSString stringWithFormat:@" AFTER %@", [[definitionFields objectAtIndex:cid-1] objectForKey:@"name"]]];
                            }
                        }
                        NSString *update=[NSString stringWithFormat:@"ALTER TABLE %@ MODIFY %@ %@;",table, [field objectForKey:@"name"], def];
                        if(![self execute:update]){
                            NSLog(@"%@", [self error]);
                        }else{
                            NSLog(@"INSERT {%@}",update);
                        }
                    }
                }else{
                    //NSLog(@"Missing field def[%@]",field);
                    NSString *def=[NSString stringWithFormat:@"%@",[field objectForKey:@"type"]];
                    NSString *dflt=nil;
                    if((dflt=[field objectForKey: @"dflt_value"])!=nil){
                        [def stringByAppendingString:[NSString stringWithFormat:@" DEFAULT %@",dflt]];
                    }
                    if([[field objectForKey:@"notnull"] boolValue]){
                        [def stringByAppendingString:@" NOT NULL"];
                    }
                    if([[field objectForKey:@"pk"] boolValue]){
                        [def stringByAppendingString:@" PRIMARY KEY"];
                    }
                    
                    int cid=[[field objectForKey:@"cid"] intValue];
                    if(cid==0){
                        def=[def stringByAppendingString:@" FIRST"];
                    }else{
                        def=[def stringByAppendingString:[NSString stringWithFormat:@" AFTER %@", [[definitionFields objectAtIndex:cid-1] objectForKey:@"name"]]];
                    }
                    
                    NSString *update=[NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@;",table, [field objectForKey:@"name"], def];
                    if(![self execute:update]){
                        NSLog(@"%@", [self error]);
                    }else{
                        NSLog(@"%@",update);
                    }
                }
            }
            
           
        }
        if(dropTable){
            NSLog(@"%s: Dropping Table: %@",__PRETTY_FUNCTION__, table);
            [self execute:[NSString stringWithFormat:@"DROP TABLE %@;", table]];
            NSLog(@"%s: Creating Table: %@",__PRETTY_FUNCTION__, table);
            [self execute:[self.tableDefinitions objectForKey:table]];
        }
    }
}

+(NSString *)Strip:(NSString *)s{

    s=[s stringByReplacingOccurrencesOfString:@"'" withString:@""];
    return s;
    
}
+(NSString *)Escape:(NSString *)s{
  
    // TODO: escape other characters.
    /*
    
    s=[s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    s=[s stringByReplacingOccurrencesOfString:@"\x00" withString:@"\\x00"];
    s=[s stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    s=[s stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    s=[s stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
     
    */
    
    s=[s stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    
    return s;

}

@end
