//
//  PJXAnimatedTabBarItem.m
//  PJXAnimatedTabBarDemo
//
//  Created by poloby on 15/12/30.
//  Copyright © 2015年 poloby. All rights reserved.
//


#import "PJXAnimatedTabBarItem.h"
#import "PJXBadge.h"


@interface PJXAnimatedTabBarItem () <NSCopying>

@property (nonatomic, strong) PJXBadge *badge;

@end


@implementation PJXAnimatedTabBarItem

- (void)awakeFromNib
{
    [super awakeFromNib];
    _savedImage = self.image;
    _savedTitle = self.title;
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    if (image) {
        // Put image to iconView and save it for future reference.
        if (self.iconView)
            self.iconView.icon.image = image;
        _savedImage = image;
    }
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    if (title.length) {
        // Put title to iconView and save it for future reference.
        if (self.iconView)
            self.iconView.textLabel.text = title;
        _savedTitle = title;
    }
}

- (NSString *)badgeValue
{
    if (self.badge) {
        return self.badge.text;
    }
    return nil;
}

- (void)setBadgeValue:(NSString *)badgeValue
{
    if (badgeValue == nil) {
        if (self.badge) {
            [self.badge removeFromSuperview];
            self.badge = nil;
        }
        return ;
    }
    
    if (self.badge == nil) {
        self.badge = [PJXBadge bage];
        
        UIView *containerView = self.iconView.icon.superview;
        if (containerView) {
            [self.badge addBadgeOnView:containerView];
        }
    }
    
    if (self.badge) {
        self.badge.text = badgeValue;
    }
}

- (void)playAnimation
{
    NSAssert(self.animation != nil, @"add animation in UITabBarItem");
    if (self.animation != nil && self.iconView != nil) {
        [self.animation playAnimation:self.iconView.icon textLabel:self.iconView.textLabel];
    }
}

- (void)deselectAnimation
{
    if (self.animation != nil && self.iconView != nil) {
        [self.animation deselectAnimation:self.iconView.icon textLabel:self.iconView.textLabel defaultTextColor:self.textColor];
    }
}

- (void)selectedState
{
    if (self.animation != nil && self.iconView != nil) {
        [self.animation selectedState:self.iconView.icon textLabel:self.iconView.textLabel];
    }
}

- (instancetype)copyWithZone:(nullable NSZone *)zone
{
    PJXAnimatedTabBarItem *item = [[PJXAnimatedTabBarItem alloc] initWithTitle:self.savedTitle image:self.savedImage tag:self.tag];
    return item;
}

@end
