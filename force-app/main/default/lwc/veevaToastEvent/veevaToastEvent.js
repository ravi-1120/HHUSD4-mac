import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getService, SERVICES } from 'c/veevaServiceFactory';

const MSG_DELIMITER = '; ';

export default class VeevaToastEvent {

  static error(obj, mode) {
    return new ShowToastEvent({
      message: (obj.body ? obj.body.message : getErrorsFromMessage(obj.message)) || obj.statusText,
      variant: 'error',
      mode: mode || 'dismissible',
    });

    function getErrorsFromMessage(message) {
        let errMsg = message;
        if (typeof errMsg !== 'string') {
            const fldErrs = Object.entries(message.fieldErrors || {}).map(([key, value]) => `${key}: ${value}`);
            const msgArr = fldErrs.concat(message.recordErrors || []);
            errMsg = msgArr.join(MSG_DELIMITER);
        }
        return errMsg;
    }
  }

  static successMessage(msg) {
    return new ShowToastEvent({
      message: msg,
      variant: 'success',
    });
  }

  // TODO: new Veeva Message if not available from Salesforce
  static async recordSaved(objectLabel, recordName) {
    let msg = await getService(SERVICES.MESSAGE).getMessageWithDefault(
      'RECORD_SAVED',
      'Lightning',
      '{0} "{1}" was saved.',
    );
    const replaceChars = { '{0}': objectLabel, '{1}': recordName };
    msg = msg.replace(/\{[0-1]\}/g, match => replaceChars[match]);
    return new ShowToastEvent({
      message: msg,
      variant: 'success',
    });
  }

  static async recordDeleted(objectLabel, recordName) {
    let msg = await getService(SERVICES.MESSAGE).getMessageWithDefault(
      'RECORD_DELETED',
      'Lightning',
      '{0} "{1}" was deleted.',
    );
    const replaceChars = { '{0}': objectLabel, '{1}': recordName };
    msg = msg.replace(/\{[0-1]\}/g, match => replaceChars[match]);
    return new ShowToastEvent({
      message: msg,
      variant: 'success',
    });
  }

  static async recordCreated(objectLabel, recordName, url) {
    const msg = await getService(SERVICES.MESSAGE).getMessageWithDefault(
      'RECORD_CREATED',
      'Lightning',
      '{0} "{1}" was created.',
    );
    return new ShowToastEvent({
        message: msg,
        messageData: [objectLabel, {url, label: recordName}],
        variant: 'success',
      });
  }

  static async notAllowedToEdit() {
    const message = await getService(SERVICES.MESSAGE).getMessageWithDefault(
      'NOT_ALLOWED_TO_EDIT',
      'Common',
      'You do not have permission to edit this record.',
    );

    return new ShowToastEvent({
      message,
      variant: 'error',
    });
  }
}