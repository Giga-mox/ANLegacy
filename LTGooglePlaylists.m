#import "LTGooglePlaylists.h"

static NSString *const kLTGoogleAPI = @"https://www.googleapis.com/youtube/v3/";
static const NSInteger kLTMaxPages = 100;

@implementation LTGooglePlaylists

+ (NSError *)errorWithMessage:(NSString *)message code:(NSInteger)code {
    return [NSError errorWithDomain:@"LTGooglePlaylists" code:code
                           userInfo:@{NSLocalizedDescriptionKey:message ?: @"Google API error"}];
}

+ (NSString *)encoded:(NSString *)value {
    NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSMutableCharacterSet *set = [allowed mutableCopy];
    [set removeCharactersInString:@"&=?+#"];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:set];
}

+ (void)request:(NSString *)endpoint
         query:(NSDictionary *)query
         token:(NSString *)token
    completion:(void (^)(NSDictionary *, NSError *))completion {
    if (!token.length) {
        completion(nil, [self errorWithMessage:@"Google sign-in required" code:401]);
        return;
    }
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *key in [[query allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", [self encoded:key],
                          [self encoded:[query objectForKey:key]]]];
    }
    NSString *urlText = [NSString stringWithFormat:@"%@%@?%@", kLTGoogleAPI,
                         endpoint, [parts componentsJoinedByString:@"&"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlText]];
    [request setValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    request.timeoutInterval = 25.0;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithRequest:request
         completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        NSError *error = networkError;
        NSDictionary *json = nil;
        if (!error && data.length) {
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if ([parsed isKindOfClass:[NSDictionary class]]) json = parsed;
            else if (!error) error = [self errorWithMessage:@"Unexpected Google response" code:502];
        }
        NSInteger status = [(NSHTTPURLResponse *)response statusCode];
        if (!error && (status < 200 || status >= 300)) {
            NSString *message = [[json objectForKey:@"error"] objectForKey:@"message"];
            error = [self errorWithMessage:message ?: @"Google API request failed" code:status];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(json, error); });
    }];
    [task resume];
}

+ (void)fetchPaged:(NSString *)endpoint
             query:(NSDictionary *)query
             token:(NSString *)token
           results:(NSMutableArray *)results
              page:(NSInteger)page
        completion:(void (^)(NSArray *, NSError *))completion {
    if (page >= kLTMaxPages) {
        completion([results copy], [self errorWithMessage:@"Too many pages; import incomplete" code:413]);
        return;
    }
    [self request:endpoint query:query token:token completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSArray *items = [json objectForKey:@"items"];
        if (![items isKindOfClass:[NSArray class]]) {
            completion(nil, [self errorWithMessage:@"No playlist data returned" code:502]);
            return;
        }
        for (id item in items) if ([item isKindOfClass:[NSDictionary class]]) [results addObject:item];
        NSString *next = [json objectForKey:@"nextPageToken"];
        if (![next isKindOfClass:[NSString class]] || !next.length) {
            completion([results copy], nil);
            return;
        }
        NSMutableDictionary *nextQuery = [query mutableCopy];
        [nextQuery setObject:next forKey:@"pageToken"];
        [self fetchPaged:endpoint query:nextQuery token:token results:results page:page+1 completion:completion];
    }];
}

+ (void)fetchPlaylistsWithAccessToken:(NSString *)token
                          completion:(void (^)(NSArray *, NSError *))completion {
    [self fetchPaged:@"playlists"
              query:@{@"part":@"snippet,contentDetails", @"mine":@"true", @"maxResults":@"50"}
              token:token results:[NSMutableArray array] page:0 completion:completion];
}

+ (void)fetchTracksForPlaylist:(NSString *)playlistId
                  accessToken:(NSString *)token
                   completion:(void (^)(NSArray *, NSError *))completion {
    if (!playlistId.length) {
        completion(nil, [self errorWithMessage:@"Missing playlist ID" code:400]);
        return;
    }
    [self fetchPaged:@"playlistItems"
              query:@{@"part":@"snippet,contentDetails", @"playlistId":playlistId, @"maxResults":@"50"}
              token:token results:[NSMutableArray array] page:0 completion:completion];
}
@end
