#import <UIKit/UIKit.h>

@interface CursorWindow : UIWindow <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIImageView *cursorView;
@property (nonatomic, assign) CGPoint lastLocation;
@end

@implementation CursorWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 1. Cấu hình Window lớp trên cùng, trong suốt
        self.windowLevel = UIWindowLevelAlert + 9999; // Đẩy lên mức cao nhất hệ thống
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.clipsToBounds = NO;
        
        // 2. Tạo con trỏ từ mảng Bitmap Pixel Art của bạn
        UIImage *cursorImg = [self drawRetroCursor];
        self.cursorView = [[UIImageView alloc] initWithImage:cursorImg];
        self.cursorView.frame = CGRectMake(0, 0, cursorImg.size.width, cursorImg.size.height);
        
        // Khởi tạo con trỏ ở chính giữa màn hình
        self.cursorView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
        [self addSubview:self.cursorView];
        
        // 3. Thêm Pan Gesture để nhận diện cử chỉ vuốt di chuyển
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self; // Gán delegate để xử lý trùng chấp cử chỉ với game
        panGesture.cancelsTouchesInView = NO; // Không chặn các sự kiện touch khác
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

// Hàm render mảng Bitmap 2D thành UIImage phong cách Pixel Art
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

    // Đặt tỉ lệ scale (2 có nghĩa là phóng to mỗi pixel thành ô vuông 2x2 để nhìn rõ trên màn hình Retina)
    int scale_factor = 2; 
    CGSize size = CGSizeMake(CURSOR_W * scale_factor, CURSOR_H * scale_factor);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // BẮT BUỘC: Tắt làm mượt hình ảnh để giữ nguyên các khối vuông Pixel góc cạnh
    CGContextSetShouldAntialias(context, NO);
    
    // Duyệt qua mảng và tô màu từng pixel
    for (int y = 0; y < CURSOR_H; y++) {
        for (int x = 0; x < CURSOR_W; x++) {
            unsigned char pixel = cursor_bitmap[y][x];
            
            if (pixel == 0) continue; // 0: Trong suốt
            
            if (pixel == 1) {
                [[UIColor blackColor] setFill]; // 1: Viền đen
            } else if (pixel == 2) {
                [[UIColor whiteColor] setFill]; // 2: Ruột trắng
            }
            
            CGRect pixelRect = CGRectMake(x * scale_factor, y * scale_factor, scale_factor, scale_factor);
            CGContextFillRect(context, pixelRect);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Logic tính toán vị trí khi vuốt màn hình
- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Lưu lại vị trí trước khi vuốt
        self.lastLocation = self.cursorView.center;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(self.lastLocation.x + translation.x,
                                        self.lastLocation.y + translation.y);
        
        // Kiểm tra ranh giới, không cho con trỏ vượt quá cạnh màn hình
        CGFloat screenWidth = self.bounds.size.width;
        CGFloat screenHeight = self.bounds.size.height;
        
        newCenter.x = fmax(0, fmin(newCenter.x, screenWidth));
        newCenter.y = fmax(0, fmin(newCenter.y, screenHeight));
        
        self.cursorView.center = newCenter;
    }
}

// Cho phép nhận diện cử chỉ vuốt của dylib song song với cử chỉ vuốt của game/app gốc
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// Cơ chế hitTest xuyên thấu: Bấm ngón tay vào chỗ trống thì sự kiện click truyền thẳng xuống dưới game
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil; // Nhường touch phản hồi cho app gốc
    }
    return hitView;
}

@end

static CursorWindow *_cursorWindow = nil;

// Hàm khởi tạo Tweak khi inject vào app thành công
%ctor {
    // Trì hoãn 1.5 giây sau khi ứng dụng mở lên để đảm bảo UI gốc đã load xong rồi mới đè Window lên
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_cursorWindow) {
            _cursorWindow = [[CursorWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [_cursorWindow setHidden:NO];
        }
    });
}