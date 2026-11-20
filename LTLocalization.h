#import <Foundation/Foundation.h>

static inline BOOL LTIsRussian(void) {
    return [[[NSUserDefaults standardUserDefaults] stringForKey:@"LTAppLanguage"] isEqualToString:@"ru"];
}
static inline NSString *LTLoc(NSString *en, NSString *ru) {
    return LTIsRussian() ? ru : en;
}

static inline NSString *LTRussianPlural(NSInteger n, NSString *one, NSString *few, NSString *many) {
    NSInteger last = n % 10, lastTwo = n % 100;
    if (lastTwo >= 11 && lastTwo <= 14) return many;
    if (last == 1) return one;
    if (last >= 2 && last <= 4) return few;
    return many;
}
static inline NSString *LTCount(NSInteger n, NSString *enOne, NSString *enMany, NSString *ruOne, NSString *ruFew, NSString *ruMany) {
    NSString *word = LTIsRussian() ? LTRussianPlural(n, ruOne, ruFew, ruMany) : (n == 1 ? enOne : enMany);
    return [NSString stringWithFormat:@"%ld %@", (long)n, word];
}
static inline NSString *LTTrackCount(NSInteger n) {
    return LTCount(n, @"track", @"tracks", @"трек", @"трека", @"треков");
}
static inline NSString *LTSongCount(NSInteger n) {
    return LTCount(n, @"song", @"songs", @"песня", @"песни", @"песен");
}
static inline NSString *LTFileCount(NSInteger n) {
    return LTCount(n, @"file", @"files", @"файл", @"файла", @"файлов");
}
