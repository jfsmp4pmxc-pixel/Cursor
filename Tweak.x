#import <UIKit/UIKit.h>

@interface CursorWindow : UIWindow
@property (nonatomic, strong) UIImageView *cursorView;
@property (nonatomic, assign) CGPoint panStartPoint;
@property (nonatomic, assign) CGPoint cursorStartPoint;
@end

@implementation CursorWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 1. Cấu hình Window lớp trên cùng, cực kỳ quan trọng
        self.windowLevel = UIWindowLevelStatusBar + 100.0; // Đặt ngang tầm StatusBar để vừa đè game vừa nhận touch chuẩn
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.clipsToBounds = NO;
        
        // 2. Vẽ con trỏ chuẩn dọc từ mảng Bitmap của bạn
        UIImage *cursorImg = [self drawRetroCursor];
        self.cursorView = [[UIImageView alloc] initWithImage:cursorImg];
        self.cursorView.frame = CGRectMake(0, 0, cursorImg.size.width, cursorImg.size.height);
        
        // Khởi tạo ở chính giữa màn hình
        self.cursorView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
        [self addSubview:self.cursorView];
    }
    return self;
}

// Hàm render mảng Bitmap chuẩn tọa độ đứng dọc
- (UIImage *)drawRetroCursor {
    #define CURSOR_W 14
    #define CURSOR_H 23
    
    unsigned char cursor_bitmap[23][14] = {
        {0,1,1,0,0,0,0,0,0,0,0,0,0,0},
        {1,2,2,1,0,0,0,0,0,0,0,0,0,0},
        {1,2,2,2,1,0,0,0,0,0,0,0,0,0},
        {1,2,2,2,2,1,0,0,0,0,0,0,0,0},
        {1,2,2,2,2,2,1,0,0,0,0,0,0,0},
        {1,2,2,2,2,2,2,1,0,0,0,0,0,0},
        {1,2,2,2,2,2,2,2,1,0,0,0,0,0},
        {1,2,2,2,2,2,2,2,2,1,0,0,0,0},
        {1,2,2,2,2,2,2,2,2,2,1,0,0,0},
        {1,2,2,2,2,2,2,2,2,2,2,1,0,0},
        {1,2,2,2,2,2,2,2,2,2,2,2,1,0},
        {1,2,2,2,2,2,2,2,2,2,2,2,2,1},
        {1,2,2,2,2,2,2,2,2,2,2,2,2,1},
        {1,2,2,2,2,2,2,1,1,1,1,1,1,0},
        {1,2,2,2,2,1,2,2,1,0,0,0,0,0},
        {1,2,2,2,1,1,2,2,1,0,0,0,0,0},
        {1,2,2,1,0,0,1,2,2,1,0,0,0,0},
        {0,1,1,0,0,0,1,2,2,1,0,0,0,0},
        {0,0,0,0,0,0,0,1,2,2,1,0,0,0},
        {0,0,0,0,0,0,0,1,2,2,1,0,0,0},
        {0,0,0,0,0,0,0,0,1,2,2,1,0,0},
        {0,0,0,0,0,0,0,0,1,2,2,1,0,0},
        {0,0,0,0,0,0,0,0,0,1,1,0,0,0},
    };

    int scale_factor = 2; // Bạn có thể tăng lên 3 nếu muốn con trỏ to hơn nữa
    CGSize size = CGSizeMake(CURSOR_W * scale_factor, CURSOR_H * scale_factor);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Tắt khử răng cưa để pixel vuông vức, sắc nét chuẩn Retro
    CGContextSetShouldAntialias(context, NO);
    
    // Duyệt chuẩn: Y là hàng (chiều cao), X là cột (chiều rộng)
    for (int y = 0; y < CURSOR_H; y++) {
        for (int x = 0; x < CURSOR_W; x++) {
            unsigned char pixel = cursor_bitmap[y][x];
            
            if (pixel == 0) continue; // Trong suốt
            
            if (pixel == 1) {
                [[UIColor blackColor] setFill]; // Viền đen
            } else if (pixel == 2) {
                [[UIColor whiteColor] setFill]; // Ruột trắng
            }
            
            CGRect pixelRect = CGRectMake(x * scale_factor, y * scale_factor, scale_factor, scale_factor);
            CGContextFillRect(context, pixelRect);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// BƯỚC FIX DI CHUYỂN: Dùng Touches gốc của Window thay vì GestureRecognizer
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    if (touch) {
        // Lưu vị trí ngón tay chạm vào và vị trí hiện tại của con trỏ
        self.panStartPoint = [touch locationInView:self];
        self.cursorStartPoint = self.cursorView.center;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    if (touch) {
        CGPoint currentTouchPoint = [touch locationInView:self];
        
        // Tính toán độ dời delta (dx, dy) của ngón tay
        CGFloat dx = currentTouchPoint.x - self.panStartPoint.x;
        CGFloat dy = currentTouchPoint.y - self.panStartPoint.y;
        
        // Cập nhật vị trí mới cho con trỏ chuột
        CGPoint newCenter = CGPointMake(self.cursorStartPoint.x + dx, self.cursorStartPoint.y + dy);
        
        // Khóa ranh giới không cho chuột bay khỏi màn hình
        CGFloat screenWidth = self.bounds.size.width;
        CGFloat screenHeight = self.bounds.size.height;
        newCenter.x = fmax(0, fmin(newCenter.x, screenWidth));
        newCenter.y = fmax(0, fmin(newCenter.y, screenHeight));
        
        self.cursorView.center = newCenter;
    }
}

// Giữ lại cơ chế hitTest để click xuyên qua màn hình
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil; // Cho phép touch truyền xuống app/game bên dưới
    }
    return hitView;
}

@end

static CursorWindow *_cursorWindow = nil;

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_cursorWindow) {
            _cursorWindow = [[CursorWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [_cursorWindow setHidden:NO];
        }
    });
}