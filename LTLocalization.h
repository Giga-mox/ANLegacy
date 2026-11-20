#import <Foundation/Foundation.h>

static inline BOOL LTIsRussian(void) {
    return [[[NSUserDefaults standardUserDefaults] stringForKey:@"LTAppLanguage"] isEqualToString:@"ru"];
}
static inline NSString *LTLoc(NSString *en, NSString *ru) {
    return LTIsRussian() ? ru : en;
}
