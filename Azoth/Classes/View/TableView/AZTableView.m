//
//  AZTableView.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import "AZTableView.h"

/*****************************************************************************\
|* "private" methods / properties
\*****************************************************************************/
@interface AZTableView()

// Number of row-heights
@property(assign, nonatomic) NSInteger					rowHeightsCount;

// Actual row-heights
@property(assign, nonatomic) float *					rowHeights;

// Default row-height
@property(assign, nonatomic) float 						standardRowHeight;


// Temporary: selected columns
@property(strong, nonatomic)
NSMutableArray<AZTableColumn *> *						selectedColumns;

// Temporary: selected row indices
@property(strong, nonatomic) NSIndexSet *				selectedRowIndices;


// The View being used as an editor
@property(strong, nonatomic) AZView *					editingView;

// Rect for the editing view
@property(assign, nonatomic) NSRect						editingFrame;

// Rect for the editing view's border
@property(assign, nonatomic) NSRect						editingBorder;

// row being dragged
@property(assign, nonatomic) NSInteger					draggingRow;

// List of sort descriptors
@property(strong, nonatomic)
NSArray<NSSortDescriptor *> *							sortDescriptors;
@end

@implementation AZTableView

@end
