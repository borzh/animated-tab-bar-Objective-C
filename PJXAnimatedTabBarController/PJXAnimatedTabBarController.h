//
//  PJXAnimatedTabBarController.h
//  PJXAnimatedTabBarDemo
//
//  Created by poloby on 15/12/30.
//  Copyright © 2015年 poloby. All rights reserved.
//

#import "PJXItemAnimation.h"

@interface PJXAnimatedTabBarController : UITabBarController
@property (nonatomic, assign) IBInspectable BOOL animated;

@property (nonatomic, strong) IBInspectable UIImage *moreImage;
@property (nonatomic, strong) IBInspectable NSString *moreTitle;
@property (nonatomic, strong) IBInspectable UIColor *moreTextColor;

@property (nonatomic, strong) IBOutlet PJXItemAnimation *moreAnimation;

// Next method is public, because it creates tab bar item for more navigation controller
// at viewDidLoad, but the user probably needs to create it earlier.
- (void)checkMoreNavigationControllerItem;
@end
