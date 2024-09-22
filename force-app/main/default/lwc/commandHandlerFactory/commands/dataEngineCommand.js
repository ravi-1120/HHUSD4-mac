import CommandHandler from "./commandHandler"

const CDE_DATA_ENDPOINT = "/api/v1/data";
const CDE_TABLES_ENDPOINT = "/api/v1/tables";

export default class DataEngineCommand extends CommandHandler {

  veevaSessionService;
  veevaDataService;
  constructor(veevaUserInterfaceApi, veevaSessionService, veevaDataService) {
    super(veevaUserInterfaceApi);
    this.veevaSessionService = veevaSessionService;
    this.veevaDataService = veevaDataService;
  }

  async queryDataEngine(cdeServer, configObject) {
    const cdeDataRequest = await this.veevaDataService.initVodRequest();
    cdeDataRequest.method = "POST";
    cdeDataRequest.url = `${cdeServer}${CDE_DATA_ENDPOINT}`;
    cdeDataRequest.body = JSON.stringify(configObject);
    return this.veevaDataService.request(cdeDataRequest);
  }

  async getDataEngineTables(cdeServer) {
    const cdeDataRequest = await this.veevaDataService.initVodRequest();
    cdeDataRequest.method = "GET";
    cdeDataRequest.url = `${cdeServer}${CDE_TABLES_ENDPOINT}`;
    return this.veevaDataService.request(cdeDataRequest);
  }

  async getDataEngineTableMetadata(cdeServer, tableName) {
    const cdeDataRequest = await this.veevaDataService.initVodRequest();
    cdeDataRequest.method = "GET";
    cdeDataRequest.url = `${cdeServer}${CDE_TABLES_ENDPOINT}/${tableName}`;
    return this.veevaDataService.request(cdeDataRequest);
  }

  async response(queryConfig) {
    let response;
    const vodInfo = await this.veevaSessionService.getVodInfo();
    const server = this.sanitizeUrl(vodInfo.cdeServer);
    if (!server) {
      return this.createInvalidCdeUrlResponse(server);
    }
    try {
      let apiResponse;
      let data;
      switch (queryConfig.command) {
        case 'queryDataEngine':
          apiResponse = await this.queryDataEngine(server, queryConfig.configObject);
          data = apiResponse?.data;
          break;
        case 'getDataEngineTables':
          apiResponse = await this.getDataEngineTables(server);
          data = apiResponse?.data;
          break;
        case 'getDataEngineTableMetadata':
          apiResponse = await this.getDataEngineTableMetadata(server, queryConfig.configObject);
          data = apiResponse?.data?.columns;
          break;
        default:
          this.formatErrorResponse({ message: "Invalid Data Engine Command" });
      };
      if (apiResponse.status === "SUCCESS") {
        response = this.formatSuccessResponse(data);
      } else {
        response = this.formatErrorResponse({ message: "Invalid Data Engine Request Configuration" });
      }
    } catch (err) {
      if (err.httpStatusCode === 404) {
        response = this.createInvalidCdeUrlResponse(server);
      } else if (err.error) {
        response = this.createNoInternetResponse();
      } else {
        response = this.formatErrorResponse(err);
      }
    }
    return response;
  }

  sanitizeUrl(cdeUrl) {
    let sanitizedUrl = "";
    if (cdeUrl) {
      sanitizedUrl = cdeUrl.trim();
    }
    if (sanitizedUrl.length > 0 && sanitizedUrl.charAt(sanitizedUrl.length - 1) === '/') {
      sanitizedUrl = sanitizedUrl.substring(0, sanitizedUrl.length - 1);
    }
    return sanitizedUrl;
  }

  formatErrorResponse(error) {
    return {
      success: false,
      message: error.message,
      code: error.httpStatusCode
    };
  }

  createInvalidCdeUrlResponse(cdeUrl) {
    return {
      success: false,
      message: `Invalid CRM Data Engine Server URL, please check Veeva Common configuration: ${cdeUrl}`,
      code: 1802
    }
  }

  createNoInternetResponse() {
    return {
      success: false,
      message: 'No Internet connection. Unable to send request to CRM Data Engine.',
      code: 1801
    }
  }
}