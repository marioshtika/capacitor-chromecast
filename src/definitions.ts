import type { PluginListenerHandle } from '@capacitor/core';

export interface InitializeOptions {
  /**
   * Google Cast receiver application ID from the Google Cast Developer Console.
   *
   * This must be an 8-character hexadecimal application ID such as `CC1AD845`.
   */
  receiverApplicationId: string;
}

export interface LoadMediaOptions {
  /**
   * Absolute URL of the media to load on the connected Chromecast device.
   */
  url: string;
}

export type SessionState = 'connecting' | 'connected' | 'disconnected';

export interface SessionStateChangedEvent {
  state: SessionState;
}

export interface ChromecastPlugin {
  /**
   * Initializes the native Google Cast SDK with your receiver application ID.
   *
   * Call this once during application startup, or configure the same value in
   * `capacitor.config.*` under `plugins.Chromecast.receiverApplicationId`.
   */
  initialize(options: InitializeOptions): Promise<void>;

  /**
   * Opens the official native Google Cast device picker.
   */
  show(): Promise<void>;

  /**
   * Loads media from a URL on the currently connected Chromecast device.
   */
  loadMedia(options: LoadMediaOptions): Promise<void>;

  /**
   * Returns whether there is an active Chromecast device connection.
   */
  isConnected(): Promise<boolean>;

  addListener(
    eventName: 'sessionStateChanged',
    listenerFunc: (event: SessionStateChangedEvent) => void,
  ): Promise<PluginListenerHandle>;

  removeAllListeners(): Promise<void>;
}
