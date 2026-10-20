#import "BAZZARPanel.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

// Opt-in adapter for one reviewed arm64 YMNight build. No audio/network hooks.
static IMP BZROriginalWindow;
static BOOL BZRInstalled;
static id BZRActiveObserver;
static void BZRLabel(UIView *view) {
    if ([view isKindOfClass:UILabel.class]) {
        UILabel *label = (UILabel *)view;
        if ([label.text isEqualToString:@"Наш Telegram"]) {
            label.attributedText = nil;
            label.text = @"О приложении · BAZZAR";
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = 0.7;
        }
    }
    if ([view.accessibilityLabel isEqualToString:@"Наш Telegram, версия 1.0"])
        view.accessibilityLabel = @"О приложении BAZZAR";
    for (UIView *child in view.subviews) BZRLabel(child);
}
static void BZRWindow(UIView *self, SEL selector) {
    ((void(*)(id,SEL))BZROriginalWindow)(self,selector);
    if (self.window) BZRLabel(self);
}
static void BZRTapped(UIView *self, SEL selector) {
    UIViewController *presenter = nil;
    for (UIResponder *r = self.nextResponder; r; r = r.nextResponder) {
        if ([r isKindOfClass:UIViewController.class]) { presenter = (UIViewController *)r; break; }
    }
    if (!presenter) presenter = self.window.rootViewController;
    while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    if (presenter) BAZZARPresentPanel(presenter);
}
static BOOL BZRMatchesImage(Class cls) {
    const char *image = class_getImageName(cls);
    if (!image) return NO;
    NSString *path = [NSString stringWithUTF8String:image];
    if (![path.lastPathComponent isEqualToString:@"YMNight.dylib"]) return NO;
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    // __text is independent of the code-signature blob. Offsets apply only to this thin binary.
    if (data.length < 16384 + 303976) return NO;
    const unsigned char *bytes = data.bytes;
    if (memcmp(bytes,"\xcf\xfa\xed\xfe",4)) return NO;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(bytes + 16384,303976,digest);
    NSMutableString *hash = [NSMutableString string];
    for (NSUInteger i=0;i<sizeof(digest);i++) [hash appendFormat:@"%02x",digest[i]];
    return [hash isEqualToString:@"61eaa48eea78439cabad815fc6cc47ac70c444777f048a1c561a4d7e8141ac97"];
}
static void BZRInstall(void) {
    if (BZRInstalled || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    if (![[NSBundle.mainBundle bundleIdentifier] isEqualToString:@"ru.yandex.mobile.music"]) return;
    if (![NSBundle.mainBundle pathForResource:@"BAZZARPanel" ofType:@"plist"]) return;
    Class cls = objc_getClass("YMLinkRow");
    BOOL isView = NO;
    for (Class parent = cls; parent; parent = class_getSuperclass(parent))
        if (parent == objc_getClass("UIView")) { isView = YES; break; }
    if (!isView || !BZRMatchesImage(cls)) return;
    Method tap = class_getInstanceMethod(cls,@selector(tapped));
    Method window = class_getInstanceMethod(cls,@selector(didMoveToWindow));
    if (!tap || !window || method_getNumberOfArguments(tap) != 2 ||
        method_getNumberOfArguments(window) != 2) return;
    char result[16] = {0}; method_getReturnType(tap,result,sizeof(result));
    if (strcmp(result,"v")) return;
    method_getReturnType(window,result,sizeof(result));
    if (strcmp(result,"v")) return;
    BZROriginalWindow = method_getImplementation(window);
    // Never change UIView's inherited implementation or hook the layout pass.
    class_replaceMethod(cls,@selector(didMoveToWindow),(IMP)BZRWindow,method_getTypeEncoding(window));
    class_replaceMethod(cls,@selector(tapped),(IMP)BZRTapped,method_getTypeEncoding(tap));
    BZRInstalled = YES;
    NSLog(@"[BAZZAR] Adapter R3 installed after activation");
}
__attribute__((constructor)) static void BZRStartAdapter(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:
                [NSBundle.mainBundle pathForResource:@"BAZZARPanel" ofType:@"plist"]];
            if ([config[@"disableAdapter"] boolValue]) {
                NSLog(@"[BAZZAR] Diagnostic mode: adapter disabled");
                return;
            }
            BZRActiveObserver = [NSNotificationCenter.defaultCenter
                addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
                queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                    dispatch_async(dispatch_get_main_queue(), ^{ BZRInstall(); });
                }];
            BZRInstall();
        }
    });
}
