//
//  XRCarouselView.h
//
//  Created by 肖睿 on 16/3/17.
//  Copyright © 2016年 肖睿. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XRCarouselView;

typedef void(^ClickBlock)(NSInteger index);

//pageControl的显示位置
typedef enum {
    PositionDefault,           //默认值 == PositionBottomCenter
    PositionHide,           //隐藏
    PositionTopCenter,      //中上
    PositionBottomLeft,     //左下
    PositionBottomCenter,   //中下
    PositionBottomRight     //右下
} PageControlPosition;

/**
 *  代理
 */
@protocol XRCarouselViewDelegate <NSObject>

/**
 *  该方法用来处理图片的点击，会返回图片在数组中的索引
 *  代理与block二选一即可，若两者都实现，block的优先级高
 *
 *  @param carouselView 控件本身
 *  @param index        图片索引
 */
- (void)carouselView:(XRCarouselView *)carouselView clickImageAtIndex:(NSInteger)index;

@end


/**
 *  说明：要想正常使用，图片数组imageArray必须设置
 *  控件的frame必须设置，xib\sb创建的可不设置
 *  其他属性都有默认值，可不设置
 */
@interface XRCarouselView : UIView


#pragma mark 属性
/**
 *  设置分页控件位置，默认为PositionBottomCenter
 *  只有一张图片时，pageControl隐藏
 */
@property (nonatomic, assign) PageControlPosition pagePosition;


/**
 *  占位图片，在设置图片数组之前设置
 *  不设置则为默认占位图
 */
@property (nonatomic, strong) UIImage *placeholderImage;


/**
 *  轮播的图片数组，可以是本地图片（UIImage，不能是图片名称），也可以是网络路径
 *  支持网络gif图片，本地gif需做处理后传入
 */
@property (nonatomic, strong) NSArray *imageArray;


/**
 *  图片描述的字符串数组，应与图片顺序对应
 *
 *  图片描述控件默认是隐藏的
 *  设置该属性，控件会显示
 *  设置为nil或空数组，控件会隐藏
 */
@property (nonatomic, strong) NSArray *describeArray;

/**
 *  点击图片后要执行的操作，会返回图片在数组中的索引
 */
@property (nonatomic, copy) ClickBlock imageClickBlock;


/**
 *  代理，用来处理图片的点击
 */
@property (nonatomic, weak) id<XRCarouselViewDelegate> delegate;


#pragma mark 方法

/**
 *  设置分页控件指示器的图片
 *  两个图片必须同时设置，否则设置无效
 *  不设置则为系统默认
 *
 *  @param pageImage    其他页码的图片
 *  @param currentImage 当前页码的图片
 */
- (void)setPageImage:(UIImage *)image andCurrentPageImage:(UIImage *)currentImage;


/**
 *  设置分页控件指示器的颜色
 *  不设置则为系统默认
 *
 *  @param color        其他页码的颜色
 *  @param currentColor 当前页码的颜色
 */
- (void)setPageColor:(UIColor *)color andCurrentPageColor:(UIColor *)currentColor;


/**
 *  修改图片描述控件的部分属性，不需要修改的传nil
 *
 *  @param color   字体颜色，默认为[UIColor whiteColor]
 *  @param font    字体，默认为[UIFont systemFontOfSize:13]
 *  @param bgColor 背景颜色，默认为[UIColor colorWithWhite:0 alpha:0.5]
 */
- (void)setDescribeTextColor:(UIColor *)color font:(UIFont *)font bgColor:(UIColor *)bgColor;


@end