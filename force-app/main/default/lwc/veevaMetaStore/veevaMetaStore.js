export default class VeevaMetaStore {
  _objectInfoDirectoryPromise;

  constructor(uiApi) {
    this.uiApi = uiApi;

    this._objectInfoDirectoryPromise = this.getObjectInfoDirectory();
  }

  async getObjectInfoDirectory() {
    if (!this._objectInfoDirectoryPromise) {
      this._objectInfoDirectoryPromise = this.uiApi.objectInfoDirectory();
    }

    const objectInfoDirectory = await this._objectInfoDirectoryPromise;
    return objectInfoDirectory;
  }

  async getObjectPluralLabel(apiName) {
    const pluralLabel = await this._objectInfoDirectoryPromise;
    return pluralLabel.objects[apiName].labelPlural;
  }
}