export default class PrintTemplateSvc {
  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  getTemplates(recordId, recordTypeName) {
    const path = `/api/v1/em.print/${recordId}/templates`;
    const params = { recordTypeName };
    return this.dataSvc.sendRequest('GET', path, params, null, 'emTemplatePrintGetTemplates');
  }

  getPreview(recordId, recordTypeName, catalogId, materialId) {
    const path = `/api/v1/em.print/${recordId}/preview`;
    const params = { catalogId, materialId, recordTypeName };
    return this.dataSvc.sendRequest('GET', path, params, null, 'emTemplatePrintGetPreview');
  }

  generatePdf(recordId, recordTypeName, catalogId, materialId) {
    const path = `/api/v1/em.print/${recordId}/pdf`;
    const params = { catalogId, materialId, recordTypeName };
    return this.dataSvc.sendRequest('POST', path, params, null, 'emTemplatePrintGeneratePdf');
  }
}