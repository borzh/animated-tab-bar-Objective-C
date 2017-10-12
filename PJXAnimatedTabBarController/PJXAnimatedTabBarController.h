//
//  PJXAnimatedTabBarController.h
//  PJXAnimatedTabBarDemo
//
//  Created by poloby on 15/12/30.
//  Copyright © 2015年 poloby. All rights reserved.
//

#import "PJXItemAnimation.h"


// Note that tag 0 normally is used for moreNavigationController's item, so set tags of your tab
// bar items starting from 1.

@protocol PJXAnimatedTabBarControllerDataSource <NSObject>

@optional
// If the image is for more navigation controller order, isMore will be set to true.
// In that case you should image with UIImageRenderingModeAlwaysOriginal.
// Otherwise, image view tint color will be used.
- (UIImage *)imageForViewControllerWithTabBarItemTag:(NSInteger)tag forMore:(BOOL)isMore;
- (UIImage *)selectedImageForViewControllerWithTabBarItemTag:(NSInteger)tag forMore:(BOOL)isMore;
@end


@interface PJXAnimatedTabBarController : UITabBarController

@property (nonatomic, weak) id<PJXAnimatedTabBarControllerDataSource> dataSource;

@property (nonatomic, assign) IBInspectable BOOL animated;

@property (nonatomic, strong) IBInspectable UIImage *moreImage;
@property (nonatomic, strong) IBInspectable UIImage *moreSelectedImage;
@property (nonatomic, strong) IBInspectable NSString *moreTitle;
@property (nonatomic, strong) IBInspectable UIColor *moreTextColor;

@property (nonatomic, strong) IBOutlet PJXItemAnimation *moreAnimation;

// Call recreateItems when image of some tab bar item is changed.
- (void)recreateItems;

// Call refresh when color of some tab bar item is changed or after recreateItems.
- (void)refresh;

@end
