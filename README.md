# capacitor-chromecast

Capacitor 8 plugin for opening the official native Google Cast / Chromecast device picker from Ionic, Angular, and other Capacitor apps.

The primary API is intentionally simple:

```ts
import { Chromecast } from 'capacitor-chromecast';

await Chromecast.show();
```

## What this plugin does

- Uses the official Google Cast Sender SDKs on Android and iOS
- Opens the native Google Cast device picker provided by those SDKs
- Lets your Capacitor app trigger the picker from any JavaScript button handler
- Keeps the public API small today while leaving room for future media controls

This plugin does **not** implement custom Chromecast discovery, custom mDNS logic, a custom HTML picker, or the Cast protocol manually.

## Capacitor 8 requirement

`capacitor-chromecast` targets **Capacitor 8**.

## Install

```bash
npm install capacitor-chromecast
npx cap sync
```

## Initialization

You must provide your Google Cast receiver application ID either in JavaScript or in Capacitor config.

### JavaScript initialization

```ts
import { Chromecast } from 'capacitor-chromecast';

await Chromecast.initialize({
  receiverApplicationId: 'YOUR_RECEIVER_APPLICATION_ID',
});
```

### Capacitor config initialization

```ts
/// <reference types="@capacitor/cli" />

import { defineConfig } from '@capacitor/cli';

export default defineConfig({
  plugins: {
    Chromecast: {
      receiverApplicationId: 'YOUR_RECEIVER_APPLICATION_ID',
    },
  },
});
```

The receiver application ID must be an 8-character hexadecimal Google Cast application ID.

## `Chromecast.show()`

After initialization, call `show()` to open the official native Cast device picker:

```ts
import { Chromecast } from 'capacitor-chromecast';

await Chromecast.initialize({
  receiverApplicationId: 'YOUR_RECEIVER_APPLICATION_ID',
});

await Chromecast.show();
```

## Ionic / Angular example

```ts
import { Component } from '@angular/core';
import { Chromecast } from 'capacitor-chromecast';

@Component({
  selector: 'app-player',
  template: ` <ion-button (click)="openChromecast()"> Chromecast </ion-button> `,
})
export class PlayerPage {
  async openChromecast() {
    await Chromecast.initialize({
      receiverApplicationId: 'YOUR_RECEIVER_APPLICATION_ID',
    });

    await Chromecast.show();
  }
}
```

## Android setup

Android integration uses the official Google Cast Android Sender SDK and Cast framework.

Included by the plugin:

- `com.google.android.gms:play-services-cast-framework`
- `androidx.mediarouter:mediarouter`
- Cast `OptionsProvider` manifest registration
- `MediaTransferReceiver` manifest registration
- required network and Wi-Fi permissions for Cast discovery

No custom device discovery UI is required in your app.

## iOS setup

iOS integration uses the official Google Cast iOS Sender SDK APIs:

- `GCKCastContext`
- `GCKCastOptions`
- `GCKDiscoveryCriteria`
- `GCKUICastButton`
- `GCKSessionManager`

The plugin package supports modern Capacitor 8 SwiftPM integration and also includes a CocoaPods spec.

### Required Info.plist entries

Google Cast discovery on iOS requires local-network and Bonjour declarations in the consuming app's `Info.plist`.
Add:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses Google Cast to discover and connect to nearby devices.</string>
<key>NSBonjourServices</key>
<array>
  <string>_googlecast._tcp</string>
  <string>_YOUR_RECEIVER_APPLICATION_ID._googlecast._tcp</string>
</array>
```

If you use the full Bluetooth-enabled Google Cast SDK in your app setup, Google may also require Bluetooth-related usage descriptions. Review the latest Google Cast iOS setup guidance for your chosen SDK distribution.

## Google Cast Developer Console setup

You need a valid Google Cast receiver application ID.

1. Create or register your receiver in the Google Cast Developer Console.
2. Copy the receiver application ID.
3. Use `YOUR_RECEIVER_APPLICATION_ID` in `Chromecast.initialize(...)` or in `capacitor.config.*`.

The receiver application ID is never hard-coded by this plugin.

## Permissions

### Android

The plugin contributes the network and Wi-Fi permissions used by Google Cast discovery through the Android library manifest.

### iOS

The consuming application must add the required `NSLocalNetworkUsageDescription` and `NSBonjourServices` entries to its own `Info.plist`.

## Web limitations

Native Chromecast support is not implemented on the web.

Calling `initialize()` or `show()` on the web throws:

```text
Chromecast is not supported on the web platform.
```

## Session events

The plugin emits a standard Capacitor listener event for future-ready session state updates:

```ts
const listener = await Chromecast.addListener('sessionStateChanged', (event) => {
  console.log(event.state);
});
```

Possible states today:

- `connecting`
- `connected`
- `disconnected`

## Troubleshooting

- **`NOT_INITIALIZED`**: call `Chromecast.initialize(...)` first or configure `plugins.Chromecast.receiverApplicationId`.
- **`INVALID_RECEIVER_APPLICATION_ID`**: use a valid 8-character hexadecimal Cast receiver application ID.
- **`CAST_NOT_AVAILABLE`**: verify Google Play services / Cast availability on Android and Cast SDK integration on iOS.
- **No devices appear on iOS**: confirm `NSLocalNetworkUsageDescription` and both Bonjour service entries are present, including your real receiver application ID.

## Future media-casting capabilities

The repository is structured so future Cast functionality can be added without breaking the simple `show()` API. Likely follow-up APIs include:

- `isConnected()`
- `getSession()`
- `disconnect()`
- `loadMedia()`
- `play()`
- `pause()`
- `stop()`
- `seek()`
- `setVolume()`
- `getMediaStatus()`

## API

<docgen-index>

- [`initialize(...)`](#initialize)
- [`show()`](#show)
- [`addListener('sessionStateChanged', ...)`](#addlistenersessionstatechanged-)
- [`removeAllListeners()`](#removealllisteners)
- [Interfaces](#interfaces)
- [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initialize(...)

```typescript
initialize(options: InitializeOptions) => Promise<void>
```

Initializes the native Google Cast SDK with your receiver application ID.

Call this once during application startup, or configure the same value in
`capacitor.config.*` under `plugins.Chromecast.receiverApplicationId`.

| Param         | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`options`** | <code><a href="#initializeoptions">InitializeOptions</a></code> |

---

### show()

```typescript
show() => Promise<void>
```

Opens the official native Google Cast device picker.

---

### addListener('sessionStateChanged', ...)

```typescript
addListener(eventName: 'sessionStateChanged', listenerFunc: (event: SessionStateChangedEvent) => void) => Promise<PluginListenerHandle>
```

| Param              | Type                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'sessionStateChanged'</code>                                                                |
| **`listenerFunc`** | <code>(event: <a href="#sessionstatechangedevent">SessionStateChangedEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

---

### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

---

### Interfaces

#### InitializeOptions

| Prop                        | Type                | Description                                                                                                                                            |
| --------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`receiverApplicationId`** | <code>string</code> | Google Cast receiver application ID from the Google Cast Developer Console. This must be an 8-character hexadecimal application ID such as `CC1AD845`. |

#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |

#### SessionStateChangedEvent

| Prop        | Type                                                  |
| ----------- | ----------------------------------------------------- |
| **`state`** | <code><a href="#sessionstate">SessionState</a></code> |

### Type Aliases

#### SessionState

<code>'connecting' | 'connected' | 'disconnected'</code>

</docgen-api>
