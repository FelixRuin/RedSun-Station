/**
 * @file
 * @copyright 2025
 * @license MIT
 */

import { KEY_ENTER, KEY_ESCAPE } from 'common/keycodes';
import { Component, createRef } from 'inferno';

import { globalEvents, KeyEvent } from '../events';
import { Icon } from './Icon';

// CSS Custom Highlight API type declarations (not yet in standard TS lib).
// The Highlight constructor is a global (window.Highlight), NOT CSS.Highlight.
declare class Highlight {
  constructor(...ranges: AbstractRange[]);
  priority: number;
}

interface HighlightRegistry {
  set(name: string, highlight: Highlight): void;
  delete(name: string): boolean;
  clear(): void;
}

/** Checks if the CSS Custom Highlight API is available. */
const hasHighlightApi = (): boolean => {
  return typeof CSS !== 'undefined'
    && 'highlights' in CSS
    && typeof globalThis.Highlight === 'function';
};

/** Returns the global highlight registry, if available. */
const getHighlights = (): HighlightRegistry | null => {
  return hasHighlightApi()
    ? (CSS as unknown as { highlights: HighlightRegistry }).highlights
    : null;
};

// Inject ::highlight() styles via JS to bypass SCSS build pipeline
// (SCSS may strip unknown pseudo-elements during compilation).
let highlightStylesInjected = false;
const injectHighlightStyles = () => {
  if (highlightStylesInjected) {
    return;
  }
  highlightStylesInjected = true;
  const style = document.createElement('style');
  style.textContent = [
    '::highlight(findbar-matches) {',
    '  background-color: rgba(255, 255, 0, 0.35);',
    '  color: inherit;',
    '}',
    '::highlight(findbar-current) {',
    '  background-color: rgba(255, 165, 0, 0.7);',
    '  color: inherit;',
    '}',
  ].join('\n');
  document.head.appendChild(style);
};

type FindBarState = {
  visible: boolean;
  matchCount: number;
  currentMatch: number;
};

export class FindBar extends Component<{}, FindBarState> {
  state: FindBarState = {
    visible: false,
    matchCount: 0,
    currentMatch: -1,
  };

  private inputRef = createRef<HTMLInputElement>();
  private barRef = createRef<HTMLDivElement>();
  private matches: Range[] = [];

  componentDidMount() {
    globalEvents.on('findbar-toggle', this.handleToggle);
    globalEvents.on('key', this.handleGlobalKey);
    if (hasHighlightApi()) {
      injectHighlightStyles();
    }
  }

  componentWillUnmount() {
    globalEvents.off('findbar-toggle', this.handleToggle);
    globalEvents.off('key', this.handleGlobalKey);
    this.clearHighlights();
  }

  handleToggle = () => {
    if (this.state.visible) {
      this.inputRef.current?.focus();
      this.inputRef.current?.select();
    } else {
      this.setState({ visible: true, matchCount: 0, currentMatch: -1 }, () => {
        this.inputRef.current?.focus();
        this.inputRef.current?.select();
      });
    }
  };

  handleGlobalKey = (key: KeyEvent) => {
    if (
      key.isDown()
      && String(key) === 'Escape'
      && this.state.visible
    ) {
      this.handleClose();
    }
  };

  handleClose = () => {
    this.clearHighlights();
    this.matches = [];
    this.setState({ visible: false, matchCount: 0, currentMatch: -1 });
  };

  handleInputKeyDown = (e: KeyboardEvent) => {
    if (e.key === KEY_ENTER) {
      e.preventDefault();
      this.navigateMatch(e.shiftKey);
    }
    if (e.key === KEY_ESCAPE) {
      e.preventDefault();
      this.handleClose();
    }
  };

  handleInput = () => {
    const text = this.inputRef.current?.value || '';
    this.performSearch(text);
  };

  performSearch(text: string) {
    this.clearHighlights();

    if (!text) {
      this.matches = [];
      this.setState({ matchCount: 0, currentMatch: -1 });
      return;
    }

    this.matches = this.findTextRanges(text);
    const matchCount = this.matches.length;
    const currentMatch = matchCount > 0 ? 0 : -1;

    this.applyHighlights(currentMatch);
    this.setState({ matchCount, currentMatch });

    if (currentMatch >= 0) {
      this.scrollToMatch(currentMatch);
    }
  }

  findTextRanges(searchText: string): Range[] {
    const ranges: Range[] = [];
    const walker = document.createTreeWalker(
      document.body,
      NodeFilter.SHOW_TEXT,
    );
    const searchLower = searchText.toLowerCase();

    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (this.barRef.current?.contains(node)) {
        continue;
      }
      const text = node.textContent?.toLowerCase() || '';
      let pos = 0;
      while ((pos = text.indexOf(searchLower, pos)) !== -1) {
        const range = new Range();
        range.setStart(node, pos);
        range.setEnd(node, pos + searchText.length);
        ranges.push(range);
        pos += searchText.length;
      }
    }
    return ranges;
  }

  applyHighlights(currentIndex: number) {
    const registry = getHighlights();
    if (!registry || this.matches.length === 0) {
      return;
    }
    const allHighlight = new Highlight(...this.matches);
    allHighlight.priority = 0;
    registry.set('findbar-matches', allHighlight);

    if (currentIndex >= 0 && currentIndex < this.matches.length) {
      const current = new Highlight(this.matches[currentIndex]);
      current.priority = 1;
      registry.set('findbar-current', current);
    }
  }

  clearHighlights() {
    const registry = getHighlights();
    if (!registry) {
      return;
    }
    registry.delete('findbar-matches');
    registry.delete('findbar-current');
  }

  scrollToMatch(index: number) {
    const range = this.matches[index];
    if (!range) {
      return;
    }
    const el = range.startContainer.parentElement;
    el?.scrollIntoView({ block: 'center' });
  }

  navigateMatch(backwards: boolean) {
    if (this.matches.length === 0) {
      return;
    }
    this.setState((prevState) => {
      let next = prevState.currentMatch + (backwards ? -1 : 1);
      if (next >= this.matches.length) {
        next = 0;
      }
      if (next < 0) {
        next = this.matches.length - 1;
      }
      this.applyHighlights(next);
      this.scrollToMatch(next);
      return { currentMatch: next };
    });
  }

  render() {
    const { visible, matchCount, currentMatch } = this.state;
    if (!visible) {
      return null;
    }
    const hasInput = !!this.inputRef.current?.value;
    return (
      <div className="FindBar" ref={this.barRef}>
        <input
          ref={this.inputRef}
          className={
            'FindBar__input'
            + (hasInput && matchCount === 0 ? ' FindBar__input--noMatch' : '')
          }
          placeholder="Поиск..."
          onKeyDown={this.handleInputKeyDown}
          onInput={this.handleInput}
        />
        {hasInput && (
          <span className="FindBar__count">
            {matchCount > 0
              ? `${currentMatch + 1}/${matchCount}`
              : 'Нет совпадений'}
          </span>
        )}
        <div
          className="FindBar__button"
          title="Предыдущее совпадение"
          onClick={() => this.navigateMatch(true)}
        >
          <Icon name="chevron-up" />
        </div>
        <div
          className="FindBar__button"
          title="Следующее совпадение"
          onClick={() => this.navigateMatch(false)}
        >
          <Icon name="chevron-down" />
        </div>
        <div
          className="FindBar__button"
          title="Закрыть"
          onClick={this.handleClose}
        >
          <Icon name="times" />
        </div>
      </div>
    );
  }
}
