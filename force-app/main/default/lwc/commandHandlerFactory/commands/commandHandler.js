import CommandError from "c/commandError";

export default class CommandHandler {
    veevaUserInterfaceApi;
    constructor(veevaUserInterfaceApi) {
        this.veevaUserInterfaceApi = veevaUserInterfaceApi;
        this.SKIP_UI_API_OBJECTS = new Set(['group', 'userterritory2association', 'territory2', 'accountshare']);
    }

    async response(queryConfig) {
        throw new Error("Abstract Command not yet implemented", queryConfig);
    }

    async objectInfo(object) {
        const objectInfo = await this._getObjectInfo(object);
        if (!objectInfo || objectInfo.length === 0) {
            this.throwCommandError(`Could not retrieve information for object ${object}`);
        }
        return objectInfo;
    }

    // If we know the requested object is not supported by the ui api, we automatically call the rest api
    // Otherwise we first try the ui api and if that is unsuccessful we defer to the rest api
    async _getObjectInfo(object) {
        if (object && this.SKIP_UI_API_OBJECTS.has(object.toLowerCase())) {
          return this.getObjectInfoFromRestAPI(object)
        }

        let objectInfo = await this.veevaUserInterfaceApi.objectInfo(object);
        if (!objectInfo || objectInfo.length === 0) {
            // Some objects are not supported by the UI API, if SKIP_UI_API_OBJECTS missed an object it will get here
            if (object) {
                objectInfo = await this.getObjectInfoFromRestAPI(object);
            }
        }
        return objectInfo;
    }

    throwCommandError(message) {
        const errorData = { message };
        throw new CommandError(errorData, this.constructor.name);
    }

    async getRecordTypes(objectName) {
        const objectInfo = await this.objectInfo(objectName);
        const recordTypeInfos = Object.values(objectInfo.recordTypeInfos);
        return recordTypeInfos;
    }

    async getObjectInfoFromRestAPI(objectName) {
        const objectNameEncoded = encodeURIComponent(objectName);
        const url = `/sobjects/${objectNameEncoded}/describe`;
        let objectMetadata;
        try {
            const response = await this.veevaUserInterfaceApi.performRequest(`sobject-describe-${objectName}`, url);
            if (response.success) {
                objectMetadata = {
                    apiName: objectName,
                    ...response.data
                };
                objectMetadata.fields = this._formatFieldsSimilarToUiAPI(objectMetadata.fields);
            } else {
                // eslint-disable-next-line no-console
                console.warn(`Could not retrieve object info for ${objectName}`, response.error);
                objectMetadata = null;
            }
        } catch (e) {
            objectMetadata = null;
        }
        if (!objectMetadata) {
            this.throwCommandError(`Could not retrieve information for object ${objectName}`);
        }
        return objectMetadata;
    }

    _formatFieldsSimilarToUiAPI(fields) {
        const fieldMap = {};
        if (fields) {
            fields.forEach(field => {
                fieldMap[field.name] = {
                    apiName: field.name,
                    dataType: field.type,
                    ...field
                }
            });
        }
        return fieldMap;
    }

    formatErrorResponse(error) {
        return {
            success: false,
            message: error.message
        };
    }

    formatSuccessResponse(responseData) {
        return {
            success: true,
            data: responseData
        };
    }
}