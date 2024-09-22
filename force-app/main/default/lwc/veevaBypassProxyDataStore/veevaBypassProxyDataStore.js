/**
 * An intermediary data store option for component areas when Salesforce's proxying
 * of API properties negatively impacts feature performance. Clients of the data store should
 * retrieve the singleton service using `VeevaServiceFactory::getService`.
 * 
 * THIS SHOULD NOT BE USED AS A GENERIC DATA-STORAGE OPTION. 
 * 
 * @property {Object} store - Data storage object
 */
export default class VeevaBypassProxyDataStore {
    store = {};

    put(data) {
        const id = crypto.randomUUID();
        this.store[id] = data;
        return id;
    }

    retrieve(id) {
        return this.store[id];
    }

    remove(id) {
        delete this.store[id];
    }
}