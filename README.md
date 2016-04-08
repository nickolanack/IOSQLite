# IOSQlite

[![CI Status](http://img.shields.io/travis/nickolanack/IOSQLite.svg?style=flat)](https://travis-ci.org/nickolanack/IOSQlite)
[![Version](https://img.shields.io/cocoapods/v/IOSQlite.svg?style=flat)](http://cocoapods.org/pods/IOSQlite)
[![License](https://img.shields.io/cocoapods/l/IOSQlite.svg?style=flat)](http://cocoapods.org/pods/IOSQlite)
[![Platform](https://img.shields.io/cocoapods/p/IOSQlite.svg?style=flat)](http://cocoapods.org/pods/IOSQlite)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```ObjC

#import "Database.h"



//...

-(void)someDatabaseInitializer{

	_db=[[Database alloc] init];
    [_db open:@"Test"]; //Creates or opens a sqlite3 db file 

    [_db execute:@"CREATE TABLE IF NOT EXISTS users (userid INTEGER PRIMARY KEY AUTOINCREMENT, uname TEXT, fullname TEXT, password TEXT, data TEXT, email TEXT)"];

}

//...

-(void)someOtherLogDatabaseValuesMethod{

	[_db query:[NSString stringWithFormat:@"SELECT userid FROM users WHERE uname='%@'", @"userone"] iterate:^(NSDictionary *row) {
        
        NSLog(@"%@",row);
        
    }];

}


```

## Requirements

## Installation

IOSQlite is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "IOSQlite"
```

## Author

nickolanack, nickblackwell82@gmail.com

## License

IOSQlite is available under the MIT license. See the LICENSE file for more info.
