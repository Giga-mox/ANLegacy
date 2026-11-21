#import <Foundation/Foundation.h>

// YouTube Data API v3: read-only playlist discovery.
// Expects a short-lived OAuth access token with youtube.readonly scope.
// Never writes tokens to disk; authentication and Keychain storage belong to a separate module.
@interface LTGooglePlaylists : NSObject
+ (void)fetchPlaylistsWithAccessToken:(NSString *)token
                          completion:(void (^)(NSArray *playlists, NSError *error))completion;
+ (void)fetchTracksForPlaylist:(NSString *)playlistId
                  accessToken:(NSString *)token
                   completion:(void (^)(NSArray *tracks, NSError *error))completion;
@end
