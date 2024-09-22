/*
 * CaseControllerMVN 
 * Created By:      Prasanjeet Sharma
 * Created Date:    6/19/2019
 * Description:     This class returns the translated record type name of the class
 *                  to be displayed on the Case Record Type page.  It also determines
 *                  if the Request is an Adverse Event/PQC or Temperature Excursion in
 *                  order to display the appropriate disclaimer in the Case Record Type
 *                  page.  
 */
public with sharing class CaseControllerMVN {
    @AuraEnabled
    public static Case queryCase(String csId)
    {
        Schema.DescribeSObjectResult r = Case.sObjectType.getDescribe();
        List<String> apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            apiNames.add(apiName);
            system.debug('apiNames>>>>>>>>>'+apiNames);
        }
        
        List<Case> caseList = database.query('select ' + String.join(apiNames, ',') + ', RecordType.Name from Case where id =: csId'); 
        system.debug('caseList>>>>>>>line 23'+caseList);
        if(caseList.size() > 0)
        {
            return caseList[0];
        }
        
        return null;
    }
    
    @AuraEnabled
    public static List<CaseAERequiredFieldWrapper> queryCaseFields(String csId)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Case');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        Map<String,Schema.FieldSet> fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap();
        
        List<CaseAERequiredFieldWrapper> fieldWrapperList = new List<CaseAERequiredFieldWrapper>();
        
        Schema.DescribeSObjectResult r = Case.sObjectType.getDescribe();
        List<String> apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            apiNames.add(apiName);
        }
        
        List<Case> caseList = database.query('select ' + String.join(apiNames, ',') + ', RecordType.Name from Case where id =: csId'); 
        User user = [select id, Name, ProfileId, Profile.Name from User where id =: UserInfo.getUserId()];
        
        System.debug('caseList ->'+caseList);        
        if(caseList.size() > 0)
        {
            Case cs = caseList[0];
            System.debug('cs.OwnerID -->'+cs.OwnerId);
            String recordTypeName = cs.RecordType.Name.toUpperCase().split(' - ')[0].replace(' ', '_');
            
            for(String key : fieldSetObj.keyset())
            {
                if(key.toUpperCase().startsWith(recordTypeName))
                {
                    Schema.FieldSet s = fieldSetObj.get(key);
                    
                    List<FieldWrapper> fieldList = new List<FieldWrapper>();
                    
                    for(Schema.FieldSetMember fieldSetMemberObj : s.getFields())
                    {
                        fieldList.add(new FieldWrapper(fieldSetMemberObj.getFieldPath(),
                                                       fieldSetMemberObj.getLabel(),
                                                       fieldSetMemberObj.getRequired(),
                                                       fieldSetMemberObj.getDbRequired(),
                                                       fieldSetMemberObj.getType()+''));
                    }
                    
                    if(fieldList.size() > 0)
                        fieldWrapperList.add(new CaseAERequiredFieldWrapper(user, cs, key.toUpperCase().replaceFirst(recordTypeName.toUpperCase().replace(' ', '_') , '').replace('_', ' '), fieldList));
                }
            }
        }
        
        return fieldWrapperList;
    }
    
    
    public static List<Schema.FieldSetMember> readFieldSet(Schema.DescribeSObjectResult DescribeSObjectResultObj, String fieldSetName, String ObjectName)
    {
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
    
        return fieldSetObj.getFields(); 
    }  
    
    
    public class CaseAERequiredFieldWrapper
    {
        @AuraEnabled public User user {get;set;}
        @AuraEnabled public Case cs {get;set;}
        @AuraEnabled public String sectionName {get;set;}
        @AuraEnabled public List<FieldWrapper> fieldList {get;set;}
        
        public CaseAERequiredFieldWrapper(User user, Case cs, String sectionName, List<FieldWrapper> fieldList)
        {
            this.user = user;
            this.cs = cs;
            this.sectionName = sectionName;
            this.fieldList = fieldList;
        }
    }
    
    
    public static boolean checkFieldValueNull(sObject o, String fieldName)
    {
        return o.get(fieldName) == null ? true : false;
    }
    
    
    public class FieldWrapper
    {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public boolean isRequired;
        @AuraEnabled public boolean isDBRequired;
        @AuraEnabled public String type;
        
        public FieldWrapper(String fieldName,
                            String fieldLabel,
                            boolean isRequired,
                            boolean isDBRequired,
                            String type)
        {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isRequired = isRequired;
            this.isDBRequired = isDBRequired;
            this.type = type;
        }
    }
    
    
    @AuraEnabled
    public static Case getAEFieldsData(String csId) { 
        return [select id, AccountId, RecordTypeId, RecordType.Name, MSD_CORE_Event_Case_Type__c,
                RecordType.DeveloperName, Type, Status, MSD_CORE_Disclaimer_Read__c,
                Patient_First_Name_MVN__c, Patient_Last_Name_MVN__c, MSD_CORE_AE_Patient_Age__c, MSD_CORE_AE_Patient_Gender__c, MSD_CORE_AE_Patient_Height__c, 
                MSD_CORE_AE_Patient_Weight__c, MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c, MSD_CORE_AE_Is_Patient_Pregnant__c,MSD_CORE_AE_Was_Treatment_Given_for_AE__c, 
                MSD_CORE_AE_Did_the_Patient_Die__c, MSD_CORE_AE_Hospitalization_or_Prolonged__c, MSD_CORE_AE_Life_Threatening__c,MSD_CORE_AE_Sig_Disability_or_Incapacity__c,
                MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c,MSD_CORE_AE_Intervention_Prevent_Serious__c,MSD_CORE_AE_Patient_Overdose__c,MSD_CORE_AE_IRRE_Reported__c,
                MSD_CORE_AE_Insertion_Difficulty__c,MSD_CORE_AE_Multiple_Insertion__c,MSD_CORE_AE_Deep_Insertion__c,MSD_CORE_AE_Incorrect_Insertion__c,
                MSD_CORE_AE_Implant_Broken_Cut__c,MSD_CORE_AE_Implant_Bent__c,MSD_CORE_AE_Implant_Palpable_At_Any_Time__c,MSD_CORE_AE_Doubt_About_Presence__c,
                MSD_CORE_AE_Implant_Located_Ultrasound__c,MSD_CORE_AE_Implant_Located_by_MRI__c,MSD_CORE_AE_Localization_Problem__c,MSD_CORE_AE_Migration__c,
                MSD_CORE_AE_Removal_Problem__c,MSD_CORE_AE_Removal_Under_Anesthesia__c,MSD_CORE_AE_Partial_Complete_Expulsion__c,MSD_CORE_AE_Significant_Fibrosis__c,
                MSD_CORE_AE_Incision_Enlarged__c,AE_Start_Date_MVN__c,MSD_CORE_AE_Therapy_Start_Date__c,MSD_CORE_AE_Therapy_End_Date__c,MSD_CORE_AE_Recovery_Date__c,
                MSD_CORE_AE_Date_of_Death__c,MSD_CORE_AE_IRRE_Onset_Date__c,MSD_CORE_AE_Implant_Insertion_Date__c,MSD_CORE_AE_Implant_Removal_Date__c,
                MSD_CORE_AE_Sought_Medical_Attention__c,MSD_CORE_AE_Description__c,MSD_CORE_AE_Route_of_Administration__c,MSD_CORE_AE_Was_Therapy_Discontinued__c,
                MSD_CORE_AE_Indication__c,MSD_CORE_AE_Treatment_Provided__c,MSD_CORE_AE_Concomitant_Medication__c,MSD_CORE_AE_Pertinent_Medical_History__c,
                MSD_CORE_AE_Drug_Reactions_Allergies__c,MSD_CORE_AE_Lab_Diagnostics_Studies__c,MSD_CORE_AE_Dechallenge__c,MSD_CORE_AE_Rechallenge__c,
                MSD_CORE_AE_Present_Status__c,MSD_CORE_AE_Cause_of_Death__c,MSD_CORE_AE_Insertion_Difficulty_Details__c,MSD_CORE_AE_Multiple_Insertion_Details__c,
                MSD_CORE_AE_Deep_Insertion_Details__c,MSD_CORE_AE_Insertion_Location__c,MSD_CORE_AE_Doubt_Details__c,MSD_CORE_AE_Migration_Details__c,
                MSD_CORE_AE_Removal_Problem_Details__c,MSD_CORE_AE_Procedure_Used_for_Removal__c,MSD_CORE_AE_Anesthesia_Removal_Details__c,MSD_CORE_AE_Expulsion_Details__c,
                MSD_CORE_AE_Other_IRRE_Details__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,MSD_CORE_PSP_Company__c,MSD_CORE_PSP_Number__c,MSD_CORE_PSP_Program_Name__c,
                MSD_CORE_PSP_Number_Other__c,MSD_CORE_PSP_Program_Name_Other__c,MSD_CORE_PSP_Agent_Name__c,MSD_CORE_PSP_Company_Other__c
                from Case where id =: csId];
    }
    
     @AuraEnabled
    public static Case getRequestFieldsData(String csId) { 
        return [select id, MSD_CORE_Campaign__c,Product_MVN__c,case_State_MVN__c,MSD_CORE_PCC_Agent_Request_Case_Closed__c,OwnerId
                from Case where id =: csId];
    }
    
    @AuraEnabled
    public static List<CaseAERequiredFieldWrapper> queryAERequiredFields(String csId)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Case');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        Map<String,Schema.FieldSet> fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap();
        
        List<CaseAERequiredFieldWrapper> fieldWrapperList = new List<CaseAERequiredFieldWrapper>();
        
        Schema.DescribeSObjectResult r = Case.sObjectType.getDescribe();
        List<String> apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            apiNames.add(apiName);
        }
        
        List<Case> caseList = database.query('select ' + String.join(apiNames, ',') + ', RecordType.Name from Case where id =: csId'); 
        User user = [select id, Name, ProfileId, Profile.Name from User where id =: UserInfo.getUserId()];
        
        if(caseList.size() > 0)
        {
            Case cs = caseList[0];
            
            for(String key : fieldSetObj.keyset())
            {
                if(key.toUpperCase().contains('MSD_CORE_AE_RF_'))
                {
                    Schema.FieldSet s = fieldSetObj.get(key);
                    
                    List<FieldWrapper> fieldList = new List<FieldWrapper>();
                    
                    for(Schema.FieldSetMember fieldSetMemberObj : s.getFields())
                    {
                        if(checkFieldValueNull(cs, fieldSetMemberObj.getFieldPath()))
                        {
                            fieldList.add(new FieldWrapper(fieldSetMemberObj.getFieldPath(),
                                                           fieldSetMemberObj.getLabel(),
                                                           fieldSetMemberObj.getRequired(),
                                                           fieldSetMemberObj.getDbRequired(),
                                                           fieldSetMemberObj.getType()+''));
                        }
                    }
                    
                    if(fieldList.size() > 0)
                        fieldWrapperList.add(new CaseAERequiredFieldWrapper(user, cs, key.toUpperCase().replace('MSD_CORE_AE_RF_', '').replace('_', ' '), fieldList));
                }
            }
        }
        
        return fieldWrapperList;
    }
    
    
    @AuraEnabled
    public static String updateCaseStatus(String csId, String status) { 
        try
        {
            if(status != 'Open'){
                update new Case(id = csId, Status = status);
                return 'Success';
            }
            else{
                User objUser = [SELECT Id, Profile.Name, MSD_CORE_Service_Cloud_Manager__c FROM User WHERE Id = :UserInfo.getUserId()];
                if(objUser.MSD_CORE_Service_Cloud_Manager__c || objUser.Profile.Name == 'System Administrator' || objUser.Profile.Name == 'System Administrator - Lightning'){
                    update new Case(id = csId, Status = status);
                    return 'Success';
                }
                else{
                    AuraHandledException e = new AuraHandledException('You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.');
                    e.setMessage('You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.');
                    system.debug(e);
                    throw e;
                    //throw new AuraHandledException('You are not authorized to Reopen the Case.');
                }
            }         
        }
        catch(Exception ex)
        {
            
            String error = ex.getMessage();
            
            if(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))
                error = error.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1].replace(': []', '');
            
            return error;
        }
    }
    
    @AuraEnabled
    public static String getSessionIdFromVFPage(){
        String content = Page.MSD_CORE_SessionId.getContent().toString();
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                e = content.indexOf('End_Of_Session_Id');
        return content.substring(s, e);
    }
    
    
    @AuraEnabled
    public static SendEmailWrapper getSendEmailData(String csId)
    {
        SendEmailWrapper sendEWrap = new SendEmailWrapper();
        
        List<String> fromEmailList = new List<String>();
        
        Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
        
        if(serviceCloudSettings.NSC_Group_Email__c != null)
            fromEmailList.add('"' + serviceCloudSettings.NSC_Group_Email__c + '" <' + serviceCloudSettings.NSC_Group_Email__c + '>');
        
        fromEmailList.add('"' + UserInfo.getName() + '" <' + UserInfo.getUserEmail() + '>');
        
        /*for(EmailServicesAddress email : [SELECT Id,AuthorizedSenders,EmailDomainName,IsActive,LocalPart FROM EmailServicesAddress where EmailDomainName !=: serviceCloudSettings.NSC_Group_Email__c])
        {
            fromEmailList.add('"' + email.AuthorizedSenders + '" <' + email.EmailDomainName + '>');
        }
        */
        
        for(OrgWideEmailAddress email : [select Id, DisplayName, Address from OrgWideEmailAddress where Address !=: serviceCloudSettings.NSC_Group_Email__c])
        {
            fromEmailList.add('"' + email.DisplayName + '" <' + email.Address + '>');
        }
        
        List<Case> csList = [select Id, Status, CaseNumber, RecordType.Name, RecordType.DeveloperName, MSD_CORE_Event_Case_Type__c from Case where id =: csId limit 1];
        if(csList.size() > 0)
        {
            Case cs = csList[0];
            User user = [select id, Profile.Name from User where id =: UserInfo.getUserId()];
            
            if(cs.RecordType.DeveloperName != null){
                sendEWrap.isValid = true;
                
                if(user.Profile.Name.contains('Read Only User'))
                    sendEWrap.isValid = false;
            }else
                sendEWrap.isValid = false;
            if (cs.RecordType.Name =='Interaction')
                sendEWrap.isValid = true;
            if(cs.Status != 'Open')
                sendEWrap.isValid = false;
            if (cs.RecordType.DeveloperName =='MSD_CORE_Compensation_Request_Closed' || cs.RecordType.DeveloperName =='Request_Closed_MVN' )
                sendEWrap.isValid = true;
            
            sendEWrap.caseId = cs.Id;
            sendEWrap.caseNumber = cs.CaseNumber;
            sendEWrap.fromEmailList = fromEmailList;
            sendEWrap.fromEmail = fromEmailList[0];
            sendEWrap.folderList = [select Id, Name from Folder where (Type = 'Email' or Type = 'EmailTemplate') Order BY Name];
            sendEWrap.bccEmail = UserInfo.getUserEmail();
            sendEWrap.emailTemplateList = [select Id, Name from EmailTemplate where FolderId =: sendEWrap.folderList[0].Id and IsActive = true];
            sendEWrap.subject = '';
            sendEWrap.body = '';
            sendEWrap.toEmail = '';
            sendEWrap.ccEmail = '';
        }
        else
        {
            sendEWrap.isValid = false;
        }
        
        return sendEWrap;
    }
    
    @AuraEnabled
    public static boolean getValidCase(String csId)
    {
        boolean isValid = true;
        List<Case> csList = [select Id, Status, CaseNumber, RecordType.Name, MSD_CORE_Event_Case_Type__c from Case where id =: csId limit 1];
        if(csList.size() > 0)
        {
            Case cs = csList[0];
            User user = [select id, Profile.Name from User where id =: UserInfo.getUserId()];
            
            if(cs.RecordType.Name != null && cs.RecordType.Name != 'Interaction'){
                isValid = true;
                
                if(user.Profile.Name.contains('Read Only User'))
                    isValid = false;
            }else
                isValid = false;
                
            if(cs.Status != 'Open')
                isValid = false;
            if(cs.Status == 'Submitted')
                isValid = true;
        }
        else
        {
            isValid = false;
        }
        
        return isValid;
    }
    
    @AuraEnabled
    public static List<EmailTemplate> getEmailTemplateList(String folderId)
    {
        return [select Id, Name from EmailTemplate where FolderId =: folderId and IsActive = true];
    }
    
    
    @AuraEnabled
    public static String getEmailBody(String csId, String templateId)
    {
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE id =: templateId];
        
        Messaging.reserveSingleEmailCapacity(1);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{'invalid@emailaddr.es'};
        mail.setToAddresses(toAddresses);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(false);
        mail.setSenderDisplayName(UserInfo.getName());
        mail.setTargetObjectId([select id from Contact where Email != null limit 1].Id);
        mail.setWhatId(csId);
        mail.setTemplateId(et.Id);

        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        allmsg.add(mail);
        
        Savepoint sp = Database.setSavepoint();
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        Database.rollback(sp);
        
        return mail.getSubject() + '<~~~~>' + mail.getHTMLBody();
    }
    
    
    public class SendEmailWrapper
    {
        @AuraEnabled 
        public String caseId {get;set;}
        @AuraEnabled 
        public String caseNumber {get;set;}
        @AuraEnabled 
        public String fromEmail {get;set;}
        @AuraEnabled 
        public String bccEmail {get;set;}
        @AuraEnabled 
        public String toEmail {get;set;}
        @AuraEnabled 
        public String ccEmail {get;set;}
        @AuraEnabled 
        public String subject{get;set;}
        @AuraEnabled 
        public String body {get;set;}
        @AuraEnabled 
        public boolean isValid {get;set;}
        @AuraEnabled 
        public List<String> fromEmailList {get;set;}
        @AuraEnabled 
        public List<Folder> folderList {get;set;}
        @AuraEnabled 
        public List<EmailTemplate> emailTemplateList {get;set;}
    }
    
    
    
    @AuraEnabled 
    public static String SendeMail(SendEmailWrapper data, String fromEmailId, String toEmail, String ccEmail, String contactId, List<String> attIds){
        system.debug('contactId :::::' + contactId);
        List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();     
        
        // Step 1: Create a new Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        List<Contact> contactList = [select id, Email from Contact where id =: contactId and Email != null];
        
        // Step 2: Set list of people who should get the email
        List<String> sendTo = new List<String>();
        
        if(contactList.size() > 0)
            sendTo.add(contactList[0].Email);    
        
        if(toEmail != null && toEmail.contains(';'))
            sendTo.addAll(toEmail.split(';'));
        else if(toEmail != null && toEmail.trim().length() > 0)
            sendTo.add(toEmail);
        
        if(sendTo.size() > 0)
            mail.setToAddresses(sendTo);
        
        if(ccEmail != null && ccEmail.trim() != '')
        {
            List<String> sendCc = new List<String>();
            sendCc.add(ccEmail);
            mail.setCcAddresses(sendCc);
        }
        
        if(data.bccEmail != null && data.bccEmail.trim() != '')
        {
            List<String> sendCc = new List<String>();
            sendCc.add(data.bccEmail);
            mail.setBccAddresses(sendCc);
        }
        
        
        // Step 3: Set who the email is sent from
        //mail.setReplyTo('noreply@gmail.com'); 
        //mail.setSenderDisplayName('salesforce User'); 
        
        String fromEmail = null;
        if(!String.isBlank(fromEmailId))
        {
            if(fromEmailId != null && fromEmailId.contains('<'))
            {
                fromEmail = fromEmailId.split('<')[1].split('>')[0];
            }
        }
        else{
            if(data.fromEmail != null && data.fromEmail.contains('<'))
            {
                fromEmail = data.fromEmail.split('<')[1].split('>')[0];
            }
        }
        
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: fromEmail];
        
        if ( owea.size() > 0 ) { mail.setOrgWideEmailAddressId(owea.get(0).Id); }
        
        // Step 4. Set email contents - you can use variables!
        mail.setSubject(data.subject);
        mail.setHtmlBody(data.body);
        mail.setSaveAsActivity(true);

        // Create the email attachment    
        List<Attachment> attList = [SELECT Id, Name, ContentType, CreatedDate, Body 
                                      FROM Attachment 
                                      WHERE ParentId =: data.caseId
                                      AND id in : attIds
                                      Order By CreatedDate desc];

        if(attList.size() > 0)
        {                      
            List<Messaging.EmailFileAttachment> emailAttachList = new List<Messaging.EmailFileAttachment>();
            
            for(Attachment a : attList)
            {                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(a.Name);
                efa.setBody(a.Body);
                
                emailAttachList.add(efa);
            }
            
            mail.setFileAttachments(emailAttachList);
        }
        
        // Step 5. Add your email to the master list
        mails.add(mail);
        
        
        // Step 6: Send all emails in the master list
        try{
            Messaging.sendEmail(mails);
            
            EmailMessage emailMsg = new EmailMessage(); // Created a EmailMessage and copy all details from above.
            emailMsg.ToAddress=(mails[0].getToAddresses())[0];
            emailMsg.Subject=mails[0].getSubject();
            emailMsg.HtmlBody=mails[0].getHtmlBody();
            emailMsg.ParentId = data.caseId; //Attach with the case
            emailMsg.MessageDate = system.now();
            emailMsg.FromAddress = fromEmail;
            /*
            if(data.fromEmail != null && data.fromEmail.contains('<'))
                fromEmail = data.fromEmail.split('<')[1].split('>')[0];
            System.debug('fromEmail -->'+fromEmail);
            emailMsg.FromAddress = fromEmail;
            */
            
            emailMsg.Status = '0';
            insert emailMsg;
            
            List<Attachment> attIList = new List<Attachment>();
            
            for(Attachment a : attList)
            {                
                Attachment aa = a.clone(false, false);
                aa.ParentId = emailMsg.Id;
                
                attIList.add(aa);
            }
            
            if(attIList.size() > 0)
                insert attIList;
            
            return 'Success';
        }
        catch(Exception ex) 
        {
            String error = ex.getMessage();
            
            if(error.contains('REQUIRED_FIELD_MISSING,'))
                error = error.split('REQUIRED_FIELD_MISSING,')[1].replace(': []', '');
            else if(error.contains('INVALID_EMAIL_ADDRESS,'))
                error = error.split('INVALID_EMAIL_ADDRESS,')[1].replace(': []', '');
                
            return error;
        }
    }           
    
    
    // Setup the Type picklist
    @AuraEnabled 
    public static List<String> getTypeSelectOptions(boolean isPersonSearch){
        List<String> typeSelectOptions = new List<String>();
        List<String> typeNewSelectOptions = new List<String>();        
        typeNewSelectOptions.add(Label.Picklist_Select_Option);

        Schema.DescribeFieldResult fieldResult = Account.Class_of_Trade_MRK__c.getDescribe();
        List<Schema.PicklistEntry> typeOptions = fieldResult.getPicklistValues();
        
        Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
        String  hcpType = serviceCloudSettings.MSD_CORE_HCP_Type__c;
        String hbpType = serviceCloudSettings.MSD_CORE_HBP_Type__c;
        
        if(isPersonSearch){            
            Set<String> validTypes = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.Person_Account_Search_Types_MVN__c));
            for(Schema.PicklistEntry typeOption : typeOptions){
                String typeValue = typeOption.getValue();
                String typeLabel = typeOption.getLabel();
                if(validTypes.contains(typeValue)){                
                    if(typeValue == hcpType){
                        typeNewSelectOptions.add(typeLabel + ' ' + Label.MSD_CORE_Prescriber_Type_Suffix);
                        typeNewSelectOptions.add(typeLabel + ' ' + Label.MSD_CORE_Non_Prescriber_Type_Suffix);
                    } else {
                        typeNewSelectOptions.add(typeValue);
                    }
                    typeSelectOptions.add(typeValue);
                }
            }
        } else {
            Set<String> businessTypes = new Set<String>();
            Map<String, String> typeToRecordTypeIdMapping = new Map<String, String>();
            List<MSD_CORE_Type_To_Record_Type_Map__c> mapSettingsList = MSD_CORE_Type_To_Record_Type_Map__c.getAll().values();
            
            Map<String,RecordType> recordTypes = new Map<String,RecordType>();
            for(RecordType rt : [SELECT Id, Name, DeveloperName, IsActive, IsPersonType FROM RecordType WHERE sObjectType = 'Account']){
                recordTypes.put(rt.DeveloperName,rt);
            }
            
            for(MSD_CORE_Type_To_Record_Type_Map__c mapSetting : mapSettingsList){
                if(!recordTypes.containsKey(mapSetting.MSD_CORE_Record_Type_MVN__c)){
                    continue;                
                }
    
                if(!typeToRecordTypeIdMapping.containsKey(mapSetting.MSD_CORE_Type_MVN__c)){
                    typeToRecordTypeIdMapping.put(mapSetting.MSD_CORE_Type_MVN__c, recordTypes.get(mapSetting.MSD_CORE_Record_Type_MVN__c).Id);
                }
    
                if(!mapSetting.MSD_CORE_Is_Person_Type__c){
                    businessTypes.add(mapSetting.MSD_CORE_Type_MVN__c);
                }
            }
        
            for(Schema.PicklistEntry typeOption : typeOptions){
                String typeValue = typeOption.getValue();
                String typeLabel = typeOption.getLabel();
                if(businessTypes.contains(typeValue)){
                    typeNewSelectOptions.add(typeValue);
                }
            }
        }
        
        return typeNewSelectOptions;
    }
    
    
    @AuraEnabled
    public static Service_Cloud_Settings_MVN__c getServiceCloudSettings(){
        return Service_Cloud_Settings_MVN__c.getInstance();
    }
    
    
    @AuraEnabled 
    public static String typeSelected(String selectedType){
        boolean isPrescriber = false;
        boolean isDCR = false;
        String cleanSelectedType = selectedType;
        if(cleanSelectedType.endsWithIgnoreCase(Label.MSD_CORE_Prescriber_Type_Suffix)){
            isPrescriber = true;
            cleanSelectedType = cleanSelectedType.removeEnd(' ' + Label.MSD_CORE_Prescriber_Type_Suffix);
        }

        if(cleanSelectedType.endsWithIgnoreCase(Label.MSD_CORE_Non_Prescriber_Type_Suffix)){
            cleanSelectedType = cleanSelectedType.removeEnd(' ' + Label.MSD_CORE_Non_Prescriber_Type_Suffix);
        }
        
        Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
        String hcpType = serviceCloudSettings.MSD_CORE_HCP_Type__c;
        Map<String, String> typeToRecordTypeIdMapping = new Map<String, String>();
        
        List<MSD_CORE_Type_To_Record_Type_Map__c> mapSettingsList = MSD_CORE_Type_To_Record_Type_Map__c.getAll().values();
            
        Map<String,RecordType> recordTypes = new Map<String,RecordType>();
        for(RecordType rt : [SELECT Id, Name, DeveloperName, IsActive, IsPersonType FROM RecordType WHERE sObjectType = 'Account']){
            recordTypes.put(rt.DeveloperName,rt);
        }
        
        for(MSD_CORE_Type_To_Record_Type_Map__c mapSetting : mapSettingsList){
            if(!recordTypes.containsKey(mapSetting.MSD_CORE_Record_Type_MVN__c)){
                continue;                
            }

            if(!typeToRecordTypeIdMapping.containsKey(mapSetting.MSD_CORE_Type_MVN__c)){
                typeToRecordTypeIdMapping.put(mapSetting.MSD_CORE_Type_MVN__c, recordTypes.get(mapSetting.MSD_CORE_Record_Type_MVN__c).Id);
            }
        }
        system.debug('typeToRecordTypeIdMapping :::::' + typeToRecordTypeIdMapping);
        system.debug('cleanSelectedType :::::' + cleanSelectedType );
        
        
        if(cleanSelectedType == hcpType && isPrescriber){
            return [select Id from RecordType where SObjectType='Account' and DeveloperName = :serviceCloudSettings.HCP_Record_Type_MVN__c].Id;
        } else {
            system.debug('isPrescriber:::::' + typeToRecordTypeIdMapping.get(cleanSelectedType ));
            return typeToRecordTypeIdMapping.get(cleanSelectedType );
        }
        //isDCR = dcrRecordTypeIds.contains(createAccount.RecordTypeId);
    }
    
    
    @AuraEnabled 
    public static String updateCaseWithAccount(String csId, String accountId, String adressId, String type){
        Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
        List<String> dcrRecordTypeDeveloperNames = UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_DCR_Record_Types__c);
        List<RecordType> dcrRecordTypes = [select Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :dcrRecordTypeDeveloperNames];
        Set<Id> dcrRecordTypeIds = new Set<Id>();
        for(RecordType dcrRecordType : dcrRecordTypes){
            dcrRecordTypeIds.add(dcrRecordType.Id);
        }
        Schema.DescribeSObjectResult r = Account.sObjectType.getDescribe();
        List<String> apiNames =  new list<String>();
        for(Schema.SObjectField apiName : r.fields.getMap().values()){
            //The if condition is modified wrt CEF2F-20956
            if(apiName.getDescribe().getName().split('__').size() <= 2 && !apiName.getDescribe().getName().endsWith('__pc') )
                apiNames.add(apiName.getDescribe().getName());
        }
        Account createAccount = database.query('select ' + String.join(apiNames, ',') + ' from Account where Id =: accountId');
        Address_vod__c createAddress;
        
        r = Address_vod__c.sObjectType.getDescribe();
        apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            if(apiName != 'RecordTypeId' && apiName != 'Id')
                apiNames.add(apiName);
        }
        
        if(adressId != ''){
            createAddress = database.query('select ' + String.join(apiNames, ',') + ', Id, RecordTypeId from Address_vod__c where Id =: adressId');
            createAddress.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_vod__c' AND DeveloperName =: serviceCloudSettings.MSD_CORE_Company_Maintained_Rec_Type__c].Id; 
            
            update createAddress;
        }
        boolean isDCR = dcrRecordTypeIds.contains(createAccount.RecordTypeId);
        system.debug('isDCR :::::' + isDCR);
        
        if(createAccount.Class_of_Trade_Sub_MRK__c != null && createAccount.IsPersonAccount)
            createAccount.Class_of_Trade_Owner_MRK__c = createAccount.Class_of_Trade_Sub_MRK__c;
        
        Set<String> activePersonTypes = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_Active_Person_Types__c));
        
        if(activePersonTypes.contains(createAccount.Class_of_Trade_MRK__c)) {
            createAccount.Status_MRK__c = serviceCloudSettings.MSD_CORE_Account_Status_Active__c;
        }
                
        if(isDCR)
        {
            if(adressId == '')
            {
                
                MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(createAccount, null);
            }
            else
            {
                
                MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(createAccount, createAddress);}
        }
        
        Case cs = new Case(Id = csId);
        
        try
        {
            if(type == 'Customer')
                cs.AccountId = accountId;
            else if(type == 'Business')
                cs.MSD_CORE_Business__c = accountId;    
            else if(type == 'Referred')
                cs.Referred_By_MVN__c = accountId;
                
            system.debug('cs :::::' + cs);
            System.debug('accountId -->'+accountId);
            Account acc = [SELECT Phone, PersonEmail, Fax FROM Account WHERE Id = :accountId];
            List<Address_vod__c> lstAdd = [SELECT Id FROM Address_vod__c WHERE Account_vod__c = :accountId LIMIT 1];
            if(!lstAdd.isEmpty())
            {
                cs.Address_MVN__c = lstAdd[0].Id;
            }
            cs.Case_Account_Phone_MVN__c = acc.Phone;
            cs.Case_Account_Email_MVN__c = acc.PersonEmail;
            cs.Case_Account_Fax_MVN__c = acc.Fax;
        
            update cs;
            system.debug('cs --->' + cs);
        }
        catch(Exception ex){
            System.debug('Exception -->'+ex.getMessage());
            return ex.getMessage();
        }  
        return 'Success';
    }
    
    
    @AuraEnabled 
    public static String createRepFollowup(String csId, String accountId, String type){
        date dateInThreeDays = date.today().addDays(3);
        
        String contactId = '';
        List<Account> records = [SELECT PersonContactId FROM Account WHERE Id =: accountId];
        
        if(records.size() > 0) 
        {
            contactId = records[0].PersonContactId;
        }
        
        Task task = new Task(Subject = Label.MSD_CORE_Rep_Follow_Up,
                             OwnerId = UserInfo.getUserId(),
                             WhatId = csId,
                             ActivityDate = dateInThreeDays);
        insert task;
        
        
        return '/'+task.id+'/e?isdtp=vw';
    }
    
    
    @AuraEnabled
    public static Case queryCaseInformations(String csId){
        return [select id, AccountId, Account.Name, Address_MVN__c, case_Account_Email_MVN__c,
                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, MSD_CORE_Business__c, MSD_CORE_Business__r.Name,
                Referred_By_MVN__c, Referred_By_MVN__r.Name 
                from Case
                where id =: csId];
    }
    
    @AuraEnabled
    public static CustomerInfoWrapper getCustomerInfo(String csId){
        CustomerInfoWrapper wrap = new CustomerInfoWrapper();
        wrap.objCase = [SELECT Id, AccountId, Account.Name, Address_MVN__c, case_Account_Email_MVN__c,
                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, MSD_CORE_Business__c, MSD_CORE_Business__r.Name,
                Referred_By_MVN__c, Referred_By_MVN__r.Name 
                FROM Case
                WHERE id =: csId];
        system.debug('wrap.objCase>>>>>>>>>>'+wrap.objCase);
        if(wrap.objCase.AccountId != null){
            wrap.optionsMap = getFieldsMapPicklists(csId);
        }
        else{
            wrap.optionsMap = new Map<String, Map<String, String>>();
        }
        
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            wrap.isReadOnlyUser = true;
        }
        else{
            wrap.isReadOnlyUser = false;
        }
        
        return wrap;
    }
    
    @AuraEnabled
    public static CustomerInfoWrapper getCustomerInfo2(String csId){
        CustomerInfoWrapper wrap = new CustomerInfoWrapper();
        wrap.objCase = [SELECT Id, AccountId, Account.Name, Address_MVN__c, case_Account_Email_MVN__c,
                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, MSD_CORE_Business__c, MSD_CORE_Business__r.Name,
                Referred_By_MVN__c, Referred_By_MVN__r.Name 
                FROM Case
                WHERE id =: csId];
        System.debug(' wrap.objCase>>>>>>>>>>>>>line 851'+ wrap.objCase);
        if(wrap.objCase.AccountId != null){
            wrap.optionsMap = getFieldsMapPicklists(csId);
        }
        else{
            wrap.optionsMap = new Map<String, Map<String, String>>();
        }
        
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            wrap.isReadOnlyUser = true;
        }
        else{
            wrap.isReadOnlyUser = false;
        }
        
        return wrap;
    }
    
    @AuraEnabled
    public static Map<String,Map<String,String>> getFieldsMapPicklists(String caseId){
        String caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        List<Address_vod__c> lstaddressRecords = [SELECT Id, Name, Address_line_2_vod__c, City_vod__c, State_vod__c, Zip_vod__c
                          , Country_vod__c, Primary_vod__c, Fax_vod__c, Fax_2_vod__c, Phone_vod__c, Phone_2_vod__c
                       FROM Address_vod__c
                      WHERE Account_vod__c = :caseAccountId]; 
        Account currentCaseAccount = [SELECT Id, Phone, PersonHomePhone, PersonMobilePhone, PersonOtherPhone, Fax,
                                      PersonEmail, Alternate_Email_MRK__c, MSD_CORE_Contact_Center_Email__c
                                      FROM Account WHERE Id =:caseAccountId];
        
        Map<String,Map<String,String>> optionsMap = new Map<String,Map<String,String>>();  
        optionsMap.put('Address',new Map<String,String>());
        optionsMap.put('Phone',new Map<String,String>());
        optionsMap.put('Email',new Map<String,String>());
        optionsMap.put('Fax',new Map<String,String>());
        
        for (Address_vod__c ad : lstaddressRecords) {
            optionsMap.get('Address').put(ad.Id, 
                                            ad.Name + (ad.Address_line_2_vod__c != null ? ', ' + ad.Address_line_2_vod__c : '')
                                            + (ad.City_vod__c != null ? ', ' + ad.City_vod__c : '')
                                            + (ad.State_vod__c != null ? ', ' + ad.State_vod__c : '')
                                            + (ad.Zip_vod__c != null ? ', ' + ad.Zip_vod__c : ''));
        }
        
        Set<String> phoneList = dedupeAddressPicklists(currentCaseAccount, lstaddressRecords, true); 
        for(String phone : phoneList) {
            if(String.isNotBlank(phone)) {
                optionsMap.get('Phone').put(phone, phone); 
            }
        }
        
        Set<String> faxList = dedupeAddressPicklists(currentCaseAccount, lstaddressRecords, false); 
        for(String fax : faxList) {
            if(String.isNotBlank(fax)) {
                optionsMap.get('Fax').put(fax, fax); 
            }
        }
        
        for(String email : dedupeEmailPicklists(currentCaseAccount)) {
            if(String.isNotBlank(email)) {
                optionsMap.get('Email').put(email, email); 
            }
        }        
        return optionsMap;
    }
    
    
    private static Set<String> dedupeAddressPicklists(Account currentCaseAccount, List<Address_vod__c> addressRecords, Boolean isPhone) {
        Set<String> values = new Set <String>(); 
        if(isPhone) {
            values.add(currentCaseAccount.Phone);
            values.add(currentCaseAccount.PersonHomePhone);
            values.add(currentCaseAccount.PersonMobilePhone);
            values.add(currentCaseAccount.PersonOtherPhone);

            for(Address_vod__c adr : addressRecords) {
                values.add(adr.Phone_vod__c);
                values.add(adr.Phone_2_vod__c);
            }
        } else {
            values.add(currentCaseAccount.Fax);
            
            for(Address_vod__c adr : addressRecords) {
                values.add(adr.Fax_vod__c);
                values.add(adr.Fax_2_vod__c);
            }
        }
        return values; 
    }
    @TestVisible
    private static Set<String> dedupeEmailPicklists(Account currentCaseAccount) {
        Set<String> emails = new Set<String>();
        emails.add(currentCaseAccount.PersonEmail);
        emails.add(currentCaseAccount.Alternate_Email_MRK__c);
        emails.add(currentCaseAccount.MSD_CORE_Contact_Center_Email__c);
        return emails;
    }
    
    public class CustomerInfoWrapper{
        @AuraEnabled public Case objCase;
        @AuraEnabled public Map<String,Map<String,String>> optionsMap;
        @AuraEnabled public Boolean isReadOnlyUser;
    }
    
    @AuraEnabled
    public static void removeSelectedCustomer(String caseId){
        Case cs = new Case(Id = caseId);
        cs.AccountId = null;
        cs.ContactId = null;
        cs.Address_MVN__c = null;
        cs.case_Account_Email_MVN__c = null;
        cs.case_City_MVN__c = null;
        cs.case_AddressLine1_MVN__c = null;
        cs.case_AddressLine2_MVN__c = null;
        cs.case_State_MVN__c = null;
        cs.case_Postal_Code_MVN__c = null;
        cs.case_Account_Phone_MVN__c = null;
        cs.case_Account_Fax_MVN__c = null;
        update cs;
    }
    
    @AuraEnabled
    public static void removeSelectedReferredBy(String caseId){
        Case cs = new Case(Id = caseId);
        cs.Referred_By_MVN__c = null;
        cs.MSD_CORE_Referred_By_Customer_Type__c = null;
        update cs;
    }
    
    @AuraEnabled
    public static void removeSelectedBusiness(String caseId){
        Case cs = new Case(Id = caseId);
        cs.MSD_CORE_Business__c = null;
        update cs;
    }
    
    @AuraEnabled
    public static void updateAddress(String caseId, String addId){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Address_MVN__c = addId;
        update cs;
    }
    
    @AuraEnabled
    public static void updatePhone(String caseId, String accountPhoneText){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Case_Account_Phone_MVN__c = accountPhoneText;
        update cs;
    } 
    
    @AuraEnabled
    public static void updateEmail(String caseId, String emailText){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Case_Account_Email_MVN__c = emailText;
        update cs;
    } 
    
    @AuraEnabled
    public static void updateFax(String caseId, String faxText){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Case_Account_Fax_MVN__c = faxText;
        update cs;
    } 
    
    @AuraEnabled
    public static String createEmail(String caseId, String email){
        System.debug('caseId -->'+caseId);
        System.debug('email -->'+email);
        Id caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        Account newAccountFields = new Account();
        newAccountFields.PersonEmail = email;
        Case currentCase = new Case();
        currentCase.Id = caseId;
        /*if (newAccountFields.PersonEmail == null || newAccountFields.PersonEmail.length() == 0) {
            hasSaveError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, system.Label.Error_Email_Required));
            return null;
        }*/

        //Account acc = new Account(id=currentCaseAccount.Id);
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Set<String> overWritePersonEmail = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Overwrite_Person_Email_Cust_Typ__c)); 
       
        String accountQuery = 'SELECT ' + String.join(UtilitiesMVN.personAccountSelectFields(), ',')
                            + '  FROM Account WHERE Id = :caseAccountId';

        List<Account> accounts = Database.query(accountQuery);
        
        if(accounts == null || accounts.size() == 0){
            throw new AuraHandledException(Label.MSD_CORE_Error_Retrieving_Account);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Error_Retrieving_Account));
            //return null;
        }

        Account acc = accounts.get(0);

        if(String.isBlank(acc.PersonEmail) || overWritePersonEmail.contains(acc.Class_of_Trade_MRK__c)) {
            acc.PersonEmail = newAccountFields.PersonEmail;
        } else {
            acc.MSD_CORE_Contact_Center_Email__c = newAccountFields.PersonEmail;
        }
        
        SavePoint sp = Database.setSavePoint();

        try {
            update acc;
            System.debug('Acc update successful');
            currentCase.case_Account_Email_MVN__c = newAccountFields.PersonEmail;
            System.debug('currentCase -->'+currentCase);
            update currentCase;
            System.debug('Case update successful');
        }
        catch (Exception e) {
            //hasSaveError = true;
            //ApexPages.addMessages(e);
            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            System.debug('Exception');
            throw new AuraHandledException(Label.MSD_CORE_Error_Retrieving_Account);
        }
        return null;
    }
    
    @AuraEnabled
    public static String createPhone(String caseId, String phone){
        Id caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        Account newAccountFields = new Account();
        newAccountFields.Phone = phone;
        Case currentCase = new Case();
        currentCase.Id = caseId;
        
        Account acc = new Account(id=caseAccountId);

        SavePoint sp = Database.setSavePoint();
        acc.Phone = newAccountFields.Phone;
        try {
            update acc;
            currentCase.case_Account_Phone_MVN__c = acc.Phone;
            update currentCase;
        }
        catch (Exception e) {
            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled
    public static String createFax(String caseId, String fax){
        System.debug('fax -->'+fax);
        Id caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        Account newAccountFields = new Account();
        newAccountFields.Fax = fax;
        Case currentCase = new Case();
        currentCase.Id = caseId;
        
        Account acc = new Account(id=caseAccountId);

        SavePoint sp = Database.setSavePoint();
        acc.Fax = newAccountFields.Fax;
        try {
            update acc;
            currentCase.case_Account_Fax_MVN__c = acc.Fax;
            System.debug('currentCase -->'+currentCase);
            update currentCase;
        }
        catch (Exception e) {
            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled
    public static void createAddress(String caseId, String caseAccId, Address_vod__c newAddress) {
        Case currentCase = new Case();
        currentCase.Id = caseId;
        
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        Set<String> businessRecordTypes = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Type_Has_Business_Address__c));
        Account currentCaseAccount = [SELECT Id, Class_of_Trade_MRK__c,RecordTypeId,Status_MRK__c FROM Account WHERE Id =:caseAccId];
        newAddress.Account_vod__c = currentCaseAccount.Id;
        if (businessRecordTypes.contains(currentCaseAccount.Class_of_Trade_MRK__c)) {
            newAddress.Business_vod__c = true; 
        }

        newAddress.Mailing_vod__c = false;
        newAddress.Home_and_Office_MRK__c = false;

        newAddress.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_vod__c' AND DeveloperName =: settings.MSD_CORE_Company_Maintained_Rec_Type__c].Id; 

        SavePoint sp = Database.setSavePoint();
        try {
            insert newAddress;
            currentCase.Address_MVN__c = newAddress.Id;
            update currentCase;
            Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
            List<String> dcrRecordTypeDeveloperNames = UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_DCR_Record_Types__c);
            List<RecordType> dcrRecordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :dcrRecordTypeDeveloperNames];
            Set<Id> dcrRecordTypeIds = new Set<Id>();
            for(RecordType dcrRecordType : dcrRecordTypes) {
                dcrRecordTypeIds.add(dcrRecordType.Id);
            }
            if(dcrRecordTypeIds.contains(currentCaseAccount.RecordTypeId) &&
                currentCaseAccount.Status_MRK__c != settings.MSD_CORE_Account_Status_Inactive__c &&
                currentCaseAccount.Status_MRK__c != settings.MSD_CORE_Account_Status_Pending__c){
                String country = [SELECT MSD_CORE_Country_Code__c 
                                    FROM User 
                                   WHERE Id = :userinfo.getUserId()].MSD_CORE_Country_Code__c; 
                List<String> fieldsToQuery = new List<String>();
                List<MSD_CORE_NAW_Field_Types__c> accountFields = MSD_CORE_DCRUtility.fieldsFor('Account', country, currentCaseAccount.RecordTypeId);

                for (MSD_CORE_NAW_Field_Types__c field : accountFields){
                    fieldsToQuery.add(field.Field_API_Name__c);
                }
                Id accountId = currentCaseAccount.Id;
                String accountToSubmitQuery = 'SELECT ' + String.join(fieldsToQuery, ', ') +
                                               ' FROM Account WHERE Id = :accountId ' +
                                               'LIMIT 1';
                Account accountToSubmit = Database.query(accountToSubmitQuery);
                MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(accountToSubmit, newAddress);
            }
        } catch (Exception e) {
            newAddress = newAddress.clone(false,true,false,false);
            Database.rollback(sp);
        }
    }    
    
    @AuraEnabled
    public static void check(Address_vod__c newAddress) {
        System.debug('check');
    }
    
    @AuraEnabled
    public static Boolean readOnlyCheck(){
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            return true;
        }
        else{
            return false;
        }
    }
    
    @AuraEnabled
    public static CustomerInfoWrapper getCaseStatusPage(String csId){
        CustomerInfoWrapper  wrap = new CustomerInfoWrapper();
        Schema.DescribeSObjectResult r = Case.sObjectType.getDescribe();
        List<String> apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            apiNames.add(apiName);
        }
        
        List<Case> caseList = database.query('select ' + String.join(apiNames, ',') + ', RecordType.Name from Case where id =: csId'); 
        
        if(caseList.size() > 0)
        {
            wrap.objCase = caseList[0];
        }
        
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            wrap.isReadOnlyUser = true;
        }
        else{
            wrap.isReadOnlyUser = false;
        }
        
        return wrap;
        
    }
    
    @AuraEnabled
    public static InteractionWrapper getCaseInfo(String csId){
        InteractionWrapper wrap = new InteractionWrapper();
        wrap.userProfile = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()].Profile.Name;
        wrap.caseStatus = [SELECT Status FROM Case WHERE Id = :csId].Status;        
        return wrap;
    }
    
     public class InteractionWrapper{
        @AuraEnabled
        public String userProfile;
         @AuraEnabled
        public String caseStatus;
    }
    
    @AuraEnabled
    public static List<pw_ccpro__ZipCode__c> queryZipCodes(String zip){
        zip = zip+'%';
        return [select id, Name, pw_ccpro__City__c, pw_ccpro__State__r.Name, pw_ccpro__State__r.pw_ccpro__Country__r.pw_ccpro__IsoCode_2__c
                from pw_ccpro__ZipCode__c
                where Name like : zip];
    }
    
    @AuraEnabled
    public static MSD_CORE_CC_Request_Links__mdt getRequestLinks()
    {
        MSD_CORE_CC_Request_Links__mdt newRequestLink = [SELECT MSD_CORE_CC_IRMS_Click__c,MSD_CORE_CC_ROME_Click__c,MSD_CORE_CC_Sample_Center_Click__c,MSD_CORE_CC_SAP_Click__c,MSD_CORE_CC_Teamspace_Click__c 
            FROM MSD_CORE_CC_Request_Links__mdt];
        return newRequestLink;
    }
}