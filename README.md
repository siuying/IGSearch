# IGSearch

A simple Objective-C full text search engine with CJK support.

## Why

- Core Data search do not built in full text search.
- SQLite3 bundled with iOS do not have proper tokenizer that support CJK language full text search.
- A simple and easy to use API, independent with the data model.

## Setup

Use [CocoaPods](http://cocoapods.org/), add following to your ```Podfile```

```
pod 'IGSearch'
```

Run ```pod install``` and you're off!

## Usage

First, create a database.

```objective-c
IGSearch* search = [[IGSearch alloc] initWithPath:aPath]; 
```

Then, index documents.

```objective-c
[search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
[search indexDocument:@{@"title": @"Super Mario Bros", @"system": @"NES"} withId:@"2"];
[search indexDocument:@{@"title": @"Sonic", @"system": @"Mega Drive"} withId:@"3"];
[search indexDocument:@{@"title": @"Mega Man", @"system": @"NES"} withId:@"4"];
```

Search the document is simple:

```objective-c
[search search:@"Street"]; // @[ @{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} ]
[search search:@"Mega" withField:@"title"]; // @[ @{@"title": @"Mega Man", @"system": @"NES"}  ]
```

## License

MIT License.
