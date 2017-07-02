//
//  XRCarouselView.m
//
//  Created by 肖睿 on 16/3/17.
//  Copyright © 2016年 肖睿. All rights reserved.
//

#import "XRCarouselView.h"
#import <ImageIO/ImageIO.h>

#define DEFAULTTIME 5
#define HORMARGIN 10
#define VERMARGIN 5
#define DES_LABEL_H 20
@interface XRCarouselView()<UIScrollViewDelegate>
//轮播的图片数组
@property (nonatomic, strong) NSMutableArray *images;
//图片描述控件，默认在底部
@property (nonatomic, strong) UILabel *describeLabel;
//滚动视图
@property (nonatomic, strong) UIScrollView *scrollView;
//分页控件
@property (nonatomic, strong) UIPageControl *pageControl;
//当前显示的imageView
@property (nonatomic, strong) UIImageView *currImageView;
//滚动显示的imageView
@property (nonatomic, strong) UIImageView *otherImageView;
//当前显示图片的索引
@property (nonatomic, assign) NSInteger currIndex;
//将要显示图片的索引
@property (nonatomic, assign) NSInteger nextIndex;
//pageControl图片大小
@property (nonatomic, assign) CGSize pageImageSize;
//定时器
@property (nonatomic, strong) NSTimer *timer;
//任务队列
@property (nonatomic, strong) NSOperationQueue *queue;
@end

static NSString *cache;


@implementation XRCarouselView
#pragma mark- 初始化方法
//创建用来缓存图片的文件夹
+ (void)initialize {
    cache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"XRCarousel"];
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:&isDir];
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark 代码创建
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initSubView];
    }
    return self;
}

#pragma mark nib创建
- (void)awakeFromNib {
    [super awakeFromNib];
    [self initSubView];
}

#pragma mark 初始化控件
- (void)initSubView {
    [self addSubview:self.scrollView];
    [self addSubview:self.describeLabel];
    [self addSubview:self.pageControl];
}

#pragma mark- frame相关
- (CGFloat)height {
    return self.scrollView.frame.size.height;
}

- (CGFloat)width {
    return self.scrollView.frame.size.width;
}

#pragma mark- 懒加载
- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.scrollsToTop = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        //添加手势监听图片的点击
        [_scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageClick)]];
        _currImageView = [[UIImageView alloc] init];
        _currImageView.clipsToBounds = YES;
        [_scrollView addSubview:_currImageView];
        _otherImageView = [[UIImageView alloc] init];
        _otherImageView.clipsToBounds = YES;
        [_scrollView addSubview:_otherImageView];
    }
    return _scrollView;
}

- (UILabel *)describeLabel {
    if (!_describeLabel) {
        _describeLabel = [[UILabel alloc] init];
        _describeLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _describeLabel.textColor = [UIColor whiteColor];
        _describeLabel.textAlignment = NSTextAlignmentCenter;
        _describeLabel.font = [UIFont systemFontOfSize:13];
        _describeLabel.hidden = YES;
    }
    return _describeLabel;
}


- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.userInteractionEnabled = NO;
    }
    return _pageControl;
}


#pragma mark- --------设置相关方法--------
#pragma mark 设置图片的内容模式
- (void)setContentMode:(UIViewContentMode)contentMode {
    _currImageView.contentMode = contentMode;
    _otherImageView.contentMode = contentMode;
}

#pragma mark 设置图片数组
- (void)setImageArray:(NSArray *)imageArray{
    
    if (!imageArray.count) return;
    
    _imageArray = imageArray;
    _images = [NSMutableArray array];
    
    for (int i = 0; i < imageArray.count; i++) {
        if ([imageArray[i] isKindOfClass:[UIImage class]]) {
            [_images addObject:imageArray[i]];
        } else if ([imageArray[i] isKindOfClass:[NSString class]]){
            //如果是网络图片，则先添加占位图片，下载完成后替换
            if (_placeholderImage) [_images addObject:_placeholderImage];
            else [_images addObject:[UIImage imageNamed:@"XRPlaceholder"]];
        }
    }
    
    //防止在滚动过程中重新给imageArray赋值时报错
    if (_currIndex >= _images.count) _currIndex = _images.count - 1;
    self.currImageView.image = _images[_currIndex];
    self.describeLabel.text = _describeArray[_currIndex];
    self.pageControl.numberOfPages = _images.count;
    [self layoutSubviews];
}


#pragma mark 设置描述数组
- (void)setDescribeArray:(NSArray *)describeArray{
    _describeArray = describeArray;
    if (!describeArray.count) {
        _describeArray = nil;
        self.describeLabel.hidden = YES;
    } else {
        //如果描述的个数与图片个数不一致，则补空字符串
        if (describeArray.count < _images.count) {
            NSMutableArray *describes = [NSMutableArray arrayWithArray:describeArray];
            for (NSInteger i = describeArray.count; i < _images.count; i++) {
                [describes addObject:@""];
            }
            _describeArray = describes;
        }
        self.describeLabel.hidden = NO;
        _describeLabel.text = _describeArray[_currIndex];
    }
    //重新计算pageControl的位置
    self.pagePosition = self.pagePosition;
}

#pragma mark 设置scrollView的contentSize
- (void)setScrollViewContentSize {
    if (_images.count > 1) {
        self.scrollView.contentSize = CGSizeMake(self.width * 5, 0);
        self.scrollView.contentOffset = CGPointMake(self.width * 2, 0);
        self.currImageView.frame = CGRectMake(self.width * 2, 0, self.width, self.height);
    } else {
        //只要一张图片时，scrollview不可滚动，且关闭定时器
        self.scrollView.contentSize = CGSizeZero;
        self.scrollView.contentOffset = CGPointZero;
        self.currImageView.frame = CGRectMake(0, 0, self.width, self.height);
    }
}

#pragma mark 设置图片描述控件
- (void)setDescribeTextColor:(UIColor *)color font:(UIFont *)font bgColor:(UIColor *)bgColor {
    if (color) self.describeLabel.textColor = color;
    if (font) self.describeLabel.font = font;
    if (bgColor) self.describeLabel.backgroundColor = bgColor;
}


#pragma mark 设置pageControl的指示器图片
- (void)setPageImage:(UIImage *)image andCurrentPageImage:(UIImage *)currentImage {
    if (!image || !currentImage) return;
    self.pageImageSize = image.size;
    [self.pageControl setValue:currentImage forKey:@"_currentPageImage"];
    [self.pageControl setValue:image forKey:@"_pageImage"];
}

#pragma mark 设置pageControl的指示器颜色
- (void)setPageColor:(UIColor *)color andCurrentPageColor:(UIColor *)currentColor {
    _pageControl.pageIndicatorTintColor = color;
    _pageControl.currentPageIndicatorTintColor = currentColor;
}

#pragma mark 设置pageControl的位置
- (void)setPagePosition:(PageControlPosition)pagePosition {
    _pagePosition = pagePosition;
    _pageControl.hidden = (_pagePosition == PositionHide) || (_imageArray.count == 1);
    if (_pageControl.hidden) return;
    
    CGSize size;
    if (!_pageImageSize.width) {//没有设置图片，系统原有样式
        size = [_pageControl sizeForNumberOfPages:_pageControl.numberOfPages];
        size.height = 8;
    } else {//设置图片了
        size = CGSizeMake(_pageImageSize.width * (_pageControl.numberOfPages * 2 - 1), _pageImageSize.height);
    }
    _pageControl.frame = CGRectMake(0, 0, size.width, size.height);
    
    CGFloat centerY = self.height - size.height * 0.5 - VERMARGIN - (_describeLabel.hidden?0: DES_LABEL_H);
    CGFloat pointY = self.height - size.height - VERMARGIN - (_describeLabel.hidden?0: DES_LABEL_H);
    
    if (_pagePosition == PositionDefault || _pagePosition == PositionBottomCenter)
        _pageControl.center = CGPointMake(self.width * 0.5, centerY);
    else if (_pagePosition == PositionTopCenter)
        _pageControl.center = CGPointMake(self.width * 0.5, size.height * 0.5 + VERMARGIN);
    else if (_pagePosition == PositionBottomLeft)
        _pageControl.frame = CGRectMake(HORMARGIN, pointY, size.width, size.height);
    else
        _pageControl.frame = CGRectMake(self.width - HORMARGIN - size.width, pointY, size.width, size.height);
}


#pragma mark- -----------其它-----------
#pragma mark 布局子控件
- (void)layoutSubviews {
    [super layoutSubviews];
    //有导航控制器时，会默认在scrollview上方添加64的内边距，这里强制设置为0
    _scrollView.contentInset = UIEdgeInsetsZero;
    
    _scrollView.frame = self.bounds;
    _describeLabel.frame = CGRectMake(0, self.height - DES_LABEL_H, self.width, DES_LABEL_H);
    //重新计算pageControl的位置
    self.pagePosition = self.pagePosition;
    [self setScrollViewContentSize];
}


#pragma mark 图片点击事件
- (void)imageClick {
    if (self.imageClickBlock) {
        self.imageClickBlock(self.currIndex);
    } else if ([_delegate respondsToSelector:@selector(carouselView:clickImageAtIndex:)]){
        [_delegate carouselView:self clickImageAtIndex:self.currIndex];
    }
}

#pragma mark 下载图片，如果是gif则计算动画时长
UIImage *getImageWithData(NSData *data) {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(imageSource);
    if (count <= 1) { //非gif
        CFRelease(imageSource);
        return [[UIImage alloc] initWithData:data];
    } else { //gif图片
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
            if (!image) continue;
            duration += durationWithSourceAtIndex(imageSource, i);
            [images addObject:[UIImage imageWithCGImage:image]];
            CGImageRelease(image);
        }
        if (!duration) duration = 0.1 * count;
        CFRelease(imageSource);
        return [UIImage animatedImageWithImages:images duration:duration];
    }
}


#pragma mark 获取每一帧图片的时长
float durationWithSourceAtIndex(CGImageSourceRef source, NSUInteger index) {
    float duration = 0.1f;
    CFDictionaryRef propertiesRef = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *properties = (__bridge NSDictionary *)propertiesRef;
    NSDictionary *gifProperties = properties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTime) duration = delayTime.floatValue;
    else {
        delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime) duration = delayTime.floatValue;
    }
    CFRelease(propertiesRef);
    return duration;
}

#pragma mark 当图片滚动过半时就修改当前页码
- (void)changeCurrentPageWithOffset:(CGFloat)offsetX {
    if (offsetX < self.width * 1.5) {
        NSInteger index = self.currIndex - 1;
        if (index < 0) index = self.images.count - 1;
        _pageControl.currentPage = index;
    } else if (offsetX > self.width * 2.5){
        _pageControl.currentPage = (self.currIndex + 1) % self.images.count;
    } else {
        _pageControl.currentPage = self.currIndex;
    }
}

#pragma mark- --------UIScrollViewDelegate--------
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (CGSizeEqualToSize(CGSizeZero, scrollView.contentSize)) return;
    CGFloat offsetX = scrollView.contentOffset.x;
    //滚动过程中改变pageControl的当前页码
    [self changeCurrentPageWithOffset:offsetX];
    //向右滚动
    if (offsetX < self.width * 2) {
        self.otherImageView.frame = CGRectMake(self.width, 0, self.width, self.height);
        
        self.nextIndex = self.currIndex - 1;
        if (self.nextIndex < 0) self.nextIndex = _images.count - 1;
        self.otherImageView.image = self.images[self.nextIndex];
        if (offsetX <= self.width) [self changeToNext];
        
    //向左滚动
    } else if (offsetX > self.width * 2){
        self.otherImageView.frame = CGRectMake(CGRectGetMaxX(_currImageView.frame), 0, self.width, self.height);
        
        self.nextIndex = (self.currIndex + 1) % _images.count;
        self.otherImageView.image = self.images[self.nextIndex];
        if (offsetX >= self.width * 3) [self changeToNext];
    }
}

- (void)changeToNext {
    //切换到下一张图片
    self.currImageView.image = self.otherImageView.image;
    self.scrollView.contentOffset = CGPointMake(self.width * 2, 0);
    [self.scrollView layoutSubviews];
    self.currIndex = self.nextIndex;
    self.pageControl.currentPage = self.currIndex;
    self.describeLabel.text = self.describeArray[self.currIndex];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
}

//该方法用来修复滚动过快导致分页异常的bug
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint currPointInSelf = [_scrollView convertPoint:_currImageView.frame.origin toView:self];
    if (currPointInSelf.x >= -self.width / 2 && currPointInSelf.x <= self.width / 2)
        [self.scrollView setContentOffset:CGPointMake(self.width * 2, 0) animated:YES];
    else [self changeToNext];
}

@end


UIImage *gifImageNamed(NSString *imageName) {
    
    if (![imageName hasSuffix:@".gif"]) {
        imageName = [imageName stringByAppendingString:@".gif"];
    }
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    if (data) return getImageWithData(data);
    
    return [UIImage imageNamed:imageName];
}




