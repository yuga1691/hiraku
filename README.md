# hiraku

HIRAKU app.

## Discord notification architecture (Step2)

Discord notifications are now sent through Firebase Cloud Functions.

Flow:
- Flutter app -> Firebase Callable Function (`sendDiscordNotification`) -> Discord Webhook

Security policy:
- Do not store Discord Webhook URL in Flutter source.
- Do not store Discord Webhook URL in Git.
- Store Webhook URL only as a Cloud Functions Secret.

## Files added for Functions

- `functions/package.json`
- `functions/tsconfig.json`
- `functions/src/index.ts`
- `functions/.gitignore`

## Firebase Functions initialization

If Functions were not initialized yet, run this once from project root:

```bash
firebase init functions
```

When prompted:
- Language: TypeScript
- ESLint: optional
- Install dependencies: Yes

If `functions/` already exists (this repository), skip re-initialization.

## Secret setup (Discord Webhook URL)

Set Discord Webhook URL as a secret:

```bash
firebase functions:secrets:set DISCORD_WEBHOOK_URL
```

Then paste the webhook URL when prompted.

To deploy the function:

```bash
firebase deploy --only functions
```

## Local testing (Emulator)

Install Functions dependencies:

```bash
cd functions
npm install
npm run build
```

Start emulator from project root:

```bash
firebase emulators:start --only functions
```

Notes:
- Callable function auth is required. Test with a signed-in user in app.
- For local tests without real Discord posting, use a test webhook only.

## Flutter side integration

Flutter calls:
- `FirebaseFunctions.instanceFor(region: 'asia-northeast1')`
- callable name: `sendDiscordNotification`

Required package:
- `cloud_functions`

After updating `pubspec.yaml`, run:

```bash
flutter pub get
```

## Rotation procedure for old leaked webhook

1. Open Discord server settings -> Integrations -> Webhooks.
2. Delete the leaked webhook URL.
3. Create a new webhook.
4. Register the new URL via:
   `firebase functions:secrets:set DISCORD_WEBHOOK_URL`
5. Redeploy:
   `firebase deploy --only functions`

## Operational notes

- Function region is fixed to `asia-northeast1`.
- Auth is required (`unauthenticated` if not signed in).
- Basic rate limit: one send per user per 10 seconds.
- `@everyone` and `@here` are neutralized and Discord `allowed_mentions` is disabled.
