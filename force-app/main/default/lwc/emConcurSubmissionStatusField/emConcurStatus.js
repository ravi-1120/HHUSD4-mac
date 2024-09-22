export default class EmConcurStatus {

    constructor(status) {
        this.icon = this._getStatusIcon(status);
        this.iconVariant = this._getStatusIconVariant(status);
        this.helptext = this._getHelpTextVeevaMessage(status);
    }

    _getStatusIcon(status) {
        let icon;
        switch(status) {
            case 'Submitted_vod':
                icon = 'utility:success';
                break;
            case 'Sending_vod':
                icon = 'utility:send';
                break;
            case 'Failed_Connection_vod':
            case 'Failed_Config_vod':
            case 'Failed_Duplicate_vod':
                icon = 'utility:warning';
                break;
            case 'Canceled_vod':
                icon = 'utility:cancel_file_request';
                break;
            case 'Unsubmitted_vod':
                icon = 'utility:ban';
                break;
            default:
                icon = '';
        }
        return icon;
    }

    _getStatusIconVariant(status) {
        let variant;
        switch(status) {
            case 'Submitted_vod':
                variant = 'success';
                break;
            case 'Sending_vod':
                variant = 'warning';
                break;
            case 'Failed_Connection_vod':
            case 'Failed_Config_vod':
            case 'Failed_Duplicate_vod':
            case 'Canceled_vod':
                variant = 'error';
                break;
            default:
                variant = '';
        }
        return variant;
    }

    _getHelpTextVeevaMessage(status) {
        let text;
        switch(status) {
            case 'Failed_Connection_vod':
                text = { key: 'CONCUR_CONNECTION_ERROR', category: 'Concur', defaultMessage: 'Lost connection to Concur. Please retry.' };
                break;
            case 'Failed_Config_vod':
            case 'Failed_Duplicate_vod':
                text = { key: 'CONCUR_POST_ERROR', category: 'Concur', defaultMessage: 'There was an error submitting to Concur. Please contact your administrator.' };
                break;
            case 'Canceled_vod':
                text = { key: 'CONCUR_SUBMIT_CANCELED', category: 'Concur', defaultMessage: 'The system admin has canceled this expense from being sent to Concur.' };
                break;
            default:
                text = {};
        }
        return text;
    }
}