//
//  PJXAnimatedTabBarController.m
//  PJXAnimatedTabBarDemo
//
//  Created by poloby on 15/12/30.
//  Copyright © 2015年 poloby. All rights reserved.
//


#import "NSString+Extension.h"
#import "PJXAnimatedTabBarController.h"
#import "PJXAnimatedTabBarItem.h"
#import "PJXIconView.h"


@interface PJXAnimatedTabBarControllerDelegate: NSObject <UITabBarControllerDelegate, CAAnimationDelegate>
@property (nonatomic, weak) PJXAnimatedTabBarController *controller;
@property (nonatomic, weak) id<UITabBarControllerDelegate> oldDelegate;
- (instancetype)initWithController:(PJXAnimatedTabBarController *)controller;
@end


@interface PJXAnimatedTabBarController () {
    NSDictionary *_containers;
    BOOL _loaded, _iconsForCustomizing;
    UIImage *emptyImage;
    NSString *emptyString;
    PJXAnimatedTabBarControllerDelegate *_delegate;
}
@end


@implementation PJXAnimatedTabBarController

#pragma mark - Life cycle.

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _delegate = [[PJXAnimatedTabBarControllerDelegate alloc] initWithController:self];
    if (self.delegate)
        _delegate.oldDelegate = self.delegate; // Save old delegate to forward all calls.
}

// We will create custom views in viewWillAppear instead of viewDidLoad, because in viewWillLoad
// tabBar.items returns all viewController's items, but later it will be only fitting items.
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_loaded) {
        [super setDelegate:_delegate];
        
        [self recreateItems];
        [self refresh];

        _loaded = YES;
    }
}

#pragma mark - Public methods.

- (void)refresh
{
    if (!self.animated)
        return;
    
    if (_containers)
        [self removeContainers];
    
    _containers = [self createViewContainers];
    [self createCustomIcons];
}


- (void)setDelegate:(id<UITabBarControllerDelegate>)delegate
{
    _delegate.oldDelegate = delegate;
}

//- (void)setSelectedIndex:(NSUInteger)selectedIndex
//{
//    NSArray *items = self.tabBar.items;
//    BOOL hasMore = (self.viewControllers.count > items.count);
//
//    NSInteger previousIndex = self.selectedIndex;
//    BOOL isPreviousMore = hasMore && (previousIndex >= items.count - 1);
//
//    PJXAnimatedTabBarItem *item = isPreviousMore ? self.moreNavigationController.tabBarItem : items[previousIndex];
//    [self setSelected:NO item:item];
//    
//    [super setSelectedIndex:selectedIndex];
//    
//    BOOL isMore = hasMore && (selectedIndex >= items.count - 1);
//    
//    item = isMore ? self.moreNavigationController.tabBarItem : items[selectedIndex];
//    [self setSelected:YES item:item];
//}
//
//- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController
//{
//    PJXAnimatedTabBarItem *item = (PJXAnimatedTabBarItem *)self.selectedViewController.tabBarItem;
//    [self setSelected:NO item:item];
//    
//    [super setSelectedViewController:selectedViewController];
//    
//    item = (PJXAnimatedTabBarItem *)selectedViewController.tabBarItem;
//    [self setSelected:YES item:item];
//}
//
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
    // Create PJXAnimatedTabBarItem for moreNavigationController.
    PJXAnimatedTabBarItem *moreItem = (PJXAnimatedTabBarItem *)self.moreNavigationController.tabBarItem;
    
    if (![moreItem isKindOfClass:[PJXAnimatedTabBarItem class]]) {
        NSLog(@"Creating more icon");
        moreItem = [self createItemWithTitle:NSLocalizedString(self.moreTitle, nil)
                                       image:self.moreImage
                                   textColor:self.moreTextColor
                                   animation:self.moreAnimation
                                         tag:moreItem.tag];
        [moreItem eraseImageAndTitle];
        if (_containers) {
            NSString *indexString = [NSString stringWithFormat:@"container%d", 0];
        
            UIView *container = _containers[indexString];
            if (container.subviews.count == 2) {
                UIImageView *imageView = container.subviews[0];
                UILabel *textLabel = container.subviews[1];
                moreItem.iconView = [[PJXIconView alloc] initWithIcon:imageView textLabel:textLabel];
            }
        }
        self.moreNavigationController.tabBarItem = moreItem;
    }
}

# pragma mark - Create tab bar items.

- (void)recreateItems
{
    // When not using animation, we recreate the items as for more view controller customizing.
    [self recreateItemsForCustomizing:!self.animated];
}

- (void)recreateItemsForCustomizing:(BOOL)isCustomizing
{
    if ((_iconsForCustomizing == isCustomizing) && _loaded)
        return;
    
    _iconsForCustomizing = isCustomizing;
    
    NSLog(@"recreateItemsForCustomizing: %@", isCustomizing ? @"yes" : @"no");

    UIViewController *selectedVC = self.selectedViewController;

    // Generate a tinted unselected image based on image passed via the storyboard.
    for (UIViewController *vc in self.viewControllers) {
        PJXAnimatedTabBarItem *item = (PJXAnimatedTabBarItem *)vc.tabBarItem;
        item = [self createTabBarItemFrom:item isSelected:(vc == selectedVC) forMore:NO forCustomizing:isCustomizing];
        if (item)
            vc.tabBarItem = item;
    }
    
    UIViewController *moreVC = self.moreNavigationController;
    PJXAnimatedTabBarItem *item = (PJXAnimatedTabBarItem *)moreVC.tabBarItem;
    item = [self createTabBarItemFrom:item isSelected:(moreVC == selectedVC) forMore:YES forCustomizing:isCustomizing];
    if (item)
        moreVC.tabBarItem = item;
}

- (PJXAnimatedTabBarItem *)createTabBarItemFrom:(PJXAnimatedTabBarItem *)item isSelected:(BOOL)isSelected forMore:(BOOL)isMore forCustomizing:(BOOL)isCustomizing
{
//    if (self.animated && isCustomizing) {
//        item.image = item.savedImage;
//        item.selectedImage = item.savedSelectedImage;
////        [item setItemImage:item.savedImage];
//        return nil;
//    }
    NSInteger tag = item.tag;
    UIImage *imageUnsel = item.image;
    UIImage *imageSel = item.selectedImage;
    UIColor *textColor = nil;
    NSString *title = nil;
    PJXItemAnimation *animation = nil;
    PJXIconView *iconView = nil;

    if ([item isKindOfClass:[PJXAnimatedTabBarItem class]]) {
        imageUnsel = item.savedImage;
        imageSel = item.savedSelectedImage;
        title = item.savedTitle;
        animation = item.animation;
        textColor = item.textColor;
        iconView = item.iconView;
    }
    
    if ([_dataSource respondsToSelector:@selector(imageForViewControllerWithTabBarItemTag:forMore:)])
        imageUnsel = [_dataSource imageForViewControllerWithTabBarItemTag:tag forMore:isCustomizing];
    if ([_dataSource respondsToSelector:@selector(selectedImageForViewControllerWithTabBarItemTag:forMore:)])
        imageSel = [_dataSource selectedImageForViewControllerWithTabBarItemTag:tag forMore:isCustomizing];
    
    if (!imageUnsel && isMore)
        imageUnsel = self.moreImage;
    
    if (!imageSel && isMore)
        imageSel = self.moreSelectedImage;
    
    if (title.length == 0 && isMore)
        title = self.moreTitle;
    if (!animation && isMore)
        animation = self.moreAnimation;
    
    if (!textColor && isMore)
        textColor = self.moreTextColor;

    NSAssert(imageUnsel, @"Please provide item's image.");
    NSAssert(textColor, @"Please provide item's text color.");
    NSAssert(animation, @"Please provide item's animation.");
    
    PJXAnimatedTabBarItem *newItem = [[PJXAnimatedTabBarItem alloc] initWithTitle:title image:imageUnsel selectedImage:imageSel];
    newItem.tag = tag;
    newItem.textColor = textColor;
    newItem.animation = animation;
    newItem.iconView = iconView;

    iconView.textLabel.textColor = isSelected ? animation.textSelectedColor : textColor;
    iconView.icon.tintColor = isSelected ? animation.iconSelectedColor : textColor;

    // Set unselected color attributes.
    NSDictionary *attributes = @{ NSForegroundColorAttributeName:textColor };
    [newItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    // Set selected color attributes.
    attributes = @{ NSForegroundColorAttributeName:animation.textSelectedColor };
    [newItem setTitleTextAttributes:attributes forState:UIControlStateSelected];

    return newItem;
}

- (PJXAnimatedTabBarItem *)createItemWithTitle:(NSString *)title image:(UIImage *)image textColor:(UIColor *)textColor animation:(PJXItemAnimation *)animation tag:(NSInteger)tag
{
    PJXAnimatedTabBarItem* item = [[PJXAnimatedTabBarItem alloc] initWithTitle:title image:image tag:tag];
    item.textColor = textColor;
    item.animation = animation;
    return item;
}

- (void)setTextForItem:(PJXAnimatedTabBarItem *)item
{
    item.title = @" ";

    CGFloat textLabelWidth = self.tabBar.frame.size.width / (CGFloat)(self.tabBar.items.count);
    textLabelWidth -= 6.0; // Some padding.
    
    UIFont *font = [UIFont systemFontOfSize:10.0];
    CGFloat kern = [item.savedTitle kernForFont:font toFitWidth:textLabelWidth];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attrs = @{
                            NSFontAttributeName: font,
                            NSKernAttributeName: @(kern),
                            NSForegroundColorAttributeName: item.textColor,
                            NSParagraphStyleAttributeName: paragraphStyle
                            };
    item.iconView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:item.savedTitle attributes:attrs];
}

- (void)removeContainers
{
    // Remove item views we created for tab bar items.
    for (NSString *key in _containers)
        [_containers[key] removeFromSuperview];
    _containers = nil;
}

- (void)createCustomIcons
{
//    // Oddly, after finishing customizing tab bar items, sometimes more navigation controller resets
//    // its tabBarItem to UITabBarItem *.
//    [self checkMoreNavigationControllerItem];
    
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
    NSAssert([item isKindOfClass:[PJXAnimatedTabBarItem class]], @"item should be PJXAnimatedTabBarItem");
    
    UIImageView *icon;
    UILabel *textLabel;
    
    if (item.iconView) {
        icon = item.iconView.icon;
        textLabel = item.iconView.textLabel;
    }
    else {
        icon = [[UIImageView alloc] initWithImage:item.savedImage];
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        
        textLabel = [[UILabel alloc] init];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.lineBreakMode = NSLineBreakByClipping;
        textLabel.text = item.savedTitle;
        textLabel.font = [UIFont systemFontOfSize:10.0];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        item.iconView = [[PJXIconView alloc] initWithIcon:icon textLabel:textLabel];
    }
    
    icon.tintColor = item.textColor;
    textLabel.textColor = item.textColor;

    [item eraseImageAndTitle];
    [self setTextForItem:item];

    if (index <= count) {
        NSString *indexString = [NSString stringWithFormat:@"container%d", count - index];
        
        UIView *container = _containers[indexString];
        container.tag = index;

        [container addSubview:icon];
        [self createConstraints:icon container:container size:item.savedImage.size yOffset:-5.5];
        
        [container addSubview:textLabel];
        CGFloat textLabelWidth = self.tabBar.frame.size.width / (CGFloat)self.tabBar.items.count;
        [self createConstraints:textLabel container:container size:CGSizeMake(textLabelWidth, 12) yOffset:17.5];
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

- (void)animateTo:(NSInteger)currentIndex doDelegate:(BOOL)doDelegate
{
    [self checkMoreNavigationControllerItem];
    
    NSArray<PJXAnimatedTabBarItem *> *items = (NSArray<PJXAnimatedTabBarItem *> *)self.tabBar.items;
    
    NSInteger selectedIndex = self.selectedIndex;
    if (selectedIndex >= items.count) // NSNotFound is index of MoreNavigationController.
        selectedIndex = items.count - 1; // Last bar item is always of MoreNavigationController.
    
    BOOL isMore = (currentIndex >= items.count - 1) && (self.viewControllers.count > items.count);
    
    UIViewController *next = isMore ? self.moreNavigationController : self.viewControllers[currentIndex];
    
    PJXAnimatedTabBarItem *deselectItem = (PJXAnimatedTabBarItem *)items[selectedIndex];
    [deselectItem deselectAnimation];
    
    PJXAnimatedTabBarItem *animationItem = (PJXAnimatedTabBarItem *)items[currentIndex];
#if ANIMATED_TAB_BAR_SHOULD_RECREATE_ITEMS_ON_SELECT_MORE
    if (isMore && self.moreNavigationController.viewControllers.count == 1)
        animationItem.animation.delegate = _delegate;
    else
        animationItem.animation.delegate = nil;
#endif
    
    [animationItem playAnimation];
    [animationItem selectedState];
    
    if (selectedIndex != currentIndex) {
        if (doDelegate && ![_delegate tabBarController:self shouldSelectViewController:next])
            return;
        
        if (isMore)
            self.selectedViewController = self.moreNavigationController;
        else
            self.selectedIndex = currentIndex;
        
        [_delegate tabBarController:self didSelectViewController:next];
    }
    
    if (isMore && (selectedIndex == currentIndex)) {
        [self.moreNavigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)tapHandler:(UIGestureRecognizer *)gesture
{
    [self animateTo:gesture.view.tag doDelegate:YES];
}

@end


#pragma mark - class PJXAnimatedTabBarControllerDelegate

@implementation PJXAnimatedTabBarControllerDelegate

- (instancetype)initWithController:(PJXAnimatedTabBarController *)controller
{
    if (self = [super init])
        _controller = controller;
    return self;
}

#pragma mark - UITabBarControllerDelegate unused methods

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:didSelectViewController:)])
        [_oldDelegate tabBarController:tabBarController didSelectViewController:viewController];
}

- (void)tabBarController:(UITabBarController *)tabBarController willBeginCustomizingViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:willBeginCustomizingViewControllers:)])
        [_oldDelegate tabBarController:tabBarController willBeginCustomizingViewControllers:viewControllers];
#if !ANIMATED_TAB_BAR_SHOULD_RECREATE_ITEMS_ON_SELECT_MORE
    if (self.animated) {
        [_controller removeContainers];
        [_controller recreateItemsForCustomizing:YES];
    }
#endif
}

- (void)tabBarController:(UITabBarController *)tabBarController willEndCustomizingViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers changed:(BOOL)changed
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:willEndCustomizingViewControllers:changed:)])
        [_oldDelegate tabBarController:tabBarController willEndCustomizingViewControllers:viewControllers changed:changed];
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers changed:(BOOL)changed
{
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:didEndCustomizingViewControllers:changed:)])
        [_oldDelegate tabBarController:tabBarController didEndCustomizingViewControllers:viewControllers changed:changed];
#if !ANIMATED_TAB_BAR_SHOULD_RECREATE_ITEMS_ON_SELECT_MORE
    if (self.animated) {
        [_controller removeContainers];
        [_controller recreateItemsForCustomizing:NO];
        [_controller refresh];
    }
#endif
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

- (nullable id <UIViewControllerInteractiveTransitioning>)tabBarController:(UITabBarController *)tabBarController interactionControllerForAnimationController: (id <UIViewControllerAnimatedTransitioning>)animationController
{
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:interactionControllerForAnimationController:)])
        return [_oldDelegate tabBarController:tabBarController interactionControllerForAnimationController:animationController];
    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController animationControllerForTransitionFromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:animationControllerForTransitionFromViewController:toViewController:)])
        return [_oldDelegate tabBarController:tabBarController animationControllerForTransitionFromViewController:fromVC toViewController:toVC];
    return nil;
}

#pragma mark - UITabBarControllerDelegate used methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    BOOL should = YES;
    // Forward to old delegate.
    if ([_oldDelegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)])
        should = [_oldDelegate tabBarController:tabBarController shouldSelectViewController:viewController];
    if (should && _controller.animated) {
#if ANIMATED_TAB_BAR_SHOULD_RECREATE_ITEMS_ON_SELECT_MORE
        if (_controller.selectedViewController == _controller.moreNavigationController) {
            // Coming from more navigation controller.
            [_controller recreateItemsForCustomizing:NO];
            [_controller refresh];
        }
#endif
        
        // Animate switch.
        NSInteger index = [_controller.viewControllers indexOfObject:viewController];
        NSInteger max = _controller.tabBar.items.count - 1;
        if (index > max)
            index = max;
        [_controller animateTo:index doDelegate:NO]; // Avoid loop.
    }
    return should;
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim
{
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSLog(@"Finished More item animation: %@", flag ? @"yes" : @"no");
    
    // This method is called after animation to More view controller.
    // Recreate icons for More View Controller customizing.
    if (flag && (_controller.selectedViewController == _controller.moreNavigationController)) {
        [_controller removeContainers];
        [_controller recreateItemsForCustomizing:YES];
    }
}

@end
