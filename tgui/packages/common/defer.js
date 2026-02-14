/**
 * Schedules callback execution on the next turn with browser-safe fallbacks.
 *
 * @param {Function} callback
 * @param {...any} args
 */
export const defer = (callback, ...args) => {
  if (typeof setImmediate === 'function') {
    return setImmediate(callback, ...args);
  }
  if (typeof queueMicrotask === 'function') {
    queueMicrotask(() => callback(...args));
    return undefined;
  }
  return setTimeout(callback, 0, ...args);
};
