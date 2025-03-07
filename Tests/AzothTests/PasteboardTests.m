//
//  PasteboardTests.m
//  AzothTests
//
//  Created by ThrudTheBarbarian on 1/9/25.
//

#import <SDL3/SDL.h>

#import <XCTest/XCTest.h>
#import <Azoth/Azoth.h>

@interface PasteboardTests : XCTestCase

@end

@implementation PasteboardTests

- (void)setUp
	{
	SDL_Init(SDL_INIT_VIDEO);
	}

- (void)tearDown
	{
	SDL_Quit();
	}

/*****************************************************************************\
|* Create the dragging pasteboard
\*****************************************************************************/
- (void)testPasteboardCreate
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
	XCTAssert(pb != nil, @"Couldn't find the drag pasteboard");
	}

/*****************************************************************************\
|* Create the dragging pasteboard, insert a string, check we can read it back
\*****************************************************************************/
- (void)testPasteboardAddStringAndCheck
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
	XCTAssert(pb != nil, @"Couldn't find the drag pasteboard");

	const char *helloWorld = "Hello World!";

	NSDictionary *info =
		@{
		@"key1" : @"value1",
		@"key2" : @[ @"element1", @"element2"],
		@"key3" : [NSData dataWithBytes:helloWorld length:strlen(helloWorld)+1]
		};
	NSString *desc = info.description;

	[pb setString:desc forType:AZPasteboardTypeString];

	NSString *readback = [pb stringForType:AZPasteboardTypeString];

	XCTAssert([desc isEqualToString:readback],
				@"\nCan't read string back\n[%@]\n[%@]\n", desc, readback);
	}


/*****************************************************************************\
|* Create the dragging pasteboard, insert a string, check we can read it back
\*****************************************************************************/
- (void)testPasteboardAddPlistAndCheck
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
	XCTAssert(pb != nil, @"Couldn't find the drag pasteboard");

	const char *helloWorld = "Hello World!";

	NSDictionary *info =
		@{
		@"key1" : @"value1",
		@"key2" : @[ @"element1", @"element2"],
		@"key3" : [NSData dataWithBytes:helloWorld length:strlen(helloWorld)+1]
		};

	[pb setPropertyList:info forType:AZPasteboardTypeString];
	NSDictionary *readback	= [pb propertyListForType:AZPasteboardTypeString];

	XCTAssert([info isEqualToDictionary:readback],
				@"\nCan't read dictionary back"
				 "\n[%@]\n[%@]\n", info, readback);
	}

/*****************************************************************************\
|* Test clearing
\*****************************************************************************/
- (void)testPasteboardClear
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
	XCTAssert(pb != nil, @"Couldn't find the drag pasteboard");

	[pb setString:@"hi there" forType:AZPasteboardTypeString];
	XCTAssert(pb.datatypes.count == 1, "Somehow got %d types in PB",
				  (int)pb.datatypes.count);

	[pb clearContents];
	XCTAssert(pb.datatypes.count == 0, "Somehow got %d types in PB",
				  (int)pb.datatypes.count);
	}


/*****************************************************************************\
|* Test fetching the system pasteboard
\*****************************************************************************/
- (void)testSystemPasteboardCreate
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameGeneral];
	XCTAssert(pb != nil, @"Couldn't find the general pasteboard");
	}

/*****************************************************************************\
|* Test getting a list of mime-types on the general pasteboard
\*****************************************************************************/
- (void)testSystemPasteboardFetchTypes
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameGeneral];
	XCTAssert(pb != nil, @"Couldn't find the general pasteboard");

	NSDate *until = [NSDate.new dateByAddingTimeInterval:5];
	NSArray *types = nil;
	while (NSDate.new.timeIntervalSince1970 < until.timeIntervalSince1970)
		{
		SDL_PumpEvents();
		types = [pb datatypes];
		if (types.count > 0)
			break;
		[NSThread sleepForTimeInterval:0.1];
		}

	NSLog(@"types: %@", types);
	}


@end
