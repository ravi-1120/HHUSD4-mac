public with sharing class MSD_CORE_EmailMessageAsAtt implements TriggersMVN.HandlerInterface{
    public void handle() { 
        List<EmailMessage> messages = Trigger.new;
        List<Attachment> atList = new List<Attachment>();
        String attName='';
        String EmailTemplate_name = '';
        Map<String, Email_to_Attachment_MetaData__mdt> eAttMap = Email_to_Attachment_MetaData__mdt.getAll();
        Map<String,EmailTemplate> emailTempMap = new Map<String,EmailTemplate>();    
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        List<String> CaseIDs = new List<String>();
        if(!eAttMap.isEmpty())
        {
            for(EmailTemplate e : [Select Id,name,Subject,Description,HtmlValue,DeveloperName,Body,BrandTemplateId  from EmailTemplate where DeveloperName in :eAttMap.keySet() and IsActive = true])
            {
                emailTempMap.put(e.Id,e);
                EmailTemplate_name = e.name;
                EmailTemplate_name = EmailTemplate_name.replaceAll('_', '') ;
                EmailTemplate_name =EmailTemplate_name.replace('Info Template', '');
                
            }
            for(EmailMessage m : messages)
            {
                
                if( (m.Subject.contains(EmailTemplate_name)) &&(m.EmailTemplateId == null) && (!String.isBlank(m.ParentId)))
                    {
                        List<String> listOfIds = new List<String>(emailTempMap.keyset());
                        
                         String sObjName = m.ParentId.getSObjectType().getDescribe().getName(); 
                    if(!emailTempMap.isEmpty() &&  emailTempMap.containsKey(listOfIds[0]) && sObjName == 'Case')
                    {
                        CaseIDs.add(m.ParentId);
                    }
                    }
                if(!String.isBlank(m.ParentId))
                {
                    String sObjName = m.ParentId.getSObjectType().getDescribe().getName(); 
                    if(!emailTempMap.isEmpty() &&  emailTempMap.containsKey(m.EmailTemplateId) && sObjName == 'Case')
                    {
                        CaseIDs.add(m.ParentId);
                    }
                }
            }
            
            if(CaseIDs.size() > 0)
            {
                
                Map<id,Case> caseMap = new Map<id,Case>([select id,CaseNumber,RecordTypeId from Case where id in: CaseIDs]);
                for(EmailMessage m : messages) 
                {
                    String pdfBodyString = '<html><body>';
                    if(!String.isBlank(m.FromAddress))
                    {
                        pdfBodyString+= '<p>From Address : ' + m.FromAddress + '</p>';
                    }
                    if(!String.isBlank(m.ToAddress))
                    {
                        pdfBodyString+= '<p>To Address : ' + m.ToAddress + '</p>';
                    }
                    if(!String.isBlank(m.BccAddress))
                    {
                        pdfBodyString+= '<p>Bcc Address : ' + m.BccAddress + '</p>';
                    }
                    if(!String.isBlank(m.CcAddress))
                    {
                        pdfBodyString+= '<p>Cc Address : ' + m.CcAddress + '</p>';
                    }
                    if(!String.isBlank(m.Subject))
                    {
                        pdfBodyString+= '<p>Subject : ' + m.Subject + '</p>';
                    }
                    
                    pdfBodyString+= '<br/><br/><br/><br/><br/></body></html>'+m.HtmlBody;
                    
                    Attachment att=new Attachment();
                    If(m.EmailTemplateId ==null && (m.Subject.contains(EmailTemplate_name)) )
                    {
                       List<String> listOfIds = new List<String>(emailTempMap.keyset());
                     attName = eAttMap.get(emailTempMap.get(listOfIds[0]).DeveloperName).Attachment_Name__c;
     
                    }
                    else
                    {
                       attName = eAttMap.get(emailTempMap.get(m.EmailTemplateId).DeveloperName).Attachment_Name__c;
       
                    }
                                 
                    if(!caseMap.isEmpty() &&  caseMap.containsKey(m.ParentId))
                    {
                        String caseNum = caseMap.get(m.ParentId).CaseNumber;
                        att.Name=attName+caseNum+'.pdf';
                        
                    }
                    else
                    {
                        att.Name=attName+ '.pdf';
                        
                    }
                    att.parentId=m.ParentId;
                    att.Body = Blob.toPDF(pdfBodyString.replaceall('src',''));
                    atList.add(att);
                    
                    
                }
                
                if(atList.size() > 0)
                {
                    insert atList;   
                }
            }
        }
        
    }
    
}