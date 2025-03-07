//
//  AZTableHeaderView.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/25/24.
//

#import <Azoth/AZTextField.h>

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

// The column view being resized
@property(assign, nonatomic) NSInteger 							resizedColumn;

// Whether we're highlighted
@property(assign, nonatomic) BOOL 								highlighted;

@end

NS_ASSUME_NONNULL_END

