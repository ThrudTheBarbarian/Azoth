//
//  AZDraggingItem.m
//  Azoth
//
//  Created by Simon Gornall on 1/9/25.
//

#import "AZDraggingItem.h"
#import "AZPasteboard.h"

@interface AZDraggingItem()

@end

@implementation AZDraggingItem

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithPasteboardWriter:(id<AZPasteboardWriting>)writer;
	{
	if (self = [super init])
		{
		_writer = writer;
		}
	return self;
	}

+ (instancetype) itemWithPasteboardWriter:(id<AZPasteboardWriting>)writer
	{
	return [[AZDraggingItem alloc] initWithPasteboardWriter:writer];
	}


/*****************************************************************************\
|* Set the properties
\*****************************************************************************/
- (void) setDraggingFrame:(NSRect)rect contents:(AZImage *)img
	{
	_draggingFrame 	= rect;
	_image 			= img;
	}

@end
