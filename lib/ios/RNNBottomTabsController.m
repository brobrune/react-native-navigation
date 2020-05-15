#import "RNNBottomTabsController.h"
#import "UITabBarController+RNNUtils.h"

@interface RNNBottomTabsController ()
@property (nonatomic, strong) BottomTabPresenter* bottomTabPresenter;
@property (nonatomic, strong) RNNDotIndicatorPresenter* dotIndicatorPresenter;
@end

@implementation RNNBottomTabsController {
  NSUInteger _currentTabIndex;
    BottomTabsBaseAttacher* _bottomTabsAttacher;
    
}

- (instancetype)initWithLayoutInfo:(RNNLayoutInfo *)layoutInfo
                           creator:(id<RNNComponentViewCreator>)creator
                           options:(RNNNavigationOptions *)options
                    defaultOptions:(RNNNavigationOptions *)defaultOptions
                         presenter:(RNNBasePresenter *)presenter
                bottomTabPresenter:(BottomTabPresenter *)bottomTabPresenter
             dotIndicatorPresenter:(RNNDotIndicatorPresenter *)dotIndicatorPresenter
                      eventEmitter:(RNNEventEmitter *)eventEmitter
              childViewControllers:(NSArray *)childViewControllers
                bottomTabsAttacher:(BottomTabsBaseAttacher *)bottomTabsAttacher {
    _bottomTabsAttacher = bottomTabsAttacher;
    _bottomTabPresenter = bottomTabPresenter;
    _dotIndicatorPresenter = dotIndicatorPresenter;
    self = [super initWithLayoutInfo:layoutInfo creator:creator options:options defaultOptions:defaultOptions presenter:presenter eventEmitter:eventEmitter childViewControllers:childViewControllers];
    if (@available(iOS 13.0, *)) {
        self.tabBar.standardAppearance = [UITabBarAppearance new];
    }
    return self;
}

- (void)onChildAddToParent:(UIViewController *)child options:(RNNNavigationOptions *)options {
    [_bottomTabPresenter applyOptionsOnWillMoveToParentViewController:options child:child];
}

- (void)mergeChildOptions:(RNNNavigationOptions *)options child:(UIViewController *)child {
    [super mergeChildOptions:options child:child];
    UIViewController* childViewController = [self findViewController:child];
    [_bottomTabPresenter mergeOptions:options resolvedOptions:childViewController.resolveOptions child:childViewController];
    [_dotIndicatorPresenter mergeOptions:options resolvedOptions:childViewController.resolveOptions child:childViewController];
}

- (id<UITabBarControllerDelegate>)delegate {
  return self;
}

- (void)render {
    [_bottomTabsAttacher attach:self];
}

- (void)viewDidLayoutSubviews {
    [self.presenter viewDidLayoutSubviews];
    // NSUInteger index = 0;
    // for (UIView *view in [[self tabBar] subviews]) {
    //      UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(handleLongPress:)];
    //       if ([NSStringFromClass([view class]) isEqualToString:@"UITabBarButton"]) {
    //           [view addGestureRecognizer: longPressGesture];
    //       }
    //     if (0 == index - 1) {
    //         for (UIView *subview in view.subviews) {
    //             if ([NSStringFromClass([subview class]) isEqualToString:@"UITabBarButtonLabel"]) {
    //                 [self setSelectionIndicatorImage:subview];
    //             }
    //         }
    //     }
    //     index++;
    // }
    
    // for (UIView *view in [[self tabBar] subviews]) {
    //      UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(handleLongPress:)];
    //       if ([NSStringFromClass([view class]) isEqualToString:@"UITabBarButton"]) {
    //           [view addGestureRecognizer: longPressGesture];
    //       }
    // }
    
    [_dotIndicatorPresenter bottomTabsDidLayoutSubviews:self];
}

- (UIViewController *)getCurrentChild {
  return self.selectedViewController;
}

- (CGFloat)getBottomTabsHeight {
    return self.tabBar.frame.size.height;
}

- (void)setSelectedIndexByComponentID:(NSString *)componentID {
  for (id child in self.childViewControllers) {
    UIViewController<RNNLayoutProtocol>* vc = child;

    if ([vc conformsToProtocol:@protocol(RNNLayoutProtocol)] && [vc.layoutInfo.componentId isEqualToString:componentID]) {
      [self setSelectedIndex:[self.childViewControllers indexOfObject:child]];
    }
  }
}

- (void)setSelectionIndicatorImage:(UIView *)item {
    CGFloat height = self.tabBar.frame.size.height;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat bottomPadding = window.safeAreaInsets.bottom;
        if (bottomPadding > 0) {
            height -= bottomPadding + 5;
        }
    }
    
    CGSize size = CGSizeMake(item.frame.size.width, height);
    UIColor * color = [UIColor colorWithRed:0/255.0f green:199.0f/255.0f blue:80.0f/255.0f alpha:1.0f];
    CGFloat lineWidth = 3.0;
    UIGraphicsBeginImageContextWithOptions(size, false, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, size.height - lineWidth, size.width, lineWidth));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.tabBar.selectionIndicatorImage = img;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
  _currentTabIndex = selectedIndex;
  [super setSelectedIndex:selectedIndex];
}

#pragma mark UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
  [self.eventEmitter sendBottomTabSelected:@(tabBarController.selectedIndex) unselected:@(_currentTabIndex)];
  _currentTabIndex = tabBarController.selectedIndex;
    // NSUInteger index = 0;
    // for (UIView *view in [[self tabBar] subviews]) {
    //     if (_currentTabIndex == index - 1) {
    //         for (UIView *subview in view.subviews) {
    //             if ([NSStringFromClass([subview class]) isEqualToString:@"UITabBarButtonLabel"]) {
    //                 [self setSelectionIndicatorImage:subview];
    //             }
    //         }
    //     }
    //     index++;
    // }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *) recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSUInteger _index = [self.tabBar.subviews indexOfObject:(UIView *)recognizer.view];
        [self.eventEmitter sendBottomTabLongPressed:@(_index)];
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSUInteger _index = [tabBarController.viewControllers indexOfObject:viewController];
    [self.eventEmitter sendBottomTabPressed:@(_index)];
    
    if([[viewController resolveOptions].bottomTab.selectTabOnPress getWithDefaultValue:YES]){
        return YES;
    }

    return NO;
}

# pragma mark - UIViewController overrides

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [self.presenter willMoveToParentViewController:parent];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.presenter getStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden {
    return [self.presenter getStatusBarVisibility];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.presenter getOrientation];
}

- (BOOL)hidesBottomBarWhenPushed {
    return [self.presenter hidesBottomBarWhenPushed];
}


@end
