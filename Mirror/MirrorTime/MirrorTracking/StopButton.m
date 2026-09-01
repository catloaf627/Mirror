//
//  StopButton.m
//  Mirror
//

#import "StopButton.h"
#import "MirrorLanguage.h"

static UIColor *StopButtonPrimaryTextColor(void)
{
    return [UIColor colorWithWhite:1 alpha:0.92];
}

static UIColor *StopButtonBackgroundColor(void)
{
    return [UIColor colorWithWhite:1 alpha:0.14];
}

static UIColor *StopButtonHighlightedColor(void)
{
    return [UIColor colorWithWhite:1 alpha:0.22];
}

static UIImage *StopButtonImageWithColor(UIColor *color)
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@interface StopButton ()

@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, assign) CGFloat progress;

@end

@implementation StopButton

- (instancetype)initWithTaskColor:(UIColor *)taskColor
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setupWithTaskColor:taskColor];
    }
    return self;
}

- (void)setupWithTaskColor:(UIColor *)taskColor
{
    [self setTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] forState:UIControlStateNormal];
    self.backgroundColor = StopButtonBackgroundColor();
    [self setTitleColor:StopButtonPrimaryTextColor() forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:20];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.6;
    UIColor *borderColor = [UIColor colorWithWhite:1 alpha:0.18];
    self.layer.borderColor = borderColor.CGColor;
    self.layer.borderWidth = 1;
    self.layer.cornerRadius = 12;
    self.clipsToBounds = YES;
    [self setBackgroundImage:StopButtonImageWithColor(StopButtonBackgroundColor()) forState:UIControlStateNormal];
    [self setBackgroundImage:StopButtonImageWithColor(StopButtonHighlightedColor()) forState:UIControlStateHighlighted];
    [self insertSubview:self.progressView atIndex:0];
    self.progressView.backgroundColor = borderColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutProgressView];
}

- (void)updateProgress:(CGFloat)progress
{
    self.progress = MIN(1, MAX(0, progress));
    self.progressView.hidden = self.progress <= 0;
    [self layoutProgressView];
}

- (void)layoutProgressView
{
    CGRect progressFrame = self.bounds;
    progressFrame.size.width = CGRectGetWidth(self.bounds) * self.progress;
    self.progressView.frame = progressFrame;
}

- (UIView *)progressView
{
    if (!_progressView) {
        _progressView = [UIView new];
        _progressView.userInteractionEnabled = NO;
        _progressView.hidden = YES;
        _progressView.layer.cornerRadius = 12;
        _progressView.layer.masksToBounds = YES;
    }
    return _progressView;
}

@end
