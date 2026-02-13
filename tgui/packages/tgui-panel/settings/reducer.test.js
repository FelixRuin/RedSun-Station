import { loadSettings } from './actions';
import { settingsReducer } from './reducer';

describe('settingsReducer', () => {
  test('loadSettings does not mutate payload objects', () => {
    const payload = {
      version: 1,
      theme: 'dark',
      view: {
        visible: true,
      },
    };

    const nextState = settingsReducer(undefined, loadSettings(payload));

    expect(nextState.theme).toBe('dark');
    expect(payload.view).toEqual({
      visible: true,
    });
  });
});
