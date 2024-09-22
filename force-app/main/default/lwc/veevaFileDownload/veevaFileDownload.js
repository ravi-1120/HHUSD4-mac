const UTF8_BOM = new Uint8Array([0xef, 0xbb, 0xbf]);
export default class VeevaFileDownload {
  static createUTF8Blob(data, blobOptions = { type: 'text/plain' }) {
    return new Blob([UTF8_BOM, data], blobOptions);
  }

  /**
   * Downloads a file with the given data and filename with extension.
   *
   * Note: Reference https://developer.salesforce.com/docs/component-library/tools/lws-distortion-viewer#URL_createObjectURL-value for valid blob types
   * References https://www.geeksforgeeks.org/how-to-create-and-download-csv-file-in-javascript/
   *
   * @param {String} filenameWithExtension
   * @param {Blob} blobData data that will be downloaded
   */
  static download(filenameWithExtension, blobData) {
    // Creating an object for downloading url
    // Note: Lightning Web Security will throw an exception when an invalid MIME type is provided to prevent malicious code from executing
    // We do not need to worry about this as long as we use the supported MIME Types
    // https://developer.salesforce.com/docs/component-library/tools/lws-distortion-viewer#URL_createObjectURL-value
    // eslint-disable-next-line @locker/locker/distorted-url-create-object-url
    const url = URL.createObjectURL(blobData);

    // Creating an anchor(a) tag of HTML
    const a = document.createElement('a');

    // Passing the blob downloading url
    a.href = url;

    // Setting the anchor tag attribute for downloading and passing the download file name
    a.download = filenameWithExtension;

    // Performing a download with click
    a.click();

    // Remove <a> after download
    a.remove();

    // Clean up no longer needed URL
    URL.revokeObjectURL(url);
  }
}