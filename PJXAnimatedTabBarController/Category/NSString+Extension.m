//
//  NSString+Additions.m
//  CompCalcPlus
//
//  Created by Boris Godin on 5/30/15.
//  Copyright (c) 2015 Boris Godin. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Extension)

- (CGFloat)kernForFont:(UIFont *)font toFitWidth:(CGFloat)width
{
    CGSize size = CGSizeMake(CGFLOAT_MAX, font.pointSize*2); // Size to fit.
    
    const CGFloat threshold = 0.1;
    CGFloat bigKern = -3.0, smallKern = 0.0, pivot = 0.0;
    NSMutableDictionary *attrs = [NSMutableDictionary new];
    attrs[NSFontAttributeName] = font;
    
    while (true) {
        attrs[NSKernAttributeName] = @(pivot);
        
        CGRect frame = [self boundingRectWithSize:size
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attrs
                                          context:nil];
        CGFloat diff = width - frame.size.width;
        if (diff > 0) {
            // String is fitting.
            if (pivot == 0.0) // Fits without kerning.
                return pivot;
            else if (smallKern - bigKern <= threshold)
                return pivot; // Threshold is reached, return the fitting pivot.
            else {
                // Pivot is fitting, but threshold is not reached, set pivot as max.
                bigKern = pivot;
            }
        }
        else {
            // String not fitting.
            smallKern = pivot;
            if (smallKern - bigKern <= threshold)
                return bigKern;
        }
        pivot = (smallKern + bigKern) / 2.0;
    }
    
    return bigKern;
}

@end
