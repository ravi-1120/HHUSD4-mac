/*
* MSD_CORE_UpdateAttachmentIdOnCaseTrigger
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   Whenever a new attachment is added to or deleted from a Case
*                this trigger handler will repopulate the MSD_CORE_Attachment_IDs__c
*                field with all of the existing Attachments for the Case.
*                This field is used by a Drawloop process in order to send all of the
*                Attachments for a Case to an external mailbox.
* Modified By:   Satish K Sunkara
* Date:          3/13/2017
* Description:   The class has been modified to now update the case with the Attachment Size & Count
*                to restrict the users from not allowing more than 30 attachments or not more than 24 MB
*                of total file size whichever is attained first. The class further check for the attachment type
*                and if the type is a zip, then display an error message telling that zip files are not allowed.
*                Custom Labels are used to display the messages and they can be extended in future to display 
*                customized errors as per user language and this code can be used globally.
*                KRB REL 9.0.1 6/19/2017 - changed the size limit from 24 to 21. 
*                KRB REL 9.0.1 6/19/2017 - Fixed Satish's Bug - No Null Check prior to interrogating Content Type
*/
public with sharing class MSD_CORE_UpdateAttachmentIdOnCaseTrigger implements TriggersMVN.HandlerInterface{
    Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
    
    public void handle() {
        List<Attachment> attachments; 
        
        if(Trigger.isInsert) {
            attachments = Trigger.new; 
        } else if(Trigger.isDelete) {
            attachments = Trigger.old; 
        }

        Set<Id> caseIds = new Set<Id>(); 
        for(Attachment a : attachments) {
            //if(!doesContain(a.Name)) {
            caseIds.add(a.ParentId); 
            //}  
        }
        
        
        List<Case> cases = [SELECT Id, MSD_CORE_Attachment_IDs__c, MSD_CORE_Attachment_Size__c, MSD_CORE_Attachment_Count__c, (SELECT Id, Name, BodyLength, ContentType,CreatedDate FROM Attachments ORDER BY CreatedDate desc) FROM Case WHERE Id IN:caseIds]; 
        for(Case c : cases) {
            Integer index = 0;
            c.MSD_CORE_Attachment_IDs__c = '';
            c.MSD_CORE_Attachment_Size__c = 0;
            c.MSD_CORE_Attachment_Count__c = 0;
             
            for(Attachment a : c.Attachments) {                
                // if(!doesContain(a.Name)) {
                if(index == 0 )
                {
                    c.MSD_CORE_Latest_Attach_DT__c = a.CreatedDate;
                    index++;
                }
                c.MSD_CORE_Attachment_IDs__c += a.Id + '|'; 
                
                //Code added by Satish to replace any existing (combination of comma and space) delimiters to a pipe delimiter.
                // This code will be redundant eventually once all the historical case records will be replaced with a pipe
                // If a developer sees this code, then he should make it a point to remove this line of code after verifying that 
                // all the commas in the string are replaced to pipe 
                c.MSD_CORE_Attachment_IDs__c.replaceAll(', ','|');
                // Code added by Satish Ends here
                //}
                
               if(!String.isBlank(a.Name)){
                  System.debug('Kevin: Attachment Name is:' + a.Name );
               }
                    
               if(a.BodyLength > 0){
                  if(!String.isBlank(a.ContentType)){ 
                     if(a.ContentType.contains('application/x-zip-compressed') || a.ContentType.contains('zip')){
                        Trigger.new[0].addError(System.Label.MSD_CORE_Attachment_Type_Warning);
                        return;
                     }
                  }
                   
                  Decimal mb = Decimal.ValueOf(a.BodyLength);
                  mb = mb.divide((1024*1024),2);
                  c.MSD_CORE_Attachment_Size__c = c.MSD_CORE_Attachment_Size__c + mb;
                  
                  if(c.MSD_CORE_Attachment_Size__c > 21){
                     Trigger.new[0].addError(System.Label.MSD_CORE_Attachment_Size_Exceeded_Warning);
                     return;
                  }
                  
                  System.Debug('Satish Attachment size in Bytes: '+c.MSD_CORE_Attachment_Size__c);
                  System.debug('Satish Attachment Body Length: '+a.BodyLength);
                  
                  if(!String.isBlank(a.ContentType)){ 
                     System.debug('Satish Attachment Content: '+a.ContentType );
                  }
                   
                  System.Debug('Satish Attachment size in Bytes: '+c.MSD_CORE_Attachment_Size__c);
               }
                
               c.MSD_CORE_Attachment_Count__c++;
                
               if(c.MSD_CORE_Attachment_Count__c > 30){
                  Trigger.new[0].addError(System.Label.MSD_CORE_Attachment_Count_Exceeded_Warning);
                  return;
               }                     
            }
            
            
            if(c.MSD_CORE_Attachment_IDs__c != '') {
                c.MSD_CORE_Attachment_IDs__c = c.MSD_CORE_Attachment_IDs__c.subString(0,c.MSD_CORE_Attachment_IDs__c.length()-1);
                //c.MSD_CORE_Attachment_Size__c = c.MSD_CORE_Attachment_Size__c;
                System.Debug('Satish Attachment sizein MB: '+c.MSD_CORE_Attachment_Size__c);
                System.Debug('Satish Attachment count: '+c.MSD_CORE_Attachment_Count__c);
                System.Debug('Satish Attachment Ids: '+c.MSD_CORE_Attachment_IDs__c);
            }
        }
        
        if(cases.size() > 0) {
           update cases; 
        }
    }
}