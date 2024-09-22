@RestResource(urlMapping='/msdcore/attachment/*')
global without sharing class MSD_CORE_AttachmentServices {

  @HttpPost
  global static Map<String,String> doPost(Map<String, String> data) {
    Map<String,String> res = new Map<String,String>();

    String method = (String)data.get('method');
    if (method == 'appendToAttachment') {
        res = appendToAttachment(data);
    }
    return res;
  }

  global static Map<String,String> appendToAttachment(Map<String, String> opts) {

      MSD_CORE_Logger.loggingEnabled = true;

      MSD_CORE_Logger.debug('AttachmentServices.appendToAttachment: start ' + JSON.serializePretty(opts));

      Map<String, String> result = new Map<String,String>();

      try {
          String op = (String)opts.get('op');

          if (op == 'createNewAttachment') {
            Attachment a = new Attachment();
            a.ContentType = (String)opts.get('contentType');
            a.Body = Blob.valueOf((String)opts.get('data'));
            a.Name = (String)opts.get('attachmentName');
            a.parentId = (String)opts.get('attachmentParentId'); // a3oJ00000003zWn


            MSD_CORE_Logger.debug('AttachmentServices.appendToAttachment: before attachment insert');
            Database.SaveResult sr = Database.insert(a);
            MSD_CORE_Logger.debug('AttachmentServices.appendToAttachment: after attachment insert');

            if (sr.isSuccess()) {
                result.put('attachmentId', sr.getId() + '');
            } else {
                String errStr = '';
                for(Database.Error err : sr.getErrors()) {
                    MSD_CORE_Logger.error('The following error has occurred.');
                    errStr = errStr + err.getStatusCode() + ': ' + err.getMessage() + '\n';
                    errStr = errStr + 'fields that affected this error: ' + err.getFields();
                }
                result.put('error', errStr);
            }

          }


          if (op == 'appendToAttachment') {
            Id attachmentId = (Id)opts.get('attachmentId');
            result.put('attachmentId', attachmentId + '');
            Attachment a = [select Name, Description, Body from Attachment where Id = :attachmentId][0];
            Blob b = a.Body;
            String contents = b.toString();
            a.Body = Blob.valueOf(contents + (String)opts.get('data'));
            Database.SaveResult sr = Database.update(a);

            if (sr.isSuccess()) {
                result.put('attachmentId', sr.getId() + '');
            } else {
                String errStr = '';
                for(Database.Error err : sr.getErrors()) {
                    MSD_CORE_Logger.error('The following error has occurred.');
                    errStr = errStr + err.getStatusCode() + ': ' + err.getMessage() + '\n';
                    errStr = errStr + 'fields that affected this error: ' + err.getFields();
                }
                result.put('error', errStr);
            }

          }

          MSD_CORE_Logger.debug('AttachmentServices.appendToAttachment: before return ' + JSON.serializePretty(result));


      } catch (Exception e) {
          String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
          MSD_CORE_Logger.error(errString);
          result.put('error', errString);
      } finally {
          MSD_CORE_Logger.flush();
      }

      return result;

  }

}