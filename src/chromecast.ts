import { registerPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';

import type { ChromecastPlugin, InitializeOptions, LoadMediaOptions, SessionStateChangedEvent } from './definitions.js';
import { normalizeReceiverApplicationId } from './errors.js';

type NativeChromecastPlugin = {
  initialize(options: InitializeOptions): Promise<void>;
  show(): Promise<void>;
  loadMedia(options: LoadMediaOptions): Promise<void>;
  isConnected(): Promise<{ isConnected: boolean }>;
  addListener(
    eventName: 'sessionStateChanged',
    listenerFunc: (event: SessionStateChangedEvent) => void,
  ): Promise<PluginListenerHandle>;
  removeAllListeners(): Promise<void>;
};

const nativeChromecastPlugin = registerPlugin<NativeChromecastPlugin>('Chromecast', {
  web: () => import('./web.js').then((module) => new module.ChromecastWeb()),
});

export class ChromecastClient implements ChromecastPlugin {
  private initializedReceiverApplicationId?: string;
  private initializePromise?: Promise<void>;

  constructor(private readonly plugin: NativeChromecastPlugin = nativeChromecastPlugin) {}

  async initialize(options: InitializeOptions): Promise<void> {
    const receiverApplicationId = normalizeReceiverApplicationId(options.receiverApplicationId);

    if (this.initializedReceiverApplicationId === receiverApplicationId) {
      return;
    }

    if (this.initializePromise) {
      await this.initializePromise;

      if (this.initializedReceiverApplicationId === receiverApplicationId) {
        return;
      }
    }

    const initializePromise = this.plugin.initialize({ receiverApplicationId });
    this.initializePromise = initializePromise;

    try {
      await initializePromise;
      this.initializedReceiverApplicationId = receiverApplicationId;
    } finally {
      if (this.initializePromise === initializePromise) {
        this.initializePromise = undefined;
      }
    }
  }

  async show(): Promise<void> {
    await this.plugin.show();
  }

  async loadMedia(options: LoadMediaOptions): Promise<void> {
    await this.plugin.loadMedia(options);
  }

  async isConnected(): Promise<boolean> {
    const { isConnected } = await this.plugin.isConnected();
    return isConnected;
  }

  addListener(
    eventName: 'sessionStateChanged',
    listenerFunc: (event: SessionStateChangedEvent) => void,
  ): Promise<PluginListenerHandle> {
    return this.plugin.addListener(eventName, listenerFunc);
  }

  async removeAllListeners(): Promise<void> {
    await this.plugin.removeAllListeners();
  }
}

export const createChromecast = (): ChromecastPlugin => new ChromecastClient();
