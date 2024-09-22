global class EmptyRecycleBinBatchable implements Database.Batchable<sObject>, Database.Stateful {

   global String emailTo;
   global String objectName;
   global Integer recordsInRecycleBinCount = 0;
   global Integer emptySuccessCount = 0;
   global Integer emptyFailedCount = 0;   
   global String output = '';
   global Integer purgeThresholdCount;
   global DateTime startTime;
   global DateTime endTime;
   
   global EmptyRecycleBinBatchable(String o, String et) {
       objectName = o;
       emailTo = et;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
       startTime = DateTime.now();
       return Database.getQueryLocator('SELECT Id FROM ' + objectName + ' WHERE IsDeleted = true ALL ROWS');
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope) {
       recordsInRecycleBinCount += scope.size();
       Database.EmptyRecycleBinResult[] emptyRecycleBinResults = Database.emptyRecycleBin(scope);
       for (Database.EmptyRecycleBinResult r : emptyRecycleBinResults) {
           if ( r.isSuccess() ) {
               emptySuccessCount += 1;
           } else {
               emptyFailedCount += 1;
           }
       }
   }

   global void finish(Database.BatchableContext BC) {
       endTime = DateTime.now();
       
       output = recordsInRecycleBinCount + ' ' + objectName + ' records in recycle bin\n' +
        emptySuccessCount + ' emptied\n' +
        emptyFailedCount + ' previously were emptied\n\n' +
        'started at ' + startTime.format('dd/MM/yyyy hh:mm:ss a', 'EST') +
        ' and finished at ' + endTime.format('dd/MM/yyyy hh:mm:ss a', 'EST') + ' (elapsed time: ' + ((endTime.getTime() - startTime.getTime()) * 0.001) + ' seconds)';       
       
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       mail.setToAddresses(new String[] {emailTo});
       mail.setReplyTo(emailTo);
       mail.setSenderDisplayName('Empty Recycle Bin Processing');
       mail.setSubject('Empty Recycle Bin for ' + objectName + ' - ' + emptySuccessCount + ' records emptied');
       mail.setPlainTextBody('Details:\n' + output);
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   }
}