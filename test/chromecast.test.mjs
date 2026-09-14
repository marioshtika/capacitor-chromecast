import assert from 'node:assert/strict';
import test from 'node:test';

const { Chromecast } = await import('../dist/esm/index.js');
const { ChromecastClient } = await import('../dist/esm/chromecast.js');
const { ChromecastWeb } = await import('../dist/esm/web.js');

test('plugin import exposes initialize and show', () => {
  assert.equal(typeof Chromecast.initialize, 'function');
  assert.equal(typeof Chromecast.show, 'function');
  assert.equal(typeof Chromecast.loadMedia, 'function');
  assert.equal(typeof Chromecast.isConnected, 'function');
});

test('initialize normalizes the receiver application ID and deduplicates repeats', async () => {
  const initializeCalls = [];
  const client = new ChromecastClient({
    async initialize(options) {
      initializeCalls.push(options);
    },
    async show() {},
    async loadMedia() {},
    async isConnected() {
      return { isConnected: false };
    },
    async addListener() {
      return {
        remove() {},
      };
    },
    async removeAllListeners() {},
  });

  await client.initialize({ receiverApplicationId: ' cc1ad845 ' });
  await client.initialize({ receiverApplicationId: 'CC1AD845' });

  assert.deepEqual(initializeCalls, [{ receiverApplicationId: 'CC1AD845' }]);
});

test('initialize rejects invalid receiver application IDs', async () => {
  const client = new ChromecastClient({
    async initialize() {},
    async show() {},
    async loadMedia() {},
    async isConnected() {
      return { isConnected: false };
    },
    async addListener() {
      return {
        remove() {},
      };
    },
    async removeAllListeners() {},
  });

  await assert.rejects(
    () => client.initialize({ receiverApplicationId: 'invalid' }),
    (error) => error.code === 'INVALID_RECEIVER_APPLICATION_ID',
  );
});

test('show delegates to the native implementation', async () => {
  let showCalls = 0;
  const client = new ChromecastClient({
    async initialize() {},
    async show() {
      showCalls += 1;
    },
    async loadMedia() {},
    async isConnected() {
      return { isConnected: false };
    },
    async addListener() {
      return {
        remove() {},
      };
    },
    async removeAllListeners() {},
  });

  await client.show();

  assert.equal(showCalls, 1);
});

test('loadMedia delegates to the native implementation', async () => {
  const loadMediaCalls = [];
  const client = new ChromecastClient({
    async initialize() {},
    async show() {},
    async loadMedia(options) {
      loadMediaCalls.push(options);
    },
    async isConnected() {
      return { isConnected: false };
    },
    async addListener() {
      return {
        remove() {},
      };
    },
    async removeAllListeners() {},
  });

  const options = { url: 'https://example.com/video.mp4', metadata: { title: 'Video' } };

  await client.loadMedia(options);

  assert.equal(loadMediaCalls[0], options);
  assert.deepEqual(loadMediaCalls, [options]);
});

test('isConnected delegates to the native implementation', async () => {
  let isConnectedCalls = 0;
  const client = new ChromecastClient({
    async initialize() {},
    async show() {},
    async loadMedia() {},
    async isConnected() {
      isConnectedCalls += 1;
      return { isConnected: true };
    },
    async addListener() {
      return {
        remove() {},
      };
    },
    async removeAllListeners() {},
  });

  const isConnected = await client.isConnected();

  assert.equal(isConnectedCalls, 1);
  assert.equal(isConnected, true);
});

test('web initialize reports unsupported platform', async () => {
  const web = new ChromecastWeb();

  await assert.rejects(
    () => web.initialize({ receiverApplicationId: 'CC1AD845' }),
    (error) =>
      error.code === 'UNSUPPORTED_PLATFORM' &&
      error.message === 'Chromecast is not supported on the web platform.',
  );
});

test('web show reports unsupported platform', async () => {
  const web = new ChromecastWeb();

  await assert.rejects(
    () => web.show(),
    (error) =>
      error.code === 'UNSUPPORTED_PLATFORM' &&
      error.message === 'Chromecast is not supported on the web platform.',
  );
});

test('web loadMedia reports unsupported platform', async () => {
  const web = new ChromecastWeb();

  await assert.rejects(
    () => web.loadMedia({ url: 'https://example.com/video.mp4' }),
    (error) =>
      error.code === 'UNSUPPORTED_PLATFORM' &&
      error.message === 'Chromecast is not supported on the web platform.',
  );
});

test('web isConnected reports unsupported platform', async () => {
  const web = new ChromecastWeb();

  await assert.rejects(
    () => web.isConnected(),
    (error) =>
      error.code === 'UNSUPPORTED_PLATFORM' &&
      error.message === 'Chromecast is not supported on the web platform.',
  );
});
