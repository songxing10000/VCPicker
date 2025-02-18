//
//  VCPickerViewController.m
//  VCPicker
//
//  Created by beforeold on 16/3/24.
//

#import "VCPickerViewController.h"
#import <objc/runtime.h>

#pragma mark - FloatingView

#ifdef DEBUG

static const CGFloat kFloatingLength = 30.0;
static const CGFloat kScreenPadding = 0.5 * kFloatingLength;

typedef NS_ENUM(NSInteger, VCPickerShowType) {
    VCPickerShowTypePresentNavi, // 默认用一个导航控制器 present 出来
    VCPickerShowTypePresent, // 直接 present
    VCPickerShowTypePush, // 在当前业务页面向前 push
};


@interface VCPickerFloatingView : UIView <UIDynamicAnimatorDelegate>

@property (nonatomic, assign) CGPoint startPoint; //触摸起始点
@property (nonatomic, assign) CGPoint endPoint; //触摸结束点
@property (nonatomic, strong) UIView *backgroundViewForHightlight; //背景视图
@property (nonatomic, strong) UIDynamicAnimator *animator; //物理仿真动画

@property (nonatomic, copy) dispatch_block_t floatingBlock;

@end

@implementation VCPickerFloatingView
// 初始化
- (instancetype)initWithFrame:(CGRect)frame{
    frame.size.width = kFloatingLength;
    frame.size.height = kFloatingLength;
    if (self = [super initWithFrame:frame]) {
        //初始化背景视图
        _backgroundViewForHightlight = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundViewForHightlight.layer.cornerRadius = _backgroundViewForHightlight.frame.size.width / 2;
        _backgroundViewForHightlight.clipsToBounds = YES;
        _backgroundViewForHightlight.backgroundColor = [UIColor colorWithRed:35/255.0 green:167/255.0 blue:67/255.0 alpha:1];
        _backgroundViewForHightlight.userInteractionEnabled = NO;
        [self addSubview:_backgroundViewForHightlight];
        
        // 初始化背景视图
        CGFloat padding = 5;
        CGRect contentFrame = CGRectMake(padding, padding, CGRectGetWidth(self.frame) - 2 * padding, CGRectGetHeight(self.frame) - 2 * padding);
        UIView * contentView = [[UIView alloc] initWithFrame:contentFrame];
        contentView.layer.cornerRadius = contentView.frame.size.width / 2;
        contentView.clipsToBounds = YES;
        contentView.backgroundColor = [UIColor colorWithRed:35/255.0 green:167/255.0 blue:67/255.0 alpha:1];
        contentView.userInteractionEnabled = NO;
        contentView.alpha = 0.7;
        [self addSubview:contentView];
        
        // 将正方形的view变成圆形
        self.layer.cornerRadius = kFloatingLength / 2;
        self.alpha = 0.7;
        
        // 开启呼吸动画
        // [self highlightAnimation];
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //得到触摸点
    UITouch *startTouch = [touches anyObject];
    //返回触摸点坐标
    self.startPoint = [startTouch locationInView:self.superview];
    // 移除之前的所有行为
    [self.animator removeAllBehaviors];
}

// 触摸移动
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    //得到触摸点
    UITouch *startTouch = [touches anyObject];
    //将触摸点赋值给touchView的中心点 也就是根据触摸的位置实时修改view的位置
    self.center = [startTouch locationInView:self.superview];
}

// 结束触摸
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    //得到触摸结束点
    UITouch *endTouch = [touches anyObject];
    //返回触摸结束点
    self.endPoint = [endTouch locationInView:self.superview];
    //判断是否移动了视图 (误差范围5)
    CGFloat errorRange = 5;
    if (( self.endPoint.x - self.startPoint.x >= -errorRange &&
         self.endPoint.x - self.startPoint.x <= errorRange ) &&
        ( self.endPoint.y - self.startPoint.y >= -errorRange &&
         self.endPoint.y - self.startPoint.y <= errorRange ))
    {
        // 未移动，调用打开视图控制器方法
        !self.floatingBlock ?: self.floatingBlock();
        
    } else {
        // 移动
        self.center = self.endPoint;
        
        // 获取安全区域边界
        UIEdgeInsets safeAreaInsets = self.superview.safeAreaInsets;
        CGFloat superwidth = self.superview.bounds.size.width;
        CGFloat superheight = self.superview.bounds.size.height;
        CGFloat endX = self.endPoint.x;
        CGFloat endY = self.endPoint.y;
        
        // 计算边界
        CGFloat minX = safeAreaInsets.left;
        CGFloat maxX = superwidth - safeAreaInsets.right;
        CGFloat minY = safeAreaInsets.top;
        CGFloat maxY = superheight - safeAreaInsets.bottom;
        
        // 限制视图不能移动到超出安全区域边界的区域
        endX = MAX(minX, MIN(endX, maxX));
        endY = MAX(minY, MIN(endY, maxY));
        
        // 添加吸附物理行为
        UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self
                                                                             attachedToAnchor:CGPointMake(endX, endY)];
        [attachmentBehavior setLength:0];
        [attachmentBehavior setDamping:0.1];
        [attachmentBehavior setFrequency:5];
        [self.animator addBehavior:attachmentBehavior];
    }
}

// UIDynamicAnimatorDelegate
- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator{
    
}

// LazyLoading
- (UIDynamicAnimator *)animator {
    if (!_animator) {
        // 创建物理仿真器(ReferenceView : 仿真范围)
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.superview];
        _animator.delegate = self;
    }
    
    return _animator;
}

// BreathingAnimation 呼吸动画
- (void)highlightAnimation {
    [UIView animateWithDuration:1.5f
                     animations:^
     {
        self.backgroundViewForHightlight.backgroundColor = [self.backgroundViewForHightlight.backgroundColor colorWithAlphaComponent:0.1f];
    }
                     completion:^(BOOL finished)
     {
        [self highlightAnimation];
    }];
}

- (void)darkAnimation {
    [UIView animateWithDuration:1.5f
                     animations:^
     {
        self.backgroundViewForHightlight.backgroundColor = [self.backgroundViewForHightlight.backgroundColor colorWithAlphaComponent:0.6f];
    }
                     completion:^(BOOL finished)
     {
        [self highlightAnimation];
    }];
}

@end

#pragma mark - VCPickerCell
static NSString *const kNameKey = @"kNameKey";
static NSString *const kTitleKey = @"kTitleKey";
static NSString *const kErrorKey = @"kErrorKey";
@interface VCPickerCell : UITableViewCell

@property (nonatomic, copy) void(^presentClick)(void);
@property (nonatomic, copy) void(^presentNaviClick)(void);
@property (nonatomic, copy) void(^presentErrorClick)(NSString *title, NSString *msg);

- (void)updateUIWithModel:(NSDictionary *)model;

@end

@interface VCPickerCell()

@property (nonatomic, strong) UIButton *presentButton;
@property (nonatomic, strong) UIButton *presentNaviButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UILabel *errorLabel;

@property (nonatomic, strong) NSDictionary *model;

@end

@implementation VCPickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        [self.contentView addSubview:self.presentButton];
        [self.contentView addSubview:self.presentNaviButton];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.detailLabel];
        [self.contentView addSubview:self.errorLabel];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat buttonWidth = 45;
    CGFloat buttonPadding = 10;
    CGFloat horizontalMarigin = 15;
    CGFloat buttonVerticalMargin = 12;
    CGFloat presentNaviWidth = 0.01;
    CGFloat heightRatio = 0.75;
    CGFloat errorLabelWidth = 20;
    
    self.presentButton.frame = CGRectMake(horizontalMarigin,
                                          buttonVerticalMargin,
                                          buttonWidth,
                                          CGRectGetHeight(self.contentView.frame) - 2*buttonVerticalMargin);
    self.presentNaviButton.frame = CGRectMake(CGRectGetMaxX(self.presentButton.frame) + buttonPadding,
                                              buttonVerticalMargin,
                                              presentNaviWidth,
                                              CGRectGetHeight(self.contentView.frame) - 2*buttonVerticalMargin);
    
    self.errorLabel.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - horizontalMarigin - errorLabelWidth,
                                       (CGRectGetHeight(self.contentView.frame) - errorLabelWidth) *0.5,
                                       errorLabelWidth,
                                       errorLabelWidth);
    self.errorLabel.layer.cornerRadius = 0.5*errorLabelWidth;
    
    CGFloat titleX = CGRectGetMaxX(self.presentNaviButton.frame) + buttonPadding;
    CGFloat titleWidth = CGRectGetMinX(self.errorLabel.frame) - buttonPadding - titleX;
    self.titleLabel.frame = CGRectMake(titleX,
                                       0,
                                       titleWidth,
                                       self.contentView.frame.size.height*heightRatio);
    
    self.detailLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame),
                                        CGRectGetMaxY(self.titleLabel.frame),
                                        CGRectGetWidth(self.titleLabel.frame),
                                        (1-heightRatio)*self.contentView.frame.size.height);
}

- (void)updateUIWithModel:(NSDictionary *)classInfo {
    _model = classInfo;
    
    NSString *classTitle = classInfo[kTitleKey];
    NSString *className = classInfo[kNameKey];
    NSString *classError = classInfo[kErrorKey];
    
    self.titleLabel.text = classTitle;
    self.detailLabel.text = className;
    self.errorLabel.text = classError ? @"i" : @">";
    UIColor *errorColor = [UIColor colorWithRed:255/255.0 green:70/255.0 blue:1/255.0 alpha:1];
    self.errorLabel.layer.backgroundColor = classError ? errorColor.CGColor : [UIColor whiteColor].CGColor;
    self.errorLabel.textColor = classError ? [UIColor whiteColor] : [UIColor grayColor];
}

- (UIButton *)presentButton {
    if (!_presentButton) {
        _presentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _presentButton.titleLabel.font = [UIFont systemFontOfSize:11];
        _presentButton.backgroundColor = [UIColor colorWithRed:35/255.0 green:167/255.0 blue:67/255.0 alpha:1];
        _presentButton.layer.cornerRadius = 5.0;
        [_presentButton addTarget:self action:@selector(presentClick:) forControlEvents:UIControlEventTouchUpInside];
        [_presentButton setTitle:@"Pres" forState:UIControlStateNormal];
        [_presentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    return _presentButton;
}

- (UIButton *)presentNaviButton {
    if (!_presentNaviButton) {
        _presentNaviButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _presentNaviButton.backgroundColor = [UIColor colorWithRed:35/255.0 green:167/255.0 blue:67/255.0 alpha:1];
        _presentNaviButton.layer.cornerRadius = 5.0;
        _presentNaviButton.titleLabel.font = [UIFont systemFontOfSize:10];
        [_presentNaviButton addTarget:self action:@selector(presentNaviClick:) forControlEvents:UIControlEventTouchUpInside];
        [_presentNaviButton setTitle:@"PresNavi" forState:UIControlStateNormal];
        [_presentNaviButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    return _presentNaviButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.font = [UIFont systemFontOfSize:13];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.numberOfLines = 0;
        _detailLabel.font = [UIFont systemFontOfSize:11];
        _detailLabel.textColor = [UIColor lightGrayColor];
    }
    return _detailLabel;
}

- (UILabel *)errorLabel {
    if (!_errorLabel) {
        _errorLabel = [[UILabel alloc] init];
        _errorLabel.numberOfLines = 0;
        _errorLabel.font = [UIFont systemFontOfSize:15];
        _errorLabel.textAlignment = NSTextAlignmentCenter;
        _errorLabel.userInteractionEnabled = YES;
        [_errorLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(errorClick:)]];
    }
    return _errorLabel;
}

- (void)presentClick:(UIButton *)button {
    if (self.presentClick) {
        self.presentClick();
    }
}

- (void)presentNaviClick:(UIButton *)button {
    if (self.presentNaviClick) {
        self.presentNaviClick();
    }
}

- (void)errorClick:(UITapGestureRecognizer *)tap {
    if (self.model[kErrorKey]) {
        NSString *title = [NSString stringWithFormat:@"ErrorClass %@ - %@", self.model[kTitleKey], self.model[kNameKey]];
        if (self.presentErrorClick) {
            self.presentErrorClick(title, self.model[kErrorKey]);
        }
    }
}

@end


#pragma mark - VCPicker

/**
 *  floating view 悬浮球
 */
static VCPickerFloatingView *vcpicker_floatingView = nil;

/**
 *  class prefixes array 类名前缀
 */
static NSArray <NSString *> *vcpicker_prefixArray = nil;

static NSArray <NSString *> *vcpicker_exceptArray = nil;

/**
 *  is VCPicker activated   是否已经激活
 */
static BOOL vcpicker_isActivated = NO;

/**
 *  all possible viewcontroller class info 所有可能的ViewController类型
 */
static NSArray <NSDictionary *> *vcpicker_finalArray = nil;

static BOOL vcpicker_needTitle = YES;

static NSString *const vcpicker_searchHistoryKey = @"vcpicker.searchHistoryKey";

@interface VCPickerViewController () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>
{
    /**
     *  temp searched results 临时搜索到的数组
     */
    NSArray <NSDictionary *> *_tempArray;
    
    /**
     *  history searched classes 历史搜索使用的数组
     */
    NSMutableArray <NSDictionary *> *_historyArray;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation VCPickerViewController
#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.placeholder = NSLocalizedString(@"Search", nil);
    searchBar.delegate = self;
    // 设置占位符颜色
    if ([searchBar respondsToSelector:@selector(valueForKey:)]) {
        UITextField *textField = [searchBar valueForKey:@"searchField"];
        if (textField) {
            textField.attributedPlaceholder =
            [[NSAttributedString alloc] initWithString:@"请输入搜索内容" attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            textField.textColor = [UIColor blackColor]; // 设置输入文本的颜色
            
            // 修改左侧放大镜图标颜色
            UIImageView *leftIconView = (UIImageView *)textField.leftView;
            if (leftIconView) {
                // 获取放大镜图标的当前图像
                UIImage *originalImage = leftIconView.image;
                // 将放大镜图标渲染为新的颜色
                UIImage *coloredImage = [originalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                leftIconView.image = coloredImage;
                leftIconView.tintColor = [UIColor grayColor]; // 设置放大镜图标的颜色
            }
        }
    }
    self.navigationItem.titleView = searchBar;
    
    [self loadHistoryData];
    
    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.tableView];
}

// view appear to find all controllers
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self findAndShowControllers];
    [VCPickerViewController setCircleHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    UISearchBar *searchBar = (UISearchBar *)self.navigationItem.titleView;
    [searchBar resignFirstResponder];
    
    [[self class] setCircleHidden:NO];
}

//layout tableview
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat buttonHeight = 40;
    CGFloat padding = 10;
    
    self.cancelButton.frame = CGRectMake(padding,
                                         CGRectGetHeight(self.view.bounds) - padding - buttonHeight,
                                         CGRectGetWidth(self.view.bounds) - 2*padding,
                                         buttonHeight);
    
    self.tableView.frame = CGRectMake(0,
                                      0,
                                      CGRectGetWidth(self.view.bounds),
                                      CGRectGetMinY(self.cancelButton.frame) - padding);
}

/**
 *  load history data 加载历史数据
 */
- (void)loadHistoryData {
    _historyArray = [[NSUserDefaults standardUserDefaults] objectForKey:vcpicker_searchHistoryKey];
    if (_historyArray) {
        _historyArray = [_historyArray mutableCopy];
        
        NSMutableArray *replaceArray = [NSMutableArray array];
        NSMutableIndexSet *replaceSet = [NSMutableIndexSet indexSet];
        
        NSMutableArray *copyArray = [NSMutableArray array];
        NSMutableIndexSet *copySet = [NSMutableIndexSet indexSet];
        for (NSDictionary *dic in _historyArray) {
            NSInteger index = [_historyArray indexOfObject:dic];
            if ([dic isKindOfClass:[NSString class]]) {
                NSMutableDictionary *newDic = [NSMutableDictionary dictionary];
                newDic[kTitleKey] = dic;
                newDic[kNameKey] = dic;
                
                [replaceSet addIndex:index];
                [replaceArray addObject:newDic];
                
            }else {
                NSMutableDictionary *newDic = [dic mutableCopy];
                [copySet addIndex:index];
                [copyArray addObject:newDic];
            }
        }
        [_historyArray replaceObjectsAtIndexes:replaceSet withObjects:replaceArray];
        [_historyArray replaceObjectsAtIndexes:copySet withObjects:copyArray];
        
    } else {
        _historyArray = [NSMutableArray array];
    }
}

/**
 *  cancel pick 取消使用
 */
- (void)pickCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  lazy initializing tableview 懒加载
 */
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    
    return _tableView;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.backgroundColor = [UIColor colorWithRed:35/255.0 green:167/255.0 blue:67/255.0 alpha:1];
        _cancelButton.layer.cornerRadius = 7.0f;
        
        [_cancelButton addTarget:self action:@selector(pickCancel) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    return _cancelButton;
}

/**
 *  find and show all viewcontroller in this project
 *  \nNote: there are some UI classes can not be handled async
 *  \nNote: some special classes can't conform to NSObject protocol, so avoid them
 *  \nNote获取工程中所有的ViewController
 *  \nNote注意，这里还是不要用异步处理了，系统有少量UI类异步处理会报线程错误
 *  \nNote另外，部分特殊类不支持NSObject协议，需要手动剔除
 */
- (void)findAndShowControllers {
    if (!vcpicker_finalArray) {
        NSArray <NSString *> *classNameArray = [self findViewControllerClassNames];
        
        NSMutableArray <NSDictionary *> *array = [NSMutableArray array];
        for (NSString *className in classNameArray) {
            UIViewController *controller = nil;
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            
            NSString *title;
            if (controller.title) {
                title = controller.title;
            } else if (controller.navigationItem.title) {
                title = controller.navigationItem.title;
            } else if (controller.tabBarItem.title) {
                title = controller.tabBarItem.title;
            } else {
                title = className;
            }
            
            dic[kNameKey] = className;
            if(title.length > 0){
                dic[kTitleKey] = title;
            }
            [self refreshHistoryForControllerInfo:dic];
            [array addObject:dic];
            
        }
        
        vcpicker_finalArray = array;
    }
    
    _tempArray = vcpicker_finalArray;
    
    [self handleMissingHistory];
    [self.tableView reloadData];
}

- (UIViewController *)makeInstanceWithClass:(Class)clz {
    if ([(id)clz respondsToSelector:@selector(vcpicker_customViewController)]) {
        return [(id)clz vcpicker_customViewController];
    } else {
        return [[clz alloc] init];
    }
}

/**
 *  刷新历史数据信息
 *
 *  @param classInfo 传入的类信息
 */
- (void)refreshHistoryForControllerInfo:(NSDictionary *)classInfo {
    for (NSMutableDictionary *dic in _historyArray) {
        if ([dic[kNameKey] isEqualToString:classInfo[kNameKey]]) {
            dic[kTitleKey] = classInfo[kTitleKey];
            [self synchronizeHistory];
            break;
        }
    }
}

/**
 *  if some classes has gone remove it from history records
 *  如果有些类已经不存在，那么从历史记录中删除
 */
- (void)handleMissingHistory {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSDictionary *dic in _historyArray) {
        BOOL isExist = NO;
        for (NSDictionary *finalDic in vcpicker_finalArray) {
            if ([dic[kNameKey] isEqualToString:finalDic[kNameKey]]) {
                isExist = YES;
                break;
            }
        }
        if (!isExist) {
            [indexSet addIndex:[_historyArray indexOfObject:dic]];
        }
    }
    
    [_historyArray removeObjectsAtIndexes:indexSet];
}

#pragma mark - UITableViewDelegate && UITableViewDataSource
//history or search
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section ? _tempArray.count : _historyArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section ? @"搜索 ↓" : @"历史 ↓";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TestPickerCell";
    VCPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[VCPickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont systemFontOfSize:11];
    }
    
    NSArray *dataArray = indexPath.section ? _tempArray : _historyArray;
    NSDictionary *classInfo = dataArray[indexPath.row];
    [cell updateUIWithModel:classInfo];
    
    __weak typeof(self) weakSelf = self;
    cell.presentClick = ^{
        __strong typeof(self) self = weakSelf;
        [self saveAndShowController:classInfo showType:VCPickerShowTypePresent];
    };
    
    cell.presentNaviClick = ^{
        __strong typeof(self) self = weakSelf;
        [self saveAndShowController:classInfo showType:VCPickerShowTypePresentNavi];
    };
    
    cell.presentErrorClick = ^(NSString *title, NSString *msg) {
        __strong typeof(self) self = weakSelf;
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(self) self = weakSelf;
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:controller animated:YES completion:nil];
    };
    
    return cell;
}

//edit history
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [_historyArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
        [self synchronizeHistory];
    }
}

- (void)synchronizeHistory {
    [[NSUserDefaults standardUserDefaults] setObject:_historyArray forKey:vcpicker_searchHistoryKey];
}


//can only edit history
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !indexPath.section;
}

// did select one ViewController and show it
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *dataArray = indexPath.section ? _tempArray : _historyArray;
    NSDictionary *classInfo = dataArray[indexPath.row];
    
    [self saveAndShowController:classInfo showType:VCPickerShowTypePresentNavi];
}

- (void)saveAndShowController:(NSDictionary *)controllerInfo showType:(VCPickerShowType)showType {
    [self addHistoryRecord:controllerInfo];
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *controllerName = controllerInfo[kNameKey];
        [self showViewController:controllerName showType:showType];
    }];
}


// hide the keyboard while scrolling
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UISearchBar *searchBar = (UISearchBar *)self.navigationItem.titleView;
    [searchBar resignFirstResponder];
}

// add one history record, the same one will be avoied
- (void)addHistoryRecord:(NSDictionary *)dic {
    if (dic[kErrorKey]) {
        return;
    }
    
    NSInteger index = NSNotFound;
    for (NSMutableDictionary *history in _historyArray) {
        if ([dic[kNameKey] isEqualToString:history[kNameKey]]) {
            index = [_historyArray indexOfObject:history];
        }
    }
    
    if (index != NSNotFound) {
        [_historyArray removeObjectAtIndex:index];
    }
    
    [_historyArray insertObject:dic.mutableCopy atIndex:0];
    
    [self synchronizeHistory];
}

#pragma mark - UISearchBarDelegate
//find proper result while editing, ignore the upperCase of character
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSMutableArray *resultArray = [NSMutableArray array];
    for (NSDictionary *classInfo in vcpicker_finalArray) {
        NSString *className = classInfo[kNameKey];
        NSString *classTitle = classInfo[kTitleKey];
        
        NSString *upperClassName = [className uppercaseString];
        NSString *upperSearchText = [searchText uppercaseString];
        
        NSRange rangeName = [upperClassName rangeOfString:upperSearchText];
        NSRange rangeTitle = [classTitle rangeOfString:searchText];
        
        BOOL isNameCompare = rangeName.location != NSNotFound;
        BOOL isTitleCompare = rangeTitle.location != NSNotFound;
        
        if (isNameCompare || isTitleCompare) {
            [resultArray addObject:classInfo];
        }
    }
    
    _tempArray = searchText.length ? resultArray : vcpicker_finalArray;
    
    [self.tableView reloadData];
}

//click search just to hide the keyboard
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Picker

+ (void)activateWhenDebug {
    [self activateWhenDebugWithClassPrefixes:nil except:nil needTitle:YES];
}

+ (void)activateWhenDebugWithClassPrefixes:(NSArray <NSString *> *)prefixes {
    [self activateWhenDebugWithClassPrefixes:prefixes except:nil needTitle:YES];
}

+ (void)activateWhenDebugWithClassPrefixes:(NSArray *)prefixes except:(NSArray *)exceptArray {
    [self activateWhenDebugWithClassPrefixes:prefixes except:exceptArray needTitle:YES];
}

+ (void)activateWhenDebugWithClassPrefixes:(NSArray<NSString *> *)prefixes
                                    except:(NSArray *)exceptArray
                                 needTitle:(BOOL)needTitle
{
    vcpicker_isActivated = YES;
    vcpicker_needTitle = needTitle;
    
    [self showFinderWithClassPrefix:prefixes except:exceptArray];
}

/**
 *  获取当前工程内所有带有特定前缀prefix的控制器，在Release模式下该方法失效
 *
 *  @param prefixArray 前缀数组，比如 @[@"AB",@"ABC"]，可为nil
 */
+ (void)showFinderWithClassPrefix:(NSArray<NSString *> *)prefixArray except:(NSArray *)exceptArray {
    if (!vcpicker_isActivated) return;
    
    UIWindow *keyWindow = [self getMainWindow];
    if (!keyWindow) return;
    
    if (!vcpicker_floatingView) {
        vcpicker_prefixArray = prefixArray;
        vcpicker_exceptArray = exceptArray;
        
        CGRect frame = CGRectMake(CGRectGetWidth(keyWindow.frame) - kFloatingLength, 150, kFloatingLength, kFloatingLength);
        vcpicker_floatingView = [[VCPickerFloatingView alloc] initWithFrame:frame];
        vcpicker_floatingView.backgroundColor = [UIColor clearColor];
        vcpicker_floatingView.floatingBlock = ^{
            [VCPickerViewController setCircleHidden:YES];
            [VCPickerViewController show];
        };
    }
    
    [keyWindow addSubview:vcpicker_floatingView];
    // 添加观察者
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentedViewController:)
                                                 name:@"UIViewControllerPresentedViewController"
                                               object:nil];
}
+ (void)presentedViewController:(NSNotification *)notification {
    NSUInteger delaySecond = 1;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySecond * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getMainWindow];
        [keyWindow bringSubviewToFront:vcpicker_floatingView];
    });
    
}
/**
 *  show VC picker 显示选择器
 */
+ (void)show {
    UIViewController *rootVC = [self getMainWindow].rootViewController;
    UIViewController *selfVC = [self new];
    UINavigationController *naviedPickerVC = [[UINavigationController alloc] initWithRootViewController:selfVC];
    naviedPickerVC.navigationBar.backgroundColor = [UIColor whiteColor];
    naviedPickerVC.navigationBar.barStyle = UIBarStyleBlack;
    
    if (rootVC.presentedViewController) {
        [rootVC dismissViewControllerAnimated:YES completion:^{
            [rootVC presentViewController:naviedPickerVC animated:YES completion:nil];
        }];
    } else {
        [rootVC presentViewController:naviedPickerVC animated:YES completion:nil];
    }
}

- (void)dismissController {
    UIViewController *rootVC = [[self class] getMainWindow].rootViewController;
    [rootVC dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  hide floatingView or not 设置是否隐藏悬浮球
 */
+ (void)setCircleHidden:(BOOL)hidden {
    vcpicker_floatingView.hidden = hidden;
}

- (BOOL)willDealloc {
    return NO;
}

+ (UIWindow *)getMainWindow {
    return [UIApplication sharedApplication].delegate.window;
}

/**
 *  show some Controller 显示控制器页面
 *
 *  @param showType 显示类型
 */
- (void)showViewController:(NSString *)controllerName showType:(VCPickerShowType)showType
{
    Class clz = NSClassFromString(controllerName);
    if ([clz respondsToSelector:@selector(vcpicker_customShow)]) {
        [(id)clz vcpicker_customShow];
        return;
    }
    
    UIViewController *controller = [self makeInstanceWithClass:clz];
    
    switch (showType) {
        case VCPickerShowTypePush: {
            UIViewController *rootVC = [[self class] getMainWindow].rootViewController;
            
            if ([rootVC isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tabbarVC = (UITabBarController *)rootVC;
                UINavigationController *naviVC = tabbarVC.selectedViewController;
                if ([naviVC isKindOfClass:[UINavigationController class]]) {
                    [naviVC pushViewController:controller animated:YES];
                }else {
                    UINavigationController *aNaviVC = [[UINavigationController alloc] initWithRootViewController:controller];
                    [naviVC presentViewController:aNaviVC animated:YES completion:nil];
                }
                
            }else if ([rootVC isKindOfClass:[UINavigationController class]]) {
                [((UINavigationController *)rootVC) pushViewController:controller animated:YES];
                
            }else {
                UINavigationController *reulstNavi = [[UINavigationController alloc] initWithRootViewController:controller];
                [rootVC presentViewController:reulstNavi animated:YES completion:nil];
            }
            break;
        }
            
        case VCPickerShowTypePresent: {
            UIViewController *rootVC = [[self class] getMainWindow].rootViewController;
            [rootVC presentViewController:controller animated:YES completion:nil];
            break;
        }
            
        case VCPickerShowTypePresentNavi: {
            UIViewController *rootVC = [[self class] getMainWindow].rootViewController;
            UIViewController *tobePresent = nil;
            if ([controller isKindOfClass:UINavigationController.class]) {
                tobePresent = controller;
            } else {
                tobePresent = [[UINavigationController alloc] initWithRootViewController:controller];
            }
            [rootVC presentViewController:tobePresent animated:YES completion:^{
                // 查找title
                NSArray<UIView *> *subviews = controller.view.subviews;
                if(subviews.count >= 3) {
                    for (UIView *subview in subviews) {
                        if(subview.subviews.count >= 4){
                            
                            UIView *desView = subview.subviews[2];
                            if (![desView isKindOfClass:[UILabel class]]){
                                desView = subview.subviews[3];
                                
                            }
                            if ([desView isKindOfClass:[UILabel class]]){
                                UILabel *titleLab = (UILabel *)desView;
                                NSString *title = titleLab.text;
                                // 更新标题
                                NSString *vcName = [NSStringFromClass([controller class]) componentsSeparatedByString: @"."].lastObject;
                                NSInteger findIdx = -1;
                                NSMutableDictionary *findDict = nil;
                                for (int i = 0; i < self->_tempArray.count; ++i) {
                                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: self->_tempArray[i]];
                                    NSString *saveStr = [dict[kNameKey] componentsSeparatedByString: @"."].lastObject;
                                    if ([saveStr isEqualToString:vcName ]) {
                                        dict[kTitleKey] = title;
                                        findIdx = i;
                                        findDict = dict;
                                        break;
                                    }
                                }
                                if (findIdx != -1) {
                                    NSMutableArray *muArr = [NSMutableArray arrayWithArray:self->_tempArray];
                                    muArr[findIdx] = findDict;
                                    self->_tempArray = muArr;
                                    // 刷新hist
                                    NSInteger findIdx = -1;
                                    for (int i = 0; i < self->_historyArray.count; ++i) {
                                        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: self->_historyArray[i]];
                                        NSString *saveStr = [dict[kNameKey] componentsSeparatedByString: @"."].lastObject;
                                        if ([saveStr isEqualToString:vcName ]) {
                                            findIdx = i;
                                            break;
                                        }
                                    }
                                    if (findIdx != -1) {
                                        _historyArray[findIdx] = findDict;
                                        [self synchronizeHistory];
                                    }
                                    
                                    
                                    [self handleMissingHistory];
                                    [self.tableView reloadData];
                                    break;
                                }
                                
                            }
                            
                        }
                    }
                    
                    
                    
                }
                
                
                
                
            }];
            
            break;
        }
    }
}

/**
 *  查找工程内的所有相关ViewController，浙江
 *  find all viewcontrollers, this will block the main thread
 *
 *  @return 控制器名字数组
 */
- (NSArray <NSString *> *)findViewControllerClassNames {
    Class *classes = NULL;
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) return @[];
    
    NSMutableArray <NSString *> *unSortedArray = [NSMutableArray array];
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    for (int i = 0; i < numClasses; i++) {
        Class theClass = classes[i];
        if (theClass == self.class) continue;
        
        NSString *className = [NSString stringWithUTF8String:class_getName(theClass)];
        
        BOOL hasValidPrefix = false;
        if (vcpicker_prefixArray.count) {
            hasValidPrefix = [self judgeIsPreferredClass:className];
        } else {
            if ([className hasPrefix:@"UI"]) continue;
            if ([className hasPrefix:@"_UI"]) continue;
            if ([className hasPrefix:@"NS"]) continue;
            if ([className hasPrefix:@"_NS"]) continue;
            if ([className hasPrefix:@"__"]) continue;
//            if ([className hasPrefix:@"_"]) continue;
            if ([className hasPrefix:@"CMKApplication"]) continue;
            if ([className hasPrefix:@"CMKCamera"]) continue;
            if ([className hasPrefix:@"DeferredPU"]) continue;
            if ([className hasPrefix:@"AB"]) continue; // 通讯录
            if ([className hasPrefix:@"MK"]) continue; // 地图
            if ([className hasPrefix:@"MF"]) continue; // Messag
            if ([className hasPrefix:@"CN"]) continue; // Messag
            if ([className hasPrefix:@"SSDK"]) continue; // Messag
            if ([className hasPrefix:@"SSP"]) continue; //
            if ([className hasPrefix:@"QL"]) continue; // AIRPlay
            if ([className hasPrefix:@"GSAuto"]) continue; // GS AutoMap
            if ([self judgeIsSpecialClass:className]) continue;
            if ([self getRootClassOfClass:theClass] != NSObject.class) continue;
            
            hasValidPrefix = true;
        }
        
        if (!hasValidPrefix) continue;
        if ([self judgeIsExceptClass:className]) continue;
        if (![theClass isSubclassOfClass:[UIViewController class]]) continue;
        
        [unSortedArray addObject:className];
    }
    free(classes);
    
    NSArray <NSString *> *sortedArray = [unSortedArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSForcedOrderingSearch];
    }];
    
    return sortedArray;
}


/**
 *  判断是否为特殊的系统类
 *
 *  @param className 传入类名进行判断
 *
 *  @return YES为特殊类，NO不是
 */
- (BOOL)judgeIsSpecialClass:(NSString *)className {
    for (NSString *aClass in [self specialClassArray]) {
        if ([className isEqualToString:aClass]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)judgeIsPreferredClass:(NSString *)className {
    for (NSString *prefix in vcpicker_prefixArray) {
        if ([className hasPrefix:prefix]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)judgeIsExceptClass:(NSString *)className {
    for (NSString *except in vcpicker_exceptArray) {
        if ([className containsString:except]) {
            return YES;
        }
    }
    
    return NO;
}


/**
 *  一些特殊的系统类，不支持NSObject协议，需要手动剔除
 *
 */
- (NSArray <NSString *> *)specialClassArray {
    static NSArray <NSString *> *special;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        special = @[@"JSExport", @"__NSMessageBuilder", @"Object", @"__ARCLite__", @"__NSAtom",
                    @"__NSGenericDeallocHandler", @"_NSZombie_", @"CLTilesManagerClient",
                    @"FigIrisAutoTrimmerMotionSampleExport", @"CNZombie", @"_CNZombie_",
                    @"ABContactViewController", @"ABLabelPickerViewController",
                    @"ABStarkContactViewController", @"CNContactContentViewController",
                    @"CNContactViewServiceViewController", @"CNStarkContactViewController",
                    @"MKActivityViewController", @"MKPlaceInfoViewController",
                    @"CNUI", @"UISearchController", @"WKObject"]; // UI的类在子线程访问有问题
    });
    
    return special;
}
BOOL classImplementsMethod(Class cls, SEL selector) {
    Method method = class_getInstanceMethod(cls, selector);
    return method != NULL;
}
/**
 *  获取类的根类
 *
 *  @param aClass 传入一个类
 *
 *  @return 获取根类
 */
- (Class)getRootClassOfClass:(Class)aClass {
    if (!aClass){
        return nil;
    }
    BOOL hasMethodSignatureForSelector = classImplementsMethod(aClass, @selector(methodSignatureForSelector:));
    BOOL hasDoesNotRecognizeSelector = classImplementsMethod(aClass, @selector(doesNotRecognizeSelector:));
    if (!hasMethodSignatureForSelector && !hasDoesNotRecognizeSelector) {
        return nil;
    }
    Class superClass = nil;
    if ([aClass respondsToSelector:@selector(superclass)]) {
        superClass = aClass.superclass;
    }
    
    if (!superClass)
        return aClass;
    
    return [self getRootClassOfClass:superClass];
}

@end

#pragma mark - swizzle

@interface UIWindow (swizzle)
@end
@implementation UIWindow (swizzle)

+ (void)load {
    [self swizzleSel:@selector(makeKeyAndVisible) withSel:@selector(swizzle_makeKeyAndVisiable)];
    [self swizzleSel:@selector(setRootViewController:) withSel:@selector(swizzle_setRootViewController:)];
}

+ (void)swizzleSel:(SEL)sel withSel:(SEL)swizzleSel {
    Method fromMethod = class_getInstanceMethod(self, sel);
    Method toMethod = class_getInstanceMethod(self, swizzleSel);
    method_exchangeImplementations(fromMethod, toMethod);
}

- (void)swizzle_makeKeyAndVisiable {
    [self swizzle_makeKeyAndVisiable];
    
    if (self == [VCPickerViewController getMainWindow]) {
        [VCPickerViewController showFinderWithClassPrefix:vcpicker_exceptArray except:vcpicker_exceptArray];
    }
}

- (void)swizzle_setRootViewController:(UIViewController *)rootViewController {
    [self swizzle_setRootViewController:rootViewController];
    
    if (self == [VCPickerViewController getMainWindow]) {
        [VCPickerViewController showFinderWithClassPrefix:vcpicker_exceptArray except:vcpicker_exceptArray];
    }
}

@end
@implementation UIViewController (PresentTracking)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(presentViewController:animated:completion:);
        SEL swizzledSelector = @selector(track_presentViewController:animated:completion:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)track_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    // 在此处执行你想要的操作，例如记录日志或者发送通知等
    NSLog(@"presentViewController 方法被调用");

    // 调用原始的实现
    [self track_presentViewController:viewControllerToPresent animated:flag completion:completion];
    
    if ([viewControllerToPresent isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *nav = (UINavigationController *)viewControllerToPresent;
        
        if (![[nav topViewController] isKindOfClass:[VCPickerViewController class]]) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewControllerPresentedViewController" object:self];
        }
    }
    
    
    
}

@end
#endif


