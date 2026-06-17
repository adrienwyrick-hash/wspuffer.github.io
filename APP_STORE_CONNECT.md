# App Store Connect Submission Checklist — WSPuffer

Bundle ID: `com.wyrickstudios.WSPuffer`

## 1. Apple Developer / App Store Connect setup

- [ ] Paid Apple Developer Program membership active ($99/yr)
- [ ] App ID `com.wyrickstudios.WSPuffer` registered in [Apple Developer portal](https://developer.apple.com/account/resources/identifiers/list)
- [ ] App created in [App Store Connect](https://appstoreconnect.apple.com/) with the same Bundle ID
- [ ] In Xcode → App target → Signing & Capabilities: add **In-App Purchase** capability

## 2. In-app purchase products

Create three **Non-Consumable** IAPs in App Store Connect → Your App → Monetization → In-App Purchases. The product IDs MUST match the JS — do not change them.

| Reference Name | Product ID                                          | Price |
|----------------|-----------------------------------------------------|-------|
| Clownfish      | `com.wyrickstudios.WSPuffer.clownfish`              | $0.99 |
| Swordfish      | `com.wyrickstudios.WSPuffer.swordfish`              | $0.99 |
| Shark          | `com.wyrickstudios.WSPuffer.shark`                  | $0.99 |

For each product:
- [ ] Localized display name (e.g., "Clownfish")
- [ ] Localized description (e.g., "Adds Clownfish as a playable character.")
- [ ] 1024×1024 review screenshot showing the character in the game
- [ ] Submit for review with the first build

## 3. App Privacy (App Store Connect → App Privacy)

- [ ] Click "Get Started"
- [ ] Select **Data Not Collected**
- [ ] Privacy Policy URL: **https://wspuffer.com/privacy.html**

## 4. App Information

- [ ] App Name: WSPuffer
- [ ] Subtitle: e.g., "Tap to puff. Squeeze through coral."
- [ ] Primary Category: Games
- [ ] Secondary Category: Arcade
- [ ] Age Rating: 4+
- [ ] Contains In-App Purchases: Yes
- [ ] Pricing: Free

## 5. Screenshots required

- [ ] iPhone 6.7" (1290×2796): 3+ screenshots
- [ ] iPhone 6.5" or smaller: 3+ (or reuse 6.7" set per Apple's current rules)
- [ ] iPad Pro 12.9" (2048×2732): 3+ screenshots (only if iPad supported)

## 6. Build upload

- [ ] In Xcode: Product → Archive
- [ ] Distribute App → App Store Connect → Upload
- [ ] Wait for processing (~15 min)
- [ ] Select build in App Store Connect → App Store → "+ Version" → Build section

## 7. App Review Information

- [ ] Sign-in not required ✅
- [ ] Contact info (name, email, phone)
- [ ] Notes: "Free game with optional cosmetic IAPs. No accounts. No data collected. Tested with Sandbox account."

## 8. Local testing (before upload)

- [ ] Edit the App scheme: Run → Options → StoreKit Configuration → `Products.storekit`
- [ ] Run on a real device (StoreKit IAPs require iOS 15+; simulator works for the config file path but real device is required for Apple review)
- [ ] Buy each IAP, then delete the app and tap Restore Purchases — confirm characters re-unlock
- [ ] Create a Sandbox Tester account in App Store Connect → Users and Access → Sandbox Testers and test the real StoreKit path too

## 9. Final pre-submit

- [ ] Privacy Policy hosted at a public URL (e.g., GitHub Pages or your domain) and pasted into App Store Connect
- [ ] `ITSAppUsesNonExemptEncryption = NO` set in Info.plist (already done in this repo)
- [ ] `PrivacyInfo.xcprivacy` present in App target (already done in this repo)
- [ ] Verified Restore Purchases works
- [ ] Submit for Review
