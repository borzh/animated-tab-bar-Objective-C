//
//  NSString+Additions.h
//  CompCalcPlus
//
//  Created by Boris Godin on 5/30/15.
//  Copyright (c) 2015 Boris Godin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extension)
- (CGFloat)kernForFont:(UIFont *)font toFitWidth:(CGFloat)width;
@end
