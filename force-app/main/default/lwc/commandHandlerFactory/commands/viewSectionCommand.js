import CommandHandler from './commandHandler';
import NavigationTarget from "../support/navigationTarget";

export default class ViewSectionCommand extends CommandHandler {

  constructor(veevaUserInterfaceAPI, myInsightsController, htmlReports, myInsightsUuid) {
    super(veevaUserInterfaceAPI);
    this.myInsightsController = myInsightsController;
    // converting proxy array of proxy objects to array of proxy objects
    this.htmlReports = htmlReports?.map(e => e) ?? [];
    this.myInsightsUuid = myInsightsUuid;
  }

  async response(config) {
    if (config.configObject.target) {
      const target = NavigationTarget.findTarget(config.configObject.target, this.htmlReports);
      if (target !== undefined) {
        return this.navigateToViewSection(target);
      }
    }
    return this.getFailureMessage();
  }

  navigateToViewSection(target) {
    this.myInsightsController.navigateToViewSection(target.targetSalesforceId, this.myInsightsUuid);
    return {
      success: true,
      target: target.targetObject
    }
  }


  getFailureMessage() {
    return {
      success: false,
      message: 'Failed to Navigate to any targets',
      code: 1492
    }
  }

}