import { LightningElement, api } from 'lwc';
import { ERROR_TYPES, ImplicitAccessError } from "c/removeFromTerritoryErrors";

const ERROR_TYPE_TO_VEEVA_MESSAGE_KEYS = new Map([
    [ERROR_TYPES.NO_ACCESS, { header: "REMOVE_FROM_TERRITORY_ERROR_IMPROPER_CONFIG_TITLE", body: "REMOVE_FROM_TERRITORY_ERROR_IMPROPER_CONFIG", category: "Feedback" }],
    [ERROR_TYPES.IMPLICIT_ACCESS, {header: "REMOVE_FROM_TERRITORY_ACCOUNT_ACCESS_TITLE", body: "REMOVE_FROM_TERRITORY_WARNING_ACCOUNT_ACCESS_TEXT", category: "Feedback"}],
    [ERROR_TYPES.PAGE_NOT_AVAILABLE, { header: "ERROR_UNAVAILABLE_DESCRIPTION", body: null, category: "Feedback" }]
]);

const VEEVA_MESSAGE_KEY_TO_DEFAULT_MESSAGE = new Map([
    ["REMOVE_FROM_TERRITORY_ERROR_IMPROPER_CONFIG_TITLE", "Improper Configuration"],
    ["REMOVE_FROM_TERRITORY_ERROR_IMPROPER_CONFIG", "Unable to access this feature. Please contact your system administrator."],
    ["REMOVE_FROM_TERRITORY_ACCOUNT_ACCESS_TITLE", "Account Access"],
    ["REMOVE_FROM_TERRITORY_WARNING_ACCOUNT_ACCESS_TEXT", "You have implicit access to this account and it is not assigned to your territory. Please contact an administrator to remove visibility."]
]);

export default class RemoveFromTerritoryErrorHandler extends LightningElement {

    @api messageService;

    _errorType;
    _errorHeader;
    _errorBody;

    @api get error() {
        return {
            errorType: this._errorType,
            errorHeader: this._errorHeader,
            errorBody: this._errorBody
        };
    }

    set error(value) {
        if (value) {
            this.setErrorType(value);
            this.setErrorText();
        }
    }

    setErrorType(error) {
        if (error instanceof ImplicitAccessError) {
            this._errorType = ERROR_TYPES.IMPLICIT_ACCESS;
        } else { /* NoFeatureAccessError */
            this._errorType = ERROR_TYPES.NO_ACCESS;
        }
    }

    setErrorText() {
        const messageKey = ERROR_TYPE_TO_VEEVA_MESSAGE_KEYS.get(this._errorType);
        const defaultHeaderMessage = VEEVA_MESSAGE_KEY_TO_DEFAULT_MESSAGE.get(messageKey.header);
        const defaultBodyMessage = VEEVA_MESSAGE_KEY_TO_DEFAULT_MESSAGE.get(messageKey.body);

        if (messageKey.header) {
            this.messageService.getMessageWithDefault(messageKey.header, messageKey.category, defaultHeaderMessage).then(message => {
                this._errorHeader = message;
            });
        } else {
            this._errorHeader = null;
        }

        if (messageKey.body) {
            this.messageService.getMessageWithDefault(messageKey.body, messageKey.category, defaultBodyMessage).then(message => {
                this._errorBody = message;
            });
        } else {
            this._errorBody = null;
        }
    }

    get showPageNotAvailableError() {
        return this.error && (this.error.errorHeader || this.error.errorBody) && this.error.errorType === ERROR_TYPES.PAGE_NOT_AVAILABLE;
    }

    get showImplicitAccessError() {
        return this.error && (this.error.errorHeader || this.error.errorBody) && this.error.errorType === ERROR_TYPES.IMPLICIT_ACCESS;
    }

    get showNoAccessError() {
        return this.error && (this.error.errorHeader || this.error.errorBody) && this.error.errorType === ERROR_TYPES.NO_ACCESS;
    }
}