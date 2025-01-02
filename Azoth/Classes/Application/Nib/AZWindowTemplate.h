//
//  AZWindowTemplate.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZView;

@interface AZWindowTemplate : NSObject

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The max size of the window
@property(assign, nonatomic) NSSize								maxSize;

// The min size of the window
@property(assign, nonatomic) NSSize								minSize;

// The rectangle of the screen we were created on
@property(assign, nonatomic) NSRect								screenRect;

// The class of the content view
@property(strong, nonatomic) id									viewClass;

// Flags for the window
@property(assign, nonatomic) NSInteger							wtFlags;

// Backing types
@property(assign, nonatomic) NSInteger							windowBacking;

// The class of the window
@property(copy, nonatomic) NSString *							windowClass;

// The window rectangle
@property(assign, nonatomic) NSRect								windowRect;

// The style mask for the window
@property(assign, nonatomic) NSInteger							windowStyleMask;

// The title of the window
@property(copy, nonatomic) NSString *							windowTitle;

// The content-view for the window
@property(strong, nonatomic) AZView *							windowView;

// autosave
@property(copy, nonatomic) NSString *							windowAutosave;

@end

NS_ASSUME_NONNULL_END

