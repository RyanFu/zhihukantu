//
//  KNPhotoBrowerImageView.m
//  KNPhotoBrower
//
//  Created by LuKane on 16/8/17.
//  Copyright © 2016年 LuKane. All rights reserved.
//

#import "KNPhotoBrowerImageView.h"
#import "KNProgressHUD.h"

@interface KNPhotoBrowerImageView()<UIScrollViewDelegate>{
    KNProgressHUD *_progressHUD;
    NSString      *_url;
    UIImage       *_placeHolder;
}

@property (nonatomic, strong ) UILabel *reloadLabel; // 重新加载 Label

@end


@implementation KNPhotoBrowerImageView

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        [_imageView setUserInteractionEnabled:YES];
        [_imageView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    }
    return _imageView;
}

- (UIScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        [_scrollView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
        [_scrollView addSubview:self.imageView];
        [_scrollView setDelegate:self];
        [_scrollView setClipsToBounds:YES];
    }
    return _scrollView;
}

- (UILabel *)reloadLabel{
    if (!_reloadLabel) {
        _reloadLabel = [[UILabel alloc] init];
        [_reloadLabel setBackgroundColor:[UIColor blackColor]];
        [_reloadLabel.layer setCornerRadius:5];
        [_reloadLabel setClipsToBounds:YES];
        [_reloadLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
        [_reloadLabel setTextColor:[UIColor whiteColor]];
        [_reloadLabel setTextAlignment:NSTextAlignmentCenter];
        [_reloadLabel setBounds:(CGRect){CGPointZero,{100,35}}];
        [_reloadLabel setText:@"重新加载"];
        [_reloadLabel setCenter:(CGPoint){ScreenWidth * 0.5,ScreenHeight * 0.5}];
        [_reloadLabel setHidden:YES];
        [_reloadLabel setUserInteractionEnabled:YES];
        [_reloadLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reloadImageIBAction)]];
        [self addSubview:_reloadLabel];
    }
    return _reloadLabel;
}

- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.scrollView];
        [self initDefaultData];
    }
    return self;
}

- (void)initDefaultData{
    // 1.生产 两种 手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDidTap:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDidDoubleTap:)];
    
    // 2.设置 手势的要求
    [tap setNumberOfTapsRequired:1];
    [tap setNumberOfTouchesRequired:1];
    [doubleTap setNumberOfTapsRequired:2];
    [doubleTap setNumberOfTouchesRequired:1];
    
    // 3.避免两种手势冲突
    [tap requireGestureRecognizerToFail:doubleTap];
    
    // 4.添加 手势
    [self addGestureRecognizer:tap];
    [self addGestureRecognizer:doubleTap];
}

#pragma mark - 单击
- (void)scrollViewDidTap:(UITapGestureRecognizer *)tap{
    if(_singleTapBlock){
        _singleTapBlock(tap);
    }
}

#pragma mark - 双击
- (void)scrollViewDidDoubleTap:(UITapGestureRecognizer *)doubleTap{
    // 这里先判断图片是否下载好,, 如果没下载好, 直接return
    if(!_imageView.image) return;
    
    if(_scrollView.zoomScale <= 1){
        // 1.获取到 手势 在 自身上的 位置
        // 2.scrollView的偏移量 x(为负) + 手势的 x 需要放大的图片的X点
        CGFloat x = [doubleTap locationInView:self].x + _scrollView.contentOffset.x;
        
        // 3.scrollView的偏移量 y(为负) + 手势的 y 需要放大的图片的Y点
        CGFloat y = [doubleTap locationInView:self].y + _scrollView.contentOffset.y;
        [_scrollView zoomToRect:(CGRect){{x,y},CGSizeZero} animated:YES];
    }else{
        // 设置 缩放的大小  还原
        [_scrollView setZoomScale:1.f animated:YES];
    }
}

- (void)reloadImageIBAction{
    [_reloadLabel setHidden:YES];
    [self sd_ImageWithUrl:_url placeHolder:_placeHolder];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _scrollView.frame = self.bounds;
    [self reloadFrames];
}

- (void)sd_ImageWithUrl:(NSString *)url placeHolder:(UIImage *)placeHolder {
    self.imageView.image = [UIImage imageWithContentsOfFile:url];
}

- (void)reloadFrames{
    CGRect frame = self.frame;
    if(_imageView.image){
        
        CGSize imageSize = _imageView.image.size;
        CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        
        if (frame.size.width <= frame.size.height) { // 如果ScrollView的 宽 <= 高
            // 将图片的 宽 设置成 ScrollView的宽  ,高度 等比率 缩放
            CGFloat ratio = frame.size.width / imageFrame.size.width;
            imageFrame.size.height = imageFrame.size.height * ratio;
            imageFrame.size.width = frame.size.width;
            
        }else{
            
            // 将图片的 宽 设置成 ScrollView的宽  ,高度 等比率 缩放
            CGFloat ratio = frame.size.height / imageFrame.size.height;
            imageFrame.size.width = imageFrame.size.width*ratio;
            imageFrame.size.height = frame.size.height;
        }
        
        // 设置 imageView 的 frame
        _imageView.frame = imageFrame;
        
        // scrollView 的滚动区域
        _scrollView.contentSize = _imageView.frame.size;
        
        // 将 scrollView.contentSize 赋值为 图片的大小. 再获取 图片的中心点
        _imageView.center = [self centerOfScrollViewContent:_scrollView];
        
        // 获取 ScrollView 高 和 图片 高 的 比率
        CGFloat maxScale = frame.size.height / imageFrame.size.height;
        // 获取 宽度的比率
        CGFloat widthRadit = frame.size.width / imageFrame.size.width;
        
        // 取出 最大的 比率
        maxScale = widthRadit > maxScale?widthRadit:maxScale;
        // 如果 最大比率 >= 2 倍 , 则取 最大比率 ,否则去 2 倍
        maxScale = maxScale > 2?maxScale:2;
        
        // 设置 scrollView的 最大 和 最小 缩放比率
        _scrollView.minimumZoomScale = 0.6;
        _scrollView.maximumZoomScale = maxScale;
        
        // 设置 scrollView的 原始缩放大小
        _scrollView.zoomScale = 1.0f;
        
    }else{
        frame.origin = CGPointZero;
        _imageView.frame = frame;
        _scrollView.contentSize = _imageView.size;
    }
    _scrollView.contentOffset = CGPointZero;
}

- (CGPoint)centerOfScrollViewContent:(UIScrollView *)scrollView{
    // scrollView.bounds.size.width > scrollView.contentSize.width : 说明:scrollView 大小 > 图片 大小
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    CGPoint actualCenter = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                       scrollView.contentSize.height * 0.5 + offsetY);
    return actualCenter;
}

#pragma mark UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    // 在ScrollView上  所需要缩放的 对象
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    // 每次 完成 拖动时 都 重置 图片的中心点
    _imageView.center = [self centerOfScrollViewContent:scrollView];
}

@end
