//
//  PJXAnimatedTabBarController.m
//  PJXAnimatedTabBarDemo
//
//  Created by poloby on 15/12/30.
//  Copyright © 2015年 poloby. All rights reserved.
//

#import "PJXAnimatedTabBarController.h"
#import "PJXAnimatedTabBarItem.h"
#import "PJXIconView.h"

@interface PJXAnimatedTabBarController () {
    NSDictionary *_containers;
}

@end


@implementation PJXAnimatedTabBarController

#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self checkMoreNavigationControllerItem];
    
    if (self.animated)
        [self refresh];
}

- (void)checkMoreNavigationControllerItem
{
    // Create PJXAnimatedTabBarItem for moreNavigationController.
    UINavigationController *moreController = self.moreNavigationController;
    if (![moreController.tabBarItem isKindOfClass:[PJXAnimatedTabBarItem class]]) {
        UIImage *image = self.moreImage;
        NSString *title = NSLocalizedString(self.moreTitle, nil);
        
        PJXAnimatedTabBarItem* moreItem = [[PJXAnimatedTabBarItem alloc] initWithTitle:title image:image tag:moreController.tabBarItem.tag];
        moreItem.textColor = self.moreTextColor;
        moreItem.animation = self.moreAnimation;
        moreController.tabBarItem = moreItem;
    }
}

#pragma mark - private methods

- (void)refresh
{
    _containers = [self createViewContainers];
    [self createCustomIcons:_containers];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];

    NSArray *items = self.tabBar.items;
    BOOL isMore = (selectedIndex >= items.count - 1) && (self.moreNavigationController.viewControllers.count > 0);
    
    PJXAnimatedTabBarItem *item = isMore ? self.moreNavigationController.tabBarItem : items[selectedIndex];
    [item.animation selectedState:item.iconView.icon textLabel:item.iconView.textLabel];
}

- (void)createCustomIcons:(NSDictionary *)containers
{
    NSArray<PJXAnimatedTabBarItem *> *items = (NSArray<PJXAnimatedTabBarItem *> *)self.tabBar.items;
    
    int itemsCount = (int)self.tabBar.items.count - 1;
    int index = 0;
    if (items) {
        for (UITabBarItem *it in self.tabBar.items) {
            PJXAnimatedTabBarItem *item = (PJXAnimatedTabBarItem *)it;
            
//            NSAssert(item.image != nil, @"add image icon in UITabBarItem");
            
            NSString *indexString = [NSString stringWithFormat:@"container%d", itemsCount-index];
            UIView *container = containers[indexString];
            container.tag = index;
  
            BOOL isSelected = index == self.selectedIndex;
            
            UIImageView *icon;
            UILabel *textLabel;
            
            if (item.iconView) {
                icon = item.iconView.icon;
                textLabel = item.iconView.textLabel;
            }
            else {
                icon = [[UIImageView alloc] initWithImage:item.savedImage];
                icon.translatesAutoresizingMaskIntoConstraints = NO;
            
                // text
                textLabel = [[UILabel alloc] init];
                textLabel.text = item.savedTitle;
                textLabel.backgroundColor = [UIColor clearColor];
                textLabel.font = [UIFont systemFontOfSize:10.0];
                textLabel.textAlignment = NSTextAlignmentCenter;
                textLabel.translatesAutoresizingMaskIntoConstraints = NO;

                item.iconView = [[PJXIconView alloc] initWithIcon:icon textLabel:textLabel];
            }
            
            icon.tintColor = isSelected ? item.animation.iconSelectedColor : item.textColor;
            textLabel.textColor = isSelected ? item.animation.textSelectedColor : item.textColor;

            [container addSubview:icon];
            [self createConstraints:icon container:container size:item.savedImage.size yOffset:-5];
            
            [container addSubview:textLabel];
            CGFloat textLabelWidth = self.tabBar.frame.size.width / (CGFloat)self.tabBar.items.count - 5.0;
            [self createConstraints:textLabel container:container size:CGSizeMake(textLabelWidth, 10) yOffset:16];
            
            item.image = nil;
            item.title = nil;
            
            index++;
        }
    }
}

- (void)createConstraints:(UIView *)view container:(UIView *)container size:(CGSize)size yOffset:(CGFloat)yOffset
{
    NSLayoutConstraint *constX = [NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:container
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1
                                                               constant:0];
    [container addConstraint:constX];
    
    NSLayoutConstraint *constY = [NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:container
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1
                                                               constant:yOffset];
    [container addConstraint:constY];
    
    NSLayoutConstraint *constW = [NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1
                                                               constant:size.width];
    [container addConstraint:constW];
    
    NSLayoutConstraint *constH = [NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1
                                                               constant:size.height];
    [container addConstraint:constH];
}

- (NSDictionary *)createViewContainers
{
    NSMutableDictionary *containersDict = [NSMutableDictionary dictionary];
    
    for (int index = 0; index < self.tabBar.items.count; index++) {
        UIView *viewContainer = [self createViewContainer];
        
        NSString *indexStr = [NSString stringWithFormat:@"container%d", index];
        containersDict[indexStr] = viewContainer;
    }
    
    // let keys = containerDict.keys
    
    NSString *formatString = @"H:|-(0)-[container0]";
    for (int index = 1; index < self.tabBar.items.count; index++) {
        
        NSString *addFormatStr = [NSString stringWithFormat:@"-(0)-[container%d(==container0)]", index];
        formatString = [formatString stringByAppendingString:addFormatStr];
    }
    
    formatString = [formatString stringByAppendingString:@"-(0)-|"];
    NSArray<NSLayoutConstraint *> *constraints = [NSLayoutConstraint constraintsWithVisualFormat:formatString
                                                                              options:NSLayoutFormatDirectionRightToLeft
                                                                              metrics:nil
                                                                                views:containersDict];
    [self.view addConstraints:constraints];
    
    return containersDict;
}

- (UIView *)createViewContainer
{
    UIView *viewContainer = [[UIView alloc] init];
    viewContainer.backgroundColor = [UIColor clearColor]; // for test
    viewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:viewContainer];
    
    // add gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    tapGesture.numberOfTouchesRequired = 1;
    [viewContainer addGestureRecognizer:tapGesture];
    
    // add constrains
    NSLayoutConstraint *constY = [NSLayoutConstraint constraintWithItem:viewContainer
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:0];
    [self.view addConstraint:constY];
    
    NSLayoutConstraint *constH = [NSLayoutConstraint constraintWithItem:viewContainer
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1
                                                               constant:self.tabBar.frame.size.height];
    [self.view addConstraint:constH];
    
    return viewContainer;
}

- (void)tapHandler:(UIGestureRecognizer *)gesture
{
    NSArray<PJXAnimatedTabBarItem *> *items = (NSArray<PJXAnimatedTabBarItem *> *)self.tabBar.items;
    
    NSInteger currentIndex = gesture.view.tag;
    NSInteger selectedIndex = self.selectedIndex;
    if (selectedIndex >= items.count) // NSNotFound is index of MoreNavigationController.
        selectedIndex = items.count - 1; // Last bar item is always of MoreNavigationController.

    BOOL isMore = (currentIndex >= items.count - 1) && (self.moreNavigationController.viewControllers.count > 0);
    
    UIViewController *next = isMore ? self.moreNavigationController : self.viewControllers[currentIndex];
    
    PJXAnimatedTabBarItem *deselectItem = (PJXAnimatedTabBarItem *)items[selectedIndex];
    [deselectItem deselectAnimation];
    
    PJXAnimatedTabBarItem *animationItem = (PJXAnimatedTabBarItem *)items[currentIndex];
    [animationItem playAnimation];
    [animationItem selectedState];
    
    if (selectedIndex != currentIndex) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)] &&
            ![self.delegate tabBarController:self shouldSelectViewController:next])
            return;
        
        if (isMore)
            self.selectedViewController = self.moreNavigationController;
        else
            self.selectedIndex = gesture.view.tag;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)])
            [self.delegate tabBarController:self didSelectViewController:next];
    }
    
    if (isMore && (selectedIndex == currentIndex)) {
        [self.moreNavigationController popToRootViewControllerAnimated:YES];
    }
}

@end
