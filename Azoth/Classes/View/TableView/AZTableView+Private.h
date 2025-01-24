//
//  AZTableView+Private.h
//  Azoth
//
//  Created by Simon Gornall on 1/23/25.
//

#ifndef __Tableview_private__
#define __Tableview_private__

#import <Azoth/AZTableView.h>

@interface AZTableView (PrivateMethods)
/*****************************************************************************\
|* Return the row at a given point
\*****************************************************************************/
- (NSInteger) rowAtPoint:(NSPoint)p;

@end

#endif // ! __Tableview_private__
