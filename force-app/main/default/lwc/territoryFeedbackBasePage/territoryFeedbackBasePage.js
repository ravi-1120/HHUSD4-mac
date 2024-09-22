import { api } from 'lwc';
import { getPageController } from 'c/veevaPageControllerFactory';
import VeevaMainPage from 'c/veevaMainPage';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class TerritoryFeedbackBasePage extends VeevaMainPage {
  // Used by the Flow to determine which screen to visit next. This is set by subclass pages before navigation.
  @api nextScreenName;

  // Used to determine whether the user clicked "back" or "forward", since the popstate event does not distinguish the two.
  @api historyId;

  // This is used by the VeevaMainPage superclass to identify which page's loading time is currently being measured. Value should be set by implementing subclasses.
  pageName = 'TerritoryFeedbackBasePage';
  pageCtrl = getPageController('pageCtrl');

  // This is a unique ID for identifying which page to navigate to.
  pageId;

  // Save the args into a variable so that we can easily unregister the handler.
  EVENT_LISTENER_ARGS = ['popstate', event => this.handlePopstateEvent(event), { once: true }];

  connectedCallback() {
    super.connectedCallback();
    this.registerEventListeners();
    this.initializeHistory();
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    this.unregisterEventListeners();
  }

  registerEventListeners() {
    window.addEventListener(...this.EVENT_LISTENER_ARGS);
  }

  unregisterEventListeners() {
    window.removeEventListener(...this.EVENT_LISTENER_ARGS);
  }

  initializeHistory() {
    // Initializes historyId and history stack on first load of Territory Feedback.
    // On subsequent visits to a page, this.historyId will be a non-null integer.
    if (this.historyId == null) {
      this.historyId = 0;
      window.history.replaceState({ historyId: this.historyId, maxHistoryId: this.historyId }, '');
    }
  }

  async handlePopstateEvent({ state }) {
    // If state.historyId is not present, then we're navigating away from Territory Feedback altogether.
    if (state.historyId == null) {
      return;
    }

    if (state.historyId === this.historyId - 1) {
      await this.goBack(state.historyId, state.maxHistoryId);
    } else if (state.historyId === this.historyId + 1) {
      await this.goForward(state.historyId, state.maxHistoryId);
    } else {
      // We only support 1 forwards and/or backwards state at a time. If this block executes, then it's an old state from a previous Feedback cycle.
      // In this scenario, we wish to simply refresh the page.
      this.reloadPage();
    }
  }

  async goBack(toHistoryId, maxHistoryId) {
    // If navigating to a page other than the first, add a state for two pages ago and a state for the previous page (which we're about to navigate to).
    if (toHistoryId > 0) {
      window.history.replaceState({ historyId: toHistoryId - 1, maxHistoryId }, '');
      window.history.pushState({ historyId: toHistoryId, maxHistoryId }, '');
    }

    // Next, push a new state for the current page (which we're about to navigate away from). Then set the History's "cursor" to the previous page.
    window.history.pushState({ historyId: this.historyId, maxHistoryId }, '');
    await this.goToHistoryState(-1);

    // Finally, go to the previous screen in the flow. The final History stack should look like this relative to the page the user is currently on (before navigation):
    // [<two pages ago>, -> <previous page>, <current page>]
    this.dispatchEvent(new FlowNavigationBackEvent());
  }

  async goForward(toHistoryId, maxHistoryId) {
    // If navigating from a page other than the first, update the History stack so that the new previous page is the current page,
    // and so that the "cursor" now points to the current page (which we're about to navigate away from).
    if (this.historyId > 0) {
      await this.goToHistoryState(-2);
      window.history.replaceState({ historyId: toHistoryId - 1, maxHistoryId }, '');
      window.history.pushState({ historyId: toHistoryId, maxHistoryId }, '');
    }

    // Next, if the page we're navigating to is not the final page in the History stack, then add an entry for two pages from now.
    if (toHistoryId < maxHistoryId) {
      window.history.pushState({ historyId: toHistoryId + 1, maxHistoryId }, '');
      await this.goToHistoryState(-1);
    }

    // Finally, go to the next screen in the flow. The final History stack should look like this relative to the page the user is currently on (before navigation):
    // [<current page>, -> <next page>, <two pages forward>]
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  async goToNextScreen(nextScreenName) {
    if (nextScreenName) {
      this.nextScreenName = nextScreenName;
    }

    // If this.historyId is null, then we're skipping the current page. Thus we do not want to log it into history.
    if (this.historyId != null) {
      if (!window.history.state?.historyId) {
        // Push an empty state on the first page of the flow, but only after user has started navigation so that users don't see the entry in the History menu.
        window.history.pushState({}, '');
      }
      await this.goToHistoryState(-1);

      const newMaxHistoryId = this.historyId + 1;

      // Update the History stack to look like this relative to the page the user is currently on (before navigation):
      // [<current page>, -> <next page>]
      window.history.replaceState({ historyId: this.historyId, maxHistoryId: newMaxHistoryId }, '');
      window.history.pushState({ historyId: newMaxHistoryId, maxHistoryId: newMaxHistoryId }, '');
    }

    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  // This wraps the `history.go` method to "convert" it from the event handler paradigm to the promise paradigm.
  // This way other functions can simply `await` this function without registering a handler every time.
  async goToHistoryState(delta) {
    this.unregisterEventListeners();
    return new Promise(resolve => {
      window.addEventListener('popstate', resolve, { once: true });
      window.history.go(delta);
    });
  }

  handleSamePageNavigation() {
    this.clearForwardsHistory();
  }

  // Clears any "forward" state in the history stack. Useful when user navigates back to a prior page, but then navigates around that page in a way that "alters" their history.
  async clearForwardsHistory() {
    const currentState = window.history.state;
    if (currentState.historyId < currentState.maxHistoryId && currentState.historyId > 0) {
      await this.goToHistoryState(-1);
      this.registerEventListeners();
      window.history.replaceState({ historyId: currentState.historyId - 1, maxHistoryId: currentState.historyId }, '');
      window.history.pushState({ historyId: currentState.historyId, maxHistoryId: currentState.historyId }, '');
    }
  }

  reloadPage() {
    this.unregisterEventListeners();
    window.location.reload();
  }
}