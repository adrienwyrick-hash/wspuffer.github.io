# WSPuffer

Pufferfish tap-dodger. Web + iOS via Capacitor.

## Run locally (browser)
```
npm run dev
```
Opens at http://localhost:5173

## Rebuild native after editing `www/`
```
npx cap sync
```

## Run on iOS device
```
npm run ios
```
Opens Xcode. Select your iPhone, click ▶.

## In-app purchases

Three Non-Consumable products at $0.99 each, configured in App Store Connect with these exact IDs:

- `com.wyrickstudios.WSPuffer.clownfish`
- `com.wyrickstudios.WSPuffer.swordfish`
- `com.wyrickstudios.WSPuffer.shark`

For local testing, the App scheme can point at `ios/App/App/Products.storekit` (Run → Options → StoreKit Configuration).

## App Store submission

See [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md) for the full submission checklist and [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the policy that needs to be hosted at a public URL.
