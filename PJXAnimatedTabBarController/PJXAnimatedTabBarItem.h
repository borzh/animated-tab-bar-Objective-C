//
//  PJXAnimatedTabBarItem.h
//  PJXAnimatedTabBarDemo
//
//  Created by poloby on 15/12/30.
//  Copyright © 2015年 poloby. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "PJXItemAnimation.h"
#import "PJXIconView.h"


// Apple recreates tabBarItem of moreNavigationController if item's image or title are nil.
// We will use empty image and empty string instead (they are not drawn on the screen).

#define TabBarItemEmptyImage          [UIImage new]
#define IsTabBarItemEmptyImage(image) (image.size.width == 0)

#define TabBarItemEmptyString         @" "
#define IsTabBarItemEmptyString(s)    (s == nil || [s isEqualToString:@" "])


@interface PJXAnimatedTabBarItem : UITabBarItem

// We want to draw image & title for more navigation controller customization, but
// we set it to nil from Animated tab bar controller and draw it manually.
// So the idea is to same them and be able to restore when needed.

@property (nonatomic, strong) UIImage *savedImage;
@property (nonatomic, strong) UIImage *savedSelectedImage;
@property (nonatomic, strong) NSString *savedTitle;

@property (nonatomic, strong) IBInspectable UIColor *textColor;
@property (nonatomic, weak) IBOutlet PJXItemAnimation *animation;

@property (nonatomic, strong) PJXIconView *iconView;

- (void)setItemImage:(UIImage *)image;
- (void)eraseImageAndTitle;

- (void)playAnimation;
- (void)deselectAnimation;
- (void)selectedState;

@end
