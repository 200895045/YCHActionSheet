//
//  YCHActionSheet.m
//  YCHActionSheetExamples
//
//  Created by Yaman JAIOUCH on 23/04/2014.
//  Copyright (c) 2014 Yaman JAIOUCH. All rights reserved.
//

#import "YCHActionSheet.h"

/**
 * YCHButton class
 */

@interface YCHButton : UIButton

@property (assign, nonatomic) NSUInteger sectionIndex;
@property (assign, nonatomic) NSUInteger buttonIndex;

@end

@implementation YCHButton
@end

/**
 * YCHLabel class
 */

@interface YCHLabel : UILabel
@end

@implementation YCHLabel

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextStrokePath(context);
}

@end

/**
 * YCHActionSheet implementation
 */

@interface YCHActionSheet ()
{
    NSMutableArray *_mutableSections;
}

@property (strong, nonatomic, readwrite) UIButton *cancelButton;
@property (strong, nonatomic) UIView *backgroundLayerView;

@end

@implementation YCHActionSheet

- (instancetype)initWithSections:(NSArray *)sections cancelButtonTitle:(NSString *)cancelButtonTitle delegate:(id)delegate
{
    if (self = [super init])
    {
        _mutableSections = [sections mutableCopy];
        _cancelButtonTitle = cancelButtonTitle;
        _delegate = delegate;
        
        [self setupCancelButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [self setupUI];
}

- (NSArray *)sections
{
    return [_mutableSections copy];
}

- (void)setSections:(NSArray *)sections
{
    _mutableSections = [sections mutableCopy];
}

- (NSInteger)addSection:(YCHActionSheetSection *)section
{
    [_mutableSections addObject:section];
    return _mutableSections.count-1;
}

- (YCHActionSheetSection *)sectionAtIndex:(NSInteger)index
{
    return _mutableSections[index];
}

- (void)showFromView:(UIView *)view
{
    CGFloat startY = view.frame.origin.y + view.frame.size.height;
    CGFloat height = [self calculateFrameHeight];
#warning FIX THIS SHIT
    self.frame = CGRectMake(view.frame.size.width/2 - 150, startY, 300, height);
    
    [view addSubview:self];
    
#warning REFRACTOR THIS
    self.backgroundLayerView = [[UIView alloc] initWithFrame:view.bounds];
    self.backgroundLayerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundLayerView.backgroundColor = [UIColor blackColor];
    self.backgroundLayerView.opaque = YES;
    self.backgroundLayerView.alpha = 0;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundLayerWasTouched:)];
    [self.backgroundLayerView addGestureRecognizer:tap];
    
    [view insertSubview:self.backgroundLayerView belowSubview:self];
    
    
    [UIView animateWithDuration:0.5 animations:^{
        self.frame = CGRectOffset(self.frame, 0, - self.frame.size.height);
        
#warning VARIABLE HERE
        self.backgroundLayerView.alpha = 0.6;
    }];
}

#warning PUT STATIC SIZE + HANDLE ROTATION
- (void)setupUI
{
    CGFloat offsetY = 0;
    
    for (int i = 0; i < self.sections.count; i++)
    {
        YCHActionSheetSection *section = self.sections[i];
        
        // 1°) display title
        UILabel *titleLabel = section.titleLabel;
        if (titleLabel)
        {
            titleLabel.frame = CGRectMake(0, offsetY, 300, 44);
            [self addSubview:titleLabel];
            offsetY += 44;
        }
        
        // 2°) display buttons
        NSArray *buttons = section.buttons;
        for (int j = 0; j < buttons.count; j++)
        {
            YCHButton *button = buttons[j];
            
            button.frame = CGRectMake(0, offsetY, 300, 44);
            button.sectionIndex = i;
            button.buttonIndex = j;
#warning DUNNO IF ITS A GOOD PLACE FOR THIS I.E WHAT HAPPEND WHEN layoutSubviews GET CALLED MULTIPLE TIMES (orientation, etc)
            [button addTarget:self action:@selector(buttonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            offsetY += 44;
        }
        
        offsetY += 10;
    }
    
    // 3°) display cancel
    if (self.cancelButton)
    {
        self.cancelButton.frame = CGRectMake(0, offsetY, 300, 44);
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];
        offsetY += 44;
    }
}

- (void)buttonWasTouched:(id)sender
{
    YCHButton *button = (YCHButton *)sender;
    if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:sectionIndex:)])
    {
        [self.delegate actionSheet:self clickedButtonAtIndex:button.buttonIndex sectionIndex:button.sectionIndex];
    }
}

- (void)cancelButtonWasTouched:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(actionSheetDidCancel:)])
    {
        [self.delegate actionSheetDidCancel:self];
    }
    
    [self dismiss];
}

- (void)backgroundLayerWasTouched:(UIGestureRecognizer *)gesture
{
#warning SHOULD CALL didCancel DELEGATE ? OR SIMPLY WILL/DID DISMISS ?
    
    [self dismiss];
}

- (void)dismiss
{
    [UIView animateWithDuration:0.5 animations:^{
        self.frame = CGRectOffset(self.frame, 0, self.frame.size.height);
        self.backgroundLayerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.backgroundLayerView removeFromSuperview];
        [self removeFromSuperview];
    }];
}

- (void)setupCancelButton
{
    if (!self.cancelButtonTitle)
        return;
    
#warning REFRACTOR THESE LINES
    UIImage *bgNormal = [[UIImage imageNamed:@"bg_50"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    UIImage *bgSelected = [[UIImage imageNamed:@"bg_50_selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    
    NSString *cancelTitle = self.cancelButtonTitle ?: @"Cancel";
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:cancelTitle
                                                                     attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:21.0]}];
    [self.cancelButton setAttributedTitle:attributed forState:UIControlStateNormal];
    [self.cancelButton setBackgroundImage:bgNormal forState:UIControlStateNormal];
    [self.cancelButton setBackgroundImage:bgSelected forState:UIControlStateSelected];
}

#warning REMOVE ALL HARD CODED NUMBER
- (CGFloat)calculateFrameHeight
{
    CGFloat height = 0;
    for (YCHActionSheetSection *section in _mutableSections)
    {
        if (section.title)
            height += 44;
        
        height += (section.buttons.count * 44);
        
        // this is for separation
        height += 10;
    }
    
    // this is for cancel button
    height += 44;
    
    // this is for letting some space
    height += 10;
    
    return height;
}

@end

/**
 * YCHActionSheetSection implementation
 */

@interface YCHActionSheetSection ()
{
    NSMutableArray *_mutableButtonTitles;
    NSMutableArray *_mutableButtons;
}

@property (strong, nonatomic, readwrite) YCHLabel *titleLabel;

@end

@implementation YCHActionSheetSection

- (instancetype)initWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    if (self = [super init])
    {
        _title = title;
        
        _mutableButtonTitles = [NSMutableArray array];
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *arg = otherButtonTitles; arg != nil; arg = va_arg(args, NSString *))
        {
            [_mutableButtonTitles addObject:arg];
        }
        va_end(args);
        
        [self setupTitleLabel];
        [self setupButtons];
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    [self setupTitleLabel];
}

- (NSArray *)buttonTitles
{
    return [_mutableButtonTitles copy];
}

- (void)setButtonTitles:(NSArray *)buttonTitles
{
    _mutableButtonTitles = [buttonTitles mutableCopy];
    [self setupButtons];
}

- (NSArray *)buttons
{
    return [_mutableButtons copy];
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    [_mutableButtonTitles addObject:title];
    return _mutableButtonTitles.count-1;
}

- (NSString *)buttonAtIndex:(NSInteger)index
{
    return _mutableButtonTitles[index];
}

- (void)setupTitleLabel
{
    if (!self.title)
        return;
    
    self.titleLabel = [[YCHLabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:13.0];
    self.titleLabel.text = self.title;
    self.titleLabel.textColor = [UIColor grayColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
#warning BETTER WAY ?
    self.titleLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_50"]];
}

- (void)setupButtons
{
#warning REFRACTOR THIS 2 LINES
    UIImage *bgNormal = [[UIImage imageNamed:@"bg_50"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    UIImage *bgSelected = [[UIImage imageNamed:@"bg_50_selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    UIImage *bgNormalLine = [[UIImage imageNamed:@"bg_50_l"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    UIImage *bgSelectedLine = [[UIImage imageNamed:@"bg_50_selected_l"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    
    _mutableButtons = [NSMutableArray array];
    for (NSString *buttonTitle in _mutableButtonTitles)
    {
#warning REFRACTOR BUTTON FACTORY
        YCHButton *button = [YCHButton buttonWithType:UIButtonTypeSystem];
        NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:buttonTitle
                                                                         attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:21.0]}];
        [button setAttributedTitle:attributed forState:UIControlStateNormal];
        
        if (buttonTitle == _mutableButtonTitles.lastObject)
        {
            [button setBackgroundImage:bgNormal forState:UIControlStateNormal];
            [button setBackgroundImage:bgSelected forState:UIControlStateSelected];
        }
        else
        {
            [button setBackgroundImage:bgNormalLine forState:UIControlStateNormal];
            [button setBackgroundImage:bgSelectedLine forState:UIControlStateSelected];
        }

        [_mutableButtons addObject:button];
    }
}

@end

