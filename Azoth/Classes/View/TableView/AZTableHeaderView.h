//
//  AZTableHeaderView.h
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//
#if 0
#import <Azoth/AZTextField.h>

NS_ASSUME_NONNULL_BEGIN

@class AZTableView;

@interface AZTableHeaderView : AZTextField

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

// Whether we're highlighted
@property(assign, nonatomic) BOOL 								highlighted;

@end

NS_ASSUME_NONNULL_END
#endif
