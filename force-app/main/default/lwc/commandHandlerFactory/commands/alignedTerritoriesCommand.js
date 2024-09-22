import getUserTerritories from '@salesforce/apex/MyInsightsService.getUserTerritories';
import getUserTerritoryHierarchy from '@salesforce/apex/MyInsightsService.getUserTerritoryHierarchy';
import CommandHandler from "./commandHandler"

export default class AlignedTerritoriesCommand extends CommandHandler {

  async response(queryConfig) {
    try {
      let territories = [];
      if (queryConfig.includeChildren === true) {
        territories = await getUserTerritoryHierarchy();
      } else {
        territories = await getUserTerritories();
      }
      const response = this.formatSuccessResponse(this.formatTerritories(territories));
      response.record_count = response.data.length;
      return response;
    } catch (err) {
      if (err?.status === 500) {
        return this.createNoInternetResponse();
      }
      return this.formatErrorResponse(err);
    }
  }

  formatTerritories(territories) {
    const formattedTerritories = [];
    for (const territory of territories) {
      formattedTerritories.push({
        name: territory.Name,
        id: territory.Id,
        developerName: territory.DeveloperName,
        description: territory.Description ?? null,
        parentTerritoryId: territory.ParentTerritoryId ?? null
      });
    }
    return formattedTerritories;
  }

  createNoInternetResponse() {
    return {
      success: false,
      message: 'No Internet connection. Unable to send request to CRM Data Engine.',
      code: 1801
    }
  }

  formatErrorResponse(err) {
    return {
      success: false,
      code: err.status,
      message: err.body.message
    }
  }
}