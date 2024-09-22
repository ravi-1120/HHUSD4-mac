import getVeevaMessages from "@salesforce/apex/VeevaMessageController.getVeevaMessages";
import VeevaMessageRequest from "./veevaMessageRequest";

const INIT_CATEGORIES = ['Common', 'Lightning'];

export default class VeevaMessageService {
    _messageMap;
    _loadedCategories;
    _msgPromiseList;
    
    constructor() {
        this._messageMap = {};
        this._loadedCategories = {};
        this._msgPromiseList = [];
        this._filterAndLoad(INIT_CATEGORIES);
    }

    async loadVeevaMessageCategories(categories) {
        await this._flushMessagePromises();
        this._filterAndLoad(categories);
    }

    async getMessageWithDefault(key, category, defaultMessage) {
        const msgKey = `${category};;${key}`;
        let message = this._messageMap[msgKey];
        if (!message) {
            await this.loadVeevaMessageCategories([category]);
            await this._flushMessagePromises();
            message = this._messageMap[msgKey];
        }
        return message || defaultMessage;
    }

    createMessageRequest() {
      return new VeevaMessageRequest(this);
    }

    async getMessageMap(msgRequest) {
        const msgWithDefaultArr = msgRequest.getMessageRequests();
        if (!msgWithDefaultArr || msgWithDefaultArr.length < 1) {
            return {};
        }
        const newCategories = msgWithDefaultArr.map(msg => msg.category).filter((cat, index, arr) => cat && !this._loadedCategories[cat] && arr.indexOf(cat) === index);
        await this.loadVeevaMessageCategories(newCategories);
        await this._flushMessagePromises();

        const msgMap = {};
        msgWithDefaultArr.forEach(msgInfo => {
            const msgKey = `${msgInfo.category};;${msgInfo.key}`;
            const msg = this._messageMap[msgKey] || msgInfo.defaultMessage;
            if (msg && msgInfo.label) {
                msgMap[msgInfo.label] = msg;
            }
        });
        return msgMap;
    }

    _filterAndLoad(categories) {
        const uncached = categories.filter(cat => !this._loadedCategories[cat]).sort();
        if (uncached.length > 0) {
            uncached.forEach(cat => {this._loadedCategories[cat] = true;});
            this._msgPromiseList.push(this._loadAndMapMessages(uncached));
        }
    }

    async _loadAndMapMessages(categories) {
        const msgData = await getVeevaMessages({"categories": categories});
        Object.assign(this._messageMap, msgData);
        if (msgData) {
            Object.keys(msgData).forEach(msgKey => {
                const msgCat = msgKey.split(';;')[0];
                this._loadedCategories[msgCat] = true;
            });
        }
    }

    // returns a map of keys to an array of values e.g. Key1:[Val1, Val2] ... for a veeva message string with the format: "<Key1>:<Val1>,<Val2>;<Key2>:<Val3>,<Val4> ..."
    static convertMessageStringToMap(message) {
        const msgMap = {};
        message.split(';').forEach(msgMappingStr => {
            const separatedEltInfo = msgMappingStr.split(':');
            if (separatedEltInfo.length === 2) {
                const keyName = separatedEltInfo[0].trim();
                msgMap[keyName] = separatedEltInfo[1].split(',').map(str => str.trim());
            }
        });
        return msgMap;
    }

    async _flushMessagePromises() {
        await Promise.all(this._msgPromiseList);
        this._msgPromiseList = [];
    }
}
export { VeevaMessageRequest };