export type ChromecastErrorCode =
  | 'NOT_INITIALIZED'
  | 'INVALID_RECEIVER_APPLICATION_ID'
  | 'INVALID_MEDIA_URL'
  | 'CAST_NOT_AVAILABLE'
  | 'CAST_CONNECTION_FAILED'
  | 'CAST_SESSION_NOT_CONNECTED'
  | 'MEDIA_LOAD_FAILED'
  | 'UNSUPPORTED_PLATFORM';

export const RECEIVER_APPLICATION_ID_VALIDATION_MESSAGE =
  'Receiver application ID must be an 8-character hexadecimal Google Cast receiver application ID.';

const RECEIVER_APPLICATION_ID_PATTERN = /^[A-F0-9]{8}$/;

export const createChromecastError = (
  code: ChromecastErrorCode,
  message: string,
): Error & { code: ChromecastErrorCode } => {
  const error = new Error(message) as Error & { code: ChromecastErrorCode };
  error.name = 'ChromecastError';
  error.code = code;
  return error;
};

export const normalizeReceiverApplicationId = (value: string | null | undefined): string => {
  const normalized = value?.trim().toUpperCase();

  if (normalized && RECEIVER_APPLICATION_ID_PATTERN.test(normalized)) {
    return normalized;
  }

  throw createChromecastError('INVALID_RECEIVER_APPLICATION_ID', RECEIVER_APPLICATION_ID_VALIDATION_MESSAGE);
};
