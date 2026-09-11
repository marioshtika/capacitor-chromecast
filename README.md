# capacitor-chromecast

A Capacitor plugin that opens Google Cast / Chromecast native picker from JavaScript or TypeScript.

## Compatibility

| Plugin version | Capacitor compatibility | Maintained |
| -------------- | ----------------------- | ---------- |
| v8.\*.\*       | v8.\*.\*                | ✅         |

## Install

```bash
npm install capacitor-chromecast
npx cap sync
```

## Initialization

You must provide your Google Cast receiver application ID either in JavaScript or in Capacitor config.

### JavaScript initialization

```typescript
import { Chromecast } from 'capacitor-chromecast';

await Chromecast.initialize({
  receiverApplicationId: 'YOUR_RECEIVER_APPLICATION_ID',
});
```

### Capacitor config initialization

You can either modify your `capacitor.config.ts` file
```typescript
import { CapacitorConfig } from '@capacitor/cli';

export default CapacitorConfig({
  plugins: {
    Chromecast: {
      receiverApplicationId: 'YOUR_RECEIVER_APPLICATION_ID',
    },
  },
});
```
or your `capacitor.config.json` file
```typescript
{
  plugins: {
    Chromecast: {
      receiverApplicationId: "YOUR_RECEIVER_APPLICATION_ID"
    }
  }
}
```

The receiver application ID must be an 8-character hexadecimal Google Cast application ID.

## Basic usage

```typescript
import { Chromecast } from 'capacitor-chromecast';

await Chromecast.initialize({
  receiverApplicationId: 'YOUR_RECEIVER_APPLICATION_ID',
});

await Chromecast.show();
```

## iOS setup

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

## API

<docgen-index>

* [`initialize(...)`](#initialize)
* [`show()`](#show)
* [`addListener('sessionStateChanged', ...)`](#addlistenersessionstatechanged-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initialize(...)

```typescript
initialize(options: InitializeOptions) => Promise<void>
```

Initializes the native Google Cast SDK with your receiver application ID.

Call this once during application startup, or configure the same value in Capacitor config.

| Param         | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`options`** | <code><a href="#initializeoptions">InitializeOptions</a></code> |

--------------------


### show()

```typescript
show() => Promise<void>
```

Opens the official native Google Cast device picker.

--------------------


### addListener('sessionStateChanged', ...)

```typescript
addListener(eventName: 'sessionStateChanged', listenerFunc: (event: SessionStateChangedEvent) => void) => Promise<PluginListenerHandle>
```

| Param              | Type                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'sessionStateChanged'</code>                                                                |
| **`listenerFunc`** | <code>(event: <a href="#sessionstatechangedevent">SessionStateChangedEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

--------------------


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