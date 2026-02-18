import { createMainPage } from './model';
import { ChatRenderer } from './renderer';

const setupScrollMetrics = (node, {
  scrollHeight = 1000,
  clientHeight = 400,
  scrollTop = 0,
} = {}) => {
  const metrics = {
    scrollHeight,
    clientHeight,
    scrollTop,
  };
  Object.defineProperty(node, 'scrollHeight', {
    configurable: true,
    get: () => metrics.scrollHeight,
  });
  Object.defineProperty(node, 'clientHeight', {
    configurable: true,
    get: () => metrics.clientHeight,
  });
  Object.defineProperty(node, 'scrollTop', {
    configurable: true,
    get: () => metrics.scrollTop,
    set: value => {
      metrics.scrollTop = value;
    },
  });
  return metrics;
};

describe('ChatRenderer', () => {
  let originalQueueMicrotask;

  beforeEach(() => {
    originalQueueMicrotask = global.queueMicrotask;
    global.queueMicrotask = jest.fn(callback => callback());
    jest.spyOn(global, 'setInterval').mockImplementation(() => 0);
  });

  afterEach(() => {
    global.queueMicrotask = originalQueueMicrotask;
    jest.restoreAllMocks();
  });

  test('mount uses explicitly provided scroll node', () => {
    const renderer = new ChatRenderer();
    const rootNode = document.createElement('div');
    const scrollNode = document.createElement('div');
    setupScrollMetrics(scrollNode);

    renderer.mount(rootNode, scrollNode);

    expect(renderer.scrollNode).toBe(scrollNode);
  });

  test('treats near-bottom offset as tracked', () => {
    const renderer = new ChatRenderer();
    const scrollNode = document.createElement('div');
    const metrics = setupScrollMetrics(scrollNode, {
      scrollTop: 560,
    });

    renderer.scrollNode = scrollNode;
    renderer.scrollTracking = false;

    renderer.handleScroll();
    expect(renderer.scrollTracking).toBe(true);

    metrics.scrollTop = 500;
    renderer.handleScroll();
    expect(renderer.scrollTracking).toBe(false);
  });

  test('auto-scrolls only when tracking is enabled', () => {
    const renderer = new ChatRenderer();
    const scrollNode = document.createElement('div');
    const metrics = setupScrollMetrics(scrollNode, {
      scrollHeight: 1000,
      scrollTop: 600,
    });

    renderer.rootNode = document.createElement('div');
    renderer.scrollNode = scrollNode;
    renderer.loaded = true;
    renderer.page = createMainPage();
    renderer.scrollTracking = true;

    renderer.processBatch([{
      text: 'first message',
    }]);
    expect(metrics.scrollTop).toBe(1000);

    metrics.scrollTop = 300;
    renderer.scrollTracking = false;
    renderer.processBatch([{
      text: 'second message',
    }]);
    expect(metrics.scrollTop).toBe(300);
  });
});
