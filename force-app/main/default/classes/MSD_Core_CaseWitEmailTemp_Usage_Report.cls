/*
 *  Created By:     Priyanka Tiwari
 *  Created Date:   06/07/2022
 *  Description:   This class is created to generate a report on EmailTemplate Usage
 */

public class MSD_Core_CaseWitEmailTemp_Usage_Report implements TriggersMVN.HandlerInterface {
    
    public void handle() { 
        
        List<EmailMessage> messages = Trigger.new;
        
        List<MSD_Core_Case_With_Email_Template__c> DatatoInsert = new List<MSD_Core_Case_With_Email_Template__c>();
        for(EmailMessage e: messages)
        {
            
            if(e.ParentId.getSObjectType().getDescribe().getName()=='case' && e.EmailTemplateId !=null)
            {
              MSD_Core_Case_With_Email_Template__c att =  new MSD_Core_Case_With_Email_Template__c();
                if(!String.isBlank(e.ParentId))
                {
                    att.Case__c= e.ParentId;
                }
                if(!String.isBlank(e.FromAddress)){
                    att.MSD_Core_FromAddress__c = e.FromAddress;
                }
                
                if(!String.isBlank(e.ToAddress)){
                     att.MSD_Core_ToAddress__c = e.ToAddress;
                }
               
                System.debug('att.ToAddress__c');
                if(!String.isBlank(e.CreatedById)){
                    User us =new user() ;
                        us= [select name from user where id=:e.CreatedById limit 1];
                    att.MSD_Core_Representative_Name__c =us.Name;
                }
                if(!String.isBlank(e.EmailTemplateId)){
                EmailTemplate mail = [select id, name from EmailTemplate where id=:e.EmailTemplateId  ];
                    att.MSD_Core_Email_Template_name__c = mail.name;
                }
                   if(!String.isBlank(e.ParentId))
                   {
                case cs = [select id,type,casenumber from case where id =:e.ParentId limit 1];
                       System.debug('cs>>>>>>>>>>'+cs);
                        att.MSD_Core_Type__c=cs.type;
                        att.case_number__c= cs.casenumber;
                   }
              
                if(e.HasAttachment==true)
                {
                     string attachment= string.valueOf(e.HasAttachment);
                     att.MSD_Core_HasAttachment__c= attachment;
                    List<ContentDocumentLink > cndLnk = new List<ContentDocumentLink >();
                    set<id> ids = new set<id>();
                    cndLnk = [SELECT ContentDocumentId,ContentDocument.Title,ShareType,SystemModstamp,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT ID From EmailMessage WHERE ParentId =:e.ParentId) order by SystemModstamp desc limit 1];
                      for(integer i=0; i<cndLnk.size();i++ )
                      {
                         ids.add(cndLnk[i].ContentDocumentId) ;
                      }
                    System.debug('cndLnk>>>>>>>'+cndLnk);
                                    
                ContentDocument cdDoc = [Select id, Title, FileType,CreatedDate, ContentSize from ContentDocument where   Id =:ids order by CreatedDate  limit 1  ];
                       System.debug('cdDoc>>>>'+cdDoc);
                  // System.debug('CreatedDate>>>>>>'+cdDoc.CreatedDate);     
                        if(cdDoc !=null)
                    {
                        att.MSD_Core_Email_Attachment_Name__c =cdDoc.Title;}
                }
                
                DatatoInsert.add(att);
            }
            
      
        }
        
        if(DatatoInsert.size()> 0)
        {
            insert DatatoInsert;
        }
        
       
    }

}