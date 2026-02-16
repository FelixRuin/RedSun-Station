/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { storage } from 'common/storage';
import { vecAdd, vecMultiply, vecScale, vecSubtract } from 'common/vector';

import { createLogger } from './logging';

const logger = createLogger('drag');
const pixelRatio = window.devicePixelRatio ?? 1;
const now = () => Date.now ? Date.now() : +new Date();

let windowKey = window.__windowId__;
let dragging = false;
let resizing = false;
let screenOffset = [0, 0];
let screenOffsetPromise;
let dragPointOffset;
let resizeMatrix;
let initialSize;
let size;
let initialGeometryReady = false;
let resolveInitialGeometryReady;
let initialGeometryReadyPromise;

export const resetInitialGeometryReady = () => {
  initialGeometryReady = false;
  initialGeometryReadyPromise = new Promise(resolve => {
    resolveInitialGeometryReady = resolve;
  });
};

const markInitialGeometryReady = () => {
  if (initialGeometryReady) {
    return;
  }
  initialGeometryReady = true;
  resolveInitialGeometryReady();
};

export const setWindowKey = key => {
  windowKey = key;
};

export const waitForInitialGeometryReady = () => initialGeometryReadyPromise;
resetInitialGeometryReady();

export const getWindowPosition = () => [
  window.screenLeft * pixelRatio,
  window.screenTop * pixelRatio,
];

export const getWindowSize = () => [
  window.innerWidth * pixelRatio,
  window.innerHeight * pixelRatio,
];

const SIZE_APPLY_TIMEOUT_MS = 250;
const SIZE_APPLY_EPSILON = Math.max(2, Math.ceil(pixelRatio * 2));

const isWindowSizeApplied = targetSize => {
  const currentSize = getWindowSize();
  return Math.abs(currentSize[0] - targetSize[0]) <= SIZE_APPLY_EPSILON
    && Math.abs(currentSize[1] - targetSize[1]) <= SIZE_APPLY_EPSILON;
};

const waitForWindowSizeApplied = targetSize => {
  const startedAt = now();
  const startSize = getWindowSize();
  if (isWindowSizeApplied(targetSize)) {
    return Promise.resolve({
      matched: true,
      reason: 'alreadyApplied',
      elapsedMs: now() - startedAt,
      targetSize,
      startSize,
      endSize: startSize,
      resizeEvents: 0,
    });
  }
  return new Promise(resolve => {
    let done = false;
    let resizeEvents = 0;
    let timeoutId = null;
    let rafId = null;
    let onResize;
    const finish = (reason, matched) => {
      if (done) {
        return;
      }
      done = true;
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      if (rafId) {
        cancelAnimationFrame(rafId);
      }
      window.removeEventListener('resize', onResize);
      resolve({
        matched,
        reason,
        elapsedMs: now() - startedAt,
        targetSize,
        startSize,
        endSize: getWindowSize(),
        resizeEvents,
      });
    };
    const maybeFinish = reason => {
      if (isWindowSizeApplied(targetSize)) {
        finish(reason, true);
      }
    };
    onResize = () => {
      resizeEvents += 1;
      maybeFinish('resize');
    };
    const onFrame = () => {
      if (done) {
        return;
      }
      maybeFinish('animationFrame');
      if (!done) {
        rafId = requestAnimationFrame(onFrame);
      }
    };
    window.addEventListener('resize', onResize);
    maybeFinish('immediateCheck');
    if (done) {
      return;
    }
    rafId = requestAnimationFrame(onFrame);
    timeoutId = setTimeout(() => {
      finish('timeout', false);
    }, SIZE_APPLY_TIMEOUT_MS);
  });
};

export const setWindowPosition = vec => {
  const byondPos = vecAdd(vec, screenOffset);
  return Byond.winset(window.__windowId__, {
    pos: byondPos[0] + ',' + byondPos[1],
  });
};

export const setWindowSize = vec => {
  return Byond.winset(window.__windowId__, {
    size: vec[0] + 'x' + vec[1],
  });
};

export const getScreenPosition = () => [
  0 - screenOffset[0],
  0 - screenOffset[1],
];

export const getScreenSize = () => [
  window.screen.availWidth * pixelRatio,
  window.screen.availHeight * pixelRatio,
];

/**
 * Moves an item to the top of the recents array, and keeps its length
 * limited to the number in `limit` argument.
 *
 * Uses a strict equality check for comparisons.
 *
 * Returns new recents and an item which was trimmed.
 */
const touchRecents = (recents, touchedItem, limit = 50) => {
  const nextRecents = [touchedItem];
  let trimmedItem;
  for (let i = 0; i < recents.length; i++) {
    const item = recents[i];
    if (item === touchedItem) {
      continue;
    }
    if (nextRecents.length < limit) {
      nextRecents.push(item);
    }
    else {
      trimmedItem = item;
    }
  }
  return [nextRecents, trimmedItem];
};

export const storeWindowGeometry = async () => {
  logger.log('storing geometry');
  const geometry = {
    pos: getWindowPosition(),
    size: getWindowSize(),
  };
  storage.set(windowKey, geometry);
  // Update the list of stored geometries
  const [geometries, trimmedKey] = touchRecents(
    await storage.get('geometries') || [],
    windowKey);
  if (trimmedKey) {
    storage.remove(trimmedKey);
  }
  storage.set('geometries', geometries);
};

export const recallWindowGeometry = async (options = {}) => {
  let geometry;
  let geometryReadyForReveal = false;
  try {
    const rawScale = options.scale;
    const hasScale = rawScale !== undefined
      && rawScale !== null
      && rawScale !== '';
    const scaleValue = Number(rawScale);
    const validScale = hasScale
      && Number.isFinite(scaleValue)
      && scaleValue > 0;
    const useScaledMode = hasScale && validScale;
    const displayScale = pixelRatio;
    if (useScaledMode) {
      // Keep neutral browser zoom in DPI-aware mode.
      document.body.style.zoom = '100%';
      document.documentElement.style.removeProperty('--scaling-amount');
    }
    else {
      // Legacy fallback for invalid/missing scale payloads.
      document.body.style.zoom = `${100 / pixelRatio}%`;
      document.documentElement.style.setProperty('--scaling-amount', pixelRatio.toString());
    }
    // Only recall geometry in fancy mode
    if (options.fancy) {
      try {
        geometry = await storage.get(windowKey);
      }
      catch {}
    }
    if (geometry) {
      logger.log('recalled geometry:', geometry);
    }
    let pos = geometry?.pos || options.pos;
    let size = options.size;
    // Convert size from css-pixels to display-pixels if UI scaling mode is enabled.
    if (useScaledMode && size) {
      size = [size[0] * displayScale, size[1] * displayScale];
    }
    // Wait until screen offset gets resolved
    await screenOffsetPromise;
    const areaAvailable = useScaledMode
      ? [
        window.screen.availWidth * displayScale,
        window.screen.availHeight * displayScale,
      ]
      : [
        window.screen.availWidth,
        window.screen.availHeight,
      ];
    // Set window size
    if (size) {
      // Constraint size to not exceed available screen area.
      size = [
        Math.min(areaAvailable[0], size[0]),
        Math.min(areaAvailable[1], size[1]),
      ];
      setWindowSize(size);
      const sizeApplyResult = await waitForWindowSizeApplied(size);
      geometryReadyForReveal = sizeApplyResult.matched;
      if (!sizeApplyResult.matched) {
        logger.warn('window size was not applied before reveal gate timeout', sizeApplyResult);
      }
    }
    else {
      geometryReadyForReveal = true;
    }
    // Set window position
    if (pos) {
      // Constraint window position if monitor lock was set in preferences.
      if (size && options.locked) {
        pos = constraintPosition(pos, size)[1];
      }
      setWindowPosition(pos);
    }
    // Set window position at the center of the screen.
    else if (size) {
      pos = vecAdd(
        vecScale(areaAvailable, 0.5),
        vecScale(size, -0.5),
        vecScale(screenOffset, -1.0));
      setWindowPosition(pos);
    }
  }
  finally {
    if (geometryReadyForReveal) {
      markInitialGeometryReady();
    }
  }
};

export const setupDrag = async () => {
  // Calculate screen offset caused by the windows taskbar
  const windowPosition = getWindowPosition();
  screenOffsetPromise = Byond.winget(window.__windowId__, 'pos')
    .then(pos => [
      pos.x - windowPosition[0],
      pos.y - windowPosition[1],
    ]);
  screenOffset = await screenOffsetPromise;
  logger.debug('screen offset', screenOffset);
};

/**
 * Constraints window position to safe screen area, accounting for safe
 * margins which could be a system taskbar.
 */
const constraintPosition = (pos, size) => {
  const screenPos = getScreenPosition();
  const screenSize = getScreenSize();
  const nextPos = [pos[0], pos[1]];
  let relocated = false;
  for (let i = 0; i < 2; i++) {
    const leftBoundary = screenPos[i];
    const rightBoundary = screenPos[i] + screenSize[i];
    if (pos[i] < leftBoundary) {
      nextPos[i] = leftBoundary;
      relocated = true;
    }
    else if (pos[i] + size[i] > rightBoundary) {
      nextPos[i] = rightBoundary - size[i];
      relocated = true;
    }
  }
  return [relocated, nextPos];
};

export const dragStartHandler = event => {
  logger.log('drag start');
  dragging = true;
  dragPointOffset = vecSubtract(
    [event.screenX * pixelRatio, event.screenY * pixelRatio],
    getWindowPosition());
  // Focus click target
  event.target?.focus();
  document.addEventListener('mousemove', dragMoveHandler);
  document.addEventListener('mouseup', dragEndHandler);
  dragMoveHandler(event);
};

const dragEndHandler = event => {
  logger.log('drag end');
  dragMoveHandler(event);
  document.removeEventListener('mousemove', dragMoveHandler);
  document.removeEventListener('mouseup', dragEndHandler);
  dragging = false;
  storeWindowGeometry();
};

const dragMoveHandler = event => {
  if (!dragging) {
    return;
  }
  event.preventDefault();
  setWindowPosition(vecSubtract(
    [event.screenX * pixelRatio, event.screenY * pixelRatio],
    dragPointOffset));
};

export const resizeStartHandler = (x, y) => event => {
  resizeMatrix = [x, y];
  logger.log('resize start', resizeMatrix);
  resizing = true;
  dragPointOffset = vecSubtract(
    [event.screenX * pixelRatio, event.screenY * pixelRatio],
    getWindowPosition());
  initialSize = getWindowSize();
  // Focus click target
  event.target?.focus();
  document.addEventListener('mousemove', resizeMoveHandler);
  document.addEventListener('mouseup', resizeEndHandler);
  resizeMoveHandler(event);
};

const resizeEndHandler = event => {
  logger.log('resize end', size);
  resizeMoveHandler(event);
  document.removeEventListener('mousemove', resizeMoveHandler);
  document.removeEventListener('mouseup', resizeEndHandler);
  resizing = false;
  storeWindowGeometry();
};

const resizeMoveHandler = event => {
  if (!resizing) {
    return;
  }
  event.preventDefault();
  const currentOffset = vecSubtract(
    [event.screenX * pixelRatio, event.screenY * pixelRatio],
    getWindowPosition());
  const delta = vecSubtract(currentOffset, dragPointOffset);
  // Extra 1x1 area is added to ensure the browser can see the cursor.
  size = vecAdd(initialSize, vecMultiply(resizeMatrix, delta), [1, 1]);
  // Sane window size values
  size[0] = Math.max(size[0], 150 * pixelRatio);
  size[1] = Math.max(size[1], 50 * pixelRatio);
  setWindowSize(size);
};
