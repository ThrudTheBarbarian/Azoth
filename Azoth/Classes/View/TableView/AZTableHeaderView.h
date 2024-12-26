//
//  AZTableHeaderView.h
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@class AZTableView;

@interface AZTableHeaderView : AZView

/*****************************************************************************\
|* The size of the rectangle for the header view
\*****************************************************************************/
- (NSRect) headerRectOfColumn:(NSInteger)column;

/*****************************************************************************\
|* The column at a given point
\*****************************************************************************/
- (NSInteger) columnAtPoint:(NSPoint)p;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The table-view we belong to
@property(strong, nonatomic) AZTableView *						tableView;

// The table-view we belong to
@property(assign, nonatomic) NSInteger 							resizedColumn;

@end

NS_ASSUME_NONNULL_END
