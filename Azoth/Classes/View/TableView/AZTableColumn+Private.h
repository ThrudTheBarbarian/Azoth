//
//  AZTableColumn+Private.h
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#ifndef AZTableColumn_Private_h
#define AZTableColumn_Private_h

@interface AZTableColumn (PrivateMethods)

/*****************************************************************************\
|* Prepare the view at a given row
\*****************************************************************************/
- (void) _prepareView:(AZView *)view inRow:(NSInteger)row;

/*****************************************************************************\
|* Sort the column
\*****************************************************************************/
- (void) _sort;

@end

#endif /* AZTableColumn_Private_h */
