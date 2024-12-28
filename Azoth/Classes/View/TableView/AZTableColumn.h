//
//  AZTableColumn.h
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZTableHeaderView;
@class AZTableView;
@class AZView;

@interface AZTableColumn : NSObject
/*****************************************************************************\
|* Initialise: programmatically
\*****************************************************************************/
- (instancetype) initWithIdentifier:(NSString *)identifier;

/*****************************************************************************\
|* Provide a view for a given row
\*****************************************************************************/
- (nullable AZView *) dataViewForRow:(NSInteger)row;

/*****************************************************************************\
|* Return any cached rows to the pool
\*****************************************************************************/
- (void) returnViewsInSet:(NSIndexSet *)set;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Identifier for the column
@property(strong, nonatomic) NSString *							identifier;

// The table-view we belong to
@property(strong, nonatomic, nullable) AZTableView *			tableView;

// The default prototype view for this column's data
@property(strong, nonatomic) AZView *							dataView;

// The width of the column, as well as extrema
@property(assign, nonatomic) float								width;
@property(assign, nonatomic) float								maxWidth;
@property(assign, nonatomic) float								minWidth;

// Whether the column is resizable
@property(assign, nonatomic) BOOL								resizable;

// Whether the column is editable
@property(assign, nonatomic) BOOL								editable;

// The type of resizing that can be performed
@property(assign, nonatomic) NSInteger							resizingMask;

// The default sort descriptor
@property(strong, nonatomic) NSSortDescriptor *					sortPrototype;

// The header's title
@property(copy, nonatomic) NSString *							title;

// The header's state
@property(assign, nonatomic) int								headerState;

@end

NS_ASSUME_NONNULL_END
