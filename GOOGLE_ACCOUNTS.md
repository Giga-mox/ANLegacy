# Google accounts — implementation plan

The fork currently has a **read-only YouTube playlist API client**, `LTGooglePlaylists.h/.m`.
It is not yet connected to the Settings UI and **Google sign-in is not implemented**.
Do not enter a Google password into ANLegacy or paste OAuth tokens into GitHub Actions.

## Google Cloud preparation

1. Create a Google Cloud project at https://console.cloud.google.com/.
2. Enable **YouTube Data API v3**.
3. Configure the **OAuth consent screen**, add a test user during testing if required.
4. Create an **iOS** OAuth 2.0 client for the exact Bundle ID used in the final IPA.
5. Add that iOS client's **reversed client ID** as an app URL scheme at packaging time.
6. Request only `https://www.googleapis.com/auth/youtube.readonly` for initial read-only import.

**Important:** Changing the IPA Bundle ID can require creating a matching iOS OAuth client.
OAuth Client ID is public configuration; access and refresh tokens are secrets.
Do not commit tokens, personal data, or OAuth client secrets.

## Architecture

- Authorize via Apple's external-browser authentication session on iOS 13, with PKCE
  and a state value. Do not embed Google login in WKWebView/UIWebView.
- Exchange the returned authorization code for tokens. Store refresh tokens in
  iOS Keychain, scoped by account. Keep access tokens short-lived and refresh as needed.
- Fetch `playlists.list?mine=true` with pagination (client implemented).
- Fetch `playlistItems.list` with pagination (client implemented).
- Map usable YouTube video IDs and metadata to local `LTTrack` objects.
- Import into namespaced local playlists (e.g. Google account/channel + playlist ID).
- Initially sync **one-way from Google**. Never delete local playlists or modify the
  remote YouTube account without a separate user-confirmed feature.
- A later phase may support multiple accounts, refresh, reauthorization and revocation.

## Limitations

YouTube Data API v3 is *not* a complete YouTube Music library API. Some Music-specific
collections and `Liked Music` behavior may be inaccessible or differ. OAuth for the
YouTube channel does not guarantee access to all YouTube Music collections.
The source project's InnerTube streaming remains independent of Google authentication.

## Current status

- [x] Read-only playlist and playlist-item API networking (not device-tested)
- [ ] OAuth client configuration / URL callback
- [ ] PKCE browser login and Keychain
- [ ] Account management UI
- [ ] Playlist import preview and mapping
- [ ] One-way sync of imported playlists
- [ ] Tests on iOS 13.6
