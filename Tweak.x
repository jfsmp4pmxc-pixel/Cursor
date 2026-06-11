#import <UIKit/UIKit.h>

// Đường dẫn tới file ảnh asset con trỏ
#define K_CURSOR_PATH @"/Library/PreferenceBundles/CursorAssets/cursor.png"

@interface CursorWindow : UIWindow
@property (nonatomic, strong) UIImageView *cursorView;
@property (nonatomic, assign) CGPoint lastLocation;
@end

@implementation CursorWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 1. Cấu hình Window lớp trên cùng
        self.windowLevel = UIWindowLevelAlert + 2000; // Siêu cao để đè mọi thứ
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES; // Cho phép nhận touch
        
        // 2. Load asset PNG và tạo UIImageView
        UIImage *cursorImg = [UIImage imageWithContentsOfFile:K_CURSOR_PATH];
        if (!cursorImg) {
            // Nếu không tìm thấy file, dùng ô vuông màu tạm để test
            cursorImg = [self squareImageWithColor:[UIColor redColor] size:CGSizeMake(20, 20)];
        }
        
        self.cursorView = [[UIImageView alloc] initWithImage:cursorImg];
        // Giữ nguyên kích thước thật của ảnh PNG
        self.cursorView.frame = CGRectMake(0, 0, cursorImg.size.width, cursorImg.size.height);
        self.cursorView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2); // Giữa màn hình
        self.cursorView.alpha = 0.8; // Hơi mờ một chút cho đẹp
        [self addSubview:self.cursorView];
        
        // 3. Thêm Pan Gesture (Cử chỉ vuốt) để di chuyển
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

// Hàm bổ trợ tạo ảnh màu tạm thời nếu thiếu asset
- (UIImage *)squareImageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Xử lý logic di chuyển con trỏ
- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Lưu vị trí hiện tại của con trỏ khi bắt đầu vuốt
        self.lastLocation = self.cursorView.center;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        // Tính toán tọa độ mới dựa trên khoảng cách vuốt
        CGPoint newCenter = CGPointMake(self.lastLocation.x + translation.x,
                                        self.lastLocation.y + translation.y);
        
        // Giới hạn (Boundary check) không cho con trỏ bay ra ngoài màn hình
        CGFloat screenWidth = self.bounds.size.width;
        CGFloat screenHeight = self.bounds.size.height;
        CGFloat halfWidth = self.cursorView.frame.size.width / 2;
        CGFloat halfHeight = self.cursorView.frame.size.height / 2;
        
        newCenter.x = fmax(halfWidth, fmin(newCenter.x, screenWidth - halfWidth));
        newCenter.y = fmax(halfHeight, fmin(newCenter.y, screenHeight - halfHeight));
        
        // Cập nhật vị trí UIImageView
        self.cursorView.center = newCenter;
    }
}

// Cho phép touch xuyên qua Window ở những chỗ không có con trỏ (quan trọng)
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    // Nếu touch trúng vào Window nhưng không trúng vào UIImageView con trỏ
    if (hitView == self) {
        return nil; // Trả về nil để hệ thống chuyển touch xuống app bên dưới
    }
    return hitView; // Nếu trúng con trỏ, giữ lại để xử lý Pan Gesture
}

@end

// Biến toàn cục để giữ Window
static CursorWindow *_cursorWindow = nil;

// Constructor: Chạy ngay khi dylib được inject
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_cursorWindow) {
            _cursorWindow = [[CursorWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [_cursorWindow setHidden:NO];
            NSLog(@"[CursorBeta] Window spawned successfully.");
        }
    });
}