import ClmPresentationHandler from './clmPresentationHandler';
import SuggestionHandler from './suggestionHandler';

export default class SmartLinkingHandlerFactory {
  static handlers(veevaUserInterfaceAPI, veevaDataService, myInsightsPageController) {
    // Each Handler must be registered with a lower case string. 
    return {
      suggestion_vod__c: new SuggestionHandler(veevaUserInterfaceAPI, veevaDataService, myInsightsPageController),
      clm_presentation_vod__c: new ClmPresentationHandler(myInsightsPageController),
    };
  }
}