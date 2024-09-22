/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_RecordToucherBatchable.cls
* @description - Batch class for touching/phantom updating records to force
*   triggers, workflows, etc. to fire.
* @createdate - Sept 4th, 2014
*
*/


/*

Scratch Area:

select Id, Merck_ID_MRK__c, iLinks_URL_Calc_MRK__c, iLinks_URL_MRK__c, LastModifiedDate from Account where Id = '001Z000000lxyNrIAI';

String query = 'select Id, RecordType.Name from Account where RecordType.Name IN (\'HCP\', \'HBP\')';
MRK_RecordToucherBatchable batch = new MRK_RecordToucherBatchable(query);
Database.executeBatch(batch);

Account acct = [select Id from Account where Id = '001Z000000lxyNrIAI' limit 1][0];
System.debug('acct.Id = ' + acct.Id);
update acct;

*/
global class MRK_RecordToucherBatchable implements Database.Batchable<sObject>, Database.Stateful {

  global final String query;
  global String output = '';
  
  global MRK_RecordToucherBatchable(String q) {
  	query = q;
  }

  global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
  }

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		try {
			// phantom update / touch on all
			update scope;
		} catch (Exception e) {
			// eat any exceptions
		}
		
  }

   global void finish(Database.BatchableContext BC) {}
}