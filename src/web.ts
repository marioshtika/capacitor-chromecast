import { WebPlugin } from '@capacitor/core';

import type { ChromecastPlugin, InitializeOptions, LoadMediaOptions } from './definitions.js';
import { createChromecastError, normalizeReceiverApplicationId } from './errors.js';

const unsupportedPlatformError = () =>
  createChromecastError('UNSUPPORTED_PLATFORM', 'Chromecast is not supported on the web platform.');

export class ChromecastWeb extends WebPlugin implements ChromecastPlugin {
  async initialize(options: InitializeOptions): Promise<void> {
    normalizeReceiverApplicationId(options.receiverApplicationId);
    throw unsupportedPlatformError();
  }

  async show(): Promise<void> {
    throw unsupportedPlatformError();
  }

  async loadMedia(options: LoadMediaOptions): Promise<void> {
    void options;
    throw unsupportedPlatformError();
  }
}
