/*Programmed to send export to promomats from veeva*/
/*21r3 revisions G. Schneible CEF2F-6824 and CEF2F-6543: 1. Altered String dateinfilename to make a file name with leading zero in Month     */
/* 2. Used Last mod date to filter out only delta changes from the previous week. 3. Added criteria for excluding expired based on end date. */


global  class MSD_CORE_Survey_For_Promomats implements Database.Batchable<sObject>,Database.Stateful{
  
    String status = 'Published_vod';
    String NSurveyType = 'Coaching_Report_vod';  //Programmed to exclude Coaching Reports. 
    String NChannel = 'CRM_vod'; //Progammed to exclude CRM Channels.
    String query; 
    List<Survey_vod__c> surveylist = new List<Survey_vod__c>();
    
    global MSD_CORE_Survey_For_Promomats (){
       
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
       // query='SELECT id, MSD_CORE_Country_code__c,External_ID_vod__c FROM Survey_vod__c where LastModifiedDate >=LAST_N_DAYS:7 AND Status_vod__c =:status';
      // query='SELECT id, MSD_CORE_Country_code__c,External_ID_vod__c FROM Survey_vod__c where LastModifiedDate >=LAST_WEEK AND Status_vod__c =:status';
      //query='SELECT id, MSD_CORE_Country_code__c,External_ID_vod__c FROM Survey_vod__c where CreatedDate >=LAST_WEEK AND Status_vod__c =:status AND RecordType.Name != :NSurveyType and Channels_vod__c != :NChannel';
        query='SELECT id, MSD_CORE_Country_code__c,External_ID_vod__c FROM Survey_vod__c where LastModifiedDate >=LAST_WEEK AND End_Date_vod__c >= Today AND Status_vod__c =:status AND RecordType.Name != :NSurveyType and Channels_vod__c != :NChannel';          
        return Database.getQueryLocator(query); 
        
    }
    global void execute(Database.BatchableContext BC, List<Survey_vod__c> batch) {
       For(Survey_vod__c surveys: batch){
           if(string.valueof(surveys.External_ID_vod__c) != 'null'){
               if (!(string.isBlank(surveys.External_ID_vod__c) )){
            {
               system.debug('Came here after null check');
               surveylist.add(surveys); 
           system.debug(surveylist.size());
           }
               }
           }
     } 
    
    }
    global void finish(Database.BatchableContext BC){
       
        string header = 'External_ID_vod_c,MSD_CORE_Country_code_c,OrgId \n';
    String finalstr = header ;
        //String dateinfilename = System.Today().year()+'_'+System.Today().month()+'_'+System.Today().day();
        String dateFormat = 'yyyy_MM_dd';
        DateTime dt = DateTime.now();
        String dateinfilename = dt.format(dateFormat);
        String orgid = 'test';
        String orgname = 'US Veeva';
        For(Survey_vod__c sur: surveylist){
           // if(sur.External_ID_vod__c != '' || sur.External_ID_vod__c != null){
       string recordString = sur.External_ID_vod__c+','+sur.MSD_CORE_Country_code__c+','+UserInfo.getOrganizationId() +'\n';
          finalstr = finalstr +recordString;
            //}            
    }
        If (string.valueOf(UserInfo.getOrganizationId())=='00DU0000000IRl9MAG'){
            
            orgid='prod';
            
        }
      Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
    blob csvBlob = Blob.valueOf(finalstr);
    string csvname= dateinfilename+'_'+'US_'+orgid+'_survey.csv';
    csvAttc.setFileName(csvname);
    csvAttc.setBody(csvBlob);
    Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
    String[] toAddresses = new list<string> {'ankur.mehrotra2@merck.com'};
            toAddresses.add('globalreviewgetaco@merck.com');
    String subject ='Survey export from '+orgname+' '+orgid+' '+UserInfo.getOrganizationId();
      email.setSubject(subject);
      email.setToAddresses( toAddresses );
      email.setPlainTextBody('Please find attached the '+'Survey export from '+orgname+' '+orgid+' '+UserInfo.getOrganizationId());
      email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
      Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
}