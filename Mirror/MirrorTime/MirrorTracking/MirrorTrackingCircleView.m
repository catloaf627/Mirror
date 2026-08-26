//
//  MirrorTrackingCircleView.m
//  Mirror
//

#import "MirrorTrackingCircleView.h"

CGFloat const MirrorTrackingCircleLineWidth = 18;

static UIColor *MirrorTrackingCircleTrackColor(void)
{
    return [UIColor colorWithWhite:0.08 alpha:0.2];
}

@implementation MirrorTrackingCircleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (void)setupLayers
{
    self.backgroundColor = UIColor.clearColor;
    self.contentMode = UIViewContentModeRedraw;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setStartAngle:(CGFloat)startAngle
{
    _startAngle = startAngle;
    [self setNeedsDisplay];
}

- (void)setTaskColor:(UIColor *)taskColor
{
    _taskColor = taskColor;
    [self setNeedsDisplay];
}

- (void)setPulseColor:(UIColor *)pulseColor
{
    _pulseColor = pulseColor;
    [self setNeedsDisplay];
}

- (CGFloat)normalizedAngleDeltaFromAngle:(CGFloat)angle startAngle:(CGFloat)startAngle
{
    CGFloat delta = angle - startAngle;
    while (delta < 0) {
        delta += 2*M_PI;
    }
    while (delta >= 2*M_PI) {
        delta -= 2*M_PI;
    }
    return delta;
}

- (BOOL)colorComponentsFromColor:(UIColor *)color red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
    if ([color getRed:red green:green blue:blue alpha:alpha]) {
        return YES;
    }
    CGFloat white = 0;
    if ([color getWhite:&white alpha:alpha]) {
        *red = white;
        *green = white;
        *blue = white;
        return YES;
    }
    return NO;
}

- (UIImage *)ringImageWithRect:(CGRect)rect center:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle sweepAngle:(CGFloat)sweepAngle
{
    CGFloat scale = UIScreen.mainScreen.scale;
    size_t width = MAX(1, (size_t)ceil(CGRectGetWidth(rect) * scale));
    size_t height = MAX(1, (size_t)ceil(CGRectGetHeight(rect) * scale));
    size_t bytesPerRow = width * 4;
    unsigned char *pixels = calloc(height * bytesPerRow, 1);
    if (!pixels) {
        return nil;
    }

    CGFloat startRed = 0, startGreen = 0, startBlue = 0, startAlpha = 0;
    CGFloat endRed = 0, endGreen = 0, endBlue = 0, endAlpha = 0;
    if (![self colorComponentsFromColor:self.taskColor red:&startRed green:&startGreen blue:&startBlue alpha:&startAlpha] ||
        ![self colorComponentsFromColor:self.pulseColor red:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha]) {
        free(pixels);
        return nil;
    }

    CGFloat halfLineWidth = MirrorTrackingCircleLineWidth / 2.0;
    CGFloat capRadius = halfLineWidth;
    CGFloat innerRadius = radius - halfLineWidth;
    CGFloat outerRadius = radius + halfLineWidth;
    CGFloat edgeWidth = 1.0 / scale;
    BOOL drawsCaps = YES;
    CGFloat capLength = drawsCaps ? capRadius : 0;
    CGFloat ringLength = radius * sweepAngle;
    CGFloat totalLength = MAX(0.001, ringLength + 2*capLength);
    CGFloat startUnitX = cos(startAngle);
    CGFloat startUnitY = sin(startAngle);
    CGFloat startCapCenterX = center.x + radius * startUnitX;
    CGFloat startCapCenterY = center.y + radius * startUnitY;
    CGFloat startTangentX = -sin(startAngle);
    CGFloat startTangentY = cos(startAngle);
    CGFloat endAngle = startAngle + sweepAngle;
    CGFloat endUnitX = cos(endAngle);
    CGFloat endUnitY = sin(endAngle);
    CGFloat endCapCenterX = center.x + radius * endUnitX;
    CGFloat endCapCenterY = center.y + radius * endUnitY;
    CGFloat endTangentX = -sin(endAngle);
    CGFloat endTangentY = cos(endAngle);

    for (size_t y = 0; y < height; y++) {
        CGFloat pointY = ((CGFloat)y + 0.5) / scale;
        for (size_t x = 0; x < width; x++) {
            CGFloat pointX = ((CGFloat)x + 0.5) / scale;
            size_t offset = y * bytesPerRow + x * 4;

            void (^blendPixel)(CGFloat, CGFloat) = ^(CGFloat coverage, CGFloat selectedProgress) {
                if (coverage <= 0) {
                    return;
                }
                CGFloat progress = MIN(1, MAX(0, selectedProgress));
                CGFloat red = startRed + (endRed - startRed) * progress;
                CGFloat green = startGreen + (endGreen - startGreen) * progress;
                CGFloat blue = startBlue + (endBlue - startBlue) * progress;
                CGFloat alpha = (startAlpha + (endAlpha - startAlpha) * progress) * MIN(1, MAX(0, coverage));
                CGFloat dstAlpha = pixels[offset + 3] / 255.0;
                CGFloat outAlpha = alpha + dstAlpha * (1 - alpha);
                CGFloat outRed = red * alpha + (pixels[offset] / 255.0) * (1 - alpha);
                CGFloat outGreen = green * alpha + (pixels[offset + 1] / 255.0) * (1 - alpha);
                CGFloat outBlue = blue * alpha + (pixels[offset + 2] / 255.0) * (1 - alpha);
                pixels[offset] = (unsigned char)lrint(MIN(1, MAX(0, outRed)) * 255);
                pixels[offset + 1] = (unsigned char)lrint(MIN(1, MAX(0, outGreen)) * 255);
                pixels[offset + 2] = (unsigned char)lrint(MIN(1, MAX(0, outBlue)) * 255);
                pixels[offset + 3] = (unsigned char)lrint(MIN(1, MAX(0, outAlpha)) * 255);
            };

            if (drawsCaps) {
                CGFloat startCapDistance = hypot(pointX - startCapCenterX, pointY - startCapCenterY);
                CGFloat startCapProjection = (pointX - startCapCenterX) * startTangentX + (pointY - startCapCenterY) * startTangentY;
                CGFloat startCapCoverage = MIN(1, MAX(0, (capRadius - startCapDistance) / edgeWidth));
                CGFloat startCapSideCoverage = MIN(1, MAX(0, (edgeWidth - startCapProjection) / edgeWidth));
                startCapCoverage *= startCapSideCoverage;
                CGFloat projection = (startCapProjection + capRadius) / capRadius;
                blendPixel(startCapCoverage, MIN(1, MAX(0, projection)) * capLength / totalLength);
            }

            CGFloat dx = pointX - center.x;
            CGFloat dy = pointY - center.y;
            CGFloat distance = hypot(dx, dy);
            CGFloat innerCoverage = MIN(1, MAX(0, (distance - innerRadius) / edgeWidth));
            CGFloat outerCoverage = MIN(1, MAX(0, (outerRadius - distance) / edgeWidth));
            CGFloat ringCoverage = innerCoverage * outerCoverage;
            CGFloat angle = atan2(dy, dx);
            CGFloat delta = [self normalizedAngleDeltaFromAngle:angle startAngle:startAngle];
            if (delta <= sweepAngle) {
                blendPixel(ringCoverage, (capLength + radius * delta) / totalLength);
            }

            if (drawsCaps) {
                CGFloat endCapDistance = hypot(pointX - endCapCenterX, pointY - endCapCenterY);
                CGFloat endCapProjection = (pointX - endCapCenterX) * endTangentX + (pointY - endCapCenterY) * endTangentY;
                CGFloat endCapCoverage = MIN(1, MAX(0, (capRadius - endCapDistance) / edgeWidth));
                CGFloat endCapSideCoverage = MIN(1, MAX(0, (endCapProjection + edgeWidth * 2) / edgeWidth));
                endCapCoverage *= endCapSideCoverage;
                CGFloat projection = endCapProjection / capRadius;
                blendPixel(endCapCoverage, (capLength + ringLength + MIN(1, MAX(0, projection)) * capLength) / totalLength);
            }
        }
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(pixels, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef imageRef = bitmapContext ? CGBitmapContextCreateImage(bitmapContext) : NULL;
    UIImage *image = imageRef ? [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp] : nil;
    if (imageRef) {
        CGImageRelease(imageRef);
    }
    if (bitmapContext) {
        CGContextRelease(bitmapContext);
    }
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    return image;
}

- (void)drawRect:(CGRect)rect
{
    if (CGRectIsEmpty(self.bounds) || !self.taskColor || !self.pulseColor) {
        return;
    }

    CGRect circleRect = CGRectInset(self.bounds, MirrorTrackingCircleLineWidth/2 + 4, MirrorTrackingCircleLineWidth/2 + 4);
    CGPoint center = CGPointMake(CGRectGetMidX(circleRect), CGRectGetMidY(circleRect));
    CGFloat radius = MIN(CGRectGetWidth(circleRect), CGRectGetHeight(circleRect))/2;
    CGFloat progress = MAX(0, MIN(1, self.progress));
    if (progress <= 0) {
        return;
    }

    CGFloat startAngle = self.startAngle;
    CGFloat sweepAngle = progress >= 1 ? 2*M_PI : 2*M_PI*progress;

    UIBezierPath *trackPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:startAngle + 2*M_PI clockwise:YES];
    trackPath.lineWidth = MirrorTrackingCircleLineWidth;
    trackPath.lineCapStyle = kCGLineCapRound;
    [MirrorTrackingCircleTrackColor() setStroke];
    [trackPath stroke];

    UIImage *ringImage = [self ringImageWithRect:self.bounds center:center radius:radius startAngle:startAngle sweepAngle:sweepAngle];
    [ringImage drawInRect:self.bounds];
}

@end
