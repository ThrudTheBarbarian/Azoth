//
//  AZWindow+Internal.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import "AZWindow+Internal.h"
#import "AZResponder.h"

@interface AZWindow()
// The list of responders in the window
@property(retain, nonatomic) NSMutableArray<AZResponder *>* responders;

// The current first-responder
@property(retain, nonatomic) AZResponder *					firstResponder;
@end

@implementation AZWindow (Internal)

/*****************************************************************************\
|* Called by a view in this window when it adds a subview
\*****************************************************************************/
- (void) _didAddSubview:(AZView *)view
	{
	[self makeFirstResponder:view];
	}

@end
