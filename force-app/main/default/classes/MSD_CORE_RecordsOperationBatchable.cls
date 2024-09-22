/*

usage:

Map<String,String> opts = new Map<String,String>{
    "op" => "delete",
    "soql" => "select Id from MSD_CORE_Deleted_Record__c"
};
MSD_CORE_RecordsOperationBatchable recordsOperationBatchable = new MSD_CORE_RecordsOperationBatchable(opts);
ID batchprocessid = Database.executeBatch(recordsOperationBatchable, 2000);

*/

global class MSD_CORE_RecordsOperationBatchable implements Database.Batchable<sObject>, Database.Stateful {

   global final Map<String,String> opts;
    global Integer totalRecordsProcessed = 0;

   global MSD_CORE_RecordsOperationBatchable(Map<String,String> opts) {
    this.opts = opts;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      MSD_CORE_Logger.loggingEnabled = true;
      MSD_CORE_Logger.debug('MSD_CORE_RecordsOperationBatchable.start, opts = \n' + JSON.serializePretty(opts));
      MSD_CORE_Logger.flush();
      return Database.getQueryLocator(opts.get('soql'));
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope) {
    String op = opts.get('op');

      MSD_CORE_Logger.loggingEnabled = true;
      MSD_CORE_Logger.debug('MSD_CORE_RecordsOperationBatchable.execute, op = ' + op + ', number of records = ' + scope.size());
      MSD_CORE_Logger.flush();



    if (op == 'delete') {
        delete scope;
    }

    if (op == 'update') {

        Map<String, Object> fieldNameToFieldValueMap = (Map<String, Object>)JSON.deserializeUntyped(opts.get('fieldNameToFieldValueMap'));
        for (sObject obj : scope) {
            for (String fieldName : fieldNameToFieldValueMap.keySet()) {
                obj.put(fieldName, fieldNameToFieldValueMap.get(fieldName));
            }
        }

        update scope;
    }

    totalRecordsProcessed += scope.size();

   }

   global void finish(Database.BatchableContext BC) {

      MSD_CORE_Logger.loggingEnabled = true;
      MSD_CORE_Logger.debug('MSD_CORE_RecordsOperationBatchable.finish, op = ' + opts.get('op') + ', total number of records processed = ' + totalRecordsProcessed);
      MSD_CORE_Logger.flush();
   }
}