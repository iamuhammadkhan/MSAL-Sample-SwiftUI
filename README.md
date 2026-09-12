# MSAL Sample, SwiftUI

A working Azure AD B2C sign-in sample for iOS, in **SwiftUI**. Sign up or sign in against a B2C user flow, get an access token, call a protected API with it, refresh it, edit the profile, and sign out.

Microsoft's official iOS B2C sample is UIKit-only. This is the SwiftUI equivalent, with the MSAL work behind a view model.

> Looking for the UIKit version? [MSAL-Sample-Swift](https://github.com/iamuhammadkhan/MSAL-Sample-Swift).

## Run it

```sh
git clone https://github.com/iamuhammadkhan/MSAL-Sample-SwiftUI
cd MSAL-Sample-SwiftUI
pod install          # Pods are committed, so this is optional
open Testing-MSAL-SwiftUI.xcworkspace
```

Open the **workspace**, not the project. Build and run: it works out of the box, because it is wired to Microsoft's public demo tenant (`fabrikamb2c.onmicrosoft.com`). No Azure account needed to try it.

Requires iOS 14+ and Xcode 13+.

## Pointing it at your own tenant

Everything you need to change is at the top of [`MainScreenViewModel.swift`](Testing-MSAL-SwiftUI/MainScreenViewModel.swift):

```swift
private let kTenantName          = "fabrikamb2c.onmicrosoft.com"
private let kAuthorityHostName   = "fabrikamb2c.b2clogin.com"
private let kClientID            = "90c0fe63-bcf2-44d5-8fb7-b8bbc0b29dc6"
private let kSignupOrSigninPolicy = "b2c_1_susi"
private let kEditProfilePolicy    = "b2c_1_edit_profile"
private let kResetPasswordPolicy  = "b2c_1_reset"
private let kGraphURI            = "https://fabrikamb2chello.azurewebsites.net/hello"
private let kScopes: [String]    = ["https://fabrikamb2c.onmicrosoft.com/helloapi/demo.read"]
```

Then update the URL scheme in [`Info.plist`](Testing-MSAL-SwiftUI/Info.plist) to `msal<your-client-id>`. MSAL builds its redirect URI as `msal<client-id>://auth` when you pass `redirectUri: nil`, and sign-in fails at the redirect step if the scheme is not registered. That mismatch is the single most common reason a first B2C integration fails.

## The parts of B2C that trip people up

**A "policy" is a whole user flow, not a setting.** B2C hands you a hosted UI per flow (sign-up/sign-in, edit profile, reset password) and each one is a separate authority URL. That is why there are three policy constants above and not one.

**The authority URL encodes the policy:**

```
https://<host>/tfp/<tenant>/<policy>
```

Every token call has to target the authority for the flow it belongs to. Calling `acquireToken` against the sign-in authority and then expecting an edit-profile result is a common early mistake.

**Silent first, interactive as fallback.** `acquireTokenSilent` uses the cached refresh token and shows no UI. When it fails with `MSALError.interactionRequired` (expired refresh token, changed password, revoked consent), you fall back to `acquireToken`, which presents the web view. `refreshToken()` in the view model shows the full pattern.

**Password reset arrives as an error, not a flow.** B2C signals "this user asked to reset their password" by failing the sign-in with a specific error code, which you catch and answer by launching the reset policy.

## Notes on the SwiftUI side

The MSAL calls are all in `MainScreenViewModel`; `ContentView` is only buttons and a log panel. Two details that matter if you are adapting this:

- The view model is an `ObservableObject` with `@Published var loggingText`, and the view holds it as `@StateObject`. All three are required. A plain `let viewModel = MainScreenViewModel()` compiles and gives you a panel that never updates.
- MSAL's completion handlers are not guaranteed to run on the main thread. Every log write goes through a helper that hops to main first, and the interactive retry inside `refreshToken` dispatches to main before touching `UIApplication`.

## Credits

Configuration and B2C flow follow [Microsoft's official iOS B2C sample](https://github.com/Azure-Samples/active-directory-b2c-ios-swift-native-msal). This repository adds the SwiftUI and view-model layer.

Built because a client was stuck on B2C and there was no SwiftUI reference to point them at. Published in case it saves someone else the same afternoon.

## License

MIT.
