import VeevaFileDownload from 'c/veevaFileDownload';

export default class MyAccountsExporter {
  async exportToExcel(sheetjs, filename, columns, data) {
    const workbook = sheetjs.utils.book_new();
    const worksheet = sheetjs.utils.aoa_to_sheet([columns, ...data]);
    sheetjs.utils.book_append_sheet(workbook, worksheet, 'Data');
    sheetjs.writeFile(workbook, `${filename}.xlsx`);
  }

  async exportToCSV(filename, columns, data) {
    const csvData = this._convertToCSV(columns, data);
    this._downloadCsv(filename, csvData);
  }

  _convertToCSV(columns, data) {
    const header = columns.map(columnHeader => `"${columnHeader.replace(/"/g, '""')}"`).join(',');
    const formattedData = data.map(cells => cells.map(cell => {
      const updatedCell = cell.toString().replace(/"/g, '""');
      return `"${updatedCell}"`;
    }));
    const csvRows = [header, ...formattedData];
    return csvRows.join('\n');
  }

  /**
   * Creates a CSV file from the csvData.
   * References https://www.geeksforgeeks.org/how-to-create-and-download-csv-file-in-javascript/
   */
  _downloadCsv(filename, csvData) {
    // Salesforce's Lightning LockerService does not support 'text/csv' so we will use 'text/plain'
    const csvBlob = VeevaFileDownload.createUTF8Blob(csvData, { type: 'text/plain' });
    VeevaFileDownload.download(`${filename}.csv`, csvBlob);
  }
}