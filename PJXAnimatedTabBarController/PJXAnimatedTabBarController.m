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


@interface PJXAnimatedTabBarController () <UITabBarControllerDelegate> {
    NSDictionary *_containers;
    id<UITabBarControllerDelegate> _oldDelegate;
    BOOL _firstTime;
}
@end


@implementation PJXAnimatedTabBarController

#pragma mark - life cycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_firstTime) {
        _firstTime = YES;

        if (self.delegate)
            _oldDelegate = self.delegate; // Save old delegate to forward all calls.
        [super setDelegate:self];
        
        [self refresh];
    }
}

- (void)setDelegate:(id<UITabBarControllerDelegate>)delegate
{
    _oldDelegate = delegate;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    NSArray *items = self.tabBar.items;
    BOOL hasMore = (self.viewControllers.count > items.count);

    NSInteger previousIndex = self.selectedIndex;
    BOOL isPreviousMore = hasMore && (previousIndex >= items.count - 1);

    PJXAnimatedTabBarItem *item = isPreviousMore ? self.moreNavigationController.tabBarItem : items[previousIndex];
    [self setSelected:NO item:item];
    
    [super setSelectedIndex:selectedIndex];
    
    BOOL isMore = hasMore && (selectedIndex >= items.count - 1);
    
    item = isMore ? self.moreNavigationController.tabBarItem : items[selectedIndex];
    [self setSelected:YES item:item];
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController
{
    PJXAnimatedTabBarItem *item = (PJXAnimatedTabBarItem *)self.selectedViewController.tabBarItem;
    [self setSelected:NO item:item];
    
    [super setSelectedViewController:selectedViewController];
    
    item = (PJXAnimatedTabBarItem *)selectedViewController.tabBarItem;
    [self setSelected:YES item:item];
}

#pragma mark - private methods

- (void)setSelected:(BOOL)isSelected item:(PJXAnimatedTabBarItem *)item
{
    if (![item isKindOfClass:[PJXAnimatedTabBarItem class]])
        return;
    
    if (isSelected)
        [item.animation selectedState:item.iconView.icon textLabel:item.iconView.textLabel];
    else {
        item.iconView.icon.tintColor = item.textColor;
        item.iconView.textLabel.textColor = item.textColor;
    }
}

- (void)checkMoreNavigationControllerItem
{
    if (!self.animated)
        return;
    
    // Create PJXAnimatedTabBarItem for moreNavigationController.
    UITabBarItem *moreItem = self.moreNavigationController.tabBarItem;
    
    if (![moreItem isKindOfClass:[PJXAnimatedTabBarItem class]]) {
        moreItem = [self createItemWithTitle:NSLocalizedString(self.moreTitle, nil)
                                       image:self.moreImage
                                   textColor:self.moreTextColor
                                   animation:self.moreAnimation
                                         tag:moreItem.tag];
        self.moreNavigationController.tabBarItem = moreItem;
    }
}

- (PJXAnimatedTabBarItem *)createItemWithTitle:(NSString *)title image:(UIImage *)image textColor:(UIColor *)textColor animation:(PJXItemAnimation *)animation tag:(NSInteger)tag
{
    PJXAnimatedTabBarItem* item = [[PJXAnimatedTabBarItem alloc] initWithTitle:title image:image tag:tag];
    item.textColor = textColor;
    item.animation = animation;
    return item;
}

- (void)refresh
{
    if (!self.animated)
        return;

    _containers = [self createViewContainers];
    [self createCustomIcons];
}

- (void)setItemImage:(UIImage *)image forItem:(PJXAnimatedTabBarItem *)item
{
    // In customized more navigation controller this works for normal but not deselected image.
    item.image = image;
    item.selectedImage = image;

    // Could not find another way around to show images in customized more navigation controller view.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [item setFinishedSelectedImage:image withFinishedUnselectedImage:image];
#pragma clang diagnostic pop
}

- (void)restoreImageForItem:(PJXAnimatedTabBarItem *)item
{
    NSAssert([item isKindOfClass:[PJXAnimatedTabBarItem class]], @"item should be PJXAnimatedTabBarItem", nil);
              
    if (item.image == nil) {
        [self setItemImage:item.savedImage forItem:item];
        item.title = item.savedTitle;
        
        // Set unselected color attributes.
        UIColor *color = item.textColor;
        if (color) {
            NSDictionary *attributes = @{ NSForegroundColorAttributeName:color };
            [item setTitleTextAttributes:attributes forState:UIControlStateNormal];
        }
        
        // Set selected color attributes.
        color = item.animation.textSelectedColor;
        if (color) {
            NSDictionary *attributes = @{ NSForegroundColorAttributeName:color };
            [item setTitleTextAttributes:attributes forState:UIControlStateSelected];
        }
    }
}

- (void)removeContainers
{
    // Remove item views we created for tab bar items.
    for (NSString *key in _containers)
        [_containers[key] removeFromSuperview];
    _containers = nil;
    
    // Restore images for tab bar items.
    for (UIViewController *vc in self.viewControllers)
        [self restoreImageForItem:(PJXAnimatedTabBarItem *)vc.tabBarItem];

    // Restore image for moreNavigationController item.
    [self checkMoreNavigationControllerItem];
    PJXAnimatedTabBarItem *item = (PJXAnimatedTabBarItem *)self.moreNavigationController.tabBarItem;
    [self restoreImageForItem:item];
}

- (void)createCustomIcons
{
    // Oddly, after finishing customizing tab bar items, sometimes more navigation controller resets
    // its tabBarItem to UITabBarItem *.
    [self checkMoreNavigationControllerItem];
    
    NSArray<PJXAnimatedTabBarItem *> *items = (NSArray<PJXAnimatedTabBarItem *> *)self.tabBar.items;
    int itemsCount = (int)self.tabBar.items.count - 1;
    int index = 0;
    
    for (PJXAnimatedTabBarItem *item in items) {
        [self createContainerForItem:item index:index count:itemsCount];
        index++;
    }

    NSInteger selectedIndex = self.selectedIndex;
    if (selectedIndex > itemsCount)
        selectedIndex = itemsCount;
    
    [self setSelected:YES item:items[selectedIndex]];
}

- (void)createContainerForItem:(PJXAnimatedTabBarItem *)item index:(int)index count:(int)count
{
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
    
    icon.tintColor = item.textColor;
    textLabel.textColor = item.textColor;

    [self setItemImage:nil forItem:item];
    item.title = nil;

    if (index <= count) {
        NSString *indexString = [NSString stringWithFormat:@"container%d", count - index];
        
        UIView *container = _containers[indexString];
        container.tag = index;

        [container addSubview:icon];
        [self createConstraints:icon container:container size:item.savedImage.size yOffset:-5];
        
        [container addSubview:textLabel];
        CGFloat textLabelWidth = self.tabBar.frame.size.width / (CGFloat)self.tabBar.items.count - 5.0;
        [self createConstraints:textLabel container:container size:CGSizeMake(textLabelWidth, 10) yOffset:16];
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

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)])
        return [_oldDelegate tabBarController:tabBarController shouldSelectViewController:viewController];
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)])
        [_oldDelegate tabBarController:tabBarController didSelectViewController:viewController];
}

- (void)tabBarController:(UITabBarController *)tabBarController willBeginCustomizingViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers
{
    [self removeContainers];

    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:willBeginCustomizingViewControllers:)])
        [_oldDelegate tabBarController:tabBarController willBeginCustomizingViewControllers:viewControllers];
}

- (void)tabBarController:(UITabBarController *)tabBarController willEndCustomizingViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers changed:(BOOL)changed
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:willEndCustomizingViewControllers:changed:)])
        [_oldDelegate tabBarController:tabBarController willEndCustomizingViewControllers:viewControllers changed:changed];
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers changed:(BOOL)changed
{
    [self refresh];

    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:didEndCustomizingViewControllers:changed:)])
        [_oldDelegate tabBarController:tabBarController didEndCustomizingViewControllers:viewControllers changed:changed];
}

- (UIInterfaceOrientationMask)tabBarControllerSupportedInterfaceOrientations:(UITabBarController *)tabBarController
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarControllerSupportedInterfaceOrientations:)])
        return [_oldDelegate tabBarControllerSupportedInterfaceOrientations:tabBarController];
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)tabBarControllerPreferredInterfaceOrientationForPresentation:(UITabBarController *)tabBarController
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarControllerPreferredInterfaceOrientationForPresentation:)])
        return [_oldDelegate tabBarControllerPreferredInterfaceOrientationForPresentation:tabBarController];
    else
        return [UIApplication sharedApplication].statusBarOrientation;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)tabBarController:(UITabBarController *)tabBarController
                               interactionControllerForAnimationController: (id <UIViewControllerAnimatedTransitioning>)animationController
{
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:interactionControllerForAnimationController:)])
        return [_oldDelegate tabBarController:tabBarController interactionControllerForAnimationController:animationController];
    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController
                     animationControllerForTransitionFromViewController:(UIViewController *)fromVC
                                                       toViewController:(UIViewController *)toVC
{
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:animationControllerForTransitionFromViewController:toViewController:)])
        return [_oldDelegate tabBarController:tabBarController animationControllerForTransitionFromViewController:fromVC toViewController:toVC];
    return nil;
}


@end
