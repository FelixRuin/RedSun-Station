/**
 * @file
 * Server-side state persistence for tgui panel.
 * Debounces and sends combined settings + chat page state to DM
 * to survive WebView2 storage loss on reconnect.
 *
 * @copyright 2025
 * @license MIT
 */

import { selectChat } from './chat/selectors';
import { selectSettings } from './settings/selectors';

let saveTimer = null;
const DEBOUNCE_MS = 3000;

/**
 * Builds a JSON string of the current panel state for server persistence.
 * Excludes transient fields (theme, view, scrollTracking, unreadCount, createdAt).
 */
const buildStateJson = (store) => {
  const settings = selectSettings(store.getState());
  const chat = selectChat(store.getState());

  // Strip theme (has its own persistence) and view (transient UI state)
  const { theme, view, ...settingsToSave } = settings;

  const chatToSave = {
    version: chat.version,
    currentPageId: chat.currentPageId,
    pages: chat.pages,
    pageById: {},
  };

  for (const id of chat.pages) {
    const page = chat.pageById[id];
    if (page) {
      // Strip transient fields
      const { unreadCount, createdAt, ...pageData } = page;
      chatToSave.pageById[id] = pageData;
    }
  }

  return JSON.stringify({ v: 1, settings: settingsToSave, chat: chatToSave });
};

/**
 * Schedules a debounced save of panel state to the server.
 * Multiple calls within DEBOUNCE_MS collapse into one.
 */
export const scheduleSaveToServer = (store) => {
  if (saveTimer) {
    clearTimeout(saveTimer);
  }
  saveTimer = setTimeout(() => {
    saveTimer = null;
    try {
      const stateJson = buildStateJson(store);
      Byond.topic({
        tgui: 1,
        window_id: window.__windowId__,
        type: 'panel/state_set',
        payload: JSON.stringify({ state: stateJson }),
      });
    }
    catch (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to save panel state to server:', err);
    }
  }, DEBOUNCE_MS);
};
